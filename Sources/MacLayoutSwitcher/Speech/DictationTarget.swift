#if os(macOS)
import ApplicationServices
import AppKit
import Foundation

/// Reasons are kept separate from recognition: unavailable AX never means
/// silence. An attempted write can have an uncertain outcome and is not retried.
enum DictationInsertionFailure: Equatable {
    case accessibilityDenied, unavailableField, unavailableSelection, unsupportedEditor
    case monitoringUnavailable, changed, protectedField, unconfirmed
    case systemFocus(DictationFocusFailure)
    case preparingAccessibility(DictationFocusFailure?)

    var message: String {
        switch self {
        case .accessibilityDenied: return "Нет разрешения «Универсальный доступ» для Mac Layout Switcher."
        case .unavailableField: return "Редактор не предоставил доступное поле ввода."
        case .systemFocus(let failure): return failure.message
        case .preparingAccessibility(let focus):
            return "Редактор подготавливает доступ к полю. Повторите действие через несколько секунд."
                + (focus.map { " Диагностика: \($0.metadata)." } ?? "")
        case .unavailableSelection: return "Редактор не сообщил положение курсора или выделение."
        case .unsupportedEditor: return "Редактор не поддерживает проверяемую вставку через Универсальный доступ."
        case .monitoringUnavailable: return "Редактор не позволяет отслеживать изменения поля для безопасной вставки."
        case .changed: return "Во время диктовки изменилось поле, выделение или был ввод."
        case .protectedField: return "Автовставка недоступна в защищённом поле."
        case .unconfirmed: return "Не удалось подтвердить вставку. Часть или весь текст уже может быть в поле. Проверьте его перед копированием; повторной вставки не было."
        }
    }
}

/// Only fixed stage names and AX result codes; no editor text or persistent log.
struct DictationFocusFailure: Equatable {
    enum Status: Equatable {
        case notRead, success, noValue, invalidType, notFrontmost, foreignOwner
        case error(Int32), ownerError(Int32)
        var code: String {
            switch self {
            case .notRead: return "not-read"
            case .success: return "ok"
            case .noValue: return "no-value"
            case .invalidType: return "invalid-type"
            case .notFrontmost: return "false"
            case .foreignOwner: return "foreign-owner"
            case .error(let code): return String(code)
            case .ownerError(let code): return "owner:\(code)"
            }
        }
    }
    let frontmost: Status
    let system: Status
    let application: Status
    var bootstrap: String? = nil
    var preventsBootstrap: Bool {
        frontmost == .notFrontmost || [system, application].contains(.foreignOwner)
            || [system, application].contains(.invalidType)
    }
    func including(_ preparation: DictationAXBootstrap?) -> Self {
        var result = self
        result.bootstrap = preparation?.diagnostic
        return result
    }
    var metadata: String {
        "AXFrontmost=\(frontmost.code); SystemFocus=\(system.code); AppFocus=\(application.code)"
            + (bootstrap.map { "; Bootstrap=\($0)" } ?? "")
    }
    var message: String {
        let reason: String
        if frontmost == .notFrontmost || system == .foreignOwner || application == .foreignOwner {
            reason = "Активное приложение изменилось. Выберите нужное поле и повторите действие."
        } else if [frontmost, system, application].contains(.error(AXError.apiDisabled.rawValue)) {
            reason = "macOS отклонила доступ к полю. Проверьте разрешение «Универсальный доступ» для Mac Layout Switcher."
        } else {
            reason = "Не удалось получить поле ввода через Универсальный доступ."
        }
        return "\(reason) Диагностика: \(metadata)."
    }
}

/// Activation is separate from capture: neither an ACK nor an enabled flag
/// authorizes a text write. Only the unchanged focused-field resolver does that.
struct DictationAXBootstrap {
    var diagnostic: String? = nil
    var settleUntil: TimeInterval? = nil
    var requiresFreshFocus = false
    var rejectsCapture = false

    /// Three capture attempts total. Chromium debounces enhanced activation for
    /// two seconds; allow another half second for its renderer tree to appear.
    /// Poll only cancellation here, never the AX tree, and never on EventTap.
    func wait(before attempt: Int, allowed: () -> Bool) -> Bool {
        let now = ProcessInfo.processInfo.systemUptime
        let deadline = attempt == 2 ? max(now + 0.08, settleUntil ?? 0) : now + 0.08
        while ProcessInfo.processInfo.systemUptime < deadline {
            guard allowed() else { return false }
            Thread.sleep(forTimeInterval: min(0.02, max(0, deadline - ProcessInfo.processInfo.systemUptime)))
        }
        return allowed()
    }
}

enum DictationAXChange: Hashable { case focus, selection, value }

enum DictationInsertionResult: Equatable { case inserted, fallback(DictationInsertionFailure) }

