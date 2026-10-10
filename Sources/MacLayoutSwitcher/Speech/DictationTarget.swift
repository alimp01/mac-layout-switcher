#if os(macOS)
import ApplicationServices
import AppKit
import Foundation

/// Reasons are kept separate from recognition: unavailable AX never means
/// silence. An attempted write can have an uncertain outcome and is not retried.
enum DictationInsertionFailure: Equatable {
    case accessibilityDenied, unavailableField, unavailableSelection, unsupportedEditor
    case monitoringUnavailable, changed, protectedField, unconfirmed

    var message: String {
        switch self {
        case .accessibilityDenied: return "Нет разрешения «Универсальный доступ» для Mac Layout Switcher."
        case .unavailableField: return "Редактор не предоставил доступное поле ввода."
        case .unavailableSelection: return "Редактор не сообщил положение курсора или выделение."
        case .unsupportedEditor: return "Редактор не поддерживает проверяемую вставку через Универсальный доступ."
        case .monitoringUnavailable: return "Редактор не позволяет отслеживать изменения поля для безопасной вставки."
        case .changed: return "Во время диктовки изменилось поле, выделение или был ввод."
        case .protectedField: return "Автовставка недоступна в защищённом поле."
        case .unconfirmed: return "Не удалось подтвердить вставку. Часть или весь текст уже может быть в поле. Проверьте его перед копированием; повторной вставки не было."
        }
    }
}

enum DictationAXChange: Hashable { case focus, selection, value }

enum DictationInsertionResult: Equatable { case inserted, fallback(DictationInsertionFailure) }

/// Injectable at the AX system boundary so the exact production capture/write
/// path can be exercised without accessing any user's editor or granting TCC.
protocol DictationAccessibility {
    var isTrusted: Bool { get }
    var isSecure: Bool { get }
    func focusedElement(pid: pid_t) -> AXUIElement?
    func enableAccessibility(pid: pid_t)
    func attribute(_ name: String, of element: AXUIElement) -> CFTypeRef?
    func selectedTextIsSettable(_ element: AXUIElement) -> Bool
    func supportsUnicodeInsertion(_ element: AXUIElement) -> Bool
    func prefersUnicodeInsertion(pid: pid_t) -> Bool
    func postUnicode(_ text: String, pid: pid_t) -> Bool
    func setSelection(_ range: CFRange, in element: AXUIElement) -> Bool
    func setSelectedText(_ text: String, in element: AXUIElement) -> AXError
    func observe(_ element: AXUIElement, pid: pid_t, changed: @escaping (DictationAXChange) -> Void) -> AnyObject?
}

struct SystemDictationAccessibility: DictationAccessibility {
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
        let app = bounded(AXUIElementCreateApplication(pid))
        guard attribute(kAXFrontmostAttribute, of: app) as? Bool == true else { return nil }
        let system = bounded(AXUIElementCreateSystemWide())
        for owner in [system, app] {
            guard let value = attribute(kAXFocusedUIElementAttribute, of: owner),
                  CFGetTypeID(value) == AXUIElementGetTypeID() else { continue }
            let element = bounded(unsafeBitCast(value, to: AXUIElement.self))
            var actualPID: pid_t = 0
            if AXUIElementGetPid(element, &actualPID) == .success, actualPID == pid { return element }
        }
        return nil
    }
    func enableAccessibility(pid: pid_t) {
        // Electron's documented opt-in lazily creates the Chromium AX tree.
        // Unsupported native apps simply reject this attribute. No permissions
        // are requested or overridden, and no editor text is touched.
        let app = bounded(AXUIElementCreateApplication(pid))
        _ = AXUIElementSetAttributeValue(app, "AXManualAccessibility" as CFString, kCFBooleanTrue)
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
        let frameworks = bundle.appendingPathComponent("Contents/Frameworks")
        let names = (try? FileManager.default.contentsOfDirectory(atPath: frameworks.path)) ?? []
        return names.contains { name in
            ["Electron Framework.framework", "Codex Framework.framework", "Chromium Framework.framework", "Google Chrome Framework.framework",
             "Brave Browser Framework.framework", "Microsoft Edge Framework.framework"].contains(name)
        }
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
        DictationAXObservation(element: element, pid: pid, changed: changed)
    }
}

