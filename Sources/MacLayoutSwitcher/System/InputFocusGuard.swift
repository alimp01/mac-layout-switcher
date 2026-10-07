#if os(macOS)
import ApplicationServices
import Foundation
import SwitcherCore

/// AX work is restricted to the sampling queue and Typist, never EventTap.
/// The cache only licenses a target identity: deletion still requires a fresh
/// empty selection and an exact source-text match at execution time.
final class InputFocusGuard {
    final class Permit {
        private let lock = NSLock()
        private var allowed = true
        func cancel() { lock.lock(); allowed = false; lock.unlock() }
        var isAllowed: Bool { lock.lock(); defer { lock.unlock() }; return allowed }
    }

    struct Target {
        let element: AXUIElement
        let pid: pid_t

        static func capture() -> Target? {
            guard !SecureInput.isActive else { return nil }
            let system = AXUIElementCreateSystemWide()
            AXUIElementSetMessagingTimeout(system, 0.1)
            var value: CFTypeRef?
            guard AXUIElementCopyAttributeValue(system, kAXFocusedUIElementAttribute as CFString, &value) == .success,
                  let value, CFGetTypeID(value) == AXUIElementGetTypeID() else { return nil }
            let element = unsafeBitCast(value, to: AXUIElement.self)
            AXUIElementSetMessagingTimeout(element, 0.1)
            var pid: pid_t = 0
            guard AXUIElementGetPid(element, &pid) == .success else { return nil }
            var subrole: CFTypeRef?
            _ = AXUIElementCopyAttributeValue(element, kAXSubroleAttribute as CFString, &subrole)
            guard subrole as? String != kAXSecureTextFieldSubrole as String else { return nil }
            return Target(element: element, pid: pid)
        }

        func matches(_ other: Target) -> Bool { pid == other.pid && CFEqual(element, other.element) }
        func isCurrent() -> Bool { Self.capture().map(matches) ?? false }

        func selection() -> CFRange? {
            var value: CFTypeRef?
            guard AXUIElementCopyAttributeValue(element, kAXSelectedTextRangeAttribute as CFString, &value) == .success,
                  let value, CFGetTypeID(value) == AXValueGetTypeID() else { return nil }
            var range = CFRange()
            guard AXValueGetValue(unsafeBitCast(value, to: AXValue.self), .cfRange, &range),
                  range.location >= 0, range.length >= 0 else { return nil }
            return range
        }

        func text(in range: CFRange) -> String? {
            var range = range
            guard let parameter = AXValueCreate(.cfRange, &range) else { return nil }
            var value: CFTypeRef?
            if AXUIElementCopyParameterizedAttributeValue(element, kAXStringForRangeParameterizedAttribute as CFString,
                                                         parameter, &value) == .success,
               let text = value as? String { return text }
            // Plain NSTextFields commonly expose AXValue instead of AXStringForRange.
            guard AXUIElementCopyAttributeValue(element, kAXValueAttribute as CFString, &value) == .success,
                  let text = value as? String, range.location <= text.utf16.count,
                  range.length <= text.utf16.count - range.location else { return nil }
            return (text as NSString).substring(with: NSRange(location: range.location, length: range.length))
        }

        func sourceRange(_ expected: String) -> CFRange? {
            let source = ReplacementSource(expected: expected)
            guard isCurrent(), let selection = selection(),
                  let range = source.rangeBeforeCaret(location: selection.location, selectionLength: selection.length) else { return nil }
            let atStart = range.lowerBound == 0
            let validationStart = atStart ? 0 : range.lowerBound - 1
            guard source.matches(text(in: CFRange(location: validationStart,
                                                  length: range.upperBound - validationStart)),
                                 atDocumentStart: atStart) else { return nil }
            return CFRange(location: range.lowerBound, length: range.count)
        }

