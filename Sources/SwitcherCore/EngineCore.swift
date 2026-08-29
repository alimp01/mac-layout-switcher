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
    /// Одиночное нажатие-отпускание Option без других клавиш между ними.
    case optionTap
    /// Сброс без исправления: комбинация с Cmd/Ctrl, автоповтор удержания,
    /// перемещение курсора (стрелки, мышь) — текущее слово больше не «наше».
    case reset
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

/// Результат обработки события: команда + побочный факт для персиста.
public struct EngineOutcome: Equatable {
    /// Что должен сделать исполнитель.
    public let command: EngineCommand
    /// Непусто, когда ядро добавило слово в исключения `Detector` (откат
    /// авто-исправления по Option): `Engine` обязан сохранить exclusions.json.
    public let excludedWordToPersist: String?

    public init(command: EngineCommand, excludedWordToPersist: String? = nil) {
        self.command = command
        self.excludedWordToPersist = excludedWordToPersist
    }

    /// Пустой результат — событие ничего не меняет на экране.
    public static let none = EngineOutcome(command: .none, excludedWordToPersist: nil)
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
        now: @escaping () -> Double = { Date().timeIntervalSince1970 }
    ) {
        self.detector = detector
        self.snippets = snippets
        self.autoSwitch = autoSwitch
        self.undoWindow = undoWindow
        self.now = now
    }

    /// Обрабатывает одно событие и возвращает команду исполнителю.
    @discardableResult
    public func handle(_ event: InputEvent) -> EngineOutcome {
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

        case .optionTap:
            return handleOptionTap()
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

    // MARK: - Option

    private func handleOptionTap() -> EngineOutcome {
        // Откат недавнего авто-исправления: вернуть как было + слово в исключения.
        if let auto = lastAuto, now() - auto.time <= undoWindow {
            detector.addExclusion(auto.original)
            lastAuto = nil
            lastRegion = Region(word: auto.original, separator: auto.separator)
            return EngineOutcome(
                command: .replaceLast(
                    len: auto.corrected.count + auto.separator.count,
                    with: auto.original + auto.separator,
                    switchTo: auto.originalLang),
                excludedWordToPersist: auto.original)
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
