// Системный слой macOS. Весь файл — под #if os(macOS): на Linux target
// собирается в пустой executable, чтобы `swift build`/`swift test` были зелёными.
#if os(macOS)
import Foundation
import CoreGraphics
import SwitcherCore

/// Оркестрация: `EventTap` → трансляция `KeyStroke` в абстрактные события
/// `EngineCore` → исполнение команд через `Typist`/`LayoutSwitcher`.
///
/// Вся логика решений живёт в платформонезависимом `EngineCore` (тесты на
/// Linux). Здесь — только перевод CGEvent-мира в события ядра и обратно:
/// детекция одиночного Option, автопауза (secure input / приложение-исключение),
/// разбор модификаторов и разделителей.
///
/// Tap остаётся `.listenOnly`: наша схема исправления (стереть слово вместе с
/// уже напечатанным разделителем и перепечатать) не требует подавления событий,
/// а Option как модификатор ничего не печатает — перехватывать нечего.
public final class Engine {

    private let core: EngineCore
    private let detector: Detector
    private let snippets: SnippetStore
    private let typist: Typist
    private let config: Config
    private let tap = EventTap()

    /// Виртуальный код Backspace (kVK_Delete).
    private static let backspaceKeyCode: UInt16 = 51

    /// Разделители слова. Пунктуация намеренно НЕ здесь: клавиши `;,.[]` в
    /// EN-раскладке дают буквы ЙЦУКЕН внутри слова (cgfcb,j = спасибо), и
    /// детектор рассчитывает видеть их как часть слова. Граница — только пробелы.
    private static let boundaryChars: Set<Character> = [" ", "\t", "\n", "\r"]

    // Детекция «чистого» одиночного Option.
    private var optionDown = false
    private var otherInputSinceOptionDown = false

    public init(config: Config = Config()) {
        self.config = config
        config.load()

        let detector = Detector()
        detector.load(from: config.exclusionsURL)
        let snippets = SnippetStore()
        snippets.load(from: config.snippetsURL)

        self.detector = detector
        self.snippets = snippets
        self.typist = Typist()
        self.core = EngineCore(
            detector: detector,
            snippets: snippets,
            autoSwitch: config.config.autoSwitch)
    }

    /// Включает перехват. `false` — система отказала (нет разрешений).
    @discardableResult
    public func start() -> Bool {
        tap.start { [weak self] stroke in
            self?.handle(keyEvent: stroke)
        }
    }

    /// Останавливает перехват.
    public func stop() {
        tap.stop()
    }

    /// Глобальный тумблер автоисправления (пункт меню). Option-хоткей и сниппеты
    /// продолжают работать при `false`.
    public func setAutoSwitch(_ on: Bool) {
        core.autoSwitch = on
        config.update { $0.autoSwitch = on }
    }

    /// Перечитывает config/snippets/exclusions с диска (после ручной правки
    /// JSON из меню).
    public func reload() {
        config.load()
        detector.load(from: config.exclusionsURL)
        snippets.load(from: config.snippetsURL)
        core.autoSwitch = config.config.autoSwitch
    }

    // MARK: - Приём события от tap

    /// Транслирует один `KeyStroke` в события ядра и исполняет команды.
    public func handle(keyEvent stroke: KeyStroke) {
        // Автопауза: пароли и приложения-исключения — молчим полностью.
        core.isPaused = SecureInput.isActive || isExcludedApp()

        switch stroke.kind {
        case .flagsChanged:
            if let event = optionTapEvent(for: stroke) {
                execute(core.handle(event))
            }
        case .keyDown:
            // Любая печатная/командная клавиша рвёт «чистый» тап Option.
            otherInputSinceOptionDown = true
            for event in translate(stroke) {
                execute(core.handle(event))
            }
        }
    }

    // MARK: - Трансляция keyDown → события ядра

    private func translate(_ stroke: KeyStroke) -> [InputEvent] {
        // Cmd/Ctrl-комбинация — команда приложения, не набор: сброс буфера.
        if stroke.flags.contains(.maskCommand) || stroke.flags.contains(.maskControl) {
            return [.reset]
        }
        // Автоповтор удержания не должен наращивать «слово».
        if stroke.isAutorepeat {
            return [.reset]
        }
        if stroke.keyCode == Self.backspaceKeyCode {
            return [.backspace]
        }
        // Ровно один печатный символ: буква/разделитель. Пусто (стрелки, F-ряд,
        // escape) или дед-ки — курсор мог уйти, слово больше не наше.
        guard stroke.characters.count == 1, let ch = stroke.characters.first else {
            return [.reset]
        }
        if Self.boundaryChars.contains(ch) {
            return [.boundary(ch)]
        }
        return [.char(ch)]
    }

    // MARK: - Детекция одиночного Option

    /// Одиночное нажатие-отпускание Option без других клавиш/модификаторов →
    /// `.optionTap`. Иначе — `nil`.
    private func optionTapEvent(for stroke: KeyStroke) -> InputEvent? {
        let flags = stroke.flags
        let optionNow = flags.contains(.maskAlternate)
        let otherMods: CGEventFlags = [.maskCommand, .maskControl, .maskShift]
        let hasOtherMods = !flags.intersection(otherMods).isEmpty

        if optionNow {
            if !optionDown {
                // Option только что нажат.
                optionDown = true
                otherInputSinceOptionDown = hasOtherMods
            } else if hasOtherMods {
                // Во время удержания Option добавился другой модификатор.
                otherInputSinceOptionDown = true
            }
            return nil
        } else {
            let wasCleanTap = optionDown && !otherInputSinceOptionDown && !hasOtherMods
            optionDown = false
            return wasCleanTap ? .optionTap : nil
        }
    }

    // MARK: - Исполнение команд

    private func execute(_ outcome: EngineOutcome) {
        switch outcome.command {
        case .none:
            break
        case .replaceLast(let len, let text, let switchTo):
            if let lang = switchTo {
                LayoutSwitcher.select(lang)
            }
            typist.replaceLastWord(len: len, with: text)
        }
        // Откат авто-исправления добавил слово в исключения — персистим на диск.
        if outcome.excludedWordToPersist != nil {
            detector.save(to: config.exclusionsURL)
        }
    }

    private func isExcludedApp() -> Bool {
        guard let bundle = FrontApp.bundleID else { return false }
        return config.config.excludedApps.contains(bundle)
    }
}
#endif
