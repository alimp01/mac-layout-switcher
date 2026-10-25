import AppKit
import ApplicationServices
import SwitcherCore

// Keep SystemDictationAccessibility.focusedElement, Target.capture and the
// complete replacement path. Only raw operating-system RPCs are intercepted:
// fault responses cannot touch another process, and text uses own NSTextView.
enum EventTap { static let syntheticMarker: Int64 = 0xC0FFEE }
var failures = 0
func check(_ condition: @autoclosure () -> Bool, _ message: String) {
    if condition() { print("PASS: \(message)") }
    else { failures += 1; fputs("FAIL: \(message)\n", stderr) }
}
func main<T>(_ body: () -> T) -> T { Thread.isMainThread ? body() : DispatchQueue.main.sync(execute: body) }
func pump() { RunLoop.current.run(until: Date().addingTimeInterval(0.005)) }
final class FocusFixture {
    var processID = getpid()
    var app: AXUIElement { AXUIElementCreateApplication(processID) }
    let system = AXUIElementCreateSystemWide()
    // These are opaque identity tokens only. No real RPC uses their fake PIDs.
    let field = AXUIElementCreateApplication(1_000_001)
    let foreign = AXUIElementCreateApplication(1_000_002)
    let other = AXUIElementCreateApplication(1_000_003)
    let editor = NSTextView()
    var frontmostError = AXError.success
    var frontmost: CFTypeRef? = kCFBooleanTrue
    var systemError = AXError.success
    var systemFocus: CFTypeRef?
    var appError = AXError.success
    var appFocus: CFTypeRef?
    var ownerError = AXError.success
    var lazyTree = false
    var rangeNeedsTree = false
    var systemReads = 0
    var bootstrapOnMain = false
    var secureField = false
    var framework: String?
    var launchDate = Date()
    var missingLaunchDate = false
    var manualError = AXError.success
    var enhancedError = AXError.success
    var enhancedReadback: CFTypeRef? = kCFBooleanTrue
    var enhancedDelay: TimeInterval = 2.05
    var enhancedReadyAt: TimeInterval?
    var enhancedCount = 0
    var bootstrapCount = 0
    var writes = 0
    var trusted = true
    var afterSelection: (() -> Void)?
    var afterMetadataRead: (() -> Void)?
    var afterManual: (() -> Void)?
    init() {
        systemFocus = field; appFocus = field
        editor.string = "before ghbdtn after"
        editor.setSelectedRange(NSRange(location: 13, length: 0))
    }
}
var fixture: FocusFixture!
var fixtureSecureInput = false
struct FixtureRunningApplication {
    let bundleURL: URL?
    let launchDate: Date?
}
let metadataRoot = FileManager.default.temporaryDirectory.appendingPathComponent("mls-focus-bundles-" + UUID().uuidString)
try! FileManager.default.createDirectory(at: metadataRoot.appendingPathComponent("Contents/Frameworks/Codex Framework.framework"), withIntermediateDirectories: true)
defer { try? FileManager.default.removeItem(at: metadataRoot) }
var otherRunningInstances: [pid_t: Date] = [:]
func fixtureRunningApplication(processIdentifier: pid_t) -> FixtureRunningApplication? {
    if let launchDate = otherRunningInstances[processIdentifier] {
        return FixtureRunningApplication(bundleURL: metadataRoot, launchDate: launchDate)
    }
    guard processIdentifier == getpid() else { return nil }
    let snapshot = FixtureRunningApplication(bundleURL: fixture.framework == nil ? nil : metadataRoot,
                                            launchDate: fixture.missingLaunchDate ? nil : fixture.launchDate)
    let callback = fixture.afterMetadataRead
    fixture.afterMetadataRead = nil
    callback?()
    return snapshot
}
func fixturePostEvent(_ event: CGEvent, _ pid: pid_t) {
    precondition(pid == getpid(), "Unicode delivery stays in fixture")
    guard let data = event.data, let received = CGEvent(withDataAllocator: nil, data: data),
          let native = NSEvent(cgEvent: received) else { fatalError("serialized event") }
    main {
        if received.type == .keyDown { fixture.writes += 1; fixture.editor.keyDown(with: native) }
        else { fixture.editor.keyUp(with: native) }
    }
}
func treePending() -> Bool {
    if let readyAt = fixture.enhancedReadyAt, ProcessInfo.processInfo.systemUptime >= readyAt { fixture.lazyTree = false }
    return fixture.lazyTree
}
func fixtureAXIsProcessTrusted() -> Bool { fixture.trusted }
@discardableResult
func fixtureAXUIElementSetMessagingTimeout(_ element: AXUIElement, _ seconds: Float) -> AXError {
    precondition(seconds > 0 && seconds <= 0.1, "bounded production RPC")
    return .success
}
func fixtureAXUIElementGetPid(_ element: AXUIElement, _ pid: UnsafeMutablePointer<pid_t>) -> AXError {
    if CFEqual(element, fixture.field) || CFEqual(element, fixture.other) { pid.pointee = getpid(); return fixture.ownerError }
    if CFEqual(element, fixture.foreign) { pid.pointee = getpid() + 1; return .success }
    if CFEqual(element, fixture.app) { pid.pointee = getpid(); return .success }
    return .invalidUIElement
}
func fixtureAXUIElementCopyAttributeValue(_ element: AXUIElement, _ name: CFString,
                                         _ value: UnsafeMutablePointer<CFTypeRef?>) -> AXError {
    value.pointee = nil
    if CFEqual(element, fixture.app) {
        switch name as String {
        case kAXFrontmostAttribute: value.pointee = fixture.frontmost; return fixture.frontmostError
        case "AXEnhancedUserInterface": value.pointee = fixture.enhancedReadyAt == nil ? kCFBooleanFalse : fixture.enhancedReadback; return value.pointee == nil ? .noValue : .success
        case kAXFocusedUIElementAttribute:
            if treePending() { return .noValue }
            value.pointee = fixture.appFocus; return fixture.appError
        default: return .attributeUnsupported
        }
    }
    if CFEqual(element, fixture.system) {
        fixture.systemReads += 1
        precondition(name as String == kAXFocusedUIElementAttribute, "only own synthetic focus metadata")
        if treePending() { return .noValue }
        value.pointee = fixture.systemFocus; return fixture.systemError
    }
    precondition(CFEqual(element, fixture.field) || CFEqual(element, fixture.other), "no attribute read of foreign element")
    return main {
        switch name as String {
        case kAXValueAttribute: value.pointee = fixture.editor.accessibilityValue() as? CFTypeRef
        case kAXSelectedTextRangeAttribute:
            if fixture.rangeNeedsTree && (fixture.enhancedReadyAt == nil || ProcessInfo.processInfo.systemUptime < fixture.enhancedReadyAt!) { return .noValue }
            let selected = fixture.editor.selectedRange()
            var range = CFRange(location: selected.location, length: selected.length)
            value.pointee = AXValueCreate(.cfRange, &range)
        case kAXRoleAttribute: value.pointee = fixture.editor.accessibilityRole()?.rawValue as CFString?
        case kAXSubroleAttribute: value.pointee = fixture.secureField ? kAXSecureTextFieldSubrole as CFString : fixture.editor.accessibilitySubrole()?.rawValue as CFString?
        case kAXEnabledAttribute: value.pointee = (fixture.framework == nil ? fixture.editor.isAccessibilityEnabled() : fixture.editor.isEditable) ? kCFBooleanTrue : kCFBooleanFalse
        default: return .attributeUnsupported
        }
        return value.pointee == nil ? .noValue : .success
    }
}
func fixtureAXUIElementIsAttributeSettable(_ element: AXUIElement, _ name: CFString,
                                         _ settable: UnsafeMutablePointer<DarwinBoolean>) -> AXError {
    precondition(CFEqual(element, fixture.field))
    settable.pointee = DarwinBoolean(main { fixture.editor.isEditable } && (name as String == kAXSelectedTextAttribute || name as String == kAXSelectedTextRangeAttribute || name as String == kAXValueAttribute))
    return .success
}
func fixtureAXUIElementSetAttributeValue(_ element: AXUIElement, _ name: CFString, _ value: CFTypeRef) -> AXError {
    if CFEqual(element, fixture.app) {
        switch name as String {
        case "AXManualAccessibility":
            fixture.bootstrapCount += 1
            if fixture.manualError == .success { fixture.lazyTree = false }
            fixture.afterManual?()
            return fixture.manualError
        case "AXEnhancedUserInterface":
            fixture.bootstrapOnMain = Thread.isMainThread
            fixture.enhancedCount += 1
            fixture.enhancedReadyAt = ProcessInfo.processInfo.systemUptime + fixture.enhancedDelay
            return fixture.enhancedError
        default: fatalError("unexpected application mutation")
        }
    }
    precondition(CFEqual(element, fixture.field))
    return main {
        switch name as String {
        case kAXSelectedTextRangeAttribute:
            var range = CFRange()
            guard CFGetTypeID(value) == AXValueGetTypeID(), AXValueGetValue(unsafeBitCast(value, to: AXValue.self), .cfRange, &range) else { return .illegalArgument }
            fixture.editor.setAccessibilitySelectedTextRange(NSRange(location: range.location, length: range.length))
            fixture.afterSelection?()
        case kAXSelectedTextAttribute:
            fixture.writes += 1
            fixture.editor.setAccessibilitySelectedText((value as! String))
        default: fatalError("whole-field writes and other mutation are forbidden")
        }
        return .success
    }
}
let app = NSApplication.shared
app.setActivationPolicy(.prohibited)
func capturedReplacement() -> Bool {
    guard let target = InputFocusGuard.Target.capture(expectedPID: getpid()) else { return false }
    let result = target.replace(range: CFRange(location: 7, length: 6), expected: "ghbdtn", with: "привет",
        originalSelection: CFRange(location: 13, length: 0), allowed: { true })
    return result == .confirmed && fixture.editor.string == "before привет after"
        && fixture.editor.selectedRange() == NSRange(location: 13, length: 0) && fixture.writes == 1
}
fixture = FocusFixture()
check(capturedReplacement(), "ordinary raw system focus authorizes exact own AppKit replacement")
fixture = FocusFixture(); fixture.frontmostError = .cannotComplete; fixture.frontmost = nil
check(capturedReplacement(), "valid system-focused field survives unavailable app-frontmost RPC")
fixture = FocusFixture(); fixture.systemFocus = fixture.foreign
check(InputFocusGuard.Target.capture(expectedPID: getpid()) == nil && fixture.writes == 0,
      "positive foreign system focus never falls back to stale application focus")
