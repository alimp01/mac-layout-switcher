// Системный слой macOS. Весь файл — под #if os(macOS).
#if os(macOS)
import Foundation
import CoreGraphics

/// Синтетический ввод: стереть последнее слово, напечатать замену и — когда
/// разделитель был перехвачен активным tap'ом — дослать его следом.
///
/// Стирание — len × Backspace (виртуальный код 51) парами keyDown/keyUp.
/// Печать — посимвольно юникодом через `CGEvent.keyboardSetUnicodeString`:
/// символ кладётся прямо в событие, поэтому результат не зависит от активной
/// раскладки (можно сначала перепечатать, потом переключить раскладку — или
/// наоборот, порядок решает Engine).
///
/// Каждое событие помечается маркером `EventTap.syntheticMarker` в
/// `CGEventField.eventSourceUserData` — по нему наш собственный tap отличает
/// эту синтетику от ввода пользователя (защита от цикла; активный tap её не
/// подавляет). Отправка — через `CGEvent.post(tap: .cghidEventTap)` с
/// микрозадержками, чтобы приложения успевали применять события по порядку.
///
/// Работа идёт на собственной ПОСЛЕДОВАТЕЛЬНОЙ очереди: usleep внутри колбэка
/// event tap'а привёл бы к `tapDisabledByTimeout`. Последовательность очереди
/// — единственная гарантия порядка «backspaces → символы → разделитель →
/// переигранные нажатия пользователя»: всё, что должно случиться ПОСЛЕ
/// перепечатки, ставится в ту же очередь (`send`).
///
/// События для `send` создаются СИНХРОННО вызывающей стороной
/// (`makeKeyPress`/`makeUnicodePress`) — ещё до того, как tap'у возвращено
/// решение «подавить». Так подавленное нажатие никогда не теряется: если
/// `CGEvent` создать не удалось, Engine это узнаёт сразу и пропускает нажатие
/// как есть.
public final class Typist {

    /// Готовая пара keyDown/keyUp, созданная заранее и ждущая своей очереди.
    public struct KeyPress {
        fileprivate let down: CGEvent
        fileprivate let up: CGEvent
    }

    /// Виртуальный код клавиши Backspace (kVK_Delete).
    private static let backspaceKeyCode: CGKeyCode = 51
    /// Виртуальные коды разделителей (kVK_Return / kVK_Tab / kVK_Space) —
    /// для досылки перехваченного разделителя по символу.
    public static let returnKeyCode: CGKeyCode = 36
    public static let tabKeyCode: CGKeyCode = 48
    public static let spaceKeyCode: CGKeyCode = 49
    /// Микрозадержка между соседними событиями, мкс.
    private static let interEventDelayMicroseconds: UInt32 = 5_000

    private let queue = DispatchQueue(label: "MacLayoutSwitcher.Typist")

    /// Число поставленных, но ещё не выполненных заданий. Пока > 0, синтетика
    /// ещё летит в приложение, и пользовательский ввод должен ложиться ПОСЛЕ
    /// неё (Engine его переигрывает через `send`), а не посреди.
    private var pending = 0
    private let pendingLock = NSLock()

    public init() {}

    /// `true`, пока очередь не опустела (перепечатка/досылка ещё идёт).
    public var isBusy: Bool {
        pendingLock.lock()
        defer { pendingLock.unlock() }
        return pending > 0
    }

    /// Стирает `len` символов Backspace'ами и печатает `text` юникодом.
    /// Асинхронно (на своей очереди); все события маркированы.
    public func replaceLastWord(len: Int, with text: String) {
        enqueue {
            Self.sendBackspaces(len)
            Self.typeUnicode(text)
        }
    }

    /// Отправляет заранее созданное нажатие в той же очереди — строго после
    /// всего, что поставлено раньше. Так перехваченный активным tap'ом
    /// Enter/пробел/Tab (и переигранные нажатия пользователя) уходят в
    /// приложение только когда слово уже перепечатано. События маркированы:
    /// tap пропустит их без обработки.
    public func send(_ press: KeyPress) {
        enqueue {
            Self.post(press.down)
            Self.post(press.up)
        }
    }

    /// Создаёт (синхронно, без отправки) нажатие клавиши по виртуальному коду.
    /// `flags` — модификаторы исходного нажатия (Shift+Enter в чате = перенос
    /// строки, а не отправка — их надо сохранить). `nil` — система отказала
    /// создать событие; вызывающий обязан НЕ подавлять исходное нажатие.
    public static func makeKeyPress(keyCode: CGKeyCode, flags: CGEventFlags) -> KeyPress? {
        let source = CGEventSource(stateID: .privateState)
        guard let down = CGEvent(keyboardEventSource: source, virtualKey: keyCode, keyDown: true),
              let up = CGEvent(keyboardEventSource: source, virtualKey: keyCode, keyDown: false)
        else { return nil }
        down.flags = flags
        up.flags = flags
        return KeyPress(down: down, up: up)
    }

    /// Создаёт (синхронно) нажатие, печатающее ровно `character` юникодом —
    /// независимо от раскладки, которая будет активна к моменту отправки.
    /// Для переигрывания букв, набранных во время перепечатки: ядро уже
    /// получило именно этот символ, приложение получит его же.
    public static func makeUnicodePress(_ character: Character) -> KeyPress? {
        let source = CGEventSource(stateID: .privateState)
        guard let down = CGEvent(keyboardEventSource: source, virtualKey: 0, keyDown: true),
              let up = CGEvent(keyboardEventSource: source, virtualKey: 0, keyDown: false)
        else { return nil }
        let utf16 = Array(String(character).utf16)
        utf16.withUnsafeBufferPointer { buffer in
            down.keyboardSetUnicodeString(stringLength: buffer.count, unicodeString: buffer.baseAddress)
            up.keyboardSetUnicodeString(stringLength: buffer.count, unicodeString: buffer.baseAddress)
        }
        down.flags = []
        up.flags = []
        return KeyPress(down: down, up: up)
    }

    /// Виртуальный код для символа-разделителя: `\n`/`\r` → Return, `\t` → Tab,
    /// пробел → Space; прочее — `nil` (досылать нечем).
    public static func keyCode(forSeparator sep: Character) -> CGKeyCode? {
        switch sep {
        case "\n", "\r", "\r\n": return returnKeyCode
        case "\t": return tabKeyCode
        case " ": return spaceKeyCode
        default: return nil
        }
    }

    /// Ставит задание в очередь, ведя счётчик занятости: +1 синхронно при
    /// постановке (чтобы `isBusy` стал `true` ещё до возврата в колбэк tap'а),
    /// −1 по завершении задания на очереди.
    private func enqueue(_ job: @escaping () -> Void) {
        pendingLock.lock()
        pending += 1
        pendingLock.unlock()
        queue.async { [self] in
            job()
            pendingLock.lock()
            pending -= 1
            pendingLock.unlock()
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
        for character in text {
            guard let press = makeUnicodePress(character) else { continue }
            post(press.down)
            post(press.up)
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
