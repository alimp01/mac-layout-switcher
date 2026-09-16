#if os(macOS)
import ApplicationServices
import Foundation

/// Fail closed when an editor cannot expose a focused element and selection.
/// Dictation still works there via an explicit Copy button; clipboard is never
/// touched by automatic insertion. AX messaging is bounded and off main.
struct DictationTarget {
    let element: AXUIElement
    let pid: pid_t
    let range: CFRange

    enum Capture { case target(DictationTarget), unavailable, protectedField }
    static func capture(expectedPID: pid_t) -> Capture {
        guard !SecureInput.isActive else { return .protectedField }
        guard let element = focusedElement() else { return .unavailable }
        if isProtected(element) { return .protectedField }
        var pid: pid_t = 0
        guard AXUIElementGetPid(element, &pid) == .success, pid == expectedPID,
              let range = selection(element) else { return .unavailable }
        return .target(DictationTarget(element: element, pid: pid, range: range))
    }
    func isCurrent(checkSelection: Bool) -> Bool {
        guard !SecureInput.isActive, let focused = Self.focusedElement(),
              CFEqual(element, focused), !Self.isProtected(focused) else { return false }
        if checkSelection {
            guard let current = Self.selection(focused) else { return false }
            return current.location == range.location && current.length == range.length
        }
        return true
    }
    private static func focusedElement() -> AXUIElement? {
        let system = AXUIElementCreateSystemWide()
        AXUIElementSetMessagingTimeout(system, 0.2)
        var value: CFTypeRef?
        guard AXUIElementCopyAttributeValue(system, kAXFocusedUIElementAttribute as CFString, &value) == .success,
              let value, CFGetTypeID(value) == AXUIElementGetTypeID() else { return nil }
        let element = unsafeBitCast(value, to: AXUIElement.self)
        AXUIElementSetMessagingTimeout(element, 0.2)
        return element
    }
    private static func isProtected(_ element: AXUIElement) -> Bool {
        var value: CFTypeRef?
        if AXUIElementCopyAttributeValue(element, kAXSubroleAttribute as CFString, &value) == .success,
           value as? String == kAXSecureTextFieldSubrole as String { return true }
        return false
    }
    private static func selection(_ element: AXUIElement) -> CFRange? {
        var value: CFTypeRef?
        guard AXUIElementCopyAttributeValue(element, kAXSelectedTextRangeAttribute as CFString, &value) == .success,
              let value, CFGetTypeID(value) == AXValueGetTypeID() else { return nil }
        var range = CFRange()
        guard AXValueGetValue(unsafeBitCast(value, to: AXValue.self), .cfRange, &range) else { return nil }
        return range
    }
}

/// A lock-protected cancellation permit may be checked by the Typist queue
/// while the main queue cancels a session. It never reads mutable UI state.
final class DictationInsertionPermit {
    private let lock = NSLock()
    private var allowed = true
    func cancel() { lock.lock(); allowed = false; lock.unlock() }
    var isAllowed: Bool { lock.lock(); defer { lock.unlock() }; return allowed }
}
#endif
