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
/// Tap АКТИВНЫЙ (`.defaultTap`, G12 — пересмотр ADR 0004): разделитель
/// (Enter/пробел/Tab) перехватывается ДО доставки. Если слово надо исправить
/// (детектор или сниппет), исходное нажатие подавляется (`.suppress`), слово
/// стирается и перепечатывается на очереди `Typist`, раскладка переключается,
/// и ТОЛЬКО ПОТОМ разделитель досылается синтетически — тем же keyCode и с
/// теми же модификаторами, что нажал пользователь. Так Enter в чате не улетает
/// как отправка сообщения с опечаткой. Если исправлять нечего — `.pass`, без
/// задержки. Хоткеи и flagsChanged — всегда `.pass`.
///
/// Три инварианта активного tap'а:
/// 1. Разделитель не теряется: `.suppress` возвращается ТОЛЬКО когда события
///    досылки уже созданы (`Typist.makeKeyPress`, синхронно); не удалось —
///    нажатие проходит как есть, а исправление уходит в legacy-варианте
///    (стереть слово вместе с доставленным разделителем и перепечатать оба).
/// 2. Ввод во время перепечатки не перемешивается с синтетикой: пока очередь
///    `Typist` занята, пользовательские keyDown (буквы/Backspace/разделители/
///    команды) прогоняются через ядро сразу (порядок решений сохраняется), а
///    само нажатие подавляется и переигрывается той же очередью следом — в
///    исходном порядке, с маркером синтетики (tap его повторно не обработает).
/// 3. В колбэке нет I/O: персист exclusions/undo-counts/config уходит на
///    фоновую очередь `Config`; колбэк только решает и ставит задания.
public final class Engine {

    private let core: EngineCore
    private let detector: Detector
    private let snippets: SnippetStore
    private let typist: Typist
    private let config: Config
    private let tap = EventTap()
    let dictation = DictationCoordinator()
    private var dictationGesture = DictationGesture()
    private var dictationRequested = false
    private var suppressedKeyUps: Set<UInt16> = []
    private var waitForRecorderModifiersUp = false
    var isRecordingHotkey = false {
        didSet {
            resetPhysicalInputState()
            if isRecordingHotkey {
                dictation.cancel()
                _ = core.handle(.reset)
            } else {
                waitForRecorderModifiersUp = true
            }
        }
    }

