// Точка входа приложения. Весь macOS-слой (EventTap, Typist, LayoutSwitcher,
// Engine, StatusBarUI, Sounds, Config) закрыт #if os(macOS): на Linux target
// собирается в пустой executable, чтобы `swift build`/`swift test` были зелёными.
#if os(macOS)
import AppKit
import Foundation

/// Делегат приложения: проверяет разрешения, поднимает Engine + меню-бар, либо
/// показывает онбординг разрешений (история R06i.1). Приложение — `.accessory`
/// (LSUIElement): без иконки в Dock, живёт только в меню-баре.
final class AppDelegate: NSObject, NSApplicationDelegate {

    // Config создаётся здесь и передаётся в Engine — общий экземпляр, чтобы
    // тумблеры меню и Engine писали/читали один и тот же файл настроек.
    private let config = Config()

    private var engine: Engine?
    private var sounds: Sounds?
    private var ui: StatusBarUI?
    private var hotkeyWindow: HotkeyRecorderWindow?
    // Автозапуск при входе (SMAppService). Источник истины — сам сервис, не config.
    private let loginItem = LoginItem()

    // Отдельный статус-элемент онбординга (когда нет доверия и Engine не поднят).
    private var onboardingItem: NSStatusItem?

    // Индикатор раскладки в меню-баре (история G09): обновляется по событиям,
    // без поллинга. Токен наблюдателя системного уведомления держим, чтобы
    // подписка жила вместе с делегатом (живёт до выхода приложения);
    // manualPaused — пауза из меню (у Engine ручной паузы нет, факт живёт здесь).
    private var layoutObserver: NSObjectProtocol?
    private var manualPaused = false

    func applicationDidFinishLaunching(_ notification: Notification) {
        config.load()
        if Permissions.trusted {
            startSwitcher()
        } else {
            presentOnboarding()
        }
    }

    // MARK: - Рабочий режим

