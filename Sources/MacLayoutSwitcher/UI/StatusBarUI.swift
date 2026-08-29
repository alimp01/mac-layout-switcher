// Слой UI/звуков macOS. Весь файл — под #if os(macOS): на Linux target
// собирается в пустой executable, чтобы `swift build`/`swift test` были зелёными.
#if os(macOS)
import AppKit

/// Иконка в меню-баре и её меню (история R06i). NSStatusItem + NSMenu, без
/// SwiftUI-окон — минимальная поверхность. Владеет только отображением и
/// состоянием тумблеров; что делать по переключению — решают колбэки, которые
/// проставляет `main` (Engine / Config / Sounds). Persist настроек — за
/// колбэками (они пишут `Config`), UI лишь хранит и рисует текущее состояние.
public final class StatusBarUI: NSObject {

    /// Отображаемое состояние тумблеров.
    public struct State {
        /// Пауза (перехват выключен): иконка приглушается.
        public var paused: Bool
        /// Автопереключение по детектору.
        public var autoSwitch: Bool
        /// Звуки ввода.
        public var sounds: Bool

        public init(paused: Bool, autoSwitch: Bool, sounds: Bool) {
            self.paused = paused
            self.autoSwitch = autoSwitch
            self.sounds = sounds
        }
    }

    // Колбэки тумблеров/пунктов. Аргумент — НОВОЕ состояние после переключения.
    public var onTogglePause: ((Bool) -> Void)?
    public var onToggleAutoSwitch: ((Bool) -> Void)?
    public var onToggleSounds: ((Bool) -> Void)?
    public var onOpenSnippets: (() -> Void)?
    public var onOpenConfig: (() -> Void)?
    public var onOpenHotkeys: (() -> Void)?
    public var onQuit: (() -> Void)?

    private var state: State
    private var statusItem: NSStatusItem?

    private var pauseItem: NSMenuItem?
    private var autoItem: NSMenuItem?
    private var soundsItem: NSMenuItem?

    /// Версия из Info.plist (заполняет build.sh); вне бандла — «dev».
    private let version: String

    public init(state: State,
                version: String = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "dev") {
        self.state = state
        self.version = version
        super.init()
    }

    /// Создаёт иконку в меню-баре и вешает меню. Вызывать на главном потоке
    /// после старта NSApplication.
    public func install() {
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = item.button {
            button.image = NSImage(
                systemSymbolName: "keyboard",
                accessibilityDescription: "Mac Layout Switcher")
            button.image?.isTemplate = true
        }
        item.menu = buildMenu()
        statusItem = item
        refresh()
    }

    /// Обновляет отображение под новое состояние (например, автопаузу извне).
    public func show(state: State) {
        self.state = state
        refresh()
    }

    /// Точечно синхронизирует галочку автопереключения, когда его поменяли
    /// снаружи меню (хоткей `.toggleAuto`). Паузу/звуки не трогает.
    public func setAutoSwitchState(_ on: Bool) {
        state.autoSwitch = on
        refresh()
    }

    // MARK: - Построение меню

    private func buildMenu() -> NSMenu {
        let menu = NSMenu()

        let pause = NSMenuItem(
            title: "", action: #selector(togglePause), keyEquivalent: "")
        pause.target = self
        pauseItem = pause
        menu.addItem(pause)

        menu.addItem(.separator())

        let auto = NSMenuItem(
            title: "Автопереключение", action: #selector(toggleAuto), keyEquivalent: "")
        auto.target = self
        autoItem = auto
        menu.addItem(auto)

        let sounds = NSMenuItem(
            title: "Звуки", action: #selector(toggleSounds), keyEquivalent: "")
        sounds.target = self
        soundsItem = sounds
        menu.addItem(sounds)

        let hotkeys = NSMenuItem(
            title: "Горячие клавиши…", action: #selector(openHotkeys), keyEquivalent: "")
        hotkeys.target = self
        menu.addItem(hotkeys)

        menu.addItem(.separator())

        let openSnippets = NSMenuItem(
            title: "Открыть snippets.json", action: #selector(openSnippets), keyEquivalent: "")
        openSnippets.target = self
        menu.addItem(openSnippets)

        let openConfig = NSMenuItem(
            title: "Открыть config.json", action: #selector(openConfig), keyEquivalent: "")
        openConfig.target = self
        menu.addItem(openConfig)

        menu.addItem(.separator())

        let about = NSMenuItem(
            title: "О программе", action: #selector(showAbout), keyEquivalent: "")
        about.target = self
        menu.addItem(about)

        let quit = NSMenuItem(
            title: "Выход", action: #selector(quit), keyEquivalent: "q")
        quit.target = self
        menu.addItem(quit)

        return menu
    }

    /// Перерисовывает заголовки/галочки/иконку под текущее состояние.
    private func refresh() {
        pauseItem?.title = state.paused ? "Работа (снять паузу)" : "Пауза"
        autoItem?.state = state.autoSwitch ? .on : .off
        soundsItem?.state = state.sounds ? .on : .off
        // В паузе иконка приглушена — видно, что перехват выключен.
        statusItem?.button?.alphaValue = state.paused ? 0.4 : 1.0
    }

    // MARK: - Действия

    @objc private func togglePause() {
        state.paused.toggle()
        refresh()
        onTogglePause?(state.paused)
    }

    @objc private func toggleAuto() {
        state.autoSwitch.toggle()
        refresh()
        onToggleAutoSwitch?(state.autoSwitch)
    }

    @objc private func toggleSounds() {
        state.sounds.toggle()
        refresh()
        onToggleSounds?(state.sounds)
    }

    @objc private func openSnippets() { onOpenSnippets?() }
    @objc private func openConfig() { onOpenConfig?() }
    @objc private func openHotkeys() { onOpenHotkeys?() }
    @objc private func quit() { onQuit?() }

    @objc private func showAbout() {
        let alert = NSAlert()
        alert.messageText = "Mac Layout Switcher \(version)"
        alert.informativeText = """
        Свой аналог Punto Switcher и Caramba Switcher — бесплатный и открытый.

        Punto для Mac заброшен Яндексом с 2017 года и на новых macOS не работает; \
        Caramba жива, но закрыта и по подписке. Наш вариант: автоматика + \
        Option-хоткей + автозамена по шаблонам + звуки, без дневника, весь код у вас.
        """
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }
}
#endif