/// Preserve the actual AX reads across concurrent publication of write states.
/// An already sampled foreign value/range must never be replaced by a reread.
struct DictationFieldState: Equatable {
    let value: String
    let range: NSRange
    init(_ value: String, _ range: CFRange) {
        self.value = value
        self.range = NSRange(location: range.location, length: range.length)
    }
}

private struct DictationWriteStates {
    let before: DictationFieldState?
    let after: [DictationFieldState]
    func contains(_ state: DictationFieldState) -> Bool {
        before == state || after.contains(state)
    }
    func maySettle(_ state: DictationFieldState) -> Bool {
        guard let before else { return false }
        // Separate AX RPCs may expose combinations of this write's known
        // value/range while it is pending. No other value/range is exempt.
        return (state.value == before.value || after.contains { $0.value == state.value })
            && (state.range == before.range || after.contains { $0.range == state.range })
    }
}

/// Injectable at the AX system boundary so the exact production capture/write
/// path can be exercised without accessing any user's editor or granting TCC.
protocol DictationAccessibility {
    var isTrusted: Bool { get }
    var isSecure: Bool { get }
    func focusedElement(pid: pid_t) -> AXUIElement?
    func focusedElement(pid: pid_t, failure: (DictationFocusFailure) -> Void) -> AXUIElement?
    func enableAccessibility(pid: pid_t)
    func prepareAccessibility(pid: pid_t, allowed: () -> Bool) -> DictationAXBootstrap
    func attribute(_ name: String, of element: AXUIElement) -> CFTypeRef?
    func selectedTextIsSettable(_ element: AXUIElement) -> Bool
    func supportsUnicodeInsertion(_ element: AXUIElement) -> Bool
    func prefersUnicodeInsertion(pid: pid_t) -> Bool
    func postUnicode(_ text: String, pid: pid_t) -> Bool
    func setSelection(_ range: CFRange, in element: AXUIElement) -> Bool
    func setSelectedText(_ text: String, in element: AXUIElement) -> AXError
    func observe(_ element: AXUIElement, pid: pid_t, changed: @escaping (DictationAXChange) -> Void) -> AnyObject?
    func observe(_ element: AXUIElement, pid: pid_t, received: @escaping (DictationAXChange) -> Bool,
                 changed: @escaping (DictationAXChange) -> Void) -> AnyObject?
}

extension DictationAccessibility {
    func prepareAccessibility(pid: pid_t, allowed: () -> Bool) -> DictationAXBootstrap {
        if allowed() { enableAccessibility(pid: pid) }
        return DictationAXBootstrap()
    }
    func focusedElement(pid: pid_t, failure: (DictationFocusFailure) -> Void) -> AXUIElement? {
        focusedElement(pid: pid)
    }
    func observe(_ element: AXUIElement, pid: pid_t, received: @escaping (DictationAXChange) -> Bool,
                 changed: @escaping (DictationAXChange) -> Void) -> AnyObject? {
        observe(element, pid: pid) { change in
            if received(change) { changed(change) }
        }
    }
}

