import AppKit
import SwitcherCore

let app = NSApplication.shared
app.setActivationPolicy(.prohibited)
let config = Config(directory: URL(fileURLWithPath: CommandLine.arguments[1]))
let recorder = HotkeyRecorderWindow(config: config)
recorder.build() // Test copy exposes construction only; never show/activate.
let window = app.windows.first { $0.title == "Настройка горячих клавиш" }!
precondition(!window.isVisible && (window.delegate as AnyObject?) === recorder)
let original = config.config
var recording = false
var changes: [Bool] = []
recorder.onRecordingChanged = { recording = $0; changes.append($0) }
let button = NSButton(); button.tag = 0
func begin() {
    recorder.perform(NSSelectorFromString("startRecording:"), with: button)
    precondition(recording, "recording must disable processing while capturing")
}
func expectCancelled(_ reason: String) {
    guard !recording else { print("FAIL: \(reason) leaves processing disabled"); exit(1) }
    precondition(config.config == original, "cancellation must not save a hotkey")
    precondition(changes.suffix(2) == [true, false], "recording must release processing once")
    print("PASS: \(reason) cancels recording without saving")
}
func flags(_ modifiers: NSEvent.ModifierFlags) {
    let event = NSEvent.keyEvent(with: .flagsChanged, location: .zero, modifierFlags: modifiers,
        timestamp: 0, windowNumber: 0, context: nil, characters: "", charactersIgnoringModifiers: "", isARepeat: false, keyCode: 56)!
    app.sendEvent(event)
}
if !CommandLine.arguments.contains("--window") {
begin()
flags(.shift)
NotificationCenter.default.post(name: NSApplication.didResignActiveNotification, object: app)
expectCancelled("application focus loss with unfinished modifier chord")
flags([])
precondition(config.config == original, "released modifiers after focus loss must not save")
let priorChanges = changes
NotificationCenter.default.post(name: NSApplication.didResignActiveNotification, object: app)
precondition(changes == priorChanges, "duplicate focus loss must not reset a new input gesture")
}
begin()
flags(.shift)
NotificationCenter.default.post(name: NSWindow.didResignKeyNotification, object: window)
expectCancelled("window focus loss with unfinished modifier chord")
flags([])
precondition(config.config == original, "released modifiers after window focus loss must not save")
begin()
window.close()
expectCancelled("window close")
begin()
let escape = NSEvent.keyEvent(with: .keyDown, location: .zero, modifierFlags: [], timestamp: 0,
    windowNumber: 0, context: nil, characters: "\u{1B}", charactersIgnoringModifiers: "\u{1B}", isARepeat: false, keyCode: 53)!
app.sendEvent(escape)
expectCancelled("Escape")
begin()
flags(.shift); flags([])
var expected = original
expected.convertHotkey = Hotkey(keyCode: nil, modifiers: [.shift])
precondition(!recording && config.config == expected, "a completed chord must still save the requested hotkey")
print("PASS: completed chord still saves once and releases processing")
print("PASS: no window was shown, no user config or global input accessed")
