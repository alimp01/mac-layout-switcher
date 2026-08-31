import Foundation

/// Сравнение семантических версий вида «1.2.3» по числовым компонентам.
/// Используется автообновлением (таск 13): версия из бандла против raw VERSION
/// с GitHub. Платформонезависимо, тестируется на Linux.
public enum SemVer {

    /// Сравнивает две версии покомпонентно слева направо.
    /// `.orderedAscending` — lhs старее rhs (доступно обновление, если lhs — своя).
    public static func compare(_ lhs: String, _ rhs: String) -> ComparisonResult {
        let l = components(lhs)
        let r = components(rhs)
        // Недостающие компоненты считаются нулями: «1.1» == «1.1.0».
        for i in 0..<max(l.count, r.count) {
            let a = i < l.count ? l[i] : 0
            let b = i < r.count ? r[i] : 0
            if a != b { return a < b ? .orderedAscending : .orderedDescending }
        }
        return .orderedSame
    }

    /// Числовые компоненты версии; нечисловой мусор в компоненте → 0.
    private static func components(_ version: String) -> [Int] {
        return version
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .split(separator: ".")
            .map { Int($0) ?? 0 }
    }
}