struct SystemDictationAccessibility: DictationAccessibility {
    private struct ProcessInstance: Hashable {
        let pid: pid_t
        let launchDate: Date
    }
    // Shared by keyboard sampling, Option capture and dictation. Repeated true
    // writes would restart Chromium's two-second debounce indefinitely.
    private static let bootstrapLock = NSLock()
    private static var enhancedBootstraps: [ProcessInstance: DictationAXBootstrap] = [:]
    private static func isChromium(_ bundle: URL?) -> Bool {
        guard let bundle else { return false }
        let frameworks = bundle.appendingPathComponent("Contents/Frameworks")
        let names = (try? FileManager.default.contentsOfDirectory(atPath: frameworks.path)) ?? []
        return names.contains {
            ["Electron Framework.framework", "Codex Framework.framework", "Chromium Framework.framework", "Google Chrome Framework.framework",
             "Brave Browser Framework.framework", "Microsoft Edge Framework.framework"].contains($0)
        }
    }
    private let postEvent: (CGEvent, pid_t) -> Void
    /// The injectable boundary is the actual process post, after event creation.
    /// Native harnesses inspect serialized CGEvents without touching other apps.
    init(postEvent: @escaping (CGEvent, pid_t) -> Void = { $0.postToPid($1) }) {
        self.postEvent = postEvent
    }
    var isTrusted: Bool { AXIsProcessTrusted() }
    var isSecure: Bool { SecureInput.isActive }
    func attribute(_ name: String, of element: AXUIElement) -> CFTypeRef? {
        var value: CFTypeRef?
        guard AXUIElementCopyAttributeValue(element, name as CFString, &value) == .success else { return nil }
        return value
    }
    private func bounded(_ element: AXUIElement) -> AXUIElement {
        AXUIElementSetMessagingTimeout(element, 0.1)
        return element
    }
    func focusedElement(pid: pid_t) -> AXUIElement? {
        focusedElement(pid: pid, failure: { _ in })
    }
    func focusedElement(pid: pid_t, failure: (DictationFocusFailure) -> Void) -> AXUIElement? {
        typealias Status = DictationFocusFailure.Status
        func read(_ name: String, from element: AXUIElement) -> (CFTypeRef?, Status) {
            var value: CFTypeRef?
            let result = AXUIElementCopyAttributeValue(element, name as CFString, &value)
            guard result == .success else { return (nil, .error(result.rawValue)) }
            return (value, value == nil ? .noValue : .success)
        }
        let app = bounded(AXUIElementCreateApplication(pid))
        var (frontmostValue, frontmostStatus) = read(kAXFrontmostAttribute, from: app)
        var systemStatus = Status.notRead
        var appStatus = Status.notRead
        func failed() -> AXUIElement? {
            failure(.init(frontmost: frontmostStatus, system: systemStatus, application: appStatus))
            return nil
        }
        let frontmost = frontmostValue as? Bool
        if frontmostValue != nil && frontmost == nil { frontmostStatus = .invalidType }
        if frontmost == false { frontmostStatus = .notFrontmost; return failed() }
        let system = bounded(AXUIElementCreateSystemWide())
        func ownedElement(_ value: CFTypeRef, status: inout Status) -> AXUIElement? {
            guard CFGetTypeID(value) == AXUIElementGetTypeID() else { status = .invalidType; return nil }
            let element = bounded(unsafeBitCast(value, to: AXUIElement.self))
            var actualPID: pid_t = 0
            let result = AXUIElementGetPid(element, &actualPID)
            guard result == .success else { status = .ownerError(result.rawValue); return nil }
            guard actualPID == pid else { status = .foreignOwner; return nil }
            return element
        }
        // A positively identified system focus is authoritative: a different
        // owner must never fall through to an application's stale focused field.
        // A missing AXFrontmost response alone cannot veto an exact system focus.
        let systemRead = read(kAXFocusedUIElementAttribute, from: system)
        systemStatus = systemRead.1
        if let value = systemRead.0 {
            return ownedElement(value, status: &systemStatus) ?? failed()
        }
        guard frontmost == true else { return failed() }
        let appRead = read(kAXFocusedUIElementAttribute, from: app)
        appStatus = appRead.1
        guard let value = appRead.0 else { return failed() }
        return ownedElement(value, status: &appStatus) ?? failed()
    }
    func enableAccessibility(pid: pid_t) {
        _ = prepareAccessibility(pid: pid, allowed: { true })
    }
    func prepareAccessibility(pid: pid_t, allowed: () -> Bool) -> DictationAXBootstrap {
        guard allowed(), isTrusted, !isSecure else { return .init(diagnostic: "cancelled") }
        let running = NSRunningApplication(processIdentifier: pid)
        let chromium = Self.isChromium(running?.bundleURL)
        let instance = running?.launchDate.map { ProcessInstance(pid: pid, launchDate: $0) }
        Self.bootstrapLock.lock()
        defer { Self.bootstrapLock.unlock() }
        // Retain a live instance's gate. At capacity, refuse another enhanced
        // activation rather than evicting it and restarting a pending debounce.
        Self.enhancedBootstraps = Self.enhancedBootstraps.filter { key, _ in
            guard let application = NSRunningApplication(processIdentifier: key.pid) else { return false }
            return application.launchDate.map { $0 == key.launchDate } ?? true
        }
        func currentProcessMatches() -> Bool {
            guard let instance, let current = NSRunningApplication(processIdentifier: pid),
                  current.launchDate == instance.launchDate else { return false }
            return !chromium || Self.isChromium(current.bundleURL)
        }
        if instance != nil && !currentProcessMatches() {
            return .init(diagnostic: "process-changed", rejectsCapture: true)
        }
        if chromium, let instance, let previous = Self.enhancedBootstraps[instance] { return previous }
        guard allowed() else { return .init(diagnostic: "cancelled") }
        let app = bounded(AXUIElementCreateApplication(pid))
        let manual = AXUIElementSetAttributeValue(app, "AXManualAccessibility" as CFString, kCFBooleanTrue)
        let manualDiagnostic = "manual:\(manual.rawValue)"
        // Electron documents the manual hook. Chromium 155 no longer implements
        // it; its BrowserCrApplication handles enhanced UI with a 2s debounce.
        // Never send that alternate attribute to native/WebKit/unknown apps.
        guard chromium, manual == .attributeUnsupported || manual == .notImplemented else {
            return .init(diagnostic: manualDiagnostic)
        }
        guard let instance else { return .init(diagnostic: manualDiagnostic + "; enhanced:no-process-instance") }
        guard Self.enhancedBootstraps.count < 32 else { return .init(diagnostic: manualDiagnostic + "; enhanced:limit") }
        guard allowed(), isTrusted, !isSecure,
              attribute(kAXFrontmostAttribute, of: app) as? Bool == true else {
            return .init(diagnostic: manualDiagnostic + "; enhanced:inactive")
        }
        func readEnhanced() -> (Bool?, String) {
            var value: CFTypeRef?
            let code = AXUIElementCopyAttributeValue(app, "AXEnhancedUserInterface" as CFString, &value)
            guard code == .success else { return (nil, String(code.rawValue)) }
            guard let value else { return (nil, "no-value") }
            guard CFGetTypeID(value) == CFBooleanGetTypeID() else { return (nil, "invalid-type") }
            let enabled = CFBooleanGetValue(unsafeBitCast(value, to: CFBoolean.self))
            return (enabled, enabled ? "true" : "false")
        }
        guard currentProcessMatches() else { return .init(diagnostic: "process-changed", rejectsCapture: true) }
        let existing = readEnhanced()
        guard currentProcessMatches() else { return .init(diagnostic: "process-changed", rejectsCapture: true) }
        var outcome = "already-on"
        var readback = existing
        if existing.0 != true {
            guard allowed() else { return .init(diagnostic: manualDiagnostic + "; enhanced:cancelled") }
            let result = AXUIElementSetAttributeValue(app, "AXEnhancedUserInterface" as CFString, kCFBooleanTrue)
            outcome = String(result.rawValue)
            readback = readEnhanced()
        }
        // Chromium forwards the setter to AppKit after requesting activation:
        // even an error may have acted. Record both outcomes, then let actual
        // focused-field readback decide. Never retry or turn the attribute off.
        let preparation = DictationAXBootstrap(diagnostic: manualDiagnostic + "; enhanced:" + outcome + "; read:" + readback.1,
                                               settleUntil: ProcessInfo.processInfo.systemUptime + 2.5, requiresFreshFocus: true)
        Self.enhancedBootstraps[instance] = preparation
        return preparation
    }
    func selectedTextIsSettable(_ element: AXUIElement) -> Bool {
        var settable = DarwinBoolean(false)
        return AXUIElementIsAttributeSettable(element, kAXSelectedTextAttribute as CFString, &settable) == .success && settable.boolValue
    }
    func prefersUnicodeInsertion(pid: pid_t) -> Bool {
        // Chromium bridges can advertise a selected-text setter whose browser
        // action is unimplemented. Select verified Unicode before any mutation;
        // never discover this by attempting text and then retrying it.
        guard let bundle = NSRunningApplication(processIdentifier: pid)?.bundleURL else { return false }
        // Safari's WebKit text controls likewise advertise AXSelectedText, but
        // the WebCore setter is a no-op. Choose the existing verified native
        // input route before selection/text mutation, never as a write retry.
        if let identifier = Bundle(url: bundle)?.bundleIdentifier,
           ["com.apple.Safari", "com.apple.SafariTechnologyPreview"].contains(identifier) { return true }
        return Self.isChromium(bundle)
    }
    func supportsUnicodeInsertion(_ element: AXUIElement) -> Bool {
        let role = attribute(kAXRoleAttribute, of: element) as? String
        var settable = DarwinBoolean(false)
        var valueSettable = DarwinBoolean(false)
        return (role == kAXTextFieldRole || role == kAXTextAreaRole)
            && attribute(kAXEnabledAttribute, of: element) as? Bool != false
            && AXUIElementIsAttributeSettable(element, kAXSelectedTextRangeAttribute as CFString, &settable) == .success
            && settable.boolValue
            && AXUIElementIsAttributeSettable(element, kAXValueAttribute as CFString, &valueSettable) == .success
            && valueSettable.boolValue
    }
    func postUnicode(_ text: String, pid: pid_t) -> Bool {
        let source = CGEventSource(stateID: .privateState)
        guard let down = CGEvent(keyboardEventSource: source, virtualKey: 0, keyDown: true),
              let up = CGEvent(keyboardEventSource: source, virtualKey: 0, keyDown: false) else { return false }
        let utf16 = Array(text.utf16)
        for event in [down, up] {
            utf16.withUnsafeBufferPointer { event.keyboardSetUnicodeString(stringLength: $0.count, unicodeString: $0.baseAddress) }
            event.flags = []
            event.setIntegerValueField(.eventSourceUserData, value: EventTap.syntheticMarker)
        }
        postEvent(down, pid)
        postEvent(up, pid) // Always finish an already posted pair.
        return true
    }
    func setSelection(_ range: CFRange, in element: AXUIElement) -> Bool {
        var range = range
        guard let value = AXValueCreate(.cfRange, &range) else { return false }
        return AXUIElementSetAttributeValue(element, kAXSelectedTextRangeAttribute as CFString, value) == .success
    }
    func setSelectedText(_ text: String, in element: AXUIElement) -> AXError {
        AXUIElementSetAttributeValue(element, kAXSelectedTextAttribute as CFString, text as CFString)
    }
    func observe(_ element: AXUIElement, pid: pid_t, changed: @escaping (DictationAXChange) -> Void) -> AnyObject? {
        DictationAXObservation(element: element, pid: pid, received: { _ in true }, changed: changed)
    }
    func observe(_ element: AXUIElement, pid: pid_t, received: @escaping (DictationAXChange) -> Bool,
                 changed: @escaping (DictationAXChange) -> Void) -> AnyObject? {
        DictationAXObservation(element: element, pid: pid, received: received, changed: changed)
    }
}