        /// One targeted text mutation; never rewrite AXValue for the whole field.
        /// Selecting the source is non-destructive and undone if the write fails.
        /// The same primitive supports a pre-existing selection (manual convert).
        func replace(range: CFRange, expected: String, with replacement: String,
                     originalSelection: CFRange, allowed: () -> Bool) -> Bool {
            guard allowed(), isCurrent(), let original = selection(),
                  original.location == originalSelection.location, original.length == originalSelection.length,
                  text(in: range) == expected else { return false }
            var rangeSettable = DarwinBoolean(false)
            var textSettable = DarwinBoolean(false)
            guard AXUIElementIsAttributeSettable(element, kAXSelectedTextRangeAttribute as CFString, &rangeSettable) == .success,
                  rangeSettable.boolValue,
                  AXUIElementIsAttributeSettable(element, kAXSelectedTextAttribute as CFString, &textSettable) == .success,
                  textSettable.boolValue else { return false }
            var selected = range
            guard let selectedValue = AXValueCreate(.cfRange, &selected), allowed(), isCurrent(),
                  selection().map({ $0.location == original.location && $0.length == original.length }) == true,
                  AXUIElementSetAttributeValue(element, kAXSelectedTextRangeAttribute as CFString, selectedValue) == .success else { return false }
            var completed = false
            defer {
                // Restore only our own temporary selection, never newer user state.
                if !completed, isCurrent(),
                   selection().map({ $0.location == range.location && $0.length == range.length }) == true {
                    var restored = original
                    if let value = AXValueCreate(.cfRange, &restored) {
                        _ = AXUIElementSetAttributeValue(element, kAXSelectedTextRangeAttribute as CFString, value)
                    }
                }
            }
            guard allowed(), isCurrent(),
                  selection().map({ $0.location == range.location && $0.length == range.length }) == true,
                  text(in: range) == expected, allowed() else { return false }
            completed = AXUIElementSetAttributeValue(element, kAXSelectedTextAttribute as CFString,
                                                     replacement as CFString) == .success
            if completed, allowed(), isCurrent() {
                // AXSelectedText setters differ in whether replacement stays
                // selected. Put the caret after our committed text explicitly.
                var caret = CFRange(location: range.location + replacement.utf16.count, length: 0)
                if let value = AXValueCreate(.cfRange, &caret) {
                    _ = AXUIElementSetAttributeValue(element, kAXSelectedTextRangeAttribute as CFString, value)
                }
            }
            return completed
        }
    }

    /// Accessed exclusively on Typist's serial queue. A delivered physical Tab
    /// or Enter may intentionally move focus; subsequent physical replays follow
    /// native event order until idle, unless unrelated navigation cancels them.
    final class ReplayRoute {
        private let target: Target
        private var policy = InputReplayPolicy()
        init(target: Target) { self.target = target }
        func didNavigate() { policy.didDeliverNavigation() }
        func canReplay(permit: Permit) -> Bool {
            let current = policy.followsNavigation || target.isCurrent()
            return policy.allowsReplay(cancelled: !permit.isAllowed,
                                       secure: SecureInput.isActive, originalTargetCurrent: current)
        }
    }

    struct Ticket {
        let target: Target
        let permit: Permit
        let replacementPermit: Permit
        let replayRoute: ReplayRoute
        var allowsReplacement: Bool { replacementPermit.isAllowed && isCurrent }
        var isCurrent: Bool { permit.isAllowed && target.isCurrent() && permit.isAllowed }
    }

    private let queue = DispatchQueue(label: "MacLayoutSwitcher.InputFocus")
    private var timer: DispatchSourceTimer?
    private var permit = Permit()
    private var replacementPermit = Permit()
    private var target: Target?
    private var replayRoute: ReplayRoute?
    private var sampling = false
    var onChange: (() -> Void)?
    var shouldSample: (() -> Bool)?
    var ticket: Ticket? {
        guard let target, let replayRoute else { return nil }
        return Ticket(target: target, permit: permit, replacementPermit: replacementPermit, replayRoute: replayRoute)
    }

    func start() {
        guard timer == nil else { return }
        let timer = DispatchSource.makeTimerSource(queue: .main)
        timer.schedule(deadline: .now(), repeating: .milliseconds(100))
        timer.setEventHandler { [weak self] in self?.refresh() }
        self.timer = timer
        timer.resume()
    }

    func stop() { timer?.cancel(); timer = nil; invalidate() }

    /// Main-thread, constant-time cancellation, suitable for the event callback.
    func invalidate() {
        permit.cancel()
        replacementPermit.cancel()
        permit = Permit()
        replacementPermit = Permit()
        target = nil
        replayRoute = nil
        onChange?()
        // The click itself must first reach the application. Start an off-tap
        // refresh on the next main-loop turn rather than waiting for the timer.
        DispatchQueue.main.async { [weak self] in
            guard let self, self.timer != nil else { return }
            self.refresh()
        }
    }

    /// A correction failure invalidates dependent corrections, not physical keys.
    /// Return false for a completion from an older field or already reset batch.
    func reject(_ ticket: Ticket) -> Bool {
        guard permit === ticket.permit, replacementPermit === ticket.replacementPermit else { return false }
        replacementPermit.cancel()
        replacementPermit = Permit()
        return true
    }

    private func refresh() {
        guard !sampling, shouldSample?() != false else { return }
        sampling = true
        let requestedPermit = permit
        queue.async { [weak self] in
            let captured = Target.capture()
            DispatchQueue.main.async { [weak self] in
                guard let self else { return }
                self.sampling = false
                guard self.timer != nil, self.permit === requestedPermit, self.shouldSample?() != false else { return }
                let unchanged = self.target.flatMap { old in captured.map { old.matches($0) } } ?? (captured == nil && self.target == nil)
                if !unchanged {
                    self.invalidate()
                    self.target = captured
                    self.replayRoute = captured.map(ReplayRoute.init)
                }
            }
        }
    }
}
#endif