    private func startSwitcher() {
        let sounds = Sounds(enabled: config.config.sounds)
        let engine = Engine(config: config)
        engine.sounds = sounds
        // Стартуем перехват. Разрешение уже проверено, но система могла
        // отказать по иной причине — тогда падаем в онбординг.
        guard engine.start() else {
            presentOnboarding()
            return
        }

        // Факт автозапуска — из SMAppService, а не из config: пользователь мог
        // снять объект входа в Системных настройках. Расхождение config↔факт
        // разрешаем в пользу факта и приводим config к нему.
        let launchFact = loginItem.isEnabled
        if config.config.launchAtLogin != launchFact {
            config.update { $0.launchAtLogin = launchFact }
        }

        let ui = StatusBarUI(state: StatusBarUI.State(
            paused: false,
            autoSwitch: config.config.autoSwitch,
            sounds: config.config.sounds,
            launchAtLogin: launchFact))

        // Пауза = полностью снять/поднять перехват (у Engine нет ручной паузы;
        // автопауза secure-input/исключений считается внутри на каждое событие).
        // Индикатор раскладки при этом приглушается/оживает.
        ui.onTogglePause = { [weak self, weak engine] paused in
            if paused { engine?.stop() } else { engine?.start() }
            self?.manualPaused = paused
            self?.updateLayoutIndicator()
        }
        ui.onToggleAutoSwitch = { [weak engine] on in
            engine?.setAutoSwitch(on)   // сам пишет config
        }
        ui.onToggleSounds = { [weak self] on in
            self?.sounds?.enabled = on
            self?.config.update { $0.sounds = on }
        }
        // Тумблер автозапуска: пробуем enable/disable, затем ВСЕГДА приводим
        // config и галочку к фактическому статусу. Ошибку register/unregister не
        // глотаем — логируем, config не меняем, галочка откатывается в факт
        // (в прежнее положение), без ложного успеха.
        ui.onToggleLaunchAtLogin = { [weak self] desired in
            guard let self = self else { return }
            do {
                if desired { try self.loginItem.enable() } else { try self.loginItem.disable() }
            } catch {
                NSLog("MacLayoutSwitcher: смена автозапуска не удалась: \(error)")
            }
            // На современных macOS register() часто не бросает ошибку, а ставит
            // статус .requiresApproval: объект входа создан, но ждёт подтверждения
            // в Системных настройках. isEnabled тут false — без подсказки
            // пользователь решит, что тумблер не сработал.
            if desired && !self.loginItem.isEnabled && self.loginItem.requiresApproval {
                self.presentLaunchApprovalNeeded()
            }
            let fact = self.loginItem.isEnabled
            self.config.update { $0.launchAtLogin = fact }
            self.ui?.setLaunchAtLoginState(fact)
        }
        ui.onOpenSnippets = { [weak self] in self?.openInEditor(self?.config.snippetsURL) }
        // config.json приватен внутри Config, но каталог публичен — собираем путь.
        ui.onOpenConfig = { [weak self] in
            self?.openInEditor(self?.config.directory.appendingPathComponent("config.json"))
        }
        ui.onOpenHotkeys = { [weak self] in self?.showHotkeys() }
        ui.onQuit = { NSApp.terminate(nil) }
        ui.install()

        // Хоткей `.toggleAuto` меняет автопереключение мимо меню — синхронизируем
        // галочку.
        engine.onAutoSwitchChanged = { [weak ui] on in
            ui?.setAutoSwitchState(on)
        }

        self.sounds = sounds
        self.engine = engine
        self.ui = ui

        // Индикатор раскладки (история G09) — строго по событиям, без поллинга:
        // 1) системное уведомление смены источника ввода (пользователь сменил
        //    раскладку сам — ⌃Space, меню ввода, другое приложение);
        // 2) колбэк Engine после programmatic select (авто-исправление, Option) —
        //    не ждём системный бродкаст, обновляемся сразу;
        // 3) начальная установка при старте.
        // Имя уведомления — kTISNotifySelectedKeyboardInputSourceChanged
        // (HIToolbox), приходит через DistributedNotificationCenter.
        layoutObserver = DistributedNotificationCenter.default().addObserver(
            forName: Notification.Name(
                "com.apple.Carbon.TISNotifySelectedKeyboardInputSourceChanged"),
            object: nil,
            queue: .main) { [weak self] _ in
            self?.updateLayoutIndicator()
        }
        engine.onLayoutSwitched = { [weak self] _ in
            DispatchQueue.main.async { self?.updateLayoutIndicator() }
        }
        updateLayoutIndicator()
    }

    /// Перечитывает текущую раскладку и отдаёт её индикатору в меню-баре.
    /// Всегда спрашиваем систему (`LayoutSwitcher.current()`), а не кэш —
    /// уведомление лишь сигнал «что-то поменялось».
    private func updateLayoutIndicator() {
        ui?.setLayoutIndicator(LayoutSwitcher.current(), paused: manualPaused)
    }

    /// Открывает окно настройки горячих клавиш (создаётся лениво, переживает
    /// закрытие — один и тот же экземпляр).
    private func showHotkeys() {
        if hotkeyWindow == nil {
            hotkeyWindow = HotkeyRecorderWindow(config: config)
        }
        hotkeyWindow?.show()
    }

    /// Автозапуск зарегистрирован, но macOS ждёт подтверждения пользователем
    /// (статус `.requiresApproval`). Объясняем это и открываем панель «Объекты
    /// входа», чтобы включение не выглядело «ничего не произошло».
    private func presentLaunchApprovalNeeded() {
        let alert = NSAlert()
        alert.messageText = "Разрешите автозапуск"
        alert.informativeText = """
        macOS просит подтвердить автозапуск вручную. Откройте «Системные \
        настройки → Основные → Объекты входа» и включите «Mac Layout Switcher» \
        в списке — после этого приложение будет стартовать при входе.
        """
        alert.addButton(withTitle: "Открыть «Объекты входа»")
        alert.addButton(withTitle: "Позже")
        let response = alert.runModal()
        if response == .alertFirstButtonReturn {
            loginItem.openLoginItemsSettings()
        }
    }