private final class DictationAXObservation {
    private final class Callback {
        let changed: (DictationAXChange) -> Void
        let received: (DictationAXChange) -> Bool
        let queue = DispatchQueue(label: "mls.dictation.ax-notifications", qos: .userInitiated)
        init(received: @escaping (DictationAXChange) -> Bool, changed: @escaping (DictationAXChange) -> Void) {
            self.received = received; self.changed = changed
        }
        func deliver(_ kind: DictationAXChange) {
            // Receipt before a write must cancel immediately, even if worker
            // delivery happens after insertion has started.
            guard received(kind) else { return }
            // Focus cancellation needs no AX work. Value/selection validation
            // reads bounded AX attributes away from the observer's main loop.
            if kind == .focus { changed(kind) }
            else { queue.async { self.changed(kind) } }
        }
    }
    private let callback: Callback
    private var observer: AXObserver?
    init?(element: AXUIElement, pid: pid_t, received: @escaping (DictationAXChange) -> Bool,
          changed: @escaping (DictationAXChange) -> Void) {
        callback = Callback(received: received, changed: changed)
        var created: AXObserver?
        guard AXObserverCreate(pid, { _, _, notification, context in
            guard let context else { return }
            let kind: DictationAXChange
            switch notification as String {
            case kAXFocusedUIElementChangedNotification: kind = .focus
            case kAXSelectedTextChangedNotification: kind = .selection
            default: kind = .value
            }
            Unmanaged<Callback>.fromOpaque(context).takeUnretainedValue().deliver(kind)
        }, &created) == .success, let created else { return nil }
        observer = created
        let app = AXUIElementCreateApplication(pid)
        AXUIElementSetMessagingTimeout(app, 0.1)
        let registrations: [(AXUIElement, String)] = [
            (app, kAXFocusedUIElementChangedNotification),
            (element, kAXSelectedTextChangedNotification),
            (element, kAXValueChangedNotification)
        ]
        for (source, notification) in registrations {
            guard AXObserverAddNotification(created, source, notification as CFString,
                Unmanaged.passUnretained(callback).toOpaque()) == .success else { return nil }
        }
        CFRunLoopAddSource(CFRunLoopGetMain(), AXObserverGetRunLoopSource(created), .commonModes)
    }
    deinit {
        if let observer {
            // Keep the callback alive until removal on its delivery run loop,
            // even when the last target reference is released on a worker.
            let callback = callback
            DispatchQueue.main.async {
                CFRunLoopRemoveSource(CFRunLoopGetMain(), AXObserverGetRunLoopSource(observer), .commonModes)
                withExtendedLifetime(callback) {}
            }
        }
    }
}