fixture = FocusFixture(); fixture.frontmost = kCFBooleanFalse
check(InputFocusGuard.Target.capture(expectedPID: getpid()) == nil && fixture.writes == 0,
      "explicit non-frontmost application stays fail-closed")
fixture = FocusFixture(); fixture.systemError = .noValue; fixture.systemFocus = nil
check(capturedReplacement(), "confirmed frontmost application can supply unavailable system focus")
fixture = FocusFixture(); fixture.lazyTree = true
check(capturedReplacement() && fixture.bootstrapCount == 1, "bounded bootstrap reacquires real raw focus path")
fixture = FocusFixture(); fixture.framework = "Codex Framework.framework"
fixture.lazyTree = true; fixture.manualError = .attributeUnsupported
var chromiumPreparation: Bool?
DispatchQueue.global().async { chromiumPreparation = capturedReplacement() }
let chromiumDeadline = Date().addingTimeInterval(5)
while chromiumPreparation == nil && Date() < chromiumDeadline { pump() }
check(chromiumPreparation == false && fixture.writes == 0, "missing initial Chromium field prepares without licensing a delayed edit")
let treeDeadline = Date().addingTimeInterval(2.6)
while Date() < treeDeadline { pump() }
check(capturedReplacement() && fixture.enhancedCount == 1,
      "Chromium 155 rejected manual bootstrap resolves delayed raw noValue and fresh request converts ghbdtn once")
