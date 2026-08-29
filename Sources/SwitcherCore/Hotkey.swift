import Foundation

/// Описание горячей клавиши: либо одиночный модификатор (правый/левый Option,
/// Caps Lock), либо обычная клавиша с модификаторами (⌘⇧K). Платформонезависимо
/// и детерминированно — сопоставление «нажата ли назначенная клавиша» живёт
/// здесь и тестируется на Linux; macOS-`Engine`/окно-рекордер лишь строят
/// описание нажатия из CGEvent/NSEvent и спрашивают `matches`.
public struct Hotkey: Codable, Equatable, Sendable {

    /// Модификатор клавиатуры. Правые варианты (`rightOption`/`rightCommand`/…)
    /// присутствуют в модели ради полноты и настройки «только правый Option»;
    /// текущий macOS-слой левый и правый различать не обязан (см. Engine).
    public enum Modifier: String, Codable, CaseIterable, Sendable {
        case command, option, control, shift, capsLock, function
        case rightCommand, rightOption, rightControl, rightShift
    }

    /// Виртуальный код клавиши. `nil` = «только модификатор(ы)» (tap): само
    /// решение «tap = этот хоткей» принимает `matches`, а down→up-механику
    /// одиночного модификатора отслеживает macOS-`Engine`.
    public var keyCode: UInt16?
    /// Набор модификаторов. Для «только модификатор» — сами модификаторы
    /// (например `[.option]`); для клавиши с модификаторами — её модификаторы.
    public var modifiers: Set<Modifier>

    public init(keyCode: UInt16? = nil, modifiers: Set<Modifier> = []) {
        self.keyCode = keyCode
        self.modifiers = modifiers
    }

    /// Дефолт клавиши конвертации/отката — одиночный Option (обратная
    /// совместимость: у тех, кто уже пользуется, поведение прежнее).
    public static let defaultConvert = Hotkey(keyCode: nil, modifiers: [.option])

    /// Сработал ли хоткей на данном описании нажатия. Сравнение точное: код
    /// клавиши и набор модификаторов должны совпасть ровно — лишний модификатор
    /// или клавиша означают «не сработал» (одиночный Option не срабатывает при
    /// Option+Cmd).
    public func matches(keyCode: UInt16?, modifiers: Set<Modifier>) -> Bool {
        self.keyCode == keyCode && self.modifiers == modifiers
    }

    /// Человекочитаемое имя для меню/окна: «⌥ Option», «⇪ Caps Lock», «⌘⇧ K».
    public var displayName: String {
        let symbols = Self.displayOrder
            .filter { modifiers.contains($0) }
            .map { $0.symbol }
            .joined()

        if let keyCode {
            let name = Self.keyName(for: keyCode)
            return symbols.isEmpty ? name : "\(symbols) \(name)"
        }
        // Только модификатор(ы).
        if modifiers.isEmpty { return "не назначено" }
        if modifiers.count == 1, let only = modifiers.first {
            return "\(only.symbol) \(only.fullName)"
        }
        return symbols
    }

    /// Порядок вывода символов модификаторов (даёт «⌘⇧» для [.command,.shift]).
    private static let displayOrder: [Modifier] = [
        .capsLock, .function, .control, .option, .rightControl, .rightOption,
        .command, .rightCommand, .shift, .rightShift,
    ]

    /// Имя клавиши по виртуальному коду (kVK_ANSI_*). Неизвестный код —
    /// «код N», чтобы окно-рекордер всё равно что-то показало.
    private static func keyName(for keyCode: UInt16) -> String {
        Self.keyNames[keyCode] ?? "код \(keyCode)"
    }

    private static let keyNames: [UInt16: String] = [
        0: "A", 1: "S", 2: "D", 3: "F", 4: "H", 5: "G", 6: "Z", 7: "X",
        8: "C", 9: "V", 11: "B", 12: "Q", 13: "W", 14: "E", 15: "R",
        16: "Y", 17: "T", 18: "1", 19: "2", 20: "3", 21: "4", 22: "6",
        23: "5", 24: "=", 25: "9", 26: "7", 27: "-", 28: "8", 29: "0",
        30: "]", 31: "O", 32: "U", 33: "[", 34: "I", 35: "P", 36: "Return",
        37: "L", 38: "J", 39: "'", 40: "K", 41: ";", 42: "\\", 43: ",",
        44: "/", 45: "N", 46: "M", 47: ".", 48: "Tab", 49: "Space",
        50: "`", 51: "Delete", 53: "Escape",
    ]
}

extension Hotkey.Modifier {
    /// Символ для строки меню/окна.
    public var symbol: String {
        switch self {
        case .command, .rightCommand: return "⌘"
        case .option, .rightOption: return "⌥"
        case .control, .rightControl: return "⌃"
        case .shift, .rightShift: return "⇧"
        case .capsLock: return "⇪"
        case .function: return "fn"
        }
    }

    /// Полное имя для одиночного модификатора.
    public var fullName: String {
        switch self {
        case .command: return "Command"
        case .option: return "Option"
        case .control: return "Control"
        case .shift: return "Shift"
        case .capsLock: return "Caps Lock"
        case .function: return "Fn"
        case .rightCommand: return "Правый Command"
        case .rightOption: return "Правый Option"
        case .rightControl: return "Правый Control"
        case .rightShift: return "Правый Shift"
        }
    }
}
