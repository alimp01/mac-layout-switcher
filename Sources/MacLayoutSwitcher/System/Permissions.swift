// Системный слой macOS. Весь файл — под #if os(macOS).
#if os(macOS)
import AppKit
import ApplicationServices

/// Разрешения TCC, без которых CGEventTap не работает: Accessibility (для
/// tap'а и синтетических событий) и Input Monitoring (для наблюдения за
/// клавиатурой). Проверка — `AXIsProcessTrusted`; запрос с системным
/// диалогом — `AXIsProcessTrustedWithOptions` + `kAXTrustedCheckOptionPrompt`;
/// панели настроек открываются URL-схемой `x-apple.systempreferences`.
public enum Permissions {

    /// Доверено ли приложение в Accessibility (без показа диалога).
    public static var trusted: Bool {
        AXIsProcessTrusted()
    }

    /// Проверяет доверие и, если его нет, просит систему показать диалог
    /// «разрешить управление компьютером». Возвращает текущее состояние
    /// (диалог асинхронный — после выдачи разрешения нужен перезапуск
    /// или повторная проверка).
    @discardableResult
    public static func requestTrust() -> Bool {
        let options = [
            kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true
        ] as CFDictionary
        return AXIsProcessTrustedWithOptions(options)
    }

    /// Открывает Настройки → Конфиденциальность и безопасность → Универсальный доступ.
    public static func openAccessibilitySettings() {
        open("x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")
    }

    /// Открывает Настройки → Конфиденциальность и безопасность → Мониторинг ввода.
    public static func openInputMonitoringSettings() {
        open("x-apple.systempreferences:com.apple.preference.security?Privacy_ListenEvent")
    }

    private static func open(_ urlString: String) {
        guard let url = URL(string: urlString) else { return }
        NSWorkspace.shared.open(url)
    }
}
#endif