func failureMessage(pid: pid_t? = getpid()) -> String {
    var message = ""
    check(InputFocusGuard.Target.capture(expectedPID: pid, failure: { message = $0.message }) == nil,
          "unavailable focus refuses target")
    return message
}
// Bootstrap compatibility and safety at the same raw OS boundary.
fixture = FocusFixture(); fixture.lazyTree = true; fixture.manualError = .attributeUnsupported
check(!capturedReplacement() && fixture.enhancedCount == 0 && fixture.writes == 0,
      "native app rejecting manual accessibility never receives enhanced UI")
fixture = FocusFixture(); fixture.framework = "Codex Framework.framework"; fixture.lazyTree = true
fixture.manualError = .attributeUnsupported; fixture.enhancedDelay = 100
let preparingMessage = failureMessage()
check(preparingMessage.contains("подготавливает") && preparingMessage.contains("SystemFocus=-25212")
    && preparingMessage.contains("manual:-25205; enhanced:0; read:true"),
    "preparing diagnostic preserves noValue and verifies alternate readback without text")
for _ in 0..<3 { _ = failureMessage() }
check(fixture.bootstrapCount == 1 && fixture.enhancedCount == 1 && fixture.writes == 0,
      "separate capture adapters do not restart a live process activation debounce")
fixture.missingLaunchDate = true
_ = failureMessage()
fixture.missingLaunchDate = false
_ = failureMessage()
check(fixture.enhancedCount == 1, "temporarily missing launch metadata cannot evict a live activation gate")
fixture.launchDate = fixture.launchDate.addingTimeInterval(1); fixture.enhancedReadyAt = nil
_ = failureMessage()
check(fixture.enhancedCount == 2, "reused PID with a new launch identity receives its own activation")
fixture = FocusFixture(); fixture.framework = "Codex Framework.framework"; fixture.lazyTree = true
fixture.manualError = .notImplemented; fixture.enhancedError = .notImplemented
fixture.enhancedReadback = kCFBooleanFalse; fixture.enhancedDelay = 0
_ = failureMessage()
check(capturedReplacement() && fixture.enhancedCount == 1,
      "alternate setter error or false flag cannot veto independently available exact field readback")
