// Системный слой macOS. Весь файл — под #if os(macOS).
#if os(macOS)
import Foundation
import CoreGraphics

/// Serial execution of targeted text replacements, speech insertion and
/// physical-key replays. Word replacement uses one AXSelectedText write; it
/// never deletes text incrementally or rewrites the entire field value.
/// CGEvents remain necessary for physical separators/keys, carry the
/// synthetic marker, and always finish an already-posted down/up pair.
public final class Typist {

    /// Готовая пара keyDown/keyUp, созданная заранее и ждущая своей очереди.
    public struct KeyPress {
        fileprivate let down: CGEvent
        fileprivate let up: CGEvent
        fileprivate let recoveryText: String
    }

    /// Виртуальные коды разделителей (kVK_Return / kVK_Tab / kVK_Space) —
    /// для досылки перехваченного разделителя по символу.
    public static let returnKeyCode: CGKeyCode = 36
    public static let tabKeyCode: CGKeyCode = 48
    public static let spaceKeyCode: CGKeyCode = 49
    /// Микрозадержка между соседними событиями, мкс.
    private static let interEventDelayMicroseconds: UInt32 = 5_000

    private let queue = DispatchQueue(label: "MacLayoutSwitcher.Typist")

    /// Число поставленных, но ещё не выполненных заданий. Пока > 0, синтетика
    /// ещё летит в приложение, и пользовательский ввод должен ложиться ПОСЛЕ
    /// неё (Engine его переигрывает через `send`), а не посреди.
    var onIdle: (() -> Void)?
    var onWithheldInput: ((String) -> Void)?
    /// Exact source and planned text survive an attempted, unconfirmed write.
    /// Delivered on main, including automatic corrections and selected text.
    var onUnconfirmedReplacement: ((String, String) -> Void)?
    private var pending = 0
    private let pendingLock = NSLock()

    private let postEvent: (CGEvent) -> Void
    public init() { postEvent = Self.post }
    /// System event boundary for the native queue harness; production posts CGEvents.
    init(postEvent: @escaping (CGEvent) -> Void) { self.postEvent = postEvent }

    /// `true`, пока очередь не опустела (перепечатка/досылка ещё идёт).
    public var isBusy: Bool {
        pendingLock.lock()
        defer { pendingLock.unlock() }
        return pending > 0
    }

    /// A single targeted AX write avoids partially deleted words if focus moves.
    func replaceLastWord(expected: String, with text: String,
                         ticket: InputFocusGuard.Ticket, separator: KeyPress?,
                         separatorCharacter: Character?, navigates: Bool,
                         conversionPermit: InputFocusGuard.Permit? = nil, conversionSelection: CFRange? = nil,
                         completion: @escaping (InputFocusGuard.ReplacementResult) -> Void) {
        enqueue {
            let inlineSpace = separatorCharacter == " "
            let result: InputFocusGuard.ReplacementResult
            let allowed = { ticket.allowsReplacement && (conversionPermit?.isAllowed ?? true) }
            let selectionMatches = conversionSelection.map { original in
                ticket.target.selection().map { $0.location == original.location && $0.length == original.length } == true
            } ?? true
            if allowed(), selectionMatches, let range = ticket.target.sourceRange(expected) {
                result = ticket.target.replace(range: range, expected: expected,
                    with: text + (inlineSpace ? " " : ""),
                    originalSelection: CFRange(location: range.location + range.length, length: 0), requiresWordBoundary: true, allowed: allowed)
            } else { result = .untouched }
            if result != .confirmed { ticket.replacementPermit.cancel() }
            if result.isUncertain { ticket.replayRoute.didBecomeUncertain(holdingAllInput: result == .unconfirmedSelection) }
            // A failed correction still delivers its physical separator in the
            // original target. Successful spaces were part of the atomic write.
            var withheld: String?
            if !result.isUncertain, (result != .confirmed || !inlineSpace), let separator,
               ticket.replayRoute.canReplay(permit: ticket.permit, navigates: navigates) {
                self.postPair(separator)
                if navigates { ticket.replayRoute.didNavigate() }
            } else if let separator, result != .confirmed || !inlineSpace,
                      ticket.replayRoute.requiresRecovery {
                withheld = separator.recoveryText
            }
            DispatchQueue.main.async { [weak self] in
                if result.isUncertain { self?.onUnconfirmedReplacement?(expected, text + (inlineSpace ? " " : "")) }
                completion(result)
                if let withheld { self?.onWithheldInput?(withheld) }
            }
        }
    }

