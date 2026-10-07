#if os(macOS)
import ApplicationServices
import Foundation
import SwitcherCore

/// Explicit conversions only. AX reads run off EventTap; any later physical
/// input cancels the request before a selected-text write can be committed.
final class SelectionConverter {
    struct Selection {
        let target: InputFocusGuard.Target
        let range: CFRange
        let text: String
    }
    enum Capture {
        case empty(InputFocusGuard.Target, CFRange)
        case selected(Selection)
        case unavailable
    }
    private let queue = DispatchQueue(label: "MacLayoutSwitcher.SelectionCapture")
    private var permit: InputFocusGuard.Permit?

    @discardableResult
    func cancel() -> Bool {
        let wasPending = permit != nil
        permit?.cancel()
        permit = nil
        return wasPending
    }
    func finish(_ request: InputFocusGuard.Permit) {
        if permit === request { permit = nil }
    }

    func capture(expected: InputFocusGuard.Target, completion: @escaping (Capture, InputFocusGuard.Permit) -> Void) {
        cancel()
        let request = InputFocusGuard.Permit()
        permit = request
        queue.async {
            let result: Capture
            if request.isAllowed, let target = InputFocusGuard.Target.capture(),
               target.matches(expected), let range = target.selection() {
                if range.length == 0 {
                    result = .empty(target, range)
                } else if range.length <= 65_536, let text = target.text(in: range),
                          text.utf16.count == range.length, target.isCurrent(),
                          target.selection().map({ $0.location == range.location && $0.length == range.length }) == true {
                    result = .selected(Selection(target: target, range: range, text: text))
                } else { result = .unavailable }
            } else { result = .unavailable }
            DispatchQueue.main.async {
                guard request.isAllowed else { return }
                completion(result, request)
            }
        }
    }

    func replace(_ selection: Selection, permit: InputFocusGuard.Permit,
                 typist: Typist, completion: @escaping (Bool, Lang) -> Void) {
        let converted = KeyMap.selectionConversion(selection.text)
        typist.enqueue {
            let completed = selection.target.replace(range: selection.range,
                expected: selection.text, with: converted.text, originalSelection: selection.range,
                allowed: { permit.isAllowed })
            DispatchQueue.main.async { completion(completed, converted.language) }
        }
    }
}
#endif
