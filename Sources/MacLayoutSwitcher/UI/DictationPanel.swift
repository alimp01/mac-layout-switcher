#if os(macOS)
import AppKit

/// Nonactivating HUD: showing progress must never move keyboard focus from
/// the destination editor. Only an explicit Copy click writes the clipboard.
final class DictationPanel: NSObject {
    private let panel: NSPanel
    private let label = NSTextField(wrappingLabelWithString: "")
    private let progress = NSProgressIndicator()
    private let primary = NSButton()
    private let cancel = NSButton()
    private let resultView = NSTextView()
    private let scroll = NSScrollView()
    private var primaryAction: (() -> Void)?
    private var cancelAction: (() -> Void)?

    override init() {
        panel = NSPanel(contentRect: NSRect(x: 0, y: 0, width: 420, height: 270),
                        styleMask: [.titled, .nonactivatingPanel], backing: .buffered, defer: false)
        super.init()
        panel.title = "Диктовка · GigaAM v3"
        panel.isFloatingPanel = true
        panel.hidesOnDeactivate = false
        panel.level = .floating
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        panel.isReleasedWhenClosed = false
        label.font = .systemFont(ofSize: 13)
        progress.isIndeterminate = false
        progress.minValue = 0; progress.maxValue = 1
        resultView.isEditable = false
        resultView.isSelectable = true
        resultView.font = .systemFont(ofSize: 14)
        scroll.documentView = resultView
        scroll.hasVerticalScroller = true
        scroll.borderType = .bezelBorder
        primary.target = self; primary.action = #selector(runPrimary)
        cancel.target = self; cancel.action = #selector(runCancel)
        let buttons = NSStackView(views: [primary, cancel])
        buttons.spacing = 10
        let stack = NSStackView(views: [label, progress, scroll, buttons])
        stack.orientation = .vertical
        stack.alignment = .leading
        stack.spacing = 12
        stack.translatesAutoresizingMaskIntoConstraints = false
        let content = NSView()
        content.addSubview(stack)
        panel.contentView = content
        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: content.leadingAnchor, constant: 18),
            stack.trailingAnchor.constraint(equalTo: content.trailingAnchor, constant: -18),
            stack.topAnchor.constraint(equalTo: content.topAnchor, constant: 18),
            stack.bottomAnchor.constraint(lessThanOrEqualTo: content.bottomAnchor, constant: -18),
            label.widthAnchor.constraint(equalTo: stack.widthAnchor),
            progress.widthAnchor.constraint(equalTo: stack.widthAnchor),
            scroll.widthAnchor.constraint(equalTo: stack.widthAnchor),
            scroll.heightAnchor.constraint(equalToConstant: 120),
        ])
        if let screen = NSScreen.main {
            let frame = screen.visibleFrame
            panel.setFrameTopLeftPoint(NSPoint(x: frame.maxX - 440, y: frame.maxY - 30))
        }
    }

    func show(_ message: String, progress value: Double? = nil,
              primaryTitle: String? = nil, primaryAction: (() -> Void)? = nil,
              cancelTitle: String = "Закрыть", cancelAction: (() -> Void)? = nil,
              text: String? = nil) {
        label.stringValue = message
        progress.isHidden = value == nil
        progress.doubleValue = value ?? 0
        primary.isHidden = primaryTitle == nil
        primary.title = primaryTitle ?? ""
        self.primaryAction = primaryAction
        cancel.title = cancelTitle
        self.cancelAction = cancelAction
        scroll.isHidden = text == nil
        resultView.string = text ?? ""
        panel.orderFrontRegardless()
    }
    func hide() { panel.orderOut(nil); resultView.string = "" }
    @objc private func runPrimary() { primaryAction?() }
    @objc private func runCancel() {
        if let cancelAction { cancelAction() } else { hide() }
    }
}
#endif
