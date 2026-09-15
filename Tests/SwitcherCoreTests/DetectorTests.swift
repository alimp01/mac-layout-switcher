import XCTest
import Foundation
import SwitcherCore

final class DetectorTests: XCTestCase {

    // MARK: - Защитные правила: короткие, смешанные, с цифрами → .unsure

    func testShortMixedAndDigitWordsAreUnsure() {
        let detector = Detector()

        // Короче 3 символов — всегда .unsure, даже явный транслит.
        XCTAssertEqual(detector.verdict(for: "gh"), .unsure)
        XCTAssertEqual(detector.verdict(for: "ы"), .unsure)
        XCTAssertEqual(detector.verdict(for: ""), .unsure)

        // Смешанный алфавит — .unsure.
        XCTAssertEqual(detector.verdict(for: "приvet"), .unsure)
        XCTAssertEqual(detector.verdict(for: "helло"), .unsure)

        // Цифры и символы вне карты — .unsure.
        XCTAssertEqual(detector.verdict(for: "ghb123"), .unsure)
        XCTAssertEqual(detector.verdict(for: "привет7"), .unsure)
        XCTAssertEqual(detector.verdict(for: "a+b=c"), .unsure)
    }

    // MARK: - Контрольный корпус (≥60 слов)

    /// Русские слова, набранные в EN-раскладке (конверсия выполнена вручную
    /// по ANSI ЙЦУКЕН↔QWERTY). Ожидаемый вердикт — .ru.
    private static let russianTypedInEn: [String] = [
        "ghbdtn",        // привет
        "cgfcb,j",       // спасибо
        "ghbrk.xtybt",   // приключение
        "[jhjij",        // хорошо
        "hf,jnf",        // работа
        "ctujlyz",       // сегодня
        "xtkjdtr",       // человек
        "djghjc",        // вопрос
        "gj;fkeqcnf",    // пожалуйста
        "plhfdcndeqnt",  // здравствуйте
        "vjkjrj",        // молоко
        ",scnhj",        // быстро
        "dhtvz",         // время
        "ltymub",        // деньги
        "ghjtrn",        // проект
        "rjvgm.nth",     // компьютер
        "ntktajy",       // телефон
        "pfdnhf",        // завтра
        "ctqxfc",        // сейчас
        "gbcmvj",        // письмо
        "dcnhtxf",       // встреча
        "pflfxf",        // задача
    ]

    /// Английские слова, набранные в RU-раскладке. Ожидаемый вердикт — .en.
    private static let englishTypedInRu: [String] = [
        "руддщ",         // hello
        "ерфтл",         // thank
        "цщкдв",         // world
        "йгуыешщт",      // question
        "здуфыу",        // please
        "сщьзгеук",      // computer
        "цштвщцы",       // windows
        "зкщоусе",       // project
        "ыукмук",        // server
        "гзвфеу",        // update
        "зфыыцщкв",      // password
        "ыныеуь",        // system
        "ышьзду",        // simple
        "тгьиук",        // number
        "ьууештп",       // meeting
    ]

    /// Валидные английские слова — трогать нельзя: 0 ложных срабатываний.
    private static let validEnglish: [String] = [
        "hello", "the", "question", "url", "code", "work", "table",
        "house", "water", "people", "think", "right", "small", "place",
        "point", "great", "group", "name", "time", "good",
    ]

    /// Валидные русские слова — трогать нельзя: 0 ложных срабатываний.
    private static let validRussian: [String] = [
        "привет", "спасибо", "работа", "вопрос", "человек", "сегодня",
        "окно", "время", "деньги", "встреча", "письмо", "хорошо",
        "задача", "проект", "молоко",
    ]

    /// Спорные короткие — всегда .unsure.
    private static let ambiguousShort: [String] = ["id", "ok", "on", "да", "ты"]

    func testCorpusNoFalsePositivesOnValidWords() {
        let detector = Detector()
        for word in Self.validEnglish {
            XCTAssertEqual(detector.verdict(for: word), .unsure,
                           "валидное английское «\(word)» нельзя трогать")
        }
        for word in Self.validRussian {
            XCTAssertEqual(detector.verdict(for: word), .unsure,
                           "валидное русское «\(word)» нельзя трогать")
        }
        for word in Self.ambiguousShort {
            XCTAssertEqual(detector.verdict(for: word), .unsure,
                           "спорное короткое «\(word)» нельзя трогать")
        }
    }

