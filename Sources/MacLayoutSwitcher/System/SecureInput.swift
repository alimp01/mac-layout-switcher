// Системный слой macOS. Весь файл — под #if os(macOS).
#if os(macOS)
import Carbon.HIToolbox

/// Обёртка `IsSecureEventInputEnabled()` (HIToolbox): `true`, когда какое-то
/// приложение включило secure input — фокус в поле пароля. Engine (таск 04)
/// по этому признаку ставит автопаузу: пароли не буферизуем и не исправляем.
public enum SecureInput {
    /// Активен ли сейчас защищённый ввод.
    public static var isActive: Bool {
        IsSecureEventInputEnabled()
    }
}
#endif
