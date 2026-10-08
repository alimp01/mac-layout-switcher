import AppKit
import ApplicationServices

// The real adapter is compiled, but these fixtures never post to other apps.
enum EventTap { static let syntheticMarker: Int64 = 0xC0FFEE }
func require(_ condition: @autoclosure () -> Bool, _ message: String) {
    guard condition() else { fputs("FAIL: \(message)\n", stderr); exit(1) }
}
final class FixtureAX: DictationAccessibility {
    let editor = NSTextView()
    let element = AXUIElementCreateApplication(getpid())
    var isTrusted = true
    var isSecure = false
    var focused = true
    var lazyTree = false
    var hasRange = true
    var invalidRange = false
    var direct = true
    var unicode = true
    var preferUnicode = false
    var notifications = true
    var writes = 0
    var posts = 0
    var delayedNotifications = false
    var pendingNotifications = false
    var ignoreWrite = false
    var partialWrite = false
    var callback: ((DictationAXChange) -> Void)?
    var afterPost: (() -> Void)?
    init() { editor.string = "До старый после"; editor.setSelectedRange(NSRange(location: 3, length: 6)) }
    func focusedElement(pid: pid_t) -> AXUIElement? { focused && !lazyTree ? element : nil }
    func enableAccessibility(pid: pid_t) { lazyTree = false }
    func attribute(_ name: String, of element: AXUIElement) -> CFTypeRef? {
        switch name {
        case kAXValueAttribute: return editor.string as CFString
        case kAXSelectedTextRangeAttribute:
            guard hasRange else { return nil }
            let ns = editor.selectedRange()
            var range = invalidRange ? CFRange(location: Int.max, length: Int.max) : CFRange(location: ns.location, length: ns.length)
            return AXValueCreate(.cfRange, &range)
        case kAXRoleAttribute: return kAXTextAreaRole as CFString
        default: return nil
        }
    }
    func selectedTextIsSettable(_ element: AXUIElement) -> Bool { direct }
    func supportsUnicodeInsertion(_ element: AXUIElement) -> Bool { unicode }
    func prefersUnicodeInsertion(pid: pid_t) -> Bool { preferUnicode }
    func setSelectedText(_ text: String, in element: AXUIElement) -> AXError {
        writes += 1
        if !ignoreWrite { editor.setAccessibilitySelectedText(partialWrite ? String(text.prefix(3)) : text) }
        callback?(.selection)
        return partialWrite ? .cannotComplete : .success
    }
    func postUnicode(_ text: String, pid: pid_t) -> Bool {
        posts += 1
        // A previous write can be read back before its notifications reach the
        // main run loop. Deliver them after the next write has been scheduled.
        if pendingNotifications { callback?(.selection); callback?(.value); pendingNotifications = false }
        if !ignoreWrite {
            let selected = editor.selectedRange()
            editor.setAccessibilitySelectedText(partialWrite ? String(text.prefix(3)) : text)
            editor.setSelectedRange(NSRange(location: selected.location + (partialWrite ? 3 : text.utf16.count), length: 0))
        }
        if delayedNotifications { pendingNotifications = true }
        else { callback?(.selection); callback?(.value) }
        afterPost?()
        return true
    }
    func setSelection(_ range: CFRange, in element: AXUIElement) -> Bool {
        editor.setSelectedRange(NSRange(location: range.location, length: range.length)); return true
    }
    func observe(_ element: AXUIElement, pid: pid_t, changed: @escaping (DictationAXChange) -> Void) -> AnyObject? {
        callback = changed
        return notifications ? NSObject() : nil
    }
    func capture(_ permit: DictationInsertionPermit) -> DictationTarget.Capture {
        DictationTarget.capture(expectedPID: getpid(), permit: permit, accessibility: self)
    }
}
func target(_ ax: FixtureAX, _ permit: DictationInsertionPermit) -> DictationTarget {
    guard case .target(let target) = ax.capture(permit) else { fatalError("capture failed") }
    return target
}
func unavailable(_ ax: FixtureAX, _ reason: DictationInsertionFailure) {
    guard case .unavailable(let actual) = ax.capture(DictationInsertionPermit()), actual == reason else { fatalError("wrong capture reason") }
}
let app = NSApplication.shared
app.setActivationPolicy(.prohibited)
let clipboardCount = NSPasteboard.general.changeCount
let text = "Новый 🦆 текст"
do {
    let ax = FixtureAX(), permit = DictationInsertionPermit()
    let destination = target(ax, permit)
    require(destination.insert(text, permit: permit) == .inserted, "native AX setter inserts and readback confirms")
    require(ax.editor.string == "До Новый 🦆 текст после", "native selection replacement preserves surrounding text")
    require(ax.editor.selectedRange() == NSRange(location: 17, length: 0), "caret follows speech")
    require(ax.writes == 1 && ax.posts == 0, "atomic path has one mutation, no synthetic retry")
}
do {
    let ax = FixtureAX(), permit = DictationInsertionPermit()
    ax.lazyTree = true; ax.direct = false
    let destination = target(ax, permit)
    let long = String(repeating: "🙂Русский текст ", count: 40)
    require(destination.insert(long, permit: permit) == .inserted, "lazy editor without selected-text setter uses confirmed Unicode path")
    require(ax.editor.string == "До " + long + " после", "long Unicode insertion preserves emoji and selection")
    require(ax.writes == 0 && ax.posts > 1, "capability fallback sends bounded chunks")
}
do {
    let ax = FixtureAX(), permit = DictationInsertionPermit()
    let destination = target(ax, permit)
    ax.focused = false; ax.callback?(.focus); ax.focused = true
    require(destination.insert(text, permit: permit) == .fallback(.changed), "away and back permanently invalidates")
    require(ax.writes == 0 && ax.posts == 0, "invalidated session never writes")
}
do {
    let ax = FixtureAX(), permit = DictationInsertionPermit()
    let destination = target(ax, permit)
    ax.editor.setSelectedRange(NSRange(location: 0, length: 0)); ax.callback?(.selection)
    ax.editor.setSelectedRange(NSRange(location: 3, length: 6))
    require(destination.insert(text, permit: permit) == .fallback(.changed), "selection away and back permanently invalidates")
}
do {
    let ax = FixtureAX(), permit = DictationInsertionPermit()
    permit.cancel()
    guard case .unavailable(.changed) = ax.capture(permit) else { fatalError("input before async capture was forgotten") }
}
do {
    let ax = FixtureAX(), permit = DictationInsertionPermit()
    ax.preferUnicode = true
    let destination = target(ax, permit)
    require(destination.insert(text, permit: permit) == .inserted, "Chromium-like advertised setter uses verified Unicode without probing a write")
    require(ax.writes == 0 && ax.posts == 1, "preferred Unicode avoids unsupported advertised setter")
}
do {
    let ax = FixtureAX(), permit = DictationInsertionPermit()
    ax.direct = false; ax.delayedNotifications = true
    let destination = target(ax, permit)
    let long = String(repeating: text, count: 10)
    require(destination.insert(long, permit: permit) == .inserted, "delayed own notifications after readback do not cancel later chunks")
    require(ax.editor.string == "До " + long + " после", "delayed notification path preserves complete text")
    permit.validateSnapshot(false)
    require(permit.isAllowed, "late original-snapshot monitor cannot cancel own insertion")
}
for direct in [true, false] {
    let ax = FixtureAX(), permit = DictationInsertionPermit()
    ax.direct = direct; ax.ignoreWrite = true
    let destination = target(ax, permit)
    require(destination.insert(text, permit: permit) == .fallback(.unconfirmed), "reported success without delivery is not insertion")
    require(ax.writes + ax.posts == 1, "uncertain write is never retried")
}
do {
    let ax = FixtureAX(), permit = DictationInsertionPermit()
    ax.direct = false; ax.partialWrite = true
    let destination = target(ax, permit)
    require(destination.insert(String(repeating: text, count: 5), permit: permit) == .fallback(.unconfirmed), "partial delivery retains uncertain result")
    require(ax.posts == 1, "partial delivery stops before further chunks")
}
do {
    let ax = FixtureAX(), permit = DictationInsertionPermit()
    ax.direct = false; ax.afterPost = { permit.cancel() }
    let destination = target(ax, permit)
    require(destination.insert(String(repeating: text, count: 5), permit: permit) == .fallback(.unconfirmed), "input during delivery stops later chunks")
    require(ax.posts == 1, "cancelled delivery has no further writes")
}
do {
    let ax = FixtureAX(), permit = DictationInsertionPermit()
    ax.direct = false; ax.afterPost = { ax.callback?(.selection) }
    let destination = target(ax, permit)
    require(destination.insert(String(repeating: text, count: 5), permit: permit) == .fallback(.unconfirmed), "foreign selection callback after own notifications cancels")
    require(ax.posts == 1, "foreign selection blocks later chunks")
}
do { let ax = FixtureAX(); ax.isTrusted = false; unavailable(ax, .accessibilityDenied) }
do { let ax = FixtureAX(); ax.invalidRange = true; unavailable(ax, .unsupportedEditor) }
do { let ax = FixtureAX(); ax.hasRange = false; unavailable(ax, .unavailableSelection) }
do { let ax = FixtureAX(); ax.direct = false; ax.unicode = false; unavailable(ax, .unsupportedEditor) }
do { let ax = FixtureAX(); ax.notifications = false; unavailable(ax, .monitoringUnavailable) }
do { let ax = FixtureAX(); ax.isSecure = true; unavailable(ax, .protectedField) }
if let codex = NSWorkspace.shared.runningApplications.first(where: { $0.bundleIdentifier == "com.openai.codex" }) {
    require(SystemDictationAccessibility().prefersUnicodeInsertion(pid: codex.processIdentifier), "installed Codex renamed framework selects guarded Unicode route")
    print("PASS: installed Codex framework routing (metadata only; no external AX access or typing)")
}
require(NSPasteboard.general.changeCount == clipboardCount, "automatic capture/insertion never changes clipboard")
print("PASS: production AX capture/insert, native NSTextView replacement, lazy tree, capability fallback, sticky cancellation, Unicode, readback failure, no retry, clipboard")
