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

    /// Озвучка ввода (история G02). Инжектится из `main` после создания Engine;
    /// nil → работаем молча. Клик звучит на каждый keyDown, отдельные сигналы —
    /// на исправление и откат (см. `playSound(for:)`).
    public var sounds: Sounds?

    /// Вызывается, когда автопереключение поменялось хоткеем `.toggleAuto` —
    /// `main` обновляет галочку в меню. Аргумент — новое состояние.
    public var onAutoSwitchChanged: ((Bool) -> Void)?

    /// Вызывается после каждого programmatic `LayoutSwitcher.select` (авто-
    /// исправление, Option-конвертация, откат) — `main` обновляет индикатор
    /// раскладки в меню-баре, не дожидаясь системного уведомления. Может прийти
    /// не с главного потока — получатель сам уходит на main.
    public var onLayoutSwitched: ((Lang) -> Void)?

    /// Виртуальный код Backspace (kVK_Delete).
    private static let backspaceKeyCode: UInt16 = 51

    /// Разделители слова. Пунктуация намеренно НЕ здесь: клавиши `;,.[]` в
    /// EN-раскладке дают буквы ЙЦУКЕН внутри слова (cgfcb,j = спасибо), и
    /// детектор рассчитывает видеть их как часть слова. Граница — только пробелы.
    private static let boundaryChars: Set<Character> = [" ", "\t", "\n", "\r"]

    // Детекция «чистого» тапа модификатора(ов) — обобщение прежней логики
    // одиночного Option на любой сконфигурированный модификатор-хоткей.
    // `peak` — максимальный набор модификаторов за текущий жест удержания;
    // `dirty` — во время жеста была нажата обычная клавиша (жест уже не «чистый
    // тап», это набор текста/комбинация).
    private var modifierGesturePeak: Set<Hotkey.Modifier> = []
    private var modifierGestureDirty = false

    /// Счётчики отмен per-word (spec G03). Загружаются из undo-counts.json при
    /// старте, обновляются по `EngineOutcome.undoCountUpdate` и сохраняются.
    private var undoCounts: [String: Int]

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

        let undoCounts = config.loadUndoCounts()
        self.undoCounts = undoCounts
        self.core = EngineCore(
            detector: detector,
            snippets: snippets,
            autoSwitch: config.config.autoSwitch,
            undoThreshold: config.config.undoThreshold,
            undoCounts: undoCounts)
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
            if let event = modifierTapEvent(for: stroke) {
                dispatch(event)
            }
        case .keyDown:
            // Клик — только когда ядро НЕ на паузе: в secure input (пароль) и
            // в приложениях-исключениях озвучка молчит полностью (история 4/A01).
            if !core.isPaused { sounds?.playKey() }
            // Любая печатная/командная клавиша рвёт «чистый» тап модификатора.
            modifierGestureDirty = true
            // Хоткей с обычной клавишей (например ⌘⇧K)? Тогда это хоткей, а не
            // набор — шлём действие вместо трансляции символа.
            if let event = hotkeyEvent(
                keyCode: stroke.keyCode, modifiers: modifierSet(from: stroke.flags)) {
                dispatch(event)
                return
            }
            for event in translate(stroke) {
                dispatch(event)
            }
        }
    }

    /// Прогоняет одно событие через ядро и исполняет команду; для `.toggleAuto`
    /// дополнительно персистит config и уведомляет UI.
    private func dispatch(_ event: InputEvent) {
        let outcome = core.handle(event)
        execute(outcome)
        playSound(for: outcome)
        if case .hotkey(.toggleAuto) = event {
            config.update { $0.autoSwitch = core.autoSwitch }
            onAutoSwitchChanged?(core.autoSwitch)
        }
    }

    /// Звук по итогу события: откат авто-исправления (в исключения ушло слово) —
    /// сигнал отката; любая другая замена (авто-исправление, конвертация по
    /// Option, разворот сниппета) — сигнал исправления. Клик на keyDown играет
    /// отдельно в `handle`.
    private func playSound(for outcome: EngineOutcome) {
        guard case .replaceLast = outcome.command else { return }
        if outcome.excludedWordToPersist != nil {
            sounds?.playUndo()
        } else {
            sounds?.playCorrection()
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

    // MARK: - Детекция тапа модификатора(ов) и сопоставление с хоткеем

    /// Собирает набор модификаторов из CGEventFlags. Левый и правый вариант
    /// одной клавиши намеренно НЕ различаются (обе Option → `.option`): так
    /// дефолтный хоткей `[.option]` срабатывает и на левый, и на правый Option,
    /// сохраняя прежнее поведение. Правые `Modifier`-кейсы существуют в модели,
    /// но окно-рекордер и Engine пишут/читают обобщённые модификаторы.
    private func modifierSet(from flags: CGEventFlags) -> Set<Hotkey.Modifier> {
        var mods: Set<Hotkey.Modifier> = []
        if flags.contains(.maskCommand) { mods.insert(.command) }
        if flags.contains(.maskAlternate) { mods.insert(.option) }
        if flags.contains(.maskControl) { mods.insert(.control) }
        if flags.contains(.maskShift) { mods.insert(.shift) }
        if flags.contains(.maskAlphaShift) { mods.insert(.capsLock) }
        if flags.contains(.maskSecondaryFn) { mods.insert(.function) }
        return mods
    }

    /// Одиночный/составной тап модификаторов без промежуточных обычных клавиш →
    /// событие соответствующего хоткея. Жест начинается, когда модификаторы
    /// появляются, и завершается, когда все отпущены; `dirty` рвёт его при любой
    /// обычной клавише. Решение «этот тап = такой-то хоткей» принимает
    /// `Hotkey.matches` (keyCode: nil).
    private func modifierTapEvent(for stroke: KeyStroke) -> InputEvent? {
        let mods = modifierSet(from: stroke.flags)
        if mods.isEmpty {
            let peak = modifierGesturePeak
            let dirty = modifierGestureDirty
            modifierGesturePeak = []
            modifierGestureDirty = false
            guard !dirty, !peak.isEmpty else { return nil }
            return hotkeyEvent(keyCode: nil, modifiers: peak)
        } else {
            if modifierGesturePeak.isEmpty {
                modifierGesturePeak = mods
                modifierGestureDirty = false
            } else {
                modifierGesturePeak.formUnion(mods)
            }
            return nil
        }
    }

    /// Сопоставляет описание нажатия с настроенными хоткеями. Конвертация имеет
    /// приоритет над переключением авто (если пользователь назначил одно и то же
    /// — срабатывает конвертация).
    private func hotkeyEvent(
        keyCode: UInt16?, modifiers: Set<Hotkey.Modifier>) -> InputEvent? {
        if config.config.convertHotkey.matches(keyCode: keyCode, modifiers: modifiers) {
            return .hotkey(.convert)
        }
        if let toggle = config.config.toggleAutoHotkey,
           toggle.matches(keyCode: keyCode, modifiers: modifiers) {
            return .hotkey(.toggleAuto)
        }
        return nil
    }

    // MARK: - Исполнение команд

    private func execute(_ outcome: EngineOutcome) {
        switch outcome.command {
        case .none:
            break
        case .replaceLast(let len, let text, let switchTo):
            if let lang = switchTo {
                LayoutSwitcher.select(lang)
                onLayoutSwitched?(lang)
            }
            typist.replaceLastWord(len: len, with: text)
        }
        // Откат авто-исправления добавил слово в исключения — персистим на диск.
        if outcome.excludedWordToPersist != nil {
            detector.save(to: config.exclusionsURL)
        }
        // Счётчик отмен изменился — сохраняем, чтобы пережить перезапуск.
        if let upd = outcome.undoCountUpdate {
            undoCounts[upd.word.lowercased()] = upd.count
            config.saveUndoCounts(undoCounts)
        }
    }

    private func isExcludedApp() -> Bool {
        guard let bundle = FrontApp.bundleID else { return false }
        return config.config.excludedApps.contains(bundle)
    }
}
#endif