fixture = FocusFixture(); fixture.framework = "Codex Framework.framework"; fixture.lazyTree = true
fixture.manualError = .attributeUnsupported; fixture.enhancedReadback = nil; fixture.enhancedDelay = 100
let unavailableMessage = failureMessage()
check(unavailableMessage.contains("read:-25212") && fixture.writes == 0,
      "unknown alternate readback never invents a focused field")
fixture = FocusFixture(); fixture.framework = "Codex Framework.framework"; fixture.lazyTree = true
fixture.manualError = .cannotComplete
check(!capturedReplacement() && fixture.enhancedCount == 0,
      "ambiguous manual timeout does not authorize an alternate mutation")
fixture = FocusFixture(); fixture.framework = "Codex Framework.framework"; fixture.lazyTree = true
fixture.manualError = .attributeUnsupported
let converterPreparing = SelectionConverter()
var preparingCapture: SelectionConverter.Capture?
converterPreparing.capture(expectedPID: getpid()) { preparingCapture = $0; _ = $1 }
let optionPreparingDeadline = Date().addingTimeInterval(1)
while preparingCapture == nil && Date() < optionPreparingDeadline { pump() }
fixture.systemFocus = fixture.other; fixture.appFocus = fixture.other
let switchedDeadline = Date().addingTimeInterval(2.6)
while Date() < switchedDeadline { pump() }
if case .unavailable(let reason) = preparingCapture {
    check(reason.message.contains("подготавливает") && fixture.writes == 0 && !fixture.bootstrapOnMain,
          "Option with no original identity prepares off-main and cannot edit a later same-app field")
} else { check(false, "Option with no original identity refuses delayed edit") }
// A known field lacking its range can wait, but must keep that exact identity.
fixture = FocusFixture(); fixture.framework = "Codex Framework.framework"; fixture.rangeNeedsTree = true
fixture.manualError = .attributeUnsupported
var changedFieldCapture: InputFocusGuard.Target?
var changedFieldDone = false
DispatchQueue.global().async { changedFieldCapture = InputFocusGuard.Target.capture(expectedPID: getpid()); changedFieldDone = true }
let enableDeadline = Date().addingTimeInterval(1)
while fixture.enhancedCount == 0 && Date() < enableDeadline { pump() }
fixture.systemFocus = fixture.other; fixture.appFocus = fixture.other
let changedDeadline = Date().addingTimeInterval(4)
while !changedFieldDone && Date() < changedDeadline { pump() }
check(changedFieldDone && changedFieldCapture == nil && fixture.writes == 0,
      "known initial field changing during delayed bootstrap is rejected")
