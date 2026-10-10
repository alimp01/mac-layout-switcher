import AppKit
import ApplicationServices
import SwitcherCore

enum EventTap { static let syntheticMarker: Int64 = 0xC0FFEE }
// A native receiver handles events on the main thread. Only the final local
// delivery seam is marshalled; Target/Typist retain their production queues.
func receive(_ action: () -> Void) {
    if Thread.isMainThread { action() }
    else { DispatchQueue.main.sync(execute: action) }
}
func require(_ condition: @autoclosure () -> Bool, _ message: String) {
    guard condition() else { fputs("FAIL: \(message)\n", stderr); exit(1) }
}

// ACK-before-apply is the AX system seam, not a simulated text replacement.
// All receiving text edits use the real, private NSTextView.
final class DelayedAX: DictationAccessibility {
    let editor = NSTextView()
    let element = AXUIElementCreateApplication(getpid())
    var selectionDelay: TimeInterval? = nil
    var restorationDelay: TimeInterval? = 0
    var pendingSelection: CFRange?
    var applyAt: TimeInterval?
    var textWrites = 0
    var selectionRequests = 0
    var ignoreText = false
    var direct = true
    var unicode = false
    var cancelAfterRequest: (() -> Void)?
    var isTrusted: Bool { true }
    var isSecure: Bool { false }
    init() { editor.string = "срфе"; editor.setSelectedRange(NSRange(location: 4, length: 0)) }
    func focusedElement(pid: pid_t) -> AXUIElement? { pid == getpid() ? element : nil }
    func enableAccessibility(pid: pid_t) {}
    func attribute(_ name: String, of element: AXUIElement) -> CFTypeRef? {
        applyDueSelection()
        switch name {
        case kAXValueAttribute: return editor.string as CFString
        case kAXSelectedTextRangeAttribute:
            let selected = editor.selectedRange()
            var range = CFRange(location: selected.location, length: selected.length)
            return AXValueCreate(.cfRange, &range)
        default: return nil
        }
    }
    func selectedTextIsSettable(_ element: AXUIElement) -> Bool { direct }
    func supportsUnicodeInsertion(_ element: AXUIElement) -> Bool { unicode }
    func prefersUnicodeInsertion(pid: pid_t) -> Bool { false }
    func postUnicode(_ text: String, pid: pid_t) -> Bool {
        let transport = SystemDictationAccessibility(postEvent: { event, actualPID in
            require(actualPID == getpid(), "Unicode targets private receiver only")
            receive {
            let native = NSEvent(cgEvent: event)!
            if event.type == .keyDown { self.editor.keyDown(with: native) }
            else { self.editor.keyUp(with: native) }
            }
        })
        return transport.postUnicode(text, pid: pid)
    }
    func setSelection(_ range: CFRange, in element: AXUIElement) -> Bool {
        selectionRequests += 1
        pendingSelection = range
        let delay = range.length == 0 ? restorationDelay : selectionDelay
        applyAt = delay.map { ProcessInfo.processInfo.systemUptime + $0 }
        cancelAfterRequest?()
        return true
    }
    func setSelectedText(_ text: String, in element: AXUIElement) -> AXError {
        textWrites += 1
        if !ignoreText { editor.setAccessibilitySelectedText(text) }
        return .success
    }
    func observe(_ element: AXUIElement, pid: pid_t, changed: @escaping (DictationAXChange) -> Void) -> AnyObject? { NSObject() }
    func applyDueSelection() {
        if let applyAt, ProcessInfo.processInfo.systemUptime >= applyAt { applyAcknowledgedSelection() }
    }
    func applyAcknowledgedSelection() {
        guard let range = pendingSelection else { return }
        pendingSelection = nil
        applyAt = nil
        editor.setSelectedRange(NSRange(location: range.location, length: range.length))
    }
}

