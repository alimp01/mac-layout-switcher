import Foundation

/// Абстрактное входное событие платформонезависимого ядра решений.
/// macOS-`Engine` транслирует сюда CGEvent/`KeyStroke`; Linux-тесты подают
/// события напрямую — весь смысл в том, чтобы решение «что сделать» жило здесь.
public enum InputEvent: Equatable {
    /// Печатный символ, добавляемый к текущему слову.
    case char(Character)
    /// Backspace: убрать последний символ слова.
    case backspace
    /// Граница слова (пробел/таб/enter/…). `Character` — сам разделитель:
    /// он уже напечатан пользователем, поэтому команда замены его сохраняет.
    case boundary(Character)
    /// Сработал сконфигурированный хоткей. macOS-`Engine` решает, что это за
    /// клавиша (через `Hotkey.matches`), и шлёт соответствующее действие.
    case hotkey(HotkeyAction)
    /// Сброс без исправления: комбинация с Cmd/Ctrl, автоповтор удержания,
    /// перемещение курсора (стрелки, мышь) — текущее слово больше не «наше».
    case reset
}

/// Действие настраиваемого хоткея (таск 08). `convert` — прежнее поведение
/// одиночного Option: конвертация текущего/последнего слова или откат
/// авто-исправления в окне отмены. `toggleAuto` — вкл/выкл автопереключения.
public enum HotkeyAction: Equatable, Sendable {
    case convert
    case toggleAuto
}

/// Команда исполнителю. macOS-`Engine` переводит её в вызовы
/// `Typist`/`LayoutSwitcher`.
public enum EngineCommand: Equatable {
    /// Ничего не делать.
    case none
    /// Стереть `len` символов Backspace'ами и напечатать `text`; если `switchTo`
    /// задан — переключить системную раскладку. Разделитель, если он был,
    /// уже включён в `text` (заменяется слово, но добраться до него можно
    /// только стерев разделитель — поэтому его перепечатываем).
    case replaceLast(len: Int, with: String, switchTo: Lang?)
}

/// Результат обработки события: команда + побочные факты для персиста.
public struct EngineOutcome: Equatable {
    /// Что должен сделать исполнитель.
    public let command: EngineCommand
    /// Непусто, когда ядро добавило слово в исключения `Detector` (откат
    /// авто-исправления по Option достиг порога): `Engine` обязан сохранить
    /// exclusions.json.
    public let excludedWordToPersist: String?
    /// Непусто, когда откат изменил счётчик отмен слова (увеличил на 1 или
    /// сбросил в 0 при достижении порога): `Engine` обязан сохранить
    /// undo-counts.json. Ключ — исходное слово, регистр как пришёл.
    public let undoCountUpdate: (word: String, count: Int)?

    public init(
        command: EngineCommand,
        excludedWordToPersist: String? = nil,
        undoCountUpdate: (word: String, count: Int)? = nil
    ) {
        self.command = command
        self.excludedWordToPersist = excludedWordToPersist
        self.undoCountUpdate = undoCountUpdate
    }

    /// Пустой результат — событие ничего не меняет на экране.
    public static let none = EngineOutcome(command: .none)

    /// Ручной `==`: кортеж `undoCountUpdate` блокирует синтез Equatable.
    public static func == (lhs: EngineOutcome, rhs: EngineOutcome) -> Bool {
        guard lhs.command == rhs.command,
              lhs.excludedWordToPersist == rhs.excludedWordToPersist else { return false }
        switch (lhs.undoCountUpdate, rhs.undoCountUpdate) {
        case (nil, nil): return true
        case let (l?, r?): return l.word == r.word && l.count == r.count
        default: return false
        }
    }
}

/// Ядро логики переключателя: поток абстрактных событий → команды.
/// Платформонезависимо и детерминированно — вся склейка тестируется на Linux.
/// macOS-`Engine` лишь транслирует события и исполняет команды.
public final class EngineCore {

    private let buffer = WordBuffer()
    private let detector: Detector
    private let snippets: SnippetStore
    private let now: () -> Double
    private let undoWindow: Double

