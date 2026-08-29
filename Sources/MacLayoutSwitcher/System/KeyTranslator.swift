// Системный слой macOS. Весь файл — под #if os(macOS).
#if os(macOS)
import Foundation
import Carbon.HIToolbox

/// Перевод «код клавиши → символ» по активной раскладке через UCKeyTranslate
/// (CarbonCore/UnicodeUtilities) — никакой зашитой таблицы под конкретную
/// клавиатуру: данные раскладки берутся из текущего источника ввода
/// (`kTISPropertyUnicodeKeyLayoutData`). Dead keys подавляются
/// (`kUCKeyTranslateNoDeadKeysBit`), чтобы `'` и `~` возвращались как символы,
/// а не копили состояние.
///
/// Внутренний помощник `EventTap`'а; наверх наружу не выставляется.
enum KeyTranslator {

    /// Символ(ы) для кода клавиши с данными модификаторами по текущей
    /// раскладке. Пустая строка, если клавиша не даёт печатного символа
    /// или данные раскладки недоступны (например, у IME-источников
    /// `kTISPropertyUnicodeKeyLayoutData` равен NULL).
    static func characters(keyCode: UInt16, flags: CGEventFlags) -> String {
        guard let layoutData = currentLayoutData() else { return "" }

        // UCKeyTranslate принимает модификаторы в формате EventRecord >> 8.
        // Для печатного символа значимы Shift/Option (и CapsLock).
        var modifiers: UInt32 = 0
        if flags.contains(.maskShift) { modifiers |= UInt32(shiftKey) >> 8 }
        if flags.contains(.maskAlternate) { modifiers |= UInt32(optionKey) >> 8 }
        if flags.contains(.maskAlphaShift) { modifiers |= UInt32(alphaLock) >> 8 }

        var deadKeyState: UInt32 = 0
        let maxLength = 4
        var chars = [UniChar](repeating: 0, count: maxLength)
        var actualLength = 0

        let status = layoutData.withUnsafeBytes { (raw: UnsafeRawBufferPointer) -> OSStatus in
            guard let layoutPtr = raw.bindMemory(to: UCKeyboardLayout.self).baseAddress else {
                return OSStatus(-1)
            }
            return UCKeyTranslate(
                layoutPtr,
                keyCode,
                UInt16(kUCKeyActionDisplay),
                modifiers,
                UInt32(LMGetKbdType()),
                // Именно ...Mask: ...Bit — это номер бита (0), а не маска.
                OptionBits(kUCKeyTranslateNoDeadKeysMask),
                &deadKeyState,
                maxLength,
                &actualLength,
                &chars
            )
        }
        guard status == noErr, actualLength > 0 else { return "" }
        return String(utf16CodeUnits: chars, count: actualLength)
    }

    /// uchr-данные текущего источника ввода (TIS). Копия `Data` — блоб
    /// принадлежит источнику и не должен переживать его освобождение.
    private static func currentLayoutData() -> Data? {
        guard let source = TISCopyCurrentKeyboardInputSource()?.takeRetainedValue(),
              let rawPtr = TISGetInputSourceProperty(source, kTISPropertyUnicodeKeyLayoutData)
        else { return nil }
        let cfData = Unmanaged<CFData>.fromOpaque(rawPtr).takeUnretainedValue()
        return cfData as Data
    }
}
#endif
