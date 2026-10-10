import AppKit
import ApplicationServices

enum EventTap { static let syntheticMarker: Int64 = 0xC0FFEE }
func require(_ condition: @autoclosure () -> Bool, _ message: String) {
    guard condition() else { fputs("FAIL: \(message)\n", stderr); exit(1) }
}
let app = NSApplication.shared
app.setActivationPolicy(.prohibited)

// Literals specify the expected text; delivery is through real production
// CGEvents and AppKit's interpretation. The WindowServer post is intercepted
// so this harness needs no TCC and cannot type into any other application.
let examples = [
    ("П", "before П after", 8),
    ("Привет ", "before Привет  after", 14),
    ("hello", "before hello after", 12),
    ("🙂", "before 🙂 after", 9),
    ("Привет\nмир", "before Привет\nмир after", 17),
    ("ДлинноеСлово🙂\nс хвостом", "before ДлинноеСлово🙂\nс хвостом after", 31)
]
for (text, expected, caret) in examples {
    let editor = NSTextView()
    editor.string = "before ghbdtn after"
    editor.setSelectedRange(NSRange(location: 7, length: 6))
    var events: [(CGEventType, String)] = []
    let transport = SystemDictationAccessibility(postEvent: { event, pid in
        require(pid == getpid(), "captured PID remains exact")
        guard let data = event.data,
              let decoded = CGEvent(withDataAllocator: nil, data: data),
              let native = NSEvent(cgEvent: decoded) else { fatalError("CGEvent serialization") }
        var length = 0
        var units = [UniChar](repeating: 0, count: 64)
        decoded.keyboardGetUnicodeString(maxStringLength: units.count, actualStringLength: &length, unicodeString: &units)
        let payload = String(utf16CodeUnits: units, count: length)
        // CFData roundtrip omits source metadata on this OS. Check the marker
        // at the actual posting boundary, not on the reconstructed event.
        require(event.getIntegerValueField(.eventSourceUserData) == 0xC0FFEE, "posted event carries synthetic marker")
        require(decoded.flags.isEmpty && native.modifierFlags.isEmpty, "transport cannot become a shortcut")
        // AppKit can retranslate keyUp characters from the hardware keycode;
        // insertion is interpreted only on keyDown.
        if decoded.type == .keyDown { require(native.characters == payload, "AppKit receives exact serialized Unicode") }
        events.append((decoded.type, payload))
        if decoded.type == .keyDown { editor.keyDown(with: native) }
        else { editor.keyUp(with: native) }
    })
    for chunk in DictationTarget.unicodeChunks(text) {
        require(transport.postUnicode(chunk, pid: getpid()), "production creates complete pair")
    }
    require(editor.string == expected && editor.selectedRange() == NSRange(location: caret, length: 0), "complete Unicode replaces selection exactly once and preserves tail")
    require(events.count % 2 == 0, "no stuck Unicode key")
    for index in stride(from: 0, to: events.count, by: 2) {
        require(events[index].0 == .keyDown && events[index + 1].0 == .keyUp, "down/up order")
        require(events[index].1 == events[index + 1].1, "up belongs to posted down")
    }
}
require(DictationTarget.unicodeChunks("123456789012345🙂z") == ["123456789012345", "🙂z"], "surrogate pair is not split at chunk boundary")
print("PASS: production Unicode payload, serialized CGEvents, AppKit interpretation, full text/caret/tail; no WindowServer delivery claimed")