/// Immutable destination captured before recording. Both selection and value
/// are preconditions; PID alone can never license an insertion. All AX calls
/// run on bounded worker queues. The original value is never written back.
struct DictationTarget {
    let element: AXUIElement
    let pid: pid_t
    private let range: CFRange
    private let original: String
    private let accessibility: any DictationAccessibility
    private let observation: AnyObject

    enum Capture { case target(DictationTarget), unavailable(DictationInsertionFailure) }
    /// Captured source segment only, for recovery after an unconfirmed attempt.
    /// Never read a changed field to reconstruct the text which was replaced.
    var selectedOriginalText: String {
        (original as NSString).substring(with: NSRange(location: range.location, length: range.length))
    }
    static func capture(expectedPID: pid_t, permit: DictationInsertionPermit,
                        accessibility: any DictationAccessibility = SystemDictationAccessibility()) -> Capture {
        guard accessibility.isTrusted else { return .unavailable(.accessibilityDenied) }
        guard !accessibility.isSecure else { return .unavailable(.protectedField) }
        var lastFailure = DictationInsertionFailure.unavailableField
        var bootstrap: DictationAXBootstrap?
        var firstElement: AXUIElement?
        // One bounded bootstrap and two reacquisitions for lazily exposed trees.
        for attempt in 0..<3 {
            guard permit.isAllowed else { return .unavailable(.changed) }
            if attempt > 0 {
                if attempt == 1 {
                    bootstrap = accessibility.prepareAccessibility(pid: expectedPID, allowed: { permit.isAllowed })
                    if bootstrap?.rejectsCapture == true { return .unavailable(.changed) }
                    if bootstrap?.requiresFreshFocus == true && firstElement == nil {
                        guard permit.isAllowed else { return .unavailable(.changed) }
                        if case .systemFocus(let focus) = lastFailure {
                            return .unavailable(.preparingAccessibility(focus.including(bootstrap)))
                        }
                        return .unavailable(.preparingAccessibility(nil))
                    }
                }
                guard bootstrap?.wait(before: attempt, allowed: { permit.isAllowed }) != false else { return .unavailable(.changed) }
            }
            guard permit.isAllowed else { return .unavailable(.changed) }
            guard accessibility.isTrusted else { return .unavailable(.accessibilityDenied) }
            guard !accessibility.isSecure else { return .unavailable(.protectedField) }
            var stop = false
            guard let element = accessibility.focusedElement(pid: expectedPID, failure: {
                lastFailure = .systemFocus($0.including(bootstrap)); stop = $0.preventsBootstrap
            }) else { if stop { return .unavailable(lastFailure) }; continue }
            if let firstElement, !CFEqual(firstElement, element) { return .unavailable(.changed) }
            var pid: pid_t = 0
            guard AXUIElementGetPid(element, &pid) == .success, pid == expectedPID else { continue }
            let role = accessibility.attribute(kAXRoleAttribute, of: element) as? String
            if role == kAXTextFieldRole || role == kAXTextAreaRole { firstElement = element }
            if accessibility.attribute(kAXSubroleAttribute, of: element) as? String == kAXSecureTextFieldSubrole {
                return .unavailable(.protectedField)
            }
            guard let range = selection(element, accessibility) else { lastFailure = .unavailableSelection; continue }
            guard let original = accessibility.attribute(kAXValueAttribute, of: element) as? String,
                  range.location <= original.utf16.count, range.length <= original.utf16.count - range.location,
                  (accessibility.selectedTextIsSettable(element) || accessibility.supportsUnicodeInsertion(element)) else {
                return .unavailable(.unsupportedEditor)
            }
            guard let observation = accessibility.observe(element, pid: pid,
                received: { permit.receiveChange($0) }, changed: { permit.observedChange($0) }) else {
                return .unavailable(.monitoringUnavailable)
            }
            let target = DictationTarget(element: element, pid: pid, range: range, original: original,
                                         accessibility: accessibility, observation: observation)
            guard permit.isAllowed, target.isCurrent() else { return .unavailable(.changed) }
            return .target(target)
        }
        return .unavailable(lastFailure)
    }

