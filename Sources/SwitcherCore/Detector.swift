import Foundation

/// Вердикт детектора для набранного слова.
public enum Verdict: Equatable, Sendable {
    /// Слово выглядит как русское, набранное в EN-раскладке — исправить в RU.
    case ru
    /// Слово выглядит как английское, набранное в RU-раскладке — исправить в EN.
    case en
    /// Уверенности нет — слово не трогать.
    case unsure
}

/// Детектор неправильной раскладки: детерминированные правила +
/// биграммные частоты + пользовательские исключения.
/// Перекос в осторожность: лучше промолчать, чем испортить валидное слово.
public final class Detector {

    // MARK: - Пороги (см. комментарии «почему такие»)

    /// Слова короче 3 символов не трогаем: на 1–2 символах ни правила,
    /// ни биграммы не дают уверенности (id, ok, ты, не — всё валидно).
    private static let minWordLength = 3

    /// Штраф за биграмму вне таблицы: чуть ниже минимального табличного
    /// значения (~-3.5), чтобы неизвестная биграмма весила как «очень редкая»,
    /// но одна опечатка не перевешивала всё слово.
    private static let unseenBigramLog = -4.5

    /// Минимальная разница средних лог-вероятностей (на биграмму), чтобы
    /// вынести вердикт по одним частотам. На проверочных валидных словах
    /// максимум ~0.65 (экзотика вроде rhythm); 0.9 оставляет запас —
    /// лучше промолчать, чем испортить валидное слово.
    private static let bigramThreshold = 0.9

    /// Средняя лог-вероятность конверсии должна быть не ниже этого уровня:
    /// если конверсия сама по себе мусор (score < -3.5 ≈ сплошь редкие
    /// биграммы), исправлять не во что — молчим.
    private static let minPlausibleScore = -3.5

    // MARK: - Алфавиты

    /// Строчные кириллические буквы ЙЦУКЕН (включая ё).
    private static let cyrillicLetters = Set("абвгдежзийклмнопрстуфхцчшщъыьэюяё")

    /// Строчные латинские буквы.
    private static let latinLetters = Set("abcdefghijklmnopqrstuvwxyz")

    /// Символы, которые ANSI-клавиатура даёт в EN-раскладке там, где в ЙЦУКЕН
    /// стоят буквы: они законны внутри «латинского кандидата»
    /// (cgfcb,j = спасибо, [jhjij = хорошо).
    private static let latinPunct = Set(";:'\"[]{},.<>`~")

    private enum Alphabet {
        case cyrillic   // целиком кириллица
        case latin      // целиком латиница + пунктуация ЙЦУКЕН-позиций
        case mixed      // смешанное / цифры / символы вне карты
    }

    private static func alphabet(of word: String) -> Alphabet {
        var hasCyrillic = false
        var hasLatin = false
        for ch in word.lowercased() {
            if cyrillicLetters.contains(ch) {
                hasCyrillic = true
            } else if latinLetters.contains(ch) || latinPunct.contains(ch) {
                hasLatin = true
            } else {
                return .mixed // цифра или символ вне карты
            }
            if hasCyrillic && hasLatin { return .mixed }
        }
        if hasCyrillic { return .cyrillic }
        if hasLatin { return .latin }
        return .mixed
    }

    // MARK: - Правила невозможных сочетаний

    /// Символы, не встречающиеся внутри английских слов, но означающие
    /// буквы ЙЦУКЕН при наборе в EN-раскладке (апостроф намеренно исключён:
    /// don't, it's — валидный английский).
    private static let latinImpossiblePunct = Set(";:[]{}<>`~\",.")

    /// Триграммы, не встречающиеся в английских словах, но типичные для
    /// транслита ЙЦУКЕН: ghb=при, ghj=про, cnd/dcn=ств, cnf=ста.
    private static let latinImpossibleTrigrams = ["ghb", "ghj", "cnd", "dcn", "cnf"]

    /// После j в английском почти всегда гласная (или r/w в именах);
    /// j+согласная — след ЙЦУКЕН («о»+согласная).
    private static let jImpossibleFollowers = Set("bcdfghklmnpqstyvxz")

    /// Биграммы, не встречающиеся в русских словах, но типичные для
    /// QWERTY-набора («ы» на s, «щ» на o и т.п.).
    private static let cyrillicImpossibleBigrams = ["кщ", "гь", "дщ", "щц", "щж", "ьу", "уы"]