    func testCorpusDetectsWrongLayoutWords() {
        let detector = Detector()
        var hits = 0
        let total = Self.russianTypedInEn.count + Self.englishTypedInRu.count

        for word in Self.russianTypedInEn {
            let v = detector.verdict(for: word)
            XCTAssertNotEqual(v, .en, "«\(word)» — русское в EN-наборе, вердикт .en опасен")
            if v == .ru { hits += 1 }
        }
        for word in Self.englishTypedInRu {
            let v = detector.verdict(for: word)
            XCTAssertNotEqual(v, .ru, "«\(word)» — английское в RU-наборе, вердикт .ru опасен")
            if v == .en { hits += 1 }
        }

        let accuracy = Double(hits) / Double(total)
        XCTAssertGreaterThanOrEqual(accuracy, 0.9,
            "точность на однозначных: \(hits)/\(total)")
    }

    // MARK: - Короткие частотные слова (G13)

    func testShortRussianWordsTypedInEnAreDetected() {
        // «Rfr» = «Как», ns = ты, yt = не, jy = он. Каждое слово из 2+ букв —
        // на свежем детекторе: без контекста, чисто по словарям.
        for word in ["Rfr", "ns", "yt", "jy", "xnj", "'nj", "tckb"] {
            XCTAssertEqual(Detector().verdict(for: word), .ru, "«\(word)» — русское в EN-наборе")
        }
    }

    func testSingleLetterWordsNeedConfirmingContext() {
        // Однобуквенные (b = и, d = в, z = я) без контекста — не трогать:
        // «plan b» в английском тексте не должен стать «plan и».
        for word in ["b", "d", "z", "c", "ы", "в"] {
            XCTAssertEqual(Detector().verdict(for: word), .unsure, "«\(word)» без контекста")
        }

        let detector = Detector()
        // После английского слова «b» остаётся английским.
        XCTAssertEqual(detector.verdict(for: "plan"), .unsure)
        XCTAssertEqual(detector.verdict(for: "b"), .unsure)

        // После русского слова (исправленного или валидного) — по инерции.
        XCTAssertEqual(detector.verdict(for: "ghbdtn"), .ru)
        XCTAssertEqual(detector.verdict(for: "b"), .ru)
        XCTAssertEqual(detector.verdict(for: "d"), .ru)
        XCTAssertEqual(detector.verdict(for: "привет"), .unsure)
        XCTAssertEqual(detector.verdict(for: "z"), .ru)

        // Симметрично: кириллическая «ф» (= a) после английского → .en,
        // после русского — остаётся.
        XCTAssertEqual(detector.verdict(for: "руддщ"), .en)
        XCTAssertEqual(detector.verdict(for: "ф"), .en)
        XCTAssertEqual(detector.verdict(for: "привет"), .unsure)
        XCTAssertEqual(detector.verdict(for: "ф"), .unsure)

        detector.resetContext()
        XCTAssertEqual(detector.verdict(for: "b"), .unsure)
    }

    func testValidShortWordsAreLeftAloneWithoutContext() {
        for word in ["of", "to", "is", "it", "in", "on", "we", "a", "I", "the", "and", "ok", "tv"] {
            XCTAssertEqual(Detector().verdict(for: word), .unsure, "валидное английское «\(word)»")
        }
        for word in ["и", "в", "на", "не", "я", "он", "Как", "ща"] {
            XCTAssertEqual(Detector().verdict(for: word), .unsure, "валидное русское «\(word)»")
        }
        // Английское в RU-наборе — симметрично: «ерфе» = that.
        XCTAssertEqual(Detector().verdict(for: "ерфе"), .en)
    }