fixture = FocusFixture(); fixture.framework = "Codex Framework.framework"; fixture.rangeNeedsTree = true
fixture.manualError = .attributeUnsupported; fixture.enhancedDelay = 100
let cancelPermit = DictationInsertionPermit()
var cancelledCapture: DictationTarget.Capture?
DispatchQueue.global().async { cancelledCapture = DictationTarget.capture(expectedPID: getpid(), permit: cancelPermit) }
let cancelEnableDeadline = Date().addingTimeInterval(1)
while fixture.enhancedCount == 0 && Date() < cancelEnableDeadline { pump() }
cancelPermit.cancel()
let cancelDeadline = Date().addingTimeInterval(0.5)
while cancelledCapture == nil && Date() < cancelDeadline { pump() }
if case .unavailable(.changed) = cancelledCapture {
    check(fixture.writes == 0 && !fixture.bootstrapOnMain, "dictation cancellation interrupts pending enhanced wait off-main without writes")
} else { check(false, "dictation cancellation interrupts pending enhanced wait") }
fixture = FocusFixture(); fixture.framework = "Codex Framework.framework"; fixture.rangeNeedsTree = true
fixture.manualError = .attributeUnsupported; fixture.enhancedDelay = 100
let boundedStart = ProcessInfo.processInfo.systemUptime
check(!capturedReplacement() && ProcessInfo.processInfo.systemUptime - boundedStart < 3.5
      && fixture.systemReads == 3 && fixture.enhancedCount == 1 && fixture.writes == 0,
      "unavailable delayed tree ends after bounded three focus reads and one activation")
fixture = FocusFixture(); fixture.framework = "Codex Framework.framework"; fixture.systemFocus = fixture.foreign
check(!capturedReplacement() && fixture.enhancedCount == 0 && fixture.bootstrapCount == 0,
      "positive foreign focus cannot trigger activation of the stale application")
for stage in ["metadata", "manual"] {
    fixture = FocusFixture(); fixture.framework = "Codex Framework.framework"; fixture.lazyTree = true
    fixture.manualError = .attributeUnsupported
    let replaceProcess = {
        fixture.launchDate = fixture.launchDate.addingTimeInterval(1)
        fixture.framework = nil
        fixture.lazyTree = false
    }
    if stage == "metadata" { fixture.afterMetadataRead = replaceProcess }
    else { fixture.afterManual = replaceProcess }
    check(!capturedReplacement() && fixture.enhancedCount == 0 && fixture.writes == 0,
          "process replacement during \(stage) refuses enhanced UI and cannot license new process field")
}
// Retain at most 32 live gates. These fake process identities never reach AX.
var capacityActivations = 0
for offset in 0..<33 {
    fixture = FocusFixture(); fixture.framework = "Codex Framework.framework"
    fixture.processID = pid_t(2_000_000 + offset); fixture.manualError = .attributeUnsupported
    otherRunningInstances[fixture.processID] = fixture.launchDate
    SystemDictationAccessibility().enableAccessibility(pid: fixture.processID)
    capacityActivations += fixture.enhancedCount
}
check(capacityActivations == 32 && fixture.enhancedCount == 0,
      "live activation gates are bounded without evicting and restarting older processes")
otherRunningInstances.removeAll()
fixture = FocusFixture(); fixture.frontmostError = .cannotComplete; fixture.frontmost = nil
fixture.systemError = .cannotComplete; fixture.systemFocus = nil
let timeoutMessage = failureMessage()
check(timeoutMessage.contains("AXFrontmost=-25204") && timeoutMessage.contains("SystemFocus=-25204"),
      "focus timeout retains exact stage and AX errors without source text")
