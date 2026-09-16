// Системный слой macOS. Весь файл — под #if os(macOS).
#if os(macOS)
import Foundation
import CoreGraphics

/// Решение активного tap'а по одному событию клавиатуры.
public enum TapDecision {
    /// Пропустить событие в приложение как есть.
    case pass
    /// Подавить: приложение события не увидит (колбэк вернёт `nil`).
    case suppress
}

/// Перехват клавиатуры во всех приложениях через CGEventTap
/// (`CGEvent.tapCreate`, `.cgSessionEventTap`, `.defaultTap` — активный tap,
/// умеющий подавлять события; для работы нужны разрешения Accessibility +
/// Input Monitoring, см. `Permissions`).
///
/// Обязанности:
/// - слушать `keyDown` + `flagsChanged`, отдавать наверх готовые `KeyStroke`
///   (символы уже расшифрованы `KeyTranslator`'ом по текущей раскладке) и
///   СИНХРОННО исполнять решение обработчика: `.pass` — событие уходит в
///   приложение, `.suppress` — колбэк возвращает `nil`, событие исчезает.
///   Так разделитель (Enter/пробел/Tab) перехватывается ДО доставки, и слово
///   исправляется раньше, чем чат отправит сообщение (G12, ADR 0004
///   пересмотрен);
/// - пропускать собственные синтетические события `Typist`'а без обработки —
///   они помечены маркером `syntheticMarker` в
///   `CGEventField.eventSourceUserData`, иначе перепечатка зациклила бы себя;
/// - переживать `tapDisabledByTimeout`/`tapDisabledByUserInput`: система
///   отключает tap, если колбэк медлит, — включаем обратно
///   (`CGEvent.tapEnable`).
///
/// Активный tap обязан отвечать быстро: решение обработчика — это детектор на
/// одном слове (микросекунды); никакого I/O, sleep и синтетики в колбэке —
/// перепечатка уходит на очередь `Typist`.
///
/// Tap вешается на главный run loop (`CFRunLoopGetMain`), поэтому и колбэк
/// `handler` приходит на главном потоке.
public final class EventTap {

    /// Маркер синтетических событий в `CGEventField.eventSourceUserData`.
    /// `Typist` ставит его на каждое своё событие; tap по нему отличает
    /// собственный ввод от пользовательского — по признаку, а не по времени.
    public static let syntheticMarker: Int64 = 0xC0FFEE

    private var tap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?
    private var handler: ((KeyStroke) -> TapDecision)?

    public init() {}

    /// Создаёт и включает tap. `false` — если система отказала (обычно нет
    /// разрешения Accessibility/Input Monitoring); повторный вызов при живом
    /// tap'е — no-op, `true`. `handler` решает синхронно, пропустить или
    /// подавить каждое пользовательское нажатие.
    @discardableResult
    public func start(handler: @escaping (KeyStroke) -> TapDecision) -> Bool {
        guard tap == nil else { return true }
        self.handler = handler

        let mask: CGEventMask =
            (1 << CGEventType.keyDown.rawValue) |
            (1 << CGEventType.keyUp.rawValue) |
            (1 << CGEventType.flagsChanged.rawValue)

        let selfPtr = Unmanaged.passUnretained(self).toOpaque()

        guard let newTap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: mask,
            callback: { _, type, event, userInfo in
                guard let userInfo = userInfo else {
                    return Unmanaged.passUnretained(event)
                }
                let owner = Unmanaged<EventTap>.fromOpaque(userInfo).takeUnretainedValue()
                switch owner.process(type: type, event: event) {
                case .pass:
                    return Unmanaged.passUnretained(event)
                case .suppress:
                    // nil = событие подавлено, приложение его не увидит.
                    return nil
                }
            },
            userInfo: selfPtr
        ) else {
            self.handler = nil
            return false
        }

        let source = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, newTap, 0)
        CFRunLoopAddSource(CFRunLoopGetMain(), source, .commonModes)
        CGEvent.tapEnable(tap: newTap, enable: true)

        self.tap = newTap
        self.runLoopSource = source
        return true
    }

    /// Выключает tap и снимает его с run loop. Безопасен при уже
    /// остановленном tap'е.
    public func stop() {
        guard let tap = tap else { return }
        CGEvent.tapEnable(tap: tap, enable: false)
        if let source = runLoopSource {
            CFRunLoopRemoveSource(CFRunLoopGetMain(), source, .commonModes)
        }
        self.tap = nil
        self.runLoopSource = nil
        self.handler = nil
    }

    /// Разбирает событие и возвращает решение. Всё, что не пользовательское
    /// нажатие (служебные типы, своя синтетика), пропускается без обработки.
    private func process(type: CGEventType, event: CGEvent) -> TapDecision {
        switch type {
        case .tapDisabledByTimeout, .tapDisabledByUserInput:
            // Система отключила tap (медленный колбэк или secure input) —
            // включаем обратно, иначе перехват молча умирает навсегда.
            if let tap = tap {
                CGEvent.tapEnable(tap: tap, enable: true)
            }
            return .pass

        case .keyDown, .keyUp, .flagsChanged:
            // Собственная синтетика (перепечатка и досланный разделитель)
            // возвращается в tap через .cghidEventTap — пропускаем её без
            // обработки: подавить или зациклить свои же события нельзя.
            guard event.getIntegerValueField(.eventSourceUserData) != Self.syntheticMarker else {
                return .pass
            }
            let keyCode = UInt16(truncatingIfNeeded: event.getIntegerValueField(.keyboardEventKeycode))
            let stroke: KeyStroke
            if type == .keyDown {
                stroke = KeyStroke(
                    kind: .keyDown,
                    keyCode: keyCode,
                    characters: KeyTranslator.characters(keyCode: keyCode, flags: event.flags),
                    flags: event.flags,
                    isAutorepeat: event.getIntegerValueField(.keyboardEventAutorepeat) != 0
                )
            } else {
                stroke = KeyStroke(
                    kind: type == .keyUp ? .keyUp : .flagsChanged,
                    keyCode: keyCode,
                    characters: "",
                    flags: event.flags,
                    isAutorepeat: false
                )
            }
            return handler?(stroke) ?? .pass

        default:
            return .pass
        }
    }
}
#endif
