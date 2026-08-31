// Автозапуск при входе в систему (launch at login). Весь файл — под
// #if os(macOS): на Linux target собирается в пустой executable, чтобы
// `swift build`/`swift test` были зелёными.
#if os(macOS)
import Foundation
import ServiceManagement

/// Обёртка над `SMAppService.mainApp` — регистрация приложения как объекта
/// входа (Системные настройки → Основные → Объекты входа). Минимум проекта —
/// macOS 13, но API помечен явно `@available`, чтобы вызов не «поплыл» при
/// снижении таргета.
///
/// Источник истины — сам `SMAppService.status`, а НЕ config: пользователь мог
/// снять объект входа в Системных настройках, и мы обязаны это увидеть.
/// `AppConfig.launchAtLogin` хранит лишь ЖЕЛАЕМОЕ состояние (для UI/диагностики),
/// фактическое всегда спрашиваем у системы.
@available(macOS 13.0, *)
public final class LoginItem {

    public init() {}

    /// Зарегистрировано ли приложение как объект входа сейчас (факт из системы).
    /// `.enabled` → true; `.notRegistered`/`.requiresApproval`/`.notFound` → false.
    /// `requiresApproval` (пользователь ещё не подтвердил в Настройках) — это НЕ
    /// «включено», поэтому false: галочка не должна показывать ложный успех.
    public var isEnabled: Bool {
        SMAppService.mainApp.status == .enabled
    }

    /// Ждёт ли автозапуск подтверждения пользователем. На современных macOS
    /// `register()` часто НЕ бросает ошибку, а переводит статус в
    /// `.requiresApproval`: объект входа создан, но выключен, пока пользователь
    /// не разрешит его в «Системные настройки → Основные → Объекты входа».
    /// Без этой проверки включение тумблера выглядело бы «ничего не произошло».
    public var requiresApproval: Bool {
        SMAppService.mainApp.status == .requiresApproval
    }

    /// Открывает панель «Объекты входа» в Системных настройках, чтобы
    /// пользователь подтвердил автозапуск, когда статус `.requiresApproval`.
    public func openLoginItemsSettings() {
        SMAppService.openSystemSettingsLoginItems()
    }

    /// Включить автозапуск. Ошибку НЕ глотаем — пробрасываем, чтобы вызывающий
    /// откатил галочку и не трогал config (тумблер не должен лгать об успехе).
    public func enable() throws {
        try SMAppService.mainApp.register()
    }

    /// Выключить автозапуск. Ошибку так же пробрасываем наверх.
    public func disable() throws {
        try SMAppService.mainApp.unregister()
    }
}
#endif