    func isCurrent() -> Bool {
        guard !accessibility.isSecure, let focused = accessibility.focusedElement(pid: pid),
              CFEqual(element, focused),
              accessibility.attribute(kAXSubroleAttribute, of: element) as? String != kAXSecureTextFieldSubrole,
              let current = Self.selection(element, accessibility),
              current.location == range.location, current.length == range.length,
              accessibility.attribute(kAXValueAttribute, of: element) as? String == original else { return false }
        return true
    }

    func insert(_ text: String, permit: DictationInsertionPermit) -> DictationInsertionResult {
        guard permit.isAllowed, isCurrent(), permit.isAllowed else { return .fallback(.changed) }
        let unicode = accessibility.supportsUnicodeInsertion(element)
        let direct = accessibility.selectedTextIsSettable(element) && !accessibility.prefersUnicodeInsertion(pid: pid)
        guard direct || unicode else { return .fallback(.unsupportedEditor) }
        guard permit.beginWriting(), isCurrent(), permit.isAllowed else { return .fallback(.changed) }
        defer { permit.endWriting() }
        // The validator owns only the system boundary and element, never the
        // observation which owns the permit's callback.
        let ax = accessibility, destination = element, destinationPID = pid
        let readSnapshot: () -> DictationFieldState? = {
            Self.fieldState(element: destination, pid: destinationPID, accessibility: ax)
        }
        if direct {
            let expected = replacing(original, range: range, with: text)
            // A timeout can still have applied the mutation. Read back, never
            // retry or switch to synthetic typing after an attempted AX write.
            let end = range.location + text.utf16.count
            let replacedSelection = CFRange(location: range.location, length: text.utf16.count)
            let caret = CFRange(location: end, length: 0)
            guard permit.expectWrite(before: DictationFieldState(original, range),
                after: [DictationFieldState(expected, replacedSelection), DictationFieldState(expected, caret)],
                readSnapshot: readSnapshot) else { return .fallback(.changed) }
            guard permit.isAllowed, readSnapshot() == DictationFieldState(original, range), permit.isAllowed else {
                permit.cancel(); return .fallback(.changed)
            }
            _ = accessibility.setSelectedText(text, in: element)
            let confirmed = confirm(expected)
            guard confirmed else { return .fallback(.unconfirmed) }
            if permit.isAllowed, isFocused(),
               let selected = Self.selection(element, accessibility),
               selected.location == range.location, selected.length == text.utf16.count {
                _ = accessibility.setSelection(CFRange(location: end, length: 0), in: element)
            }
            guard permit.isAllowed, isFocused(), confirm(expected, caret: end),
                  permit.confirmWrite(DictationFieldState(expected, caret)) else { return .fallback(.unconfirmed) }
            return .inserted
        }
        // Editors may expose selection/value without an AXSelectedText setter. Send
        // bounded Unicode chunks to that process only, verifying the exact new
        // value AND caret before the next chunk. A post is never confirmation.
        var value = original
        var selected = range
        for chunk in Self.unicodeChunks(text) {
            guard permit.isAllowed, isFocused(),
                  accessibility.attribute(kAXValueAttribute, of: element) as? String == value,
                  Self.selection(element, accessibility).map({ $0.location == selected.location && $0.length == selected.length }) == true,
                  permit.isAllowed else { return .fallback(.unconfirmed) }
            let expected = replacing(value, range: selected, with: chunk)
            let end = selected.location + chunk.utf16.count
            let afterSelection = CFRange(location: end, length: 0)
            guard permit.expectWrite(before: DictationFieldState(value, selected),
                after: [DictationFieldState(expected, afterSelection)], readSnapshot: readSnapshot) else { return .fallback(.unconfirmed) }
            // Publishing states may wait for an in-flight AX read at capacity.
            // Its known own snapshot does not prove the field stayed unchanged
            // during that wait. Revalidate immediately before the actual post.
            guard permit.isAllowed, readSnapshot() == DictationFieldState(value, selected), permit.isAllowed else {
                permit.cancel(); return .fallback(.unconfirmed)
            }
            guard accessibility.postUnicode(chunk, pid: pid) else { return .fallback(.unconfirmed) }
            let confirmed = confirm(expected, caret: end)
            guard confirmed, permit.isAllowed, isFocused(),
                  permit.confirmWrite(DictationFieldState(expected, afterSelection)) else { return .fallback(.unconfirmed) }
            value = expected
            selected = CFRange(location: end, length: 0)
        }
        return .inserted
    }

