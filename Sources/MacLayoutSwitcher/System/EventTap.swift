// Системный слой macOS. Весь файл — под #if os(macOS).
#if os(macOS)
import Foundation
import CoreGraphics

/// Перехват клавиатуры во всех приложениях через CGEventTap
/// (`CGEvent.tapCreate`, `.cgSessionEventTap`, `.listenOnly` — мы наблюдаем,
/// а не фильтруем; для работы нужны разрешения Accessibility + Input
/// Monitoring, см. `Permissions`).
///
/// Обязанности:
/// - слушать `keyDown` + `flagsChanged` и отдавать наверх готовые `KeyStroke`
///   (символы уже расшифрованы `KeyTranslator`'ом по текущей раскладке);
/// - игнорировать собственные синтетические события `Typist`'а — они помечены
///   маркером `syntheticMarker` в `CGEventField.eventSourceUserData`, иначе
///   перепечатка слова зациклила бы сама себя;
/// - переживать `tapDisabledByTimeout`/`tapDisabledByUserInput`: система
///   отключает tap, если колбэк медлит, — включаем обратно
///   (`CGEvent.tapEnable`).
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
    private var handler: ((KeyStroke) -> Void)?

    public init() {}

    /// Создаёт и включает tap. `false` — если система отказала (обычно нет
    /// разрешения Accessibility/Input Monitoring); повторный вызов при живом
    /// tap'е — no-op, `true`.
    @discardableResult
    public func start(handler: @escaping (KeyStroke) -> Void) -> Bool {
        guard tap == nil else { return true }
        self.handler = handler

        let mask: CGEventMask =
            (1 << CGEventType.keyDown.rawValue) |
            (1 << CGEventType.flagsChanged.rawValue)

        let selfPtr = Unmanaged.passUnretained(self).toOpaque()

        guard let newTap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .listenOnly,
            eventsOfInterest: mask,
            callback: { _, type, event, userInfo in
                if let userInfo = userInfo {
                    let owner = Unmanaged<EventTap>.fromOpaque(userInfo).takeUnretainedValue()
                    owner.process(type: type, event: event)
                }
                return Unmanaged.passUnretained(event)
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

    private func process(type: CGEventType, event: CGEvent) {
        switch type {
        case .tapDisabledByTimeout, .tapDisabledByUserInput:
            // Система отключила tap (медленный колбэк или secure input) —
            // включаем обратно, иначе перехват молча умирает навсегда.
            if let tap = tap {
                CGEvent.tapEnable(tap: tap, enable: true)
            }

        case .keyDown, .flagsChanged:
            // Собственная синтетика возвращается в tap через .cghidEventTap —
            // отсеиваем её до обработчика (защита от цикла перепечатки).
            guard event.getIntegerValueField(.eventSourceUserData) != Self.syntheticMarker else {
                return
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
                    kind: .flagsChanged,
                    keyCode: keyCode,
                    characters: "",
                    flags: event.flags,
                    isAutorepeat: false
                )
            }
            handler?(stroke)

        default:
            break
        }
    }
}
#endif