    /// Открывает JSON-файл настроек во внешнем редакторе. Если файла ещё нет
    /// (пользователь не создавал шаблоны) — создаёт заготовку, иначе Finder
    /// откроет пустоту.
    private func openInEditor(_ url: URL?) {
        guard let url = url else { return }
        if !FileManager.default.fileExists(atPath: url.path) {
            let stub = url.lastPathComponent == "snippets.json" ? "{\n  \"сдр\": \"С днём рождения!\"\n}\n" : "{}\n"
            try? stub.data(using: .utf8)?.write(to: url, options: .atomic)
        }
        NSWorkspace.shared.open(url)
    }

    // MARK: - Онбординг разрешений

    private func presentOnboarding() {
        // Пункт меню-бара, чтобы приложение было видимым и не выглядело
        // «тихим отказом»: из него можно повторно открыть настройки и выйти.
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = item.button {
            button.image = NSImage(
                systemSymbolName: "keyboard.badge.ellipsis",
                accessibilityDescription: "Mac Layout Switcher — нужны разрешения")
            button.image?.isTemplate = true
        }
        let menu = NSMenu()
        let access = NSMenuItem(title: "Открыть «Универсальный доступ»…",
                                action: #selector(openAccessibility), keyEquivalent: "")
        access.target = self
        menu.addItem(access)
        let input = NSMenuItem(title: "Открыть «Мониторинг ввода»…",
                               action: #selector(openInputMonitoring), keyEquivalent: "")
        input.target = self
        menu.addItem(input)
        menu.addItem(.separator())
        let recheck = NSMenuItem(title: "Я выдал разрешения — перезапустить",
                                 action: #selector(relaunch), keyEquivalent: "")
        recheck.target = self
        menu.addItem(recheck)
        let quit = NSMenuItem(title: "Выход", action: #selector(quitApp), keyEquivalent: "q")
        quit.target = self
        menu.addItem(quit)
        item.menu = menu
        onboardingItem = item

        showOnboardingAlert()
    }

    private func showOnboardingAlert() {
        let alert = NSAlert()
        alert.messageText = "Нужны разрешения"
        alert.informativeText = """
        Mac Layout Switcher слушает клавиатуру во всех приложениях, поэтому \
        macOS требует два разрешения:

        1. Универсальный доступ (Accessibility) — чтобы перехватывать и \
        перепечатывать текст.
        2. Мониторинг ввода (Input Monitoring) — чтобы видеть нажатия клавиш.

        Откройте обе панели кнопками ниже, включите «Mac Layout Switcher», \
        затем перезапустите приложение (пункт меню-бара «Я выдал разрешения»).
        """
        alert.addButton(withTitle: "Открыть «Универсальный доступ»")
        alert.addButton(withTitle: "Открыть «Мониторинг ввода»")
        alert.addButton(withTitle: "Позже")
        let response = alert.runModal()
        switch response {
        case .alertFirstButtonReturn:
            Permissions.openAccessibilitySettings()
        case .alertSecondButtonReturn:
            Permissions.openInputMonitoringSettings()
        default:
            break
        }
    }

    @objc private func openAccessibility() { Permissions.openAccessibilitySettings() }
    @objc private func openInputMonitoring() { Permissions.openInputMonitoringSettings() }
    @objc private func quitApp() { NSApp.terminate(nil) }

    /// Перезапуск после выдачи разрешений: TCC-доверие подхватывается новым
    /// процессом надёжнее, чем повторной проверкой в текущем.
    @objc private func relaunch() {
        let path = Bundle.main.bundlePath
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/open")
        process.arguments = ["-n", path]
        try? process.run()
        NSApp.terminate(nil)
    }
}

let app = NSApplication.shared
// .accessory: без иконки в Dock и без пунктов главного меню — только меню-бар.
app.setActivationPolicy(.accessory)
let delegate = AppDelegate()
app.delegate = delegate
app.run()
#endif