    private func isFocused() -> Bool {
        guard !accessibility.isSecure, let focused = accessibility.focusedElement(pid: pid) else { return false }
        return CFEqual(element, focused)
            && accessibility.attribute(kAXSubroleAttribute, of: element) as? String != kAXSecureTextFieldSubrole
    }
    private static func fieldState(element: AXUIElement, pid: pid_t,
                                   accessibility: any DictationAccessibility) -> DictationFieldState? {
        guard !accessibility.isSecure,
              accessibility.focusedElement(pid: pid).map({ CFEqual(element, $0) }) == true,
              accessibility.attribute(kAXSubroleAttribute, of: element) as? String != kAXSecureTextFieldSubrole,
              let value = accessibility.attribute(kAXValueAttribute, of: element) as? String,
              let range = selection(element, accessibility) else { return nil }
        return DictationFieldState(value, range)
    }
    private func confirm(_ expected: String, caret: Int? = nil) -> Bool {
        for attempt in 0..<6 {
            if attempt > 0 { Thread.sleep(forTimeInterval: 0.025) }
            if accessibility.attribute(kAXValueAttribute, of: element) as? String == expected {
                if let caret {
                    if let selection = Self.selection(element, accessibility), selection.location == caret, selection.length == 0 { return true }
                } else { return true }
            }
        }
        return false
    }
    private func replacing(_ value: String, range: CFRange, with text: String) -> String {
        (value as NSString).replacingCharacters(in: NSRange(location: range.location, length: range.length), with: text)
    }
    static func unicodeChunks(_ text: String) -> [String] {
        // At most 16 UTF-16 units, without splitting surrogate pairs. A long
        // grapheme is safe to deliver scalar-by-scalar across separate events.
        var chunks: [String] = [], chunk = ""
        for scalar in text.unicodeScalars {
            let next = String(scalar)
            if chunk.utf16.count + next.utf16.count > 16 { chunks.append(chunk); chunk = "" }
            chunk += next
        }
        if !chunk.isEmpty { chunks.append(chunk) }
        return chunks
    }

