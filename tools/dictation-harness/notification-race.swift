import Foundation
import ApplicationServices

// Independent Standards review's Target-level semaphore reproduction, retained
// as a regression. The only replacements are the AX and delivery boundaries;
// no foreign UI, microphone, TCC changes, or system event posts are involved.

enum EventTap { static let syntheticMarker: Int64 = 0xC0FFEE }
final class RaceAX: DictationAccessibility {
    let element = AXUIElementCreateApplication(getpid())
    var isTrusted = true
    var isSecure = false
    var value = ""
    var range = CFRange(location: 0, length: 0)
    var posts = 0
    var mainReads = 0
    var callback: ((DictationAXChange) -> Void)?
    let sampled = DispatchSemaphore(value: 0)
    let resume = DispatchSemaphore(value: 0)
    let done = DispatchSemaphore(value: 0)
    var firstWorkerValue = true
    var holdWorkerRange = false
    let kind = ProcessInfo.processInfo.environment["MLS_DICTATION_RACE_KIND"] ?? "foreign-value"
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
        return element
    }
    func enableAccessibility(pid: pid_t) {}
    func attribute(_ name: String, of element: AXUIElement) -> CFTypeRef? {
        let worker = Thread.current.threadDictionary["notification-worker"] as? Bool == true
        switch name {
        case kAXValueAttribute:
            if worker && firstWorkerValue {
                firstWorkerValue = false
                if kind != "next-own" { holdWorkerRange = true }
                let captured = value
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
                if kind != "foreign-value" { sampled.signal() }
                precondition(resume.wait(timeout: .now() + 5) == .success)
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
            precondition(done.wait(timeout: .now() + 5) == .success)
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
let phrase = "Давай проверим, работает ли вставка."
let result = target.insert(phrase, permit: permit)
print("\(ax.kind) / concurrent own-state publication: result=\(result) posts=\(ax.posts) allowed=\(permit.isAllowed) value=\(String(reflecting: ax.value))")
if ax.kind == "previous-own" || ax.kind == "next-own" {
    precondition(result == .inserted && ax.posts == 3 && ax.value == phrase && permit.isAllowed)
    print("PASS: legitimate concurrent own snapshot completes once")
} else {
    if permit.isAllowed || ax.posts > 1 {
        fputs("FAIL: sampled foreign state did not cancel permanently\n", stderr)
        exit(1)
    }
    precondition(result == .fallback(.unconfirmed) && ax.posts == 1)
    print("PASS: sampled foreign AX state remains cancellation after confirmWrite advances")
}