    /// Озвучка ввода (истории G02/G10). Инжектится из `main` после создания
    /// Engine; nil → работаем молча. Звучат только исправление и откат
    /// (см. `playSound(for:)`) — на обычные нажатия звука нет.
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
        // separatorAlreadyTyped: false — активный tap перехватывает разделитель
        // до доставки, ядро просит дослать его после перепечатки.
        self.core = EngineCore(
            detector: detector,
            snippets: snippets,
            autoSwitch: config.config.autoSwitch,
            undoThreshold: config.config.undoThreshold,
            undoCounts: undoCounts,
            separatorAlreadyTyped: false)
        dictation.shortcutName = { [weak config] in config?.config.dictationHotkey.displayName ?? "" }
        dictation.onInsert = { [weak self] text, target, permit, completion in
            guard let self else { completion(text); return }
            _ = self.core.handle(.reset)
            self.typist.insertDictation(text, target: target, permit: permit) { [weak self] remaining in
                _ = self?.core.handle(.reset)
                completion(remaining)
            }
        }
    }

    /// Включает перехват. `false` — система отказала (нет разрешений).
    @discardableResult
    public func start() -> Bool {
        resetPhysicalInputState()
        dictation.paused = false
        return tap.start { [weak self] stroke in
            self?.handle(keyEvent: stroke) ?? .pass
        }
    }

    /// Останавливает перехват.
    public func stop() {
        dictation.paused = true
        dictation.cancel()
        resetPhysicalInputState()
        _ = core.handle(.reset)
        tap.stop()
    }

    /// Tap suspension and shortcut recording can hide any corresponding key-up.
    /// No ownership or modifier-tap state may survive those boundaries.
    private func resetPhysicalInputState() {
        dictationGesture.reset()
        dictationRequested = false
        suppressedKeyUps.removeAll()
        modifierGesturePeak = []
        modifierGestureDirty = false
        waitForRecorderModifiersUp = false
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

    /// Транслирует один `KeyStroke` в события ядра, исполняет команды и
    /// возвращает решение активному tap'у. `.suppress` — только для
    /// разделителя, на котором ядро исправило слово (он будет дослан после
    /// перепечатки); всё остальное — `.pass`. Вызывается в колбэке tap'а, на
    /// главном потоке: никакого I/O и sleep здесь — решение ядра это детектор
    /// на одном слове, тяжёлая работа уходит на очередь `Typist`.
    @discardableResult
    public func handle(keyEvent stroke: KeyStroke) -> TapDecision {
        // Dictation is explicitly requested even in auto-excluded editors.
        // The event callback only tracks keys and schedules work on main.
        let secure = SecureInput.isActive
        core.isPaused = secure || isExcludedApp()
        if stroke.kind == .keyUp, suppressedKeyUps.remove(stroke.keyCode) != nil { return .suppress }
        if isRecordingHotkey {
            modifierGesturePeak = []
            modifierGestureDirty = true
            return .pass
        }
        if waitForRecorderModifiersUp {
            if modifierSet(from: stroke.flags).isEmpty { waitForRecorderModifiersUp = false }
            modifierGesturePeak = []
            modifierGestureDirty = true
            if stroke.kind != .keyDown || waitForRecorderModifiersUp { return .pass }
        }
        if stroke.kind == .keyDown, stroke.keyCode == 53, dictationRequested || dictation.isActive {
            dictationRequested = false
            dictationGesture.cancelHold()
            suppressedKeyUps.insert(stroke.keyCode)
            DispatchQueue.main.async { [weak self] in self?.dictation.cancel() }
            _ = core.handle(.reset)
            return .suppress
        }
        let modifiers = modifierSet(from: stroke.flags)
        let gestureEvent: DictationGesture.Event
        switch stroke.kind {
        case .keyDown: gestureEvent = .down(stroke.keyCode, repeatKey: stroke.isAutorepeat)
        case .keyUp: gestureEvent = .up(stroke.keyCode)
        case .flagsChanged: gestureEvent = .modifiers
        }
        let chosen = config.config.dictationHotkey
        let valid = chosen.dictationValidationError(convert: config.config.convertHotkey,
                                                     toggleAuto: config.config.toggleAutoHotkey) == nil
        let action = dictationGesture.handle(gestureEvent, modifiers: modifiers,
                                             hotkey: !secure && valid ? chosen : nil)
        switch action {
        case .begin:
            modifierGesturePeak.formUnion(modifiers)
            modifierGestureDirty = true
            dictationRequested = true
            _ = core.handle(.reset)
            DispatchQueue.main.async { [weak self] in self?.dictation.hold() }
            return stroke.kind == .keyDown ? .suppress : .pass
        case .end, .endPassingEvent:
            modifierGestureDirty = true
            dictationRequested = false
            DispatchQueue.main.async { [weak self] in self?.dictation.release() }
            // An unrelated key that happens to reveal released modifiers must
            // retain its ordinary behavior. Only the consumed key-up is hidden.
            if action == .end { return .suppress }
            if stroke.kind == .flagsChanged { return .pass }
        case .consume: return .suppress
        case .pass: break
        }
        if secure, dictation.isActive {
            DispatchQueue.main.async { [weak self] in self?.dictation.cancel() }
        }
        if dictation.isInserting, !secure {
            // No layout correction can race speech insertion. Physical keys
            // replay behind it, through the same serial Typist queue.
            _ = core.handle(.reset)
            if stroke.kind == .keyDown,
               let replay = Self.replayPress(for: stroke, events: translate(stroke)) {
                modifierGestureDirty = true
                suppressedKeyUps.insert(stroke.keyCode)
                typist.send(replay)
                return .suppress
            }
            return .pass
        }

        switch stroke.kind {
        case .keyUp:
            return .pass
        case .flagsChanged:
            if let event = modifierTapEvent(for: stroke) {
                dispatch(event)
            }
            return .pass
        case .keyDown:
            // Любая печатная/командная клавиша рвёт «чистый» тап модификатора.
            modifierGestureDirty = true
            // Хоткей с обычной клавишей (например ⌘⇧K)? Тогда это хоткей, а не
            // набор — шлём действие вместо трансляции символа. Нажатие
            // пропускаем как и раньше (хоткеи в этом таске без изменений).
            if let event = hotkeyEvent(
                keyCode: stroke.keyCode, modifiers: modifierSet(from: stroke.flags)) {
                dispatch(event)
                return .pass
            }
            let events = translate(stroke)

            // Гонка ввода: перепечатка ещё идёт. Нажатие переигрывается той же
            // очередью ПОСЛЕ синтетики; ядро получает его прямо сейчас, чтобы
            // порядок решений совпадал с порядком доставки. Не смогли создать
            // событие для переигрывания — ведём себя как в спокойном режиме.
            if typist.isBusy, let replay = Self.replayPress(for: stroke, events: events) {
                var consumed = false
                for event in events {
                    // Разделитель на границе: если ядро исправляет слово, execute
                    // поставит перепечатку и затем этот же `replay` как досылку.
                    if dispatch(event, stroke: stroke, prepared: replay) == .suppress {
                        consumed = true
                    }
                }
                if !consumed {
                    typist.send(replay)
                }
                return .suppress
            }

            var decision = TapDecision.pass
            for event in events {
                if dispatch(event, stroke: stroke) == .suppress {
                    decision = .suppress
                }
            }
            return decision
        }
    }

    /// Событие для переигрывания нажатия, попавшего в окно перепечатки.
    /// Одиночная буква — юникодом (ядро уже получило именно этот символ, и
    /// приложение получит его же, какая бы раскладка ни была активна к моменту
    /// доставки); всё остальное (разделители, Backspace, стрелки, Cmd-комбинации)
    /// — тем же keyCode и флагами, что нажал пользователь.
    private static func replayPress(for stroke: KeyStroke, events: [InputEvent]) -> Typist.KeyPress? {
        if events.count == 1, case .char(let ch) = events[0] {
            return Typist.makeUnicodePress(ch)
        }
        return Typist.makeKeyPress(keyCode: CGKeyCode(stroke.keyCode), flags: stroke.flags)
    }

    /// Прогоняет одно событие через ядро и исполняет команду; для `.toggleAuto`
    /// дополнительно персистит config (асинхронно) и уведомляет UI. `stroke` —
    /// исходное нажатие (keyCode/флаги для досылки разделителя), `prepared` —
    /// уже созданное событие досылки, если оно есть. Возвращает `.suppress`,
    /// если исходное нажатие доставлять нельзя (разделитель будет дослан
    /// после перепечатки).
    @discardableResult
    private func dispatch(
        _ event: InputEvent, stroke: KeyStroke? = nil, prepared: Typist.KeyPress? = nil
    ) -> TapDecision {
        let outcome = core.handle(event)
        let decision = execute(outcome, stroke: stroke, prepared: prepared)
        playSound(for: outcome)
        if case .hotkey(.toggleAuto) = event {
            config.update { $0.autoSwitch = core.autoSwitch }
            onAutoSwitchChanged?(core.autoSwitch)
        }
        return decision
    }

    /// Звук по итогу события: откат авто-исправления (в исключения ушло слово) —
    /// сигнал отката; любая другая замена (авто-исправление, конвертация по
    /// Option, разворот сниппета) — сигнал исправления. На обычные нажатия
    /// звука нет (G10); пауза гейтится сама собой: на паузе ядро не выдаёт
    /// `replaceLast`, значит и звучать нечему.
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

    /// Исполняет команду ядра. Возвращает `.suppress`, когда исходный
    /// разделитель надо подавить и дослать после перепечатки.
    ///
    /// Решение принимается ДО постановки заданий: событие досылки создаётся
    /// синхронно (`prepared`, иначе `Typist.makeKeyPress` по keyCode/флагам
    /// реального нажатия — numpad Enter, Shift+Enter = перенос строки; символ —
    /// запасной путь). Если создать не удалось — разделитель НЕ подавляется, а
    /// исправление уходит в legacy-варианте (ADR 0004): стереть слово вместе с
    /// доставленным разделителем и перепечатать оба. Разделитель не теряется.
    ///
    /// Порядок на очереди `Typist` (последовательная): Backspace-серия →
    /// символы → досланный разделитель. Переключение раскладки — синхронно
    /// здесь, как и раньше (TIS-вызов быстрый; печать юникодом от раскладки не
    /// зависит, а Return/Tab/Space по keyCode — тоже).
    @discardableResult
    private func execute(
        _ outcome: EngineOutcome, stroke: KeyStroke? = nil, prepared: Typist.KeyPress? = nil
    ) -> TapDecision {
        var decision = TapDecision.pass
        switch outcome.command {
        case .none:
            break
        case .replaceLast(let len, let text, let switchTo):
            if let lang = switchTo {
                LayoutSwitcher.select(lang)
                onLayoutSwitched?(lang)
            }
            if let sep = outcome.reinjectSeparator {
                if let press = prepared ?? separatorPress(stroke: stroke, sep: sep) {
                    typist.replaceLastWord(len: len, with: text)
                    typist.send(press)
                    decision = .suppress
                } else {
                    NSLog("MacLayoutSwitcher: не удалось создать событие досылки разделителя — пропускаю нажатие, исправляю в legacy-режиме")
                    typist.replaceLastWord(len: len + 1, with: text + String(sep))
                }
            } else {
                typist.replaceLastWord(len: len, with: text)
            }
        }
        // Откат авто-исправления добавил слово в исключения — персистим на диск
        // (запись на фоновой очереди Config; здесь только снимок).
        if outcome.excludedWordToPersist != nil {
            config.saveExclusions(detector.exclusionList)
        }
        // Счётчик отмен изменился — сохраняем, чтобы пережить перезапуск.
        if let upd = outcome.undoCountUpdate {
            undoCounts[upd.word.lowercased()] = upd.count
            config.saveUndoCounts(undoCounts)
        }
        return decision
    }

    /// Событие досылки разделителя: по реальному нажатию (keyCode + флаги),
    /// иначе по символу. `nil` — система отказала создать `CGEvent`.
    private func separatorPress(stroke: KeyStroke?, sep: Character) -> Typist.KeyPress? {
        if let stroke = stroke {
            return Typist.makeKeyPress(keyCode: CGKeyCode(stroke.keyCode), flags: stroke.flags)
        }
        guard let code = Typist.keyCode(forSeparator: sep) else { return nil }
        return Typist.makeKeyPress(keyCode: code, flags: [])
    }

    private func isExcludedApp() -> Bool {
        guard let bundle = FrontApp.bundleID else { return false }
        return config.config.excludedApps.contains(bundle)
    }
}
#endif