    private static func selection(_ element: AXUIElement, _ accessibility: any DictationAccessibility) -> CFRange? {
        guard let value = accessibility.attribute(kAXSelectedTextRangeAttribute, of: element),
              CFGetTypeID(value) == AXValueGetTypeID() else { return nil }
        var range = CFRange()
        guard AXValueGetValue(unsafeBitCast(value, to: AXValue.self), .cfRange, &range),
              range.location >= 0, range.length >= 0 else { return nil }
        return range
    }
}

/// Created at the physical hold, not after recognition. Cancellation is sticky
/// through capture, recording, transcription and the queued insertion.
final class DictationInsertionPermit {
    private let lock = NSCondition()
    private var allowed = true
    private var insertionStarted = false
    private var expectedStates: DictationWriteStates?
    private var readSnapshot: (() -> DictationFieldState?)?
    private var nextReadID = 0
    private var activeReads: [Int: [DictationWriteStates]] = [:]
    private let maximumReadStates = 16
    func beginWriting() -> Bool {
        lock.lock(); defer { lock.unlock() }
        guard allowed else { return false }
        insertionStarted = true
        return true
    }
    func expectWrite(before: DictationFieldState, after: [DictationFieldState],
                     readSnapshot: @escaping () -> DictationFieldState?) -> Bool {
        lock.lock(); defer { lock.unlock() }
        guard allowed else { return false }
        // Bound history to active AX reads, without discarding an intermediate
        // own state while its immutable sample is still being read. At capacity
        // only the insertion worker waits; condition.wait releases the lock so
        // the observer or physical cancellation can finish immediately.
        let deadline = Date(timeIntervalSinceNow: 0.6)
        while allowed && activeReads.values.contains(where: { $0.count >= maximumReadStates }) {
            if !lock.wait(until: deadline) {
                invalidateLocked(); return false
            }
        }
        guard allowed else { return false }
        // AX notifications describe state, not one acknowledgment per write.
        // Accept duplicates/coalescing only while the exact original target,
        // value and selection match the current write's known states.
        let states = DictationWriteStates(before: before, after: after)
        expectedStates = states
        for id in Array(activeReads.keys) { activeReads[id]?.append(states) }
        self.readSnapshot = readSnapshot
        return true
    }
    func observedChange(_ change: DictationAXChange) {
        if change == .focus { cancel(); return }
        for attempt in 0..<6 {
            lock.lock()
            guard allowed, let statesAtRead = expectedStates, let readSnapshot else {
                invalidateLocked(); lock.unlock(); return
            }
            let readID = nextReadID
            nextReadID &+= 1
            activeReads[readID] = [statesAtRead]
            lock.unlock()
            let sampled = readSnapshot()
            lock.lock()
            let knownStates = activeReads.removeValue(forKey: readID)
            lock.broadcast()
            guard allowed, let sampled, let knownStates, expectedStates != nil else {
                invalidateLocked(); lock.unlock(); return
            }
            // A read may overlap several chunks. Keep all exact own states
            // published DURING this read; release them as soon as it ends.
            // A foreign sample never disappears through a later field reread.
            if knownStates.contains(where: { $0.contains(sampled) }) {
                lock.unlock(); return
            }
            guard knownStates.contains(where: { $0.maySettle(sampled) }) else {
                invalidateLocked(); lock.unlock(); return
            }
            lock.unlock()
            if attempt < 5 { Thread.sleep(forTimeInterval: 0.025) }
        }
        cancel()
    }
    func receiveChange(_ change: DictationAXChange) -> Bool {
        lock.lock(); defer { lock.unlock() }
        if change == .focus || expectedStates == nil {
            invalidateLocked()
        }
        return allowed
    }
    func confirmWrite(_ state: DictationFieldState) -> Bool {
        // Drop the before/transition states as soon as exact readback succeeds.
        lock.lock(); defer { lock.unlock() }
        guard allowed, expectedStates != nil else { return false }
        expectedStates = DictationWriteStates(before: nil, after: [state])
        return true
    }
    func endWriting() {
        lock.lock(); defer { lock.unlock() }
        expectedStates = nil
        readSnapshot = nil
        activeReads.removeAll()
        lock.broadcast()
    }
    func validateSnapshot(_ current: Bool) {
        lock.lock(); defer { lock.unlock() }
        if !insertionStarted && !current { invalidateLocked() }
    }
    private func invalidateLocked() {
        allowed = false
        activeReads.removeAll()
        lock.broadcast()
    }
    func cancel() {
        lock.lock(); invalidateLocked(); lock.unlock()
    }
    var isAllowed: Bool { lock.lock(); defer { lock.unlock() }; return allowed }
}
#endif
