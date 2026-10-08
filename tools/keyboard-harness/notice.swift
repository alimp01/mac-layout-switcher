import AppKit
func require(_ condition: @autoclosure () -> Bool, _ message: String) {
    guard condition() else { fputs("FAIL: \(message)\n", stderr); exit(1) }
}
let app = NSApplication.shared
app.setActivationPolicy(.prohibited)
let panel = NSPanel(contentRect: NSRect(x: 0, y: 0, width: 390, height: 130), styleMask: [.titled, .nonactivatingPanel], backing: .buffered, defer: false)
let notice = ConversionNotice(panel: panel, presentsWindow: false)
let originalClipboard = NSPasteboard.general.changeCount
notice.showUncertain()
let first = String(repeating: "Сохранённый ввод 1234567890 ", count: 120)
notice.appendWithheldInput(first)
notice.hide() // a later successful Option is not explicit dismissal
notice.showUncertain()
notice.appendWithheldInput("следующая очередь")
panel.contentView!.layoutSubtreeIfNeeded()
let stack = panel.contentView!.subviews.compactMap { $0 as? NSStackView }.first!
let scroll = stack.arrangedSubviews.compactMap { $0 as? NSScrollView }.first!
let text = scroll.documentView as! NSTextView
require(text.string == first + "\nследующая очередь", "two failed batches and later Option preserve all retained text")
require(!scroll.isHidden && scroll.contentSize.width > 300 && text.frame.width > 300, "recovery document and container have visible width")
text.layoutManager!.ensureLayout(for: text.textContainer!)
require(text.layoutManager!.numberOfGlyphs > 1000, "long recovery has laid out glyphs")
require(text.frame.height > scroll.contentSize.height, "long recovery scrolls vertically")
text.setSelectedRange(NSRange(location: 0, length: 12))
require(text.selectedRange().length == 12 && text.isSelectable, "retained input selectable for manual copying")
require(NSPasteboard.general.changeCount == originalClipboard, "notice never writes clipboard")
require(!panel.isVisible, "headless native harness never displays its window")
notice.dismiss()
notice.showUncertain()
notice.appendWithheldInput("новый ввод")
require(text.string == "новый ввод", "only explicit Close clears retained input")
print("PASS: production recovery panel retention, width, long scrolling, selection and clipboard preservation")