struct Outcome {
    let result: InputFocusGuard.ReplacementResult
    let replayed: [(UInt16, NSEvent.ModifierFlags)]
    let original: String
    let planned: String
    let held: String
}
func run(_ ax: DelayedAX, key: CGKeyCode = 49, flags: CGEventFlags = [],
         fastInput: Bool = false, cancelled: Bool = false) -> Outcome {
    let target = InputFocusGuard.Target(element: ax.element, pid: getpid(), accessibility: ax)
    let ticket = InputFocusGuard.Ticket(target: target, permit: .init(), replacementPermit: .init(), replayRoute: .init(target: target))
    if cancelled { ticket.replacementPermit.cancel() }
    let cancel = ax.cancelAfterRequest != nil
    if cancel { ax.cancelAfterRequest = { ticket.replacementPermit.cancel() } }
    var replayed: [(UInt16, NSEvent.ModifierFlags)] = []
    var result: InputFocusGuard.ReplacementResult?
    var original = "", planned = "", held = ""
    let typist = Typist(postEvent: { event in
        receive {
        // Deterministic hostile interleaving: an ACKed but unapplied selection
        // reaches this receiver before the next physical key, if one is sent.
        ax.applyAcknowledgedSelection()
        let received = NSEvent(cgEvent: event)!
        let native: NSEvent
        if received.keyCode == 49 || received.keyCode == 36 || received.keyCode == 48 {
            // Explicit WindowServer translation substitute, same seam as the
            // Engine fixture. Physical CGEvents lack translated Unicode here.
            let character = received.keyCode == 49 ? " " : (received.keyCode == 36 ? "\r" : "\t")
            native = NSEvent.keyEvent(with: event.type == .keyDown ? .keyDown : .keyUp,
                location: .zero, modifierFlags: received.modifierFlags, timestamp: received.timestamp,
                windowNumber: 0, context: nil, characters: character, charactersIgnoringModifiers: character,
                isARepeat: false, keyCode: received.keyCode)!
        } else { native = received }
        replayed.append((native.keyCode, native.modifierFlags))
        if event.type == .keyDown { ax.editor.keyDown(with: native) }
        else { ax.editor.keyUp(with: native) }
        }
    })
    typist.onUnconfirmedReplacement = { original = $0; planned = $1 }
    typist.onWithheldInput = { held += $0 }
    let separator: Character = key == 49 ? " " : (key == 36 ? "\n" : "\t")
    typist.replaceLastWord(expected: "срфе", with: "chat", ticket: ticket,
        separator: Typist.makeKeyPress(keyCode: key, flags: flags)!,
        separatorCharacter: separator, navigates: key != 49) { result = $0 }
    if fastInput { typist.send(Typist.makeUnicodePress("x")!, ticket: ticket) }
    let deadline = Date().addingTimeInterval(4)
    while (result == nil || typist.isBusy) && Date() < deadline { RunLoop.current.run(until: Date().addingTimeInterval(0.005)) }
    RunLoop.current.run(until: Date().addingTimeInterval(0.02))
    require(result != nil && !typist.isBusy, "serial caller completes")
    return Outcome(result: result!, replayed: replayed, original: original, planned: planned, held: held)
}

