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
    let sampledForeign = DispatchSemaphore(value: 0)
    let resumeObserver = DispatchSemaphore(value: 0)
    let observerFinished = DispatchSemaphore(value: 0)
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
            if Thread.current.threadDictionary["foreign-read"] as? Bool == true {
                Thread.current.threadDictionary["foreign-read"] = false
                let sampled = editor.string
                print("Observer actually sampled: \(sampled)")
                sampledForeign.signal()
                resumeObserver.wait()
                return sampled as CFString
            }
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
        if posts == 2 {
            resumeObserver.signal()
            precondition(observerFinished.wait(timeout: .now() + 2) == .success)
            print("After false foreign snapshot completes: permit will remain allowed")
        }
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
let ax = CompletionAX(), permit = DictationInsertionPermit()
ax.notificationMode = "coalesced"
guard case .target(let target) = DictationTarget.capture(expectedPID: getpid(), permit: permit, accessibility: ax) else { fatalError("capture") }
ax.afterPost = {
    if ax.posts == 1 {
        let own = ax.editor.string, caret = ax.editor.selectedRange()
        ax.editor.string = "UNRELATED FOREIGN VALUE"
        DispatchQueue.global().async {
            Thread.current.threadDictionary["foreign-read"] = true
            ax.callback?(.value)
            ax.observerFinished.signal()
        }
        precondition(ax.sampledForeign.wait(timeout: .now() + 2) == .success)
        ax.editor.string = own; ax.editor.setSelectedRange(caret)
    }
}
let phrase = "Давай проверим, работает ли вставка."
let result = target.insert(phrase, permit: permit)
print("Target result=\(result), posts=\(ax.posts), allowed=\(permit.isAllowed), actual=\(String(reflecting: ax.editor.string))")
exit(result == .inserted && ax.posts == 3 ? 1 : 0)