    func testCollisionsAreResolvedByContextOfPreviousWord() {
        let detector = Detector()

        // «of» ↔ «ща»: обе стороны частотны. Без контекста — не трогать.
        XCTAssertEqual(detector.verdict(for: "of"), .unsure)

        // После русского слова (исправленного) — латинское «of» = «ща».
        XCTAssertEqual(detector.verdict(for: "ghbdtn"), .ru)
        XCTAssertEqual(detector.verdict(for: "of"), .ru)

        // После валидного английского — «of» остаётся английским.
        XCTAssertEqual(detector.verdict(for: "hello"), .unsure)
        XCTAssertEqual(detector.verdict(for: "of"), .unsure)
        XCTAssertEqual(detector.verdict(for: "vs"), .unsure)

        // Симметрично: «ща» после английского в RU-наборе → «of»,
        // после валидного русского — остаётся русским.
        XCTAssertEqual(detector.verdict(for: "руддщ"), .en)
        XCTAssertEqual(detector.verdict(for: "ща"), .en)
        XCTAssertEqual(detector.verdict(for: "привет"), .unsure)
        XCTAssertEqual(detector.verdict(for: "ща"), .unsure)
        XCTAssertEqual(detector.verdict(for: "рук"), .unsure)

        // Контекст даёт и слово, оставленное как есть: «Как» — валидное
        // русское, после него «vs» = «мы».
        XCTAssertEqual(detector.verdict(for: "Как"), .unsure)
        XCTAssertEqual(detector.verdict(for: "vs"), .ru)

        // resetContext() возвращает к «без контекста».
        detector.resetContext()
        XCTAssertEqual(detector.verdict(for: "vs"), .unsure)

        // Смешанное слово контекст не трогает: после русского «ghb123» не
        // мешает «of» решиться в RU.
        XCTAssertEqual(detector.verdict(for: "ghbdtn"), .ru)
        XCTAssertEqual(detector.verdict(for: "ghb123"), .unsure)
        XCTAssertEqual(detector.verdict(for: "of"), .ru)
    }

    func testShortWordCaseSurvivesConversionEndToEnd() {
        // «Rfr ns b z» → «Как ты и я»: вердикт по словарю, регистр — KeyMap.
        let detector = Detector()
        let typed = ["Rfr", "ns", "b", "z"]
        var fixed: [String] = []
        for word in typed {
            XCTAssertEqual(detector.verdict(for: word), .ru)
            fixed.append(KeyMap.convert(word, to: .ru))
        }
        XCTAssertEqual(fixed.joined(separator: " "), "Как ты и я")
    }

    // MARK: - Исключения

    private func makeTempFile() -> URL {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("exclusions-test-\(UUID().uuidString).json")
        addTeardownBlock {
            try? FileManager.default.removeItem(at: url)
        }
        return url
    }

    func testExclusionsSilenceVerdictAndSurviveReload() throws {
        let detector = Detector()

        // «ghbdtn» — однозначный транслит, детектор его ловит…
        XCTAssertEqual(detector.verdict(for: "ghbdtn"), .ru)

        // …но после добавления в исключения — всегда .unsure,
        // без учёта регистра.
        detector.addExclusion("GhBdTn")
        XCTAssertTrue(detector.isExcluded("ghbdtn"))
        XCTAssertTrue(detector.isExcluded("GHBDTN"))
        XCTAssertFalse(detector.isExcluded("руддщ"))
        XCTAssertEqual(detector.verdict(for: "ghbdtn"), .unsure)
        XCTAssertEqual(detector.verdict(for: "GHBDTN"), .unsure)

        // Исключения переживают сохранение и загрузку из JSON.
        let url = makeTempFile()
        detector.addExclusion("руддщ")
        detector.save(to: url)

        let reloaded = Detector()
        reloaded.load(from: url)
        XCTAssertTrue(reloaded.isExcluded("ghbdtn"))
        XCTAssertEqual(reloaded.verdict(for: "ghbdtn"), .unsure)
        XCTAssertEqual(reloaded.verdict(for: "руддщ"), .unsure)
        // Не из списка — детектируется по-прежнему.
        XCTAssertEqual(reloaded.verdict(for: "cgfcb,j"), .ru)
    }

    func testLoadOfMissingOrCorruptFileMeansEmptyExclusions() throws {
        let missing = makeTempFile() // файл не создан
        let detector = Detector()
        detector.addExclusion("ghbdtn")
        detector.load(from: missing)
        XCTAssertFalse(detector.isExcluded("ghbdtn"), "load заменяет набор целиком")

        let corrupt = makeTempFile()
        try #"{"не": "массив"#.write(to: corrupt, atomically: true, encoding: .utf8)
        detector.addExclusion("ghbdtn")
        detector.load(from: corrupt)
        XCTAssertFalse(detector.isExcluded("ghbdtn"))
    }
}
