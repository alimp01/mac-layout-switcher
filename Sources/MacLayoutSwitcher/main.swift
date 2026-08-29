// Весь macOS-слой (EventTap, Typist, LayoutSwitcher, Engine, StatusBarUI,
// Config) живёт в этом target и целиком закрыт #if os(macOS):
// на Linux target собирается в пустой executable, чтобы `swift build`
// и `swift test` оставались зелёными.
#if os(macOS)
import Foundation

// Точка входа приложения; наполняется следующими тасками.
print("MacLayoutSwitcher: app layer is added by subsequent tasks.")
#endif
