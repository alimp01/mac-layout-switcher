// Системный слой macOS. Весь файл — под #if os(macOS): на Linux target
// собирается в пустой executable, чтобы `swift build`/`swift test` были зелёными.
#if os(macOS)
import CoreGraphics

/// Одно событие клавиатуры, снятое `EventTap`'ом с CGEventTap и уже
/// расшифрованное: вместо сырого `CGEvent` — код клавиши, символы по текущей
/// раскладке (через UCKeyTranslate, см. `KeyTranslator`) и модификаторы.
/// Это единственное, что системный слой отдаёт наверх (Engine, таск 04):
/// сам `CGEvent` за границу модуля не выходит.
public struct KeyStroke {
    /// Какого типа было CGEvent-событие.
    public enum Kind {
        /// Нажатие клавиши (`CGEventType.keyDown`).
        case keyDown
        /// Изменение модификаторов (`CGEventType.flagsChanged`) — нужно
        /// Engine'у, чтобы ловить одиночный тап Option.
        case flagsChanged
    }

    /// Тип события.
    public let kind: Kind
    /// Виртуальный код клавиши (`CGEventField.keyboardEventKeycode`).
    public let keyCode: UInt16
    /// Символ(ы), которые это нажатие даёт в текущей раскладке
    /// (UCKeyTranslate). Пустая строка для `flagsChanged` и клавиш без
    /// печатного символа (стрелки, F-ряд и т.п.).
    public let characters: String
    /// Флаги модификаторов на момент события (`CGEvent.flags`).
    public let flags: CGEventFlags
    /// Автоповтор при удержании (`CGEventField.keyboardEventAutorepeat`).
    public let isAutorepeat: Bool

    public init(
        kind: Kind,
        keyCode: UInt16,
        characters: String,
        flags: CGEventFlags,
        isAutorepeat: Bool
    ) {
        self.kind = kind
        self.keyCode = keyCode
        self.characters = characters
        self.flags = flags
        self.isAutorepeat = isAutorepeat
    }
}
#endif