    /// Порог отмен одной и той же замены, после которого слово уходит в
    /// исключения автоматически (spec G03, дефолт 3). `1` воспроизводит
    /// прежнее поведение — исключение с первого отката.
    private let undoThreshold: Int

    /// Счётчики отмен per-word (ключ — исходное слово в нижнем регистре,
    /// консистентно с `Detector.isExcluded`). Переживают перезапуск: приходят
    /// в `init` из undo-counts.json и отдаются наружу через `undoCountUpdate`.
    private var undoCounts: [String: Int]

    /// Глобальный тумблер автоисправления по детектору. `false` → детектор
    /// молчит, но Option-хоткей и сниппеты продолжают работать (см. spec).
    public var autoSwitch: Bool

    /// Автопауза: secure input или приложение-исключение. `true` → ядро молчит
    /// полностью и не буферизует (пароли и команды терминала не копим).
    public var isPaused: Bool = false {
        didSet {
            guard isPaused, !oldValue else { return }
            buffer.reset()
            lastRegion = nil
            lastAuto = nil
        }
    }

    /// Последняя область у курсора, пригодная к ручной конвертации по Option:
    /// либо незавершённое слово в буфере (separator == ""), либо только что
    /// завершённое слово вместе с его разделителем.
    private struct Region {
        var word: String
        var separator: String
    }
    private var lastRegion: Region?

    /// Последнее АВТО-исправление — для отката по Option в окне `undoWindow`.
    private struct AutoCorrection {
        let original: String
        let corrected: String
        let separator: String
        /// Раскладка, которую надо вернуть при откате (была до исправления).
        let originalLang: Lang
        let time: Double
    }
    private var lastAuto: AutoCorrection?

    public init(
        detector: Detector,
        snippets: SnippetStore,
        autoSwitch: Bool = true,
        undoWindow: Double = 5,
        undoThreshold: Int = 3,
        undoCounts: [String: Int] = [:],
        now: @escaping () -> Double = { Date().timeIntervalSince1970 }
    ) {
        self.detector = detector
        self.snippets = snippets
        self.autoSwitch = autoSwitch
        self.undoWindow = undoWindow
        self.undoThreshold = undoThreshold
        // Нормализуем ключи к нижнему регистру — сравнение без учёта регистра.
        self.undoCounts = Dictionary(
            undoCounts.map { ($0.key.lowercased(), $0.value) },
            uniquingKeysWith: { max($0, $1) })
        self.now = now
    }

    /// Обрабатывает одно событие и возвращает команду исполнителю.
    @discardableResult
    public func handle(_ event: InputEvent) -> EngineOutcome {
        // Переключение автопереключения — глобальная настройка, а не работа с
        // текстом: срабатывает даже на автопаузе (secure input / приложение-
        // исключение), где ядро иначе молчит.
        if case .hotkey(.toggleAuto) = event {
            autoSwitch.toggle()
            return .none
        }

        if isPaused { return .none }

        switch event {
        case .char(let c):
            buffer.append(char: c)
            // Печать после исправления закрывает окно отката и начинает новое
            // слово — прошлая завершённая область больше не «последняя».
            lastAuto = nil
            lastRegion = nil
            return .none

        case .backspace:
            buffer.backspace()
            lastAuto = nil
            return .none

        case .reset:
            buffer.reset()
            lastAuto = nil
            lastRegion = nil
            return .none

        case .boundary(let sep):
            return handleBoundary(sep)

        case .hotkey(.convert):
            return handleConvert()

        case .hotkey(.toggleAuto):
            // Обработано выше, до guard isPaused; сюда не доходит.
            return .none
        }
    }

    // MARK: - Граница слова