let app = NSApplication.shared
app.setActivationPolicy(.prohibited)
if ProcessInfo.processInfo.environment["MLS_SELECTION_CASE"] != "preselected" {
for (name, key, flags, held) in [("Space", CGKeyCode(49), CGEventFlags(), " "),
                               ("Enter", 36, CGEventFlags(), "⏎"),
                               ("ShiftEnter", 36, CGEventFlags.maskShift, "⏎"),
                               ("Tab", 48, CGEventFlags(), "⇥")] {
    let ax = DelayedAX()
    require(ax.editor.string == "срфе", "wrong-layout source exists before \(name)")
    let outcome = run(ax, key: key, flags: flags, fastInput: true)
    print("\(name): actual=\(String(reflecting: ax.editor.string)); result=\(outcome.result); writes=\(ax.textWrites); replayed=\(outcome.replayed.count); recovery=\(String(reflecting: outcome.original))/\(String(reflecting: outcome.planned))/\(String(reflecting: outcome.held))")
    require(outcome.result != .untouched && outcome.result != .confirmed, "unapplied selection must not be called untouched")
    require(ax.editor.string == "срфе" && ax.textWrites == 0 && outcome.replayed.isEmpty, "unconfirmed selection cannot erase source or release separator/fast input")
    require(outcome.original == "срфе" && outcome.planned == (key == 49 ? "chat " : "chat") && outcome.held == held + "x", "source, complete plan and physical input retained")
}
for (key, flags, expected) in [(CGKeyCode(49), CGEventFlags(), "chat x"),
                              (36, CGEventFlags(), "chat\nx"),
                              (36, CGEventFlags.maskShift, "chat\nx")] {
    let ax = DelayedAX()
    ax.selectionDelay = 0.035
    let outcome = run(ax, key: key, flags: flags, fastInput: true)
    require(outcome.result == .confirmed && ax.editor.string == expected && ax.textWrites == 1, "delayed acknowledged selection must be confirmed before full replacement")
    require(outcome.original.isEmpty && outcome.held.isEmpty, "confirmed replacement has no recovery")
    if key == 36 { require(outcome.replayed.first?.0 == 36 && outcome.replayed.first?.1.contains(NSEvent.ModifierFlags.shift) == flags.contains(.maskShift), "Enter retains native Shift flag") }
}
let restoration = DelayedAX()
restoration.selectionDelay = 0; restoration.restorationDelay = 0.035; restoration.ignoreText = true
let restored = run(restoration, fastInput: true)
require(restored.result != .untouched && restored.result != .confirmed && restoration.editor.string == "срфеx", "confirmed delayed restoration safely admits ordinary input")
require(restored.replayed.count == 2 && restored.held == " " && restored.original == "срфе", "restored caret preserves original recovery and withheld separator")
let unresolvedRestore = DelayedAX()
unresolvedRestore.selectionDelay = 0; unresolvedRestore.restorationDelay = nil; unresolvedRestore.ignoreText = true
let heldRestore = run(unresolvedRestore, fastInput: true)
require(unresolvedRestore.editor.string == "срфе" && heldRestore.replayed.isEmpty && heldRestore.held == " x", "unconfirmed restoration withholds all input")
let before = DelayedAX()
let beforeCancelled = run(before, cancelled: true)
require(beforeCancelled.result == .untouched && before.selectionRequests == 0 && before.editor.string == "срфе ", "cancellation before mutation remains safe untouched replay")
let during = DelayedAX()
during.cancelAfterRequest = {}
let duringCancelled = run(during, fastInput: true)
require(duringCancelled.result != .untouched && duringCancelled.result != .confirmed && during.editor.string == "срфе" && during.textWrites == 0 && duringCancelled.replayed.isEmpty, "cancellation after selection ACK cannot assume unchanged caret means no pending action")
require(duringCancelled.original == "срфе" && duringCancelled.held == " x", "cancelled pending action retains source and queued physical input")
}
// Preselected source needs no selection RPC. A redundant acknowledged old
// range can otherwise reselect the replacement after Unicode has committed.
let selected = DelayedAX()
selected.direct = false; selected.unicode = true
selected.editor.setSelectedRange(NSRange(location: 0, length: 4))
let selectedTarget = InputFocusGuard.Target(element: selected.element, pid: getpid(), accessibility: selected)
let selectedRoute = InputFocusGuard.ReplayRoute(target: selectedTarget)
let selectedTicket = InputFocusGuard.Ticket(target: selectedTarget, permit: .init(), replacementPermit: .init(), replayRoute: selectedRoute)
var selectedResult: InputFocusGuard.ReplacementResult?
let selectedTypist = Typist(postEvent: { event in
    receive {
    selected.applyAcknowledgedSelection()
    let native = NSEvent(cgEvent: event)!
    if event.type == .keyDown { selected.editor.keyDown(with: native) }
    else { selected.editor.keyUp(with: native) }
    }
})
SelectionConverter().replace(.init(target: selectedTarget, range: CFRange(location: 0, length: 4),
    text: "срфе", originalSelection: CFRange(location: 0, length: 4)), permit: .init(), typist: selectedTypist,
    replayRoute: selectedRoute) { result, _ in selectedResult = result }
selectedTypist.send(Typist.makeUnicodePress("x")!, ticket: selectedTicket)
let selectedDeadline = Date().addingTimeInterval(4)
while (selectedResult == nil || selectedTypist.isBusy) && Date() < selectedDeadline { RunLoop.current.run(until: Date().addingTimeInterval(0.005)) }
print("Preselected: actual=\(String(reflecting: selected.editor.string)); result=\(String(describing: selectedResult)); pendingSelectionRequests=\(selected.selectionRequests)")
require(selectedResult == .confirmed && selected.editor.string == "chatx" && selected.editor.selectedRange() == NSRange(location: 5, length: 0), "selected conversion must not queue old offsets which later erase replacement")
print("PASS delayed selection/restoration ACK, native separators/flags, fast input, cancellation and complete recovery; no WindowServer claim")
