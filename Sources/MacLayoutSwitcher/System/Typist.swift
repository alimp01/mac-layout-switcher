// Системный слой macOS. Весь файл — под #if os(macOS).
#if os(macOS)
import Foundation
import CoreGraphics

/// Serial execution of targeted text replacements, speech insertion and
/// physical-key replays. Word replacement uses one AXSelectedText write; it
/// never deletes text incrementally or rewrites the entire field value.
/// CGEvents remain necessary for speech and physical separators/keys, carry the
/// synthetic marker, and always finish an already-posted down/up pair.
public final class Typist {

    /// Готовая пара keyDown/keyUp, созданная заранее и ждущая своей очереди.
    public struct KeyPress {
        fileprivate let down: CGEvent
        fileprivate let up: CGEvent
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
    private var pending = 0
    private let pendingLock = NSLock()

    public init() {}

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
                         completion: @escaping (Bool) -> Void) {
        enqueue {
            let inlineSpace = separatorCharacter == " "
            let completed: Bool
            if ticket.allowsReplacement, let range = ticket.target.sourceRange(expected) {
                completed = ticket.target.replace(range: range, expected: expected,
                    with: text + (inlineSpace ? " " : ""),
                    originalSelection: CFRange(location: range.location + range.length, length: 0), allowed: { ticket.allowsReplacement })
            } else { completed = false }
            if !completed { ticket.replacementPermit.cancel() }
            // A failed correction still delivers its physical separator in the
            // original target. Successful spaces were part of the atomic write.
            if (!completed || !inlineSpace), let separator,
               ticket.replayRoute.canReplay(permit: ticket.permit) {
                Self.postPair(separator)
                if navigates { ticket.replayRoute.didNavigate() }
            }
            DispatchQueue.main.async { completion(completed) }
        }
    }

    /// Replay only real physical input. Planned Tab/Enter transitions may update
    /// its destination; correction text is never allowed to follow that route.
    func send(_ press: KeyPress, ticket: InputFocusGuard.Ticket? = nil, navigates: Bool = false) {
        enqueue {
            if let ticket, !ticket.replayRoute.canReplay(permit: ticket.permit) { return }
            Self.postPair(press)
            if navigates { ticket?.replayRoute.didNavigate() }
        }
    }

    private static func postPair(_ press: KeyPress) {
        post(press.down)
        // Always release a posted key, including when cancellation raced down.
        post(press.up)
    }

    /// Inserts speech on the same queue as replacements and physical-key
    /// replays. Recheck focus/security before every character, and report any
    /// uninserted suffix rather than silently losing or copying it.
    func insertDictation(_ text: String, target: DictationTarget,
                         permit: DictationInsertionPermit,
                         completion: @escaping (String) -> Void) {
        enqueue {
            let characters = Array(text)
            var inserted = 0
            if permit.isAllowed && target.isCurrent(checkSelection: true) {
                for character in characters {
                    guard permit.isAllowed, target.isCurrent(checkSelection: false),
                          let press = Self.makeUnicodePress(character) else { break }
                    Self.post(press.down)
                    Self.post(press.up)
                    inserted += 1
                }
            }
            let remaining = String(characters.dropFirst(inserted))
            DispatchQueue.main.async { completion(remaining) }
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
        return KeyPress(down: down, up: up)
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
        return KeyPress(down: down, up: up)
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
