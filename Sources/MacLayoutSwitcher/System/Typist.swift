// Системный слой macOS. Весь файл — под #if os(macOS).
#if os(macOS)
import Foundation
import CoreGraphics

/// Синтетический ввод: стереть последнее слово и напечатать замену.
///
/// Стирание — len × Backspace (виртуальный код 51) парами keyDown/keyUp.
/// Печать — посимвольно юникодом через `CGEvent.keyboardSetUnicodeString`:
/// символ кладётся прямо в событие, поэтому результат не зависит от активной
/// раскладки (можно сначала перепечатать, потом переключить раскладку — или
/// наоборот, порядок решает Engine).
///
/// Каждое событие помечается маркером `EventTap.syntheticMarker` в
/// `CGEventField.eventSourceUserData` — по нему наш собственный tap отличает
/// эту синтетику от ввода пользователя (защита от цикла). Отправка — через
/// `CGEvent.post(tap: .cghidEventTap)` с микрозадержками, чтобы приложения
/// успевали применять события по порядку.
///
/// Работа идёт на собственной последовательной очереди: usleep внутри колбэка
/// event tap'а привёл бы к `tapDisabledByTimeout`.
public final class Typist {

    /// Виртуальный код клавиши Backspace (kVK_Delete).
    private static let backspaceKeyCode: CGKeyCode = 51
    /// Микрозадержка между соседними событиями, мкс.
    private static let interEventDelayMicroseconds: UInt32 = 5_000

    private let queue = DispatchQueue(label: "MacLayoutSwitcher.Typist")

    public init() {}

    /// Стирает `len` символов Backspace'ами и печатает `text` юникодом.
    /// Асинхронно (на своей очереди); все события маркированы.
    public func replaceLastWord(len: Int, with text: String) {
        queue.async {
            Self.sendBackspaces(len)
            Self.typeUnicode(text)
        }
    }

    /// len × (keyDown + keyUp) Backspace. Флаги очищаются: удерживаемый
    /// пользователем Option превратил бы Backspace в «удалить слово».
    private static func sendBackspaces(_ count: Int) {
        guard count > 0 else { return }
        let source = CGEventSource(stateID: .privateState)
        for _ in 0..<count {
            guard let down = CGEvent(keyboardEventSource: source, virtualKey: backspaceKeyCode, keyDown: true),
                  let up = CGEvent(keyboardEventSource: source, virtualKey: backspaceKeyCode, keyDown: false)
            else { continue }
            down.flags = []
            up.flags = []
            post(down)
            post(up)
        }
    }

    /// Посимвольная печать юникодом. `keyboardSetUnicodeString` вкладывает
    /// текст в само событие (virtualKey 0 — заглушка), поэтому активная
    /// раскладка на результат не влияет.
    private static func typeUnicode(_ text: String) {
        guard !text.isEmpty else { return }
        let source = CGEventSource(stateID: .privateState)
        for character in text {
            let utf16 = Array(String(character).utf16)
            guard let down = CGEvent(keyboardEventSource: source, virtualKey: 0, keyDown: true),
                  let up = CGEvent(keyboardEventSource: source, virtualKey: 0, keyDown: false)
            else { continue }
            utf16.withUnsafeBufferPointer { buffer in
                down.keyboardSetUnicodeString(stringLength: buffer.count, unicodeString: buffer.baseAddress)
                up.keyboardSetUnicodeString(stringLength: buffer.count, unicodeString: buffer.baseAddress)
            }
            down.flags = []
            up.flags = []
            post(down)
            post(up)
        }
    }

    /// Маркирует событие как наше и отправляет в HID-очередь с микрозадержкой.
    private static func post(_ event: CGEvent) {
        event.setIntegerValueField(.eventSourceUserData, value: EventTap.syntheticMarker)
        event.post(tap: .cghidEventTap)
        usleep(interEventDelayMicroseconds)
    }
}
#endif
