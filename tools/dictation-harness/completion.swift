import AppKit
import ApplicationServices

// Headless own NSTextView; the only substitutions are AX and final delivery.
// No microphone, external editor, TCC changes, or WindowServer delivery.
enum EventTap { static let syntheticMarker: Int64 = 0xC0FFEE }
func require(_ condition: @autoclosure () -> Bool, _ message: String) {
    guard condition() else { fputs("FAIL: \(message)\n", stderr); exit(1) }
}
final class CompletionAX: DictationAccessibility {
    let editor = NSTextView()
    let element = AXUIElementCreateApplication(getpid())
    var isTrusted = true
    var isSecure = false
    var focused = true
    var focusedOtherField = false
    let otherElement = AXUIElementCreateSystemWide()
    var posts = 0
    var postedPairs = 0
    var notificationMode = "duplicate"
    var pendingNotifications = false
    var staleValueReads = 0
    var staleRangeReads = 0
    var readbackDelay = false
    var oldValue = ""
    var oldRange = NSRange(location: 0, length: 0)
    var ignoreWrite = false
    var partialWrite = false
    var afterPost: (() -> Void)?
    var callback: ((DictationAXChange) -> Void)?
    var queuedNotifications: [() -> Void] = []
    init() { editor.string = ""; editor.setSelectedRange(NSRange(location: 0, length: 0)) }
    func focusedElement(pid: pid_t) -> AXUIElement? { focused ? (focusedOtherField ? otherElement : element) : nil }
    func enableAccessibility(pid: pid_t) {}
    func attribute(_ name: String, of element: AXUIElement) -> CFTypeRef? {
        switch name {
        case kAXValueAttribute:
            if staleValueReads > 0 { staleValueReads -= 1; return oldValue as CFString }
            return editor.string as CFString
        case kAXSelectedTextRangeAttribute:
            let ns: NSRange
            if staleRangeReads > 0 { staleRangeReads -= 1; ns = oldRange }
            else { ns = editor.selectedRange() }
            var range = CFRange(location: ns.location, length: ns.length)
            return AXValueCreate(.cfRange, &range)
        default: return nil
        }
    }
    func selectedTextIsSettable(_ element: AXUIElement) -> Bool { false }
    func supportsUnicodeInsertion(_ element: AXUIElement) -> Bool { true }
    func prefersUnicodeInsertion(pid: pid_t) -> Bool { true }
    func postUnicode(_ text: String, pid: pid_t) -> Bool {
        posts += 1
        if pendingNotifications {
            if notificationMode == "late" { Thread.sleep(forTimeInterval: 0.18) }
            callback?(.selection); callback?(.value); callback?(.selection)
            pendingNotifications = false
        }
        let range = editor.selectedRange()
        oldValue = editor.string; oldRange = range
        if !ignoreWrite {
            let transport = SystemDictationAccessibility(postEvent: { event, actualPID in
                require(actualPID == pid, "Unicode pair targets captured process")
                require(event.getIntegerValueField(.eventSourceUserData) == EventTap.syntheticMarker, "synthetic marker retained")
                guard let data = event.data,
                      let decoded = CGEvent(withDataAllocator: nil, data: data),
                      let native = NSEvent(cgEvent: decoded) else { fatalError("event serialization") }
                require(decoded.flags.isEmpty, "Unicode is never a shortcut")
                if decoded.type == .keyDown {
                    if self.partialWrite { self.editor.insertText("Дав", replacementRange: self.editor.selectedRange()) }
                    else { self.editor.keyDown(with: native) }
                } else {
                    require(decoded.type == .keyUp, "every posted down has one up")
                    self.postedPairs += 1
                    self.editor.keyUp(with: native)
                }
            })
            require(transport.postUnicode(text, pid: pid), "production Unicode event construction")
        }
        if readbackDelay { staleValueReads = 2; staleRangeReads = 3 }
        switch notificationMode {
        case "delayed", "late": pendingNotifications = true
        case "coalesced": callback?(.value)
        default:
            callback?(.value); callback?(.selection)
            callback?(.selection) // Two notifications can report the same own state.
        }
        afterPost?()
        return true
    }
    func setSelection(_ range: CFRange, in element: AXUIElement) -> Bool {
        editor.setSelectedRange(NSRange(location: range.location, length: range.length)); return true
    }
    func setSelectedText(_ text: String, in element: AXUIElement) -> AXError { fatalError("must choose Unicode before mutation") }
    func observe(_ element: AXUIElement, pid: pid_t, changed: @escaping (DictationAXChange) -> Void) -> AnyObject? {
        callback = { change in
            if self.notificationMode == "queued" { self.queuedNotifications.append { changed(change) } }
            else { changed(change) }
        }
        return NSObject()
    }
    func observe(_ element: AXUIElement, pid: pid_t, received: @escaping (DictationAXChange) -> Bool,
                 changed: @escaping (DictationAXChange) -> Void) -> AnyObject? {
        callback = { change in
            guard received(change) else { return }
            if self.notificationMode == "queued" { self.queuedNotifications.append { changed(change) } }
            else { changed(change) }
        }
        return NSObject()
    }
}
let app = NSApplication.shared
app.setActivationPolicy(.prohibited)
let clipboardCount = NSPasteboard.general.changeCount
func receiptBeforeWrite() {
    let ax = CompletionAX(), permit = DictationInsertionPermit()
    ax.notificationMode = "queued"
    guard case .target(let target) = DictationTarget.capture(expectedPID: getpid(), permit: permit, accessibility: ax) else { fatalError("capture failed") }
    // AX arrives during recognition; worker processing would run after insert.
    ax.callback?(.selection)
    let result = target.insert("Давай проверим, работает ли вставка.", permit: permit)
    print("queued-recording-receipt: result=\(result) posts=\(ax.posts)")
    require(result == .fallback(.changed) && ax.posts == 0 && !permit.isAllowed, "recording receipt cannot later become own-write acknowledgment")
    ax.queuedNotifications.forEach { $0() }
    require(!permit.isAllowed, "late worker does not revive cancellation")
}
if ProcessInfo.processInfo.environment["MLS_DICTATION_CASE"] == "receipt" {
    receiptBeforeWrite(); print("PASS: receipt before queued insertion"); exit(0)
}
let ax = CompletionAX(), permit = DictationInsertionPermit()
guard case .target(let target) = DictationTarget.capture(expectedPID: getpid(), permit: permit, accessibility: ax) else { fatalError("capture failed") }
let phrase = "Давай проверим, работает ли вставка."
let result = target.insert(phrase, permit: permit)
print("duplicate-own-notification: result=\(result) actual=\(String(reflecting: ax.editor.string)) posts=\(ax.posts) caret=\(ax.editor.selectedRange())")
require(result == .inserted && ax.editor.string == phrase && ax.editor.selectedRange() == NSRange(location: 36, length: 0), "full literal phrase completes once despite duplicate own AX notifications")
require(ax.posts == 3, "literal phrase has three deliveries, no repeated chunk")
require(ax.postedPairs == 3, "literal phrase uses exactly three complete production Unicode pairs")
receiptBeforeWrite()