check(!timeoutMessage.contains("ghbdtn") && !timeoutMessage.contains("before"), "diagnostic contains no editor text")
fixture = FocusFixture()
check(failureMessage(pid: nil).contains("macOS не сообщила активное приложение"), "missing foreground PID has a distinct explanation")
for (error, code) in [(AXError.attributeUnsupported, "-25205"), (.apiDisabled, "-25211"), (.notImplemented, "-25208"), (.noValue, "-25212")] {
    fixture = FocusFixture(); fixture.systemError = error; fixture.systemFocus = nil
    fixture.appError = error; fixture.appFocus = nil
    let message = failureMessage()
    check(message.contains("SystemFocus=\(code)") && message.contains("AppFocus=\(code)"), "raw unsupported/denied/no-value stages remain distinguishable: \(code)")
}
fixture = FocusFixture(); fixture.systemFocus = "not an AX element" as CFString
check(failureMessage().contains("SystemFocus=invalid-type"), "malformed positive system focus cannot authorize stale app fallback")
fixture = FocusFixture(); fixture.ownerError = .invalidUIElement
check(failureMessage().contains("SystemFocus=owner:-25202"), "unknown owner remains fail-closed and reports lookup error")
fixture = FocusFixture(); fixture.systemFocus = nil; fixture.systemError = .success
fixture.frontmost = nil; fixture.frontmostError = .success
check(failureMessage().contains("AXFrontmost=no-value; SystemFocus=no-value"), "success without returned values does not invent a target")
fixture = FocusFixture(); fixture.systemFocus = fixture.foreign
check(failureMessage().contains("SystemFocus=foreign-owner"), "foreign focus exposes metadata only")
fixture = FocusFixture(); fixture.frontmost = kCFBooleanFalse
check(failureMessage().contains("AXFrontmost=false"), "explicit inactive application has a distinct diagnostic")
fixture = FocusFixture(); fixture.trusted = false
check(failureMessage().contains("нет разрешения"), "trust failure remains separate")
fixture = FocusFixture(); fixture.secureField = true
check(failureMessage().contains("защищённое"), "secure target remains unavailable")
fixture = FocusFixture(); fixtureSecureInput = true
check(failureMessage().contains("защищённое"), "secure input remains unavailable")
fixtureSecureInput = false
fixture = FocusFixture(); fixture.editor.isEditable = false
check(!capturedReplacement() && fixture.writes == 0 && fixture.editor.string == "before ghbdtn after", "read-only control cannot authorize a write")
fixture = FocusFixture()
let captured = InputFocusGuard.Target.capture(expectedPID: getpid())!
fixture.systemFocus = fixture.foreign
let foreignResult = captured.replace(range: CFRange(location: 7, length: 6), expected: "ghbdtn", with: "привет",
    originalSelection: CFRange(location: 13, length: 0), allowed: { true })
check(foreignResult == .untouched && fixture.writes == 0 && fixture.editor.string == "before ghbdtn after", "system focus change after capture blocks old target")
fixture = FocusFixture()
fixture.afterSelection = { fixture.frontmost = kCFBooleanFalse }
check(!capturedReplacement() && fixture.writes == 0 && fixture.editor.string == "before ghbdtn after", "frontend change during selection blocks text mutation")
fixture = FocusFixture()
let cancelledTarget = InputFocusGuard.Target.capture(expectedPID: getpid())!
let permit = InputFocusGuard.Permit()
fixture.afterSelection = { permit.cancel() }
check(cancelledTarget.replace(range: CFRange(location: 7, length: 6), expected: "ghbdtn", with: "привет",
    originalSelection: CFRange(location: 13, length: 0), allowed: { permit.isAllowed }) == .untouched
    && fixture.writes == 0 && fixture.editor.string == "before ghbdtn after", "cancellation after selection preserves source")