    private func handleBoundary(_ sep: Character) -> EngineOutcome {
        let word = buffer.word
        buffer.boundary()
        lastAuto = nil

        guard !word.isEmpty else {
            lastRegion = nil
            return .none
        }
        let sepStr = String(sep)

        // 1) Сниппеты — приоритет выше детектора; после разворота детектор
        //    к этому слову не применяется.
        if let expansion = snippets.expansion(for: word) {
            lastRegion = Region(word: expansion, separator: sepStr)
            return EngineOutcome(command: .replaceLast(
                len: word.count + sepStr.count,
                with: expansion + sepStr,
                switchTo: nil))
        }

        // 2) Автоисправление по детектору (если глобально включено).
        if autoSwitch {
            switch detector.verdict(for: word) {
            case .ru: return autoCorrect(word: word, sep: sepStr, to: .ru)
            case .en: return autoCorrect(word: word, sep: sepStr, to: .en)
            case .unsure: break
            }
        }

        // 3) Ничего не исправляем, но слово остаётся кандидатом на ручную
        //    конвертацию по Option.
        lastRegion = Region(word: word, separator: sepStr)
        return .none
    }

    private func autoCorrect(word: String, sep: String, to lang: Lang) -> EngineOutcome {
        let converted = KeyMap.convert(word, to: lang)
        let originalLang: Lang = (lang == .ru) ? .en : .ru
        lastRegion = Region(word: converted, separator: sep)
        lastAuto = AutoCorrection(
            original: word, corrected: converted, separator: sep,
            originalLang: originalLang, time: now())
        return EngineOutcome(command: .replaceLast(
            len: word.count + sep.count,
            with: converted + sep,
            switchTo: lang))
    }

    // MARK: - Конвертация/откат (хоткей .convert, прежний Option)

    private func handleConvert() -> EngineOutcome {
        // Откат недавнего авто-исправления: всегда возвращаем как было; в
        // исключения слово уходит только по достижении порога отмен (spec G03).
        if let auto = lastAuto, now() - auto.time <= undoWindow {
            lastAuto = nil
            lastRegion = Region(word: auto.original, separator: auto.separator)
            let command = EngineCommand.replaceLast(
                len: auto.corrected.count + auto.separator.count,
                with: auto.original + auto.separator,
                switchTo: auto.originalLang)

            let key = auto.original.lowercased()
            let bumped = (undoCounts[key] ?? 0) + 1
            if bumped >= undoThreshold {
                // Порог достигнут — исключаем слово и сбрасываем счётчик.
                detector.addExclusion(auto.original)
                undoCounts[key] = 0
                return EngineOutcome(
                    command: command,
                    excludedWordToPersist: auto.original,
                    undoCountUpdate: (word: auto.original, count: 0))
            } else {
                // Ниже порога — только считаем, слово не исключаем.
                undoCounts[key] = bumped
                return EngineOutcome(
                    command: command,
                    undoCountUpdate: (word: auto.original, count: bumped))
            }
        }

        // Ручная конвертация. Незавершённое слово в буфере имеет приоритет.
        if !buffer.word.isEmpty {
            let word = buffer.word
            let target = Self.conversionTarget(for: word)
            let converted = KeyMap.convert(word, to: target)
            setBuffer(to: converted)
            lastRegion = nil
            return EngineOutcome(command: .replaceLast(
                len: word.count, with: converted, switchTo: target))
        }

        // Иначе — последнее завершённое слово вместе с его разделителем.
        if let region = lastRegion, !region.word.isEmpty {
            let target = Self.conversionTarget(for: region.word)
            let converted = KeyMap.convert(region.word, to: target)
            lastRegion = Region(word: converted, separator: region.separator)
            return EngineOutcome(command: .replaceLast(
                len: region.word.count + region.separator.count,
                with: converted + region.separator,
                switchTo: target))
        }

        return .none
    }

    // MARK: - Вспомогательное

    private static let cyrillicSet =
        Set("абвгдежзийклмнопрстуфхцчшщъыьэюяёАБВГДЕЖЗИЙКЛМНОПРСТУФХЦЧШЩЪЫЬЭЮЯЁ")

    /// Куда конвертировать при ручном Option: слово с кириллицей → в EN,
    /// иначе → в RU. Так повторный Option естественно возвращает как было.
    private static func conversionTarget(for word: String) -> Lang {
        word.contains(where: { cyrillicSet.contains($0) }) ? .en : .ru
    }

    private func setBuffer(to text: String) {
        buffer.reset()
        for ch in text { buffer.append(char: ch) }
    }
}
