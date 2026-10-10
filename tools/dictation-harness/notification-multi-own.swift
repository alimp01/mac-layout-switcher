import Foundation
import ApplicationServices

// Independent Spec review's multi-chunk extension of the Standards semaphore
// reproduction, retained
// as a regression. The only replacements are the AX and delivery boundaries;
// no foreign UI, microphone, TCC changes, or system event posts are involved.
// Capacity mutation extends the independent Standards final3 stale-preflight
// probe: the field changes AFTER preflight while advancement waits for AX.

enum EventTap { static let syntheticMarker: Int64 = 0xC0FFEE }
final class RaceAX: DictationAccessibility {
    let element = AXUIElementCreateApplication(getpid())
    var isTrusted = true
    var isSecure = false
    var focusedOtherField = false
    let otherElement = AXUIElementCreateSystemWide()
    var value = ""
    var range = CFRange(location: 0, length: 0)
    var posts = 0
    var mainReads = 0
    var callback: ((DictationAXChange) -> Void)?
    let sampled = DispatchSemaphore(value: 0)
    let resume = DispatchSemaphore(value: 0)
    let done = DispatchSemaphore(value: 0)
    let sampledRange = DispatchSemaphore(value: 0)
    let resumeRange = DispatchSemaphore(value: 0)
    var firstWorkerValue = true
    var holdWorkerRange = false
    let kind = ProcessInfo.processInfo.environment["MLS_DICTATION_RACE_KIND"] ?? "next-own"
    let scopeKind = ProcessInfo.processInfo.environment["MLS_DICTATION_MULTI_KIND"] ?? "four"
    let releaseLock = NSLock()
    var releasedRead = false
    var cancelAction: (() -> Void)?
    var sampledOwnValue = ""
    var sampledOwnRange = CFRange(location: 0, length: 0)
    var holdWorkerFocus = true
    func focusedElement(pid: pid_t) -> AXUIElement? {
        if Thread.current.threadDictionary["notification-worker"] as? Bool == true,
           kind == "next-own", holdWorkerFocus {
            holdWorkerFocus = false
            // observedChange has captured chunk1's states. Read the actual AX
            // snapshot only after chunk2 has published and applied its states.
            sampled.signal()
            precondition(resume.wait(timeout: .now() + 5) == .success)
        }
        return focusedOtherField ? otherElement : element
    }
    func enableAccessibility(pid: pid_t) {}
    func attribute(_ name: String, of element: AXUIElement) -> CFTypeRef? {
        let worker = Thread.current.threadDictionary["notification-worker"] as? Bool == true
        switch name {
        case kAXValueAttribute:
            if worker && firstWorkerValue {
                firstWorkerValue = false
                holdWorkerRange = true
                let captured = value
                sampledOwnValue = captured
                if kind == "foreign-value" {
                    precondition(captured == "foreign")
                    sampled.signal()
                }
                return captured as CFString
            }
            if !worker && posts == 1 {
                mainReads += 1
                if mainReads == 2 && kind != "next-own" {
                    // This is the next iteration's preflight read, after the
                    // first chunk's confirmWrite published the exact snapshot.
                    resume.signal()
                    precondition(done.wait(timeout: .now() + 5) == .success)
                }
            }
            return value as CFString
        case kAXSelectedTextRangeAttribute:
            if worker && holdWorkerRange {
                holdWorkerRange = false
                var captured = range
                sampledOwnRange = captured
                if kind == "next-own" {
                    print("Captured intermediate legitimate own value/range at chunk2")
                    sampledRange.signal()
                    precondition(resumeRange.wait(timeout: .now() + 5) == .success)
                } else {
                    if kind != "foreign-value" { sampled.signal() }
                    precondition(resume.wait(timeout: .now() + 5) == .success)
                }
                return AXValueCreate(.cfRange, &captured)
            }
            var captured = range
            return AXValueCreate(.cfRange, &captured)
        default: return nil
        }
    }
    func selectedTextIsSettable(_ element: AXUIElement) -> Bool { false }
    func supportsUnicodeInsertion(_ element: AXUIElement) -> Bool { true }
    func prefersUnicodeInsertion(pid: pid_t) -> Bool { true }
    func postUnicode(_ text: String, pid: pid_t) -> Bool {
        posts += 1
        let releaseChunk = scopeKind == "four" || scopeKind == "cleanup" ? 4 : 16
        if posts == releaseChunk && kind == "next-own" {
            if scopeKind == "four" || scopeKind == "cleanup" {
                resumeRange.signal()
                precondition(done.wait(timeout: .now() + 5) == .success)
                if scopeKind == "cleanup" {
                    // A completed read's history cannot license a NEW external
                    // change back to its old intermediate value/selection.
                    let ownValue = value, ownRange = range
                    value = sampledOwnValue; range = sampledOwnRange
                    callback?(.value)
                    value = ownValue; range = ownRange
                }
            } else if scopeKind == "capacity" || scopeKind.hasPrefix("mutate-") {
                DispatchQueue.global().asyncAfter(deadline: .now() + 0.05) {
                    switch self.scopeKind {
                    case "mutate-value": self.value = "FOREIGN"; self.range = CFRange(location: 0, length: 0)
                    case "mutate-range": self.range = CFRange(location: 0, length: 0)
                    case "mutate-field": self.focusedOtherField = true
                    case "mutate-secure": self.isSecure = true
                    default: break
                    }
                    self.releaseLock.lock(); self.releasedRead = true; self.releaseLock.unlock()
                    self.resumeRange.signal()
                }
            } else if scopeKind == "cancel" || scopeKind == "focus" {
                DispatchQueue.global().asyncAfter(deadline: .now() + 0.05) { self.cancelAction?() }
            } // stalled keeps AX pending until insertion truthfully stops.
        }
        if posts == 17 {
            releaseLock.lock(); let released = releasedRead; releaseLock.unlock()
            precondition((scopeKind == "capacity" || scopeKind.hasPrefix("mutate-")) && released, "advancement waits for in-flight read at ledger capacity")
        }
        value = (value as NSString).replacingCharacters(in: NSRange(location: range.location, length: range.length), with: text)
        range = CFRange(location: range.location + text.utf16.count, length: 0)
        if posts == 1 {
            let ownValue = value, ownRange = range
            if kind == "foreign-value" { value = "foreign" }
            if kind == "foreign-range" { range = CFRange(location: 999, length: 0) }
            DispatchQueue.global().async {
                Thread.current.threadDictionary["notification-worker"] = true
                self.callback?(.value)
                self.done.signal()
            }
            precondition(sampled.wait(timeout: .now() + 5) == .success)
            // Foreign state has already been returned by the AX boundary.
            // An external restore precedes insertion's exact readback.
            value = ownValue; range = ownRange
        }
        if posts == 2 && kind == "next-own" {
            resume.signal()
            precondition(sampledRange.wait(timeout: .now() + 5) == .success)
        }
        return true
    }
    func setSelection(_ range: CFRange, in element: AXUIElement) -> Bool { false }
    func setSelectedText(_ text: String, in element: AXUIElement) -> AXError { .failure }
    func observe(_ element: AXUIElement, pid: pid_t, changed: @escaping (DictationAXChange) -> Void) -> AnyObject? {
        callback = changed; return NSObject()
    }
}
let ax = RaceAX(), permit = DictationInsertionPermit()
guard case .target(let target) = DictationTarget.capture(expectedPID: getpid(), permit: permit, accessibility: ax) else { fatalError("capture") }
ax.cancelAction = { if ax.scopeKind == "focus" { ax.callback?(.focus) } else { permit.cancel() } }
let short = ax.scopeKind == "four" || ax.scopeKind == "cleanup"
let phrase = String(repeating: "Давай проверим, работает ли вставка.", count: short ? 3 : 12)
let started = Date()
let result = target.insert(phrase, permit: permit)
let elapsed = Date().timeIntervalSince(started)
if ax.scopeKind.hasPrefix("mutate-") {
    precondition(ax.done.wait(timeout: .now() + 5) == .success)
    print("\(ax.scopeKind) after capacity wait: result=\(result) posts=\(ax.posts) allowed=\(permit.isAllowed) value=\(String(reflecting: ax.value))")
    if result != .fallback(.unconfirmed) || ax.posts != 16 || permit.isAllowed {
        fputs("FAIL: stale preflight after wait permitted another write\n", stderr); exit(1)
    }
    if ax.scopeKind == "mutate-value" { precondition(ax.value == "FOREIGN" && ax.range.location == 0 && ax.range.length == 0) }
    else { precondition(ax.value.utf16.count == 256, "already confirmed prefix preserved") }
    ax.focusedOtherField = false; ax.isSecure = false
    precondition(target.insert(phrase, permit: permit) == .fallback(.changed) && ax.posts == 16, "stale wait cancellation remains sticky after restoration")
    print("PASS: exact target/value/caret/permit rechecked after capacity wait, no further write/retry")
    exit(0)
}
if ax.scopeKind == "stalled" || ax.scopeKind == "cancel" || ax.scopeKind == "focus" {
    ax.resumeRange.signal()
    precondition(ax.done.wait(timeout: .now() + 5) == .success)
    precondition(result == .fallback(.unconfirmed) && ax.posts == 16 && !permit.isAllowed)
    precondition(target.insert(phrase, permit: permit) == .fallback(.changed) && ax.posts == 16, "late callback cannot revive stopped insertion")
    if ax.scopeKind == "stalled" { precondition(elapsed >= 0.5 && elapsed < 2, "stalled AX has bounded truthful refusal") }
    else { precondition(elapsed < 0.4, "physical/focus cancellation wakes capacity wait immediately") }
    print("PASS: \(ax.scopeKind) at capacity: posts=\(ax.posts) elapsed=\(elapsed), unconfirmed + sticky cancel + late-reader cleanup")
    exit(0)
}
if ax.scopeKind == "cleanup" {
    precondition(result == .fallback(.unconfirmed) && ax.posts == 4 && !permit.isAllowed)
    print("PASS: completed read's own history cannot exempt later foreign restoration")
    exit(0)
}
print("\(ax.scopeKind): \(ax.kind) / concurrent own-state publication: result=\(result) posts=\(ax.posts) allowed=\(permit.isAllowed) units=\(ax.value.utf16.count)")
if ax.kind == "previous-own" || ax.kind == "next-own" {
    if result != .inserted || ax.value != phrase || !permit.isAllowed {
        fputs("FAIL: legitimate own snapshot crossing multiple chunks cancels completion\n", stderr)
        exit(1)
    }
    print("PASS: legitimate concurrent own snapshot completes once")
} else {
    if permit.isAllowed || ax.posts > 1 {
        fputs("FAIL: sampled foreign state did not cancel permanently\n", stderr)
        exit(1)
    }
    precondition(result == .fallback(.unconfirmed) && ax.posts == 1)
    print("PASS: sampled foreign AX state remains cancellation after confirmWrite advances")
}
