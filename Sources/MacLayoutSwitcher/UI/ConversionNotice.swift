#if os(macOS)
import AppKit

/// An explicit failed conversion is explained without taking editor focus.
final class ConversionNotice: NSObject {
    private let panel: NSPanel
    private let label = NSTextField(wrappingLabelWithString: "")

    override init() {
        panel = NSPanel(contentRect: NSRect(x: 0, y: 0, width: 390, height: 130),
                        styleMask: [.titled, .nonactivatingPanel], backing: .buffered, defer: false)
        super.init()
        panel.title = "Конвертация раскладки"
        panel.isFloatingPanel = true
        panel.hidesOnDeactivate = false
        panel.level = .floating
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        panel.isReleasedWhenClosed = false
        let close = NSButton(title: "Закрыть", target: self, action: #selector(hide))
        let stack = NSStackView(views: [label, close])
        stack.orientation = .vertical
        stack.alignment = .leading
        stack.spacing = 12
        stack.translatesAutoresizingMaskIntoConstraints = false
        let content = NSView()
        content.addSubview(stack)
        panel.contentView = content
        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: content.leadingAnchor, constant: 16),
            stack.trailingAnchor.constraint(equalTo: content.trailingAnchor, constant: -16),
            stack.topAnchor.constraint(equalTo: content.topAnchor, constant: 16),
            stack.bottomAnchor.constraint(lessThanOrEqualTo: content.bottomAnchor, constant: -16),
            label.widthAnchor.constraint(equalTo: stack.widthAnchor)
        ])
        if let screen = NSScreen.main {
            panel.setFrameTopLeftPoint(NSPoint(x: screen.visibleFrame.maxX - 410,
                                               y: screen.visibleFrame.maxY - 30))
        }
    }
    func show() {
        label.stringValue = "Не удалось безопасно изменить текст. Поле защищено, не предоставляет доступ к выделению или выделение изменилось. Выделите текст в поддерживаемом редакторе и повторите."
        panel.orderFrontRegardless()
    }
    @objc func hide() { panel.orderOut(nil) }
}
#endif