    /// Replay only real physical input. Planned Tab/Enter transitions may update
    /// its destination; correction text is never allowed to follow that route.
    func send(_ press: KeyPress, ticket: InputFocusGuard.Ticket? = nil, navigates: Bool = false) {
        enqueue {
            if let ticket, !ticket.replayRoute.canReplay(permit: ticket.permit, navigates: navigates) {
                if ticket.replayRoute.requiresRecovery {
                    DispatchQueue.main.async { [weak self] in self?.onWithheldInput?(press.recoveryText) }
                }
                return
            }
            self.postPair(press)
            if navigates { ticket?.replayRoute.didNavigate() }
        }
    }

    private func postPair(_ press: KeyPress) {
        postEvent(press.down)
        // Always release a posted key, including when cancellation raced down.
        postEvent(press.up)
    }

    /// One targeted AX mutation with read-back verification; no synthetic
    /// character count is ever interpreted as proof of delivery.
    func insertDictation(_ text: String, target: DictationTarget,
                         permit: DictationInsertionPermit,
                         completion: @escaping (DictationInsertionResult) -> Void) {
        enqueue {
            let result = target.insert(text, permit: permit)
            DispatchQueue.main.async { [weak self] in
                if result == .fallback(.unconfirmed), !target.selectedOriginalText.isEmpty {
                    self?.onUnconfirmedReplacement?(target.selectedOriginalText, text)
                }
                completion(result)
            }
        }
    }

    /// Создаёт (синхронно, без отправки) нажатие клавиши по виртуальному коду.
    /// `flags` — модификаторы исходного нажатия (Shift+Enter в чате = перенос
    /// строки, а не отправка — их надо сохранить). `nil` — система отказала
    /// создать событие; вызывающий обязан НЕ подавлять исходное нажатие.
    public static func makeKeyPress(keyCode: CGKeyCode, flags: CGEventFlags) -> KeyPress? {
        let source = CGEventSource(stateID: .privateState)
        guard let down = CGEvent(keyboardEventSource: source, virtualKey: keyCode, keyDown: true),
              let up = CGEvent(keyboardEventSource: source, virtualKey: keyCode, keyDown: false)
        else { return nil }
        down.flags = flags
        up.flags = flags
        let recovery: String
        switch keyCode {
        case returnKeyCode: recovery = "⏎"
        case tabKeyCode: recovery = "⇥"
        case spaceKeyCode: recovery = " "
        case 51: recovery = "⌫"
        default: recovery = "[клавиша \(keyCode)]"
        }
        return KeyPress(down: down, up: up, recoveryText: recovery)
    }

    /// Создаёт (синхронно) нажатие, печатающее ровно `character` юникодом —
    /// независимо от раскладки, которая будет активна к моменту отправки.
    /// Для переигрывания букв, набранных во время перепечатки: ядро уже
    /// получило именно этот символ, приложение получит его же.
    public static func makeUnicodePress(_ character: Character) -> KeyPress? {
        let source = CGEventSource(stateID: .privateState)
        guard let down = CGEvent(keyboardEventSource: source, virtualKey: 0, keyDown: true),
              let up = CGEvent(keyboardEventSource: source, virtualKey: 0, keyDown: false)
        else { return nil }
        let utf16 = Array(String(character).utf16)
        utf16.withUnsafeBufferPointer { buffer in
            down.keyboardSetUnicodeString(stringLength: buffer.count, unicodeString: buffer.baseAddress)
            up.keyboardSetUnicodeString(stringLength: buffer.count, unicodeString: buffer.baseAddress)
        }
        down.flags = []
        up.flags = []
        return KeyPress(down: down, up: up, recoveryText: String(character))
    }

    /// Виртуальный код для символа-разделителя: `\n`/`\r` → Return, `\t` → Tab,
    /// пробел → Space; прочее — `nil` (досылать нечем).
    public static func keyCode(forSeparator sep: Character) -> CGKeyCode? {
        switch sep {
        case "\n", "\r", "\r\n": return returnKeyCode
        case "\t": return tabKeyCode
        case " ": return spaceKeyCode
        default: return nil
        }
    }

    /// Ставит задание в очередь, ведя счётчик занятости: +1 синхронно при
    /// постановке (чтобы `isBusy` стал `true` ещё до возврата в колбэк tap'а),
    /// −1 по завершении задания на очереди.
    func enqueue(_ job: @escaping () -> Void) {
        pendingLock.lock()
        pending += 1
        pendingLock.unlock()
        queue.async { [self] in
            job()
            pendingLock.lock()
            pending -= 1
            let idle = pending == 0
            pendingLock.unlock()
            if idle { DispatchQueue.main.async { [weak self] in self?.onIdle?() } }
        }
    }

    /// Маркирует событие как наше и отправляет в HID-очередь с микрозадержкой.
    private static func post(_ event: CGEvent) {
        event.setIntegerValueField(.eventSourceUserData, value: EventTap.syntheticMarker)
        event.post(tap: .cghidEventTap)
        usleep(interEventDelayMicroseconds)
    }
}
#endif
