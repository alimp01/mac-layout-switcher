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
    var ownerPID = getpid()
    let spotlightPID = getpid() + 20
    var spotlightBundleID = "com.apple.Spotlight"
    var spotlightBundleURL = URL(fileURLWithPath: "/System/Library/CoreServices/Spotlight.app")
    var spotlightExecutableURL = URL(fileURLWithPath: "/System/Library/CoreServices/Spotlight.app/Contents/MacOS/Spotlight")
    var spotlightStartSeconds: UInt64 = 1_792_904_729
    var spotlightStartMicroseconds: UInt64 = 518_098
    var spotlightProcResult: Int32? = nil
    var spotlightProcPID: UInt32? = nil
    var spotlightTerminated = false
    var spotlightMissing = false
    var spotlightFrontmost: CFTypeRef? = kCFBooleanFalse
    var spotlightAppFocus: CFTypeRef? = nil
    var postedPIDs: [pid_t] = []
    var observerPIDs: [pid_t] = []
    var spotlightBootstrapCount = 0
    var directSettable = true
    let background = AXUIElementCreateApplication(1_000_004)
    var backgroundReads = 0
    var afterRangeRead: (() -> Void)?
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
    var directWrites = 0
    var directWriteIsNoOp = false
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
    var bundleIdentifier: String? = nil
    var executableURL: URL? = nil
    var isTerminated = false
}
let metadataRoot = FileManager.default.temporaryDirectory.appendingPathComponent("mls-focus-bundles-" + UUID().uuidString)
func fixtureBundle(framework: String) -> URL {
    // The .app name is deliberately unrelated to the framework identity.
    let bundle = metadataRoot.appendingPathComponent(framework).appendingPathComponent("Renamed.app")
    try! FileManager.default.createDirectory(at: bundle.appendingPathComponent("Contents/Frameworks/" + framework), withIntermediateDirectories: true)
    return bundle
}
defer { try? FileManager.default.removeItem(at: metadataRoot) }
var otherRunningInstances: [pid_t: Date] = [:]
func fixtureRunningApplication(processIdentifier: pid_t) -> FixtureRunningApplication? {
    if let launchDate = otherRunningInstances[processIdentifier] {
        return FixtureRunningApplication(bundleURL: fixtureBundle(framework: "Codex Framework.framework"), launchDate: launchDate)
    }
    if processIdentifier == fixture.spotlightPID {
        guard !fixture.spotlightMissing else { return nil }
        let snapshot = FixtureRunningApplication(bundleURL: fixture.spotlightBundleURL,
            launchDate: fixture.missingLaunchDate ? nil : fixture.launchDate,
            bundleIdentifier: fixture.spotlightBundleID, executableURL: fixture.spotlightExecutableURL,
            isTerminated: fixture.spotlightTerminated)
        let callback = fixture.afterMetadataRead
        fixture.afterMetadataRead = nil
        callback?()
        return snapshot
    }
    guard processIdentifier == getpid() else { return nil }
    let snapshot = FixtureRunningApplication(bundleURL: fixture.framework.map(fixtureBundle),
                                            launchDate: fixture.missingLaunchDate ? nil : fixture.launchDate)
    let callback = fixture.afterMetadataRead
    fixture.afterMetadataRead = nil
    callback?()
    return snapshot
}
func fixtureproc_pidinfo(_ pid: Int32, _ flavor: Int32, _ arg: UInt64,
                         _ buffer: UnsafeMutableRawPointer?, _ size: Int32) -> Int32 {
    precondition(pid == fixture.spotlightPID && flavor == PROC_PIDTBSDINFO && arg == 0)
    let info = buffer!.assumingMemoryBound(to: proc_bsdinfo.self)
    info.pointee.pbi_pid = fixture.spotlightProcPID ?? UInt32(pid)
    info.pointee.pbi_start_tvsec = fixture.spotlightStartSeconds
    info.pointee.pbi_start_tvusec = fixture.spotlightStartMicroseconds
    return fixture.spotlightProcResult ?? size
}
func fixtureAXObserverCreate(_ pid: pid_t, _ callback: AXObserverCallback,
                             _ observer: UnsafeMutablePointer<AXObserver?>) -> AXError {
    fixture.observerPIDs.append(pid)
    // Own process only; notifications are never registered against any real UI.
    return AXObserverCreate(getpid(), callback, observer)
}
func fixtureAXObserverAddNotification(_ observer: AXObserver, _ element: AXUIElement,
                                     _ notification: CFString, _ context: UnsafeMutableRawPointer?) -> AXError { .success }