    /// Русские слова не начинаются с ь/ъ/ы, а с й — только перед гласной
    /// (йод, йогурт).
    private static let cyrillicImpossibleStarts = Set("ьъы")
    private static let russianConsonants = Set("бвгджзйклмнпрстфхцчшщ")

    /// Слово не может быть валидным английским.
    private static func impossibleInEnglish(_ w: [Character]) -> Bool {
        if w.contains(where: { latinImpossiblePunct.contains($0) }) { return true }
        let s = String(w)
        if latinImpossibleTrigrams.contains(where: { s.contains($0) }) { return true }
        for i in 0..<(w.count - 1) {
            if w[i] == "q" && w[i + 1] != "u" { return true }
            if w[i] == "j" && jImpossibleFollowers.contains(w[i + 1]) { return true }
        }
        return false
    }

    /// Слово не может быть валидным русским.
    private static func impossibleInRussian(_ w: [Character]) -> Bool {
        guard let first = w.first else { return false }
        if cyrillicImpossibleStarts.contains(first) { return true }
        if first == "й", w.count > 1, russianConsonants.contains(w[1]) { return true }
        let s = String(w)
        return cyrillicImpossibleBigrams.contains(where: { s.contains($0) })
    }

    // MARK: - Биграммный скоринг

    /// Средняя log10-вероятность биграмм слова (с маркерами границ ^слово$).
    private static func score(_ word: String, table: [String: Double]) -> Double {
        let padded = Array("^" + word + "$")
        var sum = 0.0
        for i in 0..<(padded.count - 1) {
            sum += table[String(padded[i...(i + 1)])] ?? unseenBigramLog
        }
        return sum / Double(padded.count - 1)
    }

    // MARK: - Исключения

    /// Пользовательские слова-исключения, хранятся в нижнем регистре.
    private var exclusions: Set<String> = []

    public init() {}

    /// Добавляет слово в исключения (сравнение без учёта регистра).
    public func addExclusion(_ word: String) {
        exclusions.insert(word.lowercased())
    }

    /// Есть ли слово в исключениях (без учёта регистра).
    public func isExcluded(_ word: String) -> Bool {
        return exclusions.contains(word.lowercased())
    }

    /// Загружает исключения из файла (JSON-массив строк).
    /// Отсутствующий или битый файл означает пустой набор, а не ошибку.
    public func load(from url: URL) {
        guard
            let data = try? Data(contentsOf: url),
            let decoded = try? JSONDecoder().decode([String].self, from: data)
        else {
            exclusions = []
            return
        }
        exclusions = Set(decoded.map { $0.lowercased() })
    }

    /// Сохраняет исключения в файл (JSON-массив строк, отсортирован
    /// для стабильности диффов).
    public func save(to url: URL) {
        guard let data = try? JSONEncoder().encode(exclusions.sorted()) else { return }
        try? data.write(to: url, options: .atomic)
    }

    /// Отвечает на вопрос «это слово набрано не в той раскладке?».
    public func verdict(for word: String) -> Verdict {
        guard word.count >= Self.minWordLength else { return .unsure }
        guard !isExcluded(word) else { return .unsure }

        let lowered = word.lowercased()

        switch Self.alphabet(of: word) {
        case .mixed:
            return .unsure

        case .latin:
            // Кандидат «русское в EN-наборе»: сравниваем правдоподобие
            // конверсии в RU с правдоподобием самого слова как английского.
            let conv = KeyMap.convert(lowered, to: .ru).lowercased()
            let ruScore = Self.score(conv, table: DetectorBigrams.ruBigrams)
            guard ruScore >= Self.minPlausibleScore else { return .unsure }
            let diff = ruScore - Self.score(lowered, table: DetectorBigrams.enBigrams)
            if diff >= Self.bigramThreshold { return .ru }
            // Правило сильнее порога: невозможное для английского сочетание
            // означает, что портить нечего — достаточно перевеса в пользу RU.
            if Self.impossibleInEnglish(Array(lowered)) && diff > 0 { return .ru }
            return .unsure

        case .cyrillic:
            // Кандидат «английское в RU-наборе» — симметрично.
            let conv = KeyMap.convert(lowered, to: .en).lowercased()
            let enScore = Self.score(conv, table: DetectorBigrams.enBigrams)
            guard enScore >= Self.minPlausibleScore else { return .unsure }
            let diff = enScore - Self.score(lowered, table: DetectorBigrams.ruBigrams)
            if diff >= Self.bigramThreshold { return .en }
            if Self.impossibleInRussian(Array(lowered)) && diff > 0 { return .en }
            return .unsure
        }
    }
}