for kind in ["word", "selected", "empty"] {
    fixture = FocusFixture(); fixture.frontmostError = .cannotComplete; fixture.frontmost = nil
    if kind == "selected" { fixture.editor.setSelectedRange(NSRange(location: 7, length: 6)) }
    if kind == "empty" { fixture.editor.string = ""; fixture.editor.setSelectedRange(NSRange(location: 0, length: 0)) }
    let converter = SelectionConverter()
    var capture: SelectionConverter.Capture?
    var request: InputFocusGuard.Permit?
    converter.capture(expectedPID: getpid()) { capture = $0; request = $1 }
    let deadline = Date().addingTimeInterval(4)
    while capture == nil && Date() < deadline { pump() }
    var selection: SelectionConverter.Selection?
    switch capture {
    case .selected(let value): selection = value
    case .empty(_, _, let word, _): selection = word
    default: break
    }
    if kind == "empty" {
        if case .empty = capture { check(selection == nil && fixture.writes == 0, "empty Option capture retains layout-only route") }
        else { check(false, "empty Option capture retains layout-only route") }
    } else if let selection, let request {
        let typist = Typist(postEvent: { _ in fatalError("Option does not post global keys") })
        var result: InputFocusGuard.ReplacementResult?
        converter.replace(selection, permit: request, typist: typist, replayRoute: .init(target: selection.target)) { result = $0; _ = $1 }
        let writeDeadline = Date().addingTimeInterval(4)
        while (result == nil || typist.isBusy) && Date() < writeDeadline { pump() }
        check(result == .confirmed && fixture.editor.string == "before привет after" && fixture.writes == 1,
              "production Option \(kind) captures through raw system focus and converts literal ghbdtn once")
    } else { check(false, "production Option \(kind) raw focus capture") }
}
for (label, key, flags) in [("Space", CGKeyCode(49), CGEventFlags()), ("Enter", 36, CGEventFlags()),
                            ("ShiftEnter", 36, CGEventFlags.maskShift), ("Tab", 48, CGEventFlags())] {
    fixture = FocusFixture(); fixture.frontmostError = .cannotComplete; fixture.frontmost = nil
    guard let target = InputFocusGuard.Target.capture(expectedPID: getpid()) else {
        check(false, "automatic \(label) target through raw focus"); continue
    }
    let ticket = InputFocusGuard.Ticket(target: target, permit: .init(), replacementPermit: .init(), replayRoute: .init(target: target))
    var posted: [CGEvent] = []
    let typist = Typist(postEvent: { posted.append(CGEvent(withDataAllocator: nil, data: $0.data!)!) })
    var result: InputFocusGuard.ReplacementResult?
    typist.replaceLastWord(expected: "ghbdtn", with: "привет", ticket: ticket,
        separator: Typist.makeKeyPress(keyCode: key, flags: flags), separatorCharacter: key == 49 ? " " : (key == 48 ? "\t" : "\n"), navigates: key != 49) { result = $0 }
    let deadline = Date().addingTimeInterval(4)
    while (result == nil || typist.isBusy) && Date() < deadline { pump() }
    check(result == .confirmed && fixture.editor.string == (key == 49 ? "before привет  after" : "before привет after")
        && fixture.writes == 1 && posted.count == (key == 49 ? 0 : 2), "automatic \(label) uses newly resolved target and preserves once-only separator")
    if key != 49 { check(posted.allSatisfy { $0.getIntegerValueField(.keyboardEventKeycode) == key && $0.flags == flags }, "\(label) key and flags preserved") }
}
fixture = FocusFixture(); fixture.frontmostError = .cannotComplete; fixture.frontmost = nil
fixture.systemError = .cannotComplete; fixture.systemFocus = nil
switch DictationTarget.capture(expectedPID: getpid(), permit: .init()) {
case .unavailable(let failure):
    check(failure.message.contains("AXFrontmost=-25204") && failure.message.contains("SystemFocus=-25204"), "dictation exposes the same raw focus diagnostic before observation or insertion")
case .target: check(false, "failed raw dictation focus may not invent a target")
}
if failures > 0 { exit(1) }
print("System focus harness passed; raw AX faults and own AppKit only, not live WindowServer acceptance.")
