// Системный слой macOS. Весь файл — под #if os(macOS).
#if os(macOS)
import AppKit

/// Обёртка `NSWorkspace.shared.frontmostApplication`: bundle id активного
/// приложения. Engine (таск 04) сверяет его со списком исключений из config
/// (Terminal, iTerm2, VS Code — автопауза в терминалах/IDE).
public enum FrontApp {
    /// Bundle id активного приложения (например "com.apple.Terminal");
    /// `nil`, если система его не отдала.
    public static var bundleID: String? {
        NSWorkspace.shared.frontmostApplication?.bundleIdentifier
    }
}
#endif