private final class DictationAXObservation {
    private final class Callback {
        let changed: (DictationAXChange) -> Void
        init(_ changed: @escaping (DictationAXChange) -> Void) { self.changed = changed }
    }
    private let callback: Callback
    private var observer: AXObserver?
    init?(element: AXUIElement, pid: pid_t, changed: @escaping (DictationAXChange) -> Void) {
        callback = Callback(changed)
        var created: AXObserver?
        guard AXObserverCreate(pid, { _, _, notification, context in
            guard let context else { return }
            let kind: DictationAXChange
            switch notification as String {
            case kAXFocusedUIElementChangedNotification: kind = .focus
            case kAXSelectedTextChangedNotification: kind = .selection
            default: kind = .value
            }
            Unmanaged<Callback>.fromOpaque(context).takeUnretainedValue().changed(kind)
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
        // One bounded bootstrap and two reacquisitions for lazily exposed trees.
        for attempt in 0..<3 {
            guard permit.isAllowed else { return .unavailable(.changed) }
            if attempt > 0 {
                if attempt == 1 { accessibility.enableAccessibility(pid: expectedPID) }
                Thread.sleep(forTimeInterval: 0.08)
            }
            guard !accessibility.isSecure else { return .unavailable(.protectedField) }
            guard let element = accessibility.focusedElement(pid: expectedPID) else { continue }
            var pid: pid_t = 0
            guard AXUIElementGetPid(element, &pid) == .success, pid == expectedPID else { continue }
            if accessibility.attribute(kAXSubroleAttribute, of: element) as? String == kAXSecureTextFieldSubrole {
                return .unavailable(.protectedField)
            }
            guard let range = selection(element, accessibility) else { lastFailure = .unavailableSelection; continue }
            guard let original = accessibility.attribute(kAXValueAttribute, of: element) as? String,
                  range.location <= original.utf16.count, range.length <= original.utf16.count - range.location,
                  (accessibility.selectedTextIsSettable(element) || accessibility.supportsUnicodeInsertion(element)) else {
                return .unavailable(.unsupportedEditor)
            }
            guard let observation = accessibility.observe(element, pid: pid, changed: { permit.observedChange($0) }) else {
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
        if direct {
            let expected = replacing(original, range: range, with: text)
            // A timeout can still have applied the mutation. Read back, never
            // retry or switch to synthetic typing after an attempted AX write.
            guard permit.expectWrite() else { return .fallback(.changed) }
            _ = accessibility.setSelectedText(text, in: element)
            let confirmed = confirm(expected)
            guard confirmed else { return .fallback(.unconfirmed) }
            let end = range.location + text.utf16.count
            if permit.isAllowed, isFocused(),
               let selected = Self.selection(element, accessibility),
               selected.location == range.location, selected.length == text.utf16.count {
                _ = accessibility.setSelection(CFRange(location: end, length: 0), in: element)
            }
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
            guard permit.expectWrite(), accessibility.postUnicode(chunk, pid: pid) else { return .fallback(.unconfirmed) }
            let end = selected.location + chunk.utf16.count
            let confirmed = confirm(expected, caret: end)
            guard confirmed else { return .fallback(.unconfirmed) }
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
    private let lock = NSLock()
    private var allowed = true
    private var insertionStarted = false
    private var acknowledgments: [DictationAXChange: [TimeInterval]] = [:]
    func beginWriting() -> Bool {
        lock.lock(); defer { lock.unlock() }
        guard allowed else { return false }
        insertionStarted = true
        return true
    }
    func expectWrite() -> Bool {
        lock.lock(); defer { lock.unlock() }
        guard allowed else { return false }
        // AX observer delivery is asynchronous on the main run loop. Keep
        // bounded outstanding acknowledgments across adjacent chunks, even
        // when read-back completes first. Never exempt a focus notification.
        let deadline = ProcessInfo.processInfo.systemUptime + 0.15
        for change in [DictationAXChange.selection, .value] {
            acknowledgments[change, default: []].removeAll { $0 < deadline - 0.15 }
            acknowledgments[change, default: []].append(deadline)
        }
        return true
    }
    func observedChange(_ change: DictationAXChange) {
        lock.lock(); defer { lock.unlock() }
        let now = ProcessInfo.processInfo.systemUptime
        acknowledgments[change, default: []].removeAll { $0 < now }
        if change == .focus || acknowledgments[change, default: []].isEmpty {
            allowed = false
        } else {
            acknowledgments[change]?.removeFirst()
        }
    }
    func validateSnapshot(_ current: Bool) {
        lock.lock(); defer { lock.unlock() }
        if !insertionStarted && !current { allowed = false }
    }
    func cancel() { lock.lock(); allowed = false; lock.unlock() }
    var isAllowed: Bool { lock.lock(); defer { lock.unlock() }; return allowed }
}
#endif