func fixturePostEvent(_ event: CGEvent, _ pid: pid_t) {
    precondition(pid == fixture.ownerPID, "Unicode delivery stays in captured fixture owner")
    fixture.postedPIDs.append(pid)
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
    if CFEqual(element, fixture.field) || CFEqual(element, fixture.other) { pid.pointee = fixture.ownerPID; return fixture.ownerError }
    if CFEqual(element, fixture.background) { pid.pointee = getpid(); return .success }
    if CFEqual(element, fixture.foreign) { pid.pointee = getpid() + 1; return .success }
    if CFEqual(element, fixture.app) { pid.pointee = getpid(); return .success }
    return .invalidUIElement
}
func fixtureAXUIElementCopyAttributeValue(_ element: AXUIElement, _ name: CFString,
                                         _ value: UnsafeMutablePointer<CFTypeRef?>) -> AXError {
    value.pointee = nil
    if CFEqual(element, AXUIElementCreateApplication(fixture.spotlightPID)) {
        if name as String == kAXFrontmostAttribute { value.pointee = fixture.spotlightFrontmost; return .success }
        if name as String == kAXFocusedUIElementAttribute { value.pointee = fixture.spotlightAppFocus; return value.pointee == nil ? .noValue : .success }
        return .attributeUnsupported
    }
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
    if CFEqual(element, fixture.background) { fixture.backgroundReads += 1; return .noValue }
    precondition(CFEqual(element, fixture.field) || CFEqual(element, fixture.other), "no attribute read of foreign element")
    return main {
        switch name as String {
        case kAXValueAttribute: value.pointee = fixture.editor.accessibilityValue() as? CFTypeRef
        case kAXSelectedTextRangeAttribute:
            let callback = fixture.afterRangeRead
            fixture.afterRangeRead = nil
            callback?()
            if fixture.rangeNeedsTree && (fixture.enhancedReadyAt == nil || ProcessInfo.processInfo.systemUptime < fixture.enhancedReadyAt!) { return .noValue }
            let selected = fixture.editor.selectedRange()
            var range = CFRange(location: selected.location, length: selected.length)
            value.pointee = AXValueCreate(.cfRange, &range)
        case kAXRoleAttribute: value.pointee = fixture.editor.accessibilityRole()?.rawValue as CFString?
        case kAXSubroleAttribute: value.pointee = fixture.secureField ? kAXSecureTextFieldSubrole as CFString : fixture.editor.accessibilitySubrole()?.rawValue as CFString?
        case kAXEnabledAttribute: value.pointee = (fixture.framework == nil && fixture.ownerPID != fixture.spotlightPID ? fixture.editor.isAccessibilityEnabled() : fixture.editor.isEditable) ? kCFBooleanTrue : kCFBooleanFalse
        default: return .attributeUnsupported
        }
        return value.pointee == nil ? .noValue : .success
    }
}
func fixtureAXUIElementIsAttributeSettable(_ element: AXUIElement, _ name: CFString,
                                         _ settable: UnsafeMutablePointer<DarwinBoolean>) -> AXError {
    precondition(CFEqual(element, fixture.field))
    settable.pointee = DarwinBoolean(main { fixture.editor.isEditable } && (fixture.directSettable || name as String != kAXSelectedTextAttribute) && (name as String == kAXSelectedTextAttribute || name as String == kAXSelectedTextRangeAttribute || name as String == kAXValueAttribute))
    return .success
}
func fixtureAXUIElementSetAttributeValue(_ element: AXUIElement, _ name: CFString, _ value: CFTypeRef) -> AXError {
    if CFEqual(element, AXUIElementCreateApplication(fixture.spotlightPID)) {
        precondition(name as String == "AXManualAccessibility", "only bounded accessibility activation")
        fixture.spotlightBootstrapCount += 1
        return .attributeUnsupported
    }
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
            fixture.directWrites += 1
            if fixture.directWriteIsNoOp { return .success }
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
// Literal Spotlight overlay: menu application is frontmost, but the system
// field belongs to the canonical, live Apple Spotlight process.
func spotlightFixture() -> FocusFixture {
    let value = FocusFixture()
    value.ownerPID = value.spotlightPID
    value.appFocus = value.background
    value.missingLaunchDate = true
    value.editor.string = "ghbdtn"
    value.editor.setSelectedRange(NSRange(location: 6, length: 0))
    return value
}

for frontmost in [kCFBooleanTrue as CFTypeRef?, nil] {
    fixture = spotlightFixture(); fixture.spotlightFrontmost = frontmost
    if let target = InputFocusGuard.Target.capture(expectedPID: fixture.spotlightPID) {
        print("EDGE: initial Spotlight frontmost=\(String(describing: frontmost)) stamped=\(target.processStart != nil)")
        fixture.spotlightStartMicroseconds += 1
        check(!target.isCurrent(), "initial same-PID Spotlight rejects changed process incarnation")
    } else { print("EDGE: initial capture refused") }
}
fixture = spotlightFixture(); fixture.spotlightFrontmost = kCFBooleanTrue
fixture.systemFocus = nil; fixture.spotlightAppFocus = fixture.field
check(InputFocusGuard.Target.capture(expectedPID: fixture.spotlightPID) == nil,
      "initial frontmost Spotlight rejects stale app-only focus")
fixture = spotlightFixture(); fixture.spotlightFrontmost = kCFBooleanTrue
let permit = DictationInsertionPermit()
switch DictationTarget.capture(expectedPID: fixture.spotlightPID, permit: permit) {
case .target(let target):
    fixture.spotlightStartMicroseconds += 1
    check(!target.isCurrent(), "dictation initial frontmost Spotlight rejects changed process")
case .unavailable: print("EDGE: dictation initial capture refused")
}
if failures > 0 { exit(1) }
