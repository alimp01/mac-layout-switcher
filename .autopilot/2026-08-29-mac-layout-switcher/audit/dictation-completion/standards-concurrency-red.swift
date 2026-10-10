import Foundation
import ApplicationServices

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
    func focusedElement(pid: pid_t) -> AXUIElement? { element }
    func enableAccessibility(pid: pid_t) {}
    func attribute(_ name: String, of element: AXUIElement) -> CFTypeRef? {
        let worker = Thread.current.threadDictionary["notification-worker"] as? Bool == true
        switch name {
        case kAXValueAttribute:
            if worker && firstWorkerValue {
                firstWorkerValue = false; holdWorkerRange = true
                let capturedForeign = value
                precondition(capturedForeign == "foreign")
                sampled.signal()
                return capturedForeign as CFString
            }
            if !worker && posts == 1 {
                mainReads += 1
                if mainReads == 2 {
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
                precondition(resume.wait(timeout: .now() + 5) == .success)
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
            let ownValue = value
            value = "foreign"
            DispatchQueue.global().async {
                Thread.current.threadDictionary["notification-worker"] = true
                self.callback?(.value)
                self.done.signal()
            }
            precondition(sampled.wait(timeout: .now() + 5) == .success)
            // Foreign state has already been returned by the AX boundary.
            // An external restore precedes insertion's exact readback.
            value = ownValue
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
print("sampled foreign AXValue / first confirmWrite: result=\(result) posts=\(ax.posts) allowed=\(permit.isAllowed) value=\(String(reflecting: ax.value))")
if permit.isAllowed || ax.posts > 1 {
    fputs("FAIL: sampled foreign state did not cancel permanently\n", stderr)
    exit(1)
}