func capture(_ ax: CompletionAX, _ permit: DictationInsertionPermit) -> DictationTarget {
    guard case .target(let target) = DictationTarget.capture(expectedPID: getpid(), permit: permit, accessibility: ax) else { fatalError("capture failed") }
    return target
}
for mode in ["duplicate", "delayed", "coalesced", "late"] {
    for fixture in [("1234567890123456", 16), ("12345678901234567", 17), (phrase, 36), ("🙂Русский\n🦆 e\u{301}\n", 16)] {
        let ax = CompletionAX(), permit = DictationInsertionPermit()
        ax.notificationMode = mode
        ax.editor.string = "До старый после"; ax.editor.setSelectedRange(NSRange(location: 3, length: 6))
        let target = capture(ax, permit)
        require(target.insert(fixture.0, permit: permit) == .inserted, "\(mode) insertion completes")
        require(ax.editor.string == "До " + fixture.0 + " после", "Unicode, selected replacement and suffix preserved")
        require(ax.editor.selectedRange() == NSRange(location: 3 + fixture.1, length: 0), "exact UTF16 caret")
    }
}
do {
    let ax = CompletionAX(), permit = DictationInsertionPermit()
    ax.notificationMode = "delayed"
    let target = capture(ax, permit)
    let long = String(repeating: "🙂Русский\n🦆 e\u{301}\n", count: 80)
    require(target.insert(long, permit: permit) == .inserted && ax.editor.string == long, "long Unicode paragraphs complete once")
    require(ax.editor.selectedRange() == NSRange(location: 1280, length: 0), "long Unicode caret")
}
do {
    let ax = CompletionAX(), permit = DictationInsertionPermit()
    ax.readbackDelay = true
    let target = capture(ax, permit)
    require(target.insert(phrase, permit: permit) == .inserted && ax.editor.string == phrase, "independently delayed value and caret settle before further delivery")
}
for mutation in ["selection", "value", "input", "focus", "secure", "other-field"] {
    let ax = CompletionAX(), permit = DictationInsertionPermit()
    let target = capture(ax, permit)
    ax.afterPost = {
        let range = ax.editor.selectedRange(), value = ax.editor.string
        switch mutation {
        case "selection":
            ax.editor.setSelectedRange(NSRange(location: 0, length: 0)); ax.callback?(.selection)
            ax.editor.setSelectedRange(range)
        case "value":
            ax.editor.string = "чужой текст"; ax.callback?(.value); ax.editor.string = value; ax.editor.setSelectedRange(range)
        case "input": permit.cancel()
        case "focus": ax.focused = false; ax.callback?(.focus); ax.focused = true
        case "secure": ax.isSecure = true; ax.callback?(.value); ax.isSecure = false
        default: ax.focusedOtherField = true; ax.callback?(.selection); ax.focusedOtherField = false
        }
    }
    require(target.insert(phrase, permit: permit) == .fallback(.unconfirmed) && ax.posts == 1, "\(mutation) permanently stops after first possibly applied chunk")
    require(!permit.isAllowed, "\(mutation) cancellation stays sticky after original state restored")
}
for change in ["caret", "value", "other-field"] {
    let ax = CompletionAX(), permit = DictationInsertionPermit()
    if change == "caret" { ax.editor.string = "abc"; ax.editor.setSelectedRange(NSRange(location: 1, length: 0)) }
    let target = capture(ax, permit)
    switch change {
    case "caret": ax.editor.setSelectedRange(NSRange(location: 2, length: 0))
    case "value": ax.editor.string = "foreign"; ax.editor.setSelectedRange(NSRange(location: 0, length: 0))
    default: ax.focusedOtherField = true
    }
    require(target.insert(phrase, permit: permit) == .fallback(.changed) && ax.posts == 0, "stale \(change) never writes")
}
for partial in [false, true] {
    let ax = CompletionAX(), permit = DictationInsertionPermit()
    ax.ignoreWrite = !partial; ax.partialWrite = partial
    let target = capture(ax, permit)
    require(target.insert(phrase, permit: permit) == .fallback(.unconfirmed) && ax.posts == 1, "no-op/partial write never retries")
}
require(NSPasteboard.general.changeCount == clipboardCount, "clipboard unchanged")
print("PASS: literal completion, chunks, Unicode paragraphs, selected replacement, duplicate/delayed/coalesced notifications, delayed value/caret, sticky external cancellation, no-op/partial/no retry, clipboard")
