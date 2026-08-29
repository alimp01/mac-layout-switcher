import XCTest
import Foundation
@testable import SwitcherCore

/// Тесты модели `Hotkey` — ключевой шов таска 08 на Linux: сопоставление
/// «нажата ли назначенная клавиша» должно быть проверено, а не собрано вслепую.
/// Ожидаемые displayName взяты из спецификации таска («⌥ Option», «⇪ Caps Lock»,
/// «⌘⇧ K»), а не вычислены тем же кодом, что под тестом.
final class HotkeyTests: XCTestCase {

    // MARK: - Одиночный модификатор

    func testSingleModifierMatchesExactlyAndNotWithExtraKeys() {
        let hk = Hotkey(keyCode: nil, modifiers: [.option])
        // Чистый одиночный Option-tap.
        XCTAssertTrue(hk.matches(keyCode: nil, modifiers: [.option]))
        // Лишний модификатор — не срабатывает.
        XCTAssertFalse(hk.matches(keyCode: nil, modifiers: [.option, .command]))
        // Лишняя клавиша (keyCode) — не срабатывает.
        XCTAssertFalse(hk.matches(keyCode: 40, modifiers: [.option]))
        // Другой модификатор — не срабатывает.
        XCTAssertFalse(hk.matches(keyCode: nil, modifiers: [.control]))
        // Пусто — не срабатывает.
        XCTAssertFalse(hk.matches(keyCode: nil, modifiers: []))
    }

    func testCapsLockSingleModifier() {
        let hk = Hotkey(keyCode: nil, modifiers: [.capsLock])
        XCTAssertTrue(hk.matches(keyCode: nil, modifiers: [.capsLock]))
        XCTAssertFalse(hk.matches(keyCode: nil, modifiers: [.option]))
    }

    // MARK: - Клавиша с модификаторами

    func testKeyWithModifiersMatches() {
        // ⌘⇧K
        let hk = Hotkey(keyCode: 40, modifiers: [.command, .shift])
        XCTAssertTrue(hk.matches(keyCode: 40, modifiers: [.command, .shift]))
        // Не хватает модификатора.
        XCTAssertFalse(hk.matches(keyCode: 40, modifiers: [.command]))
        // Другой код клавиши.
        XCTAssertFalse(hk.matches(keyCode: 41, modifiers: [.command, .shift]))
        // Лишний модификатор.
        XCTAssertFalse(hk.matches(keyCode: 40, modifiers: [.command, .shift, .option]))
    }

    // MARK: - Codable / Equatable

    func testCodableRoundTrip() throws {
        let cases = [
            Hotkey(keyCode: nil, modifiers: [.option]),
            Hotkey(keyCode: nil, modifiers: [.capsLock]),
            Hotkey(keyCode: 40, modifiers: [.command, .shift]),
            Hotkey(keyCode: nil, modifiers: [.rightOption]),
        ]
        for hk in cases {
            let data = try JSONEncoder().encode(hk)
            let back = try JSONDecoder().decode(Hotkey.self, from: data)
            XCTAssertEqual(hk, back)
        }
    }

    func testEquatable() {
        XCTAssertEqual(
            Hotkey(keyCode: 40, modifiers: [.command, .shift]),
            Hotkey(keyCode: 40, modifiers: [.shift, .command]))
        XCTAssertNotEqual(
            Hotkey(keyCode: nil, modifiers: [.option]),
            Hotkey(keyCode: nil, modifiers: [.rightOption]))
    }

    // MARK: - displayName

    func testDisplayName() {
        XCTAssertEqual(Hotkey(keyCode: nil, modifiers: [.option]).displayName, "⌥ Option")
        XCTAssertEqual(Hotkey(keyCode: nil, modifiers: [.capsLock]).displayName, "⇪ Caps Lock")
        XCTAssertEqual(Hotkey(keyCode: 40, modifiers: [.command, .shift]).displayName, "⌘⇧ K")
        // Неназначенная (пустая) — понятный плейсхолдер.
        XCTAssertEqual(Hotkey(keyCode: nil, modifiers: []).displayName, "не назначено")
    }

    func testDefaultConvertIsOption() {
        XCTAssertEqual(Hotkey.defaultConvert, Hotkey(keyCode: nil, modifiers: [.option]))
        XCTAssertTrue(Hotkey.defaultConvert.matches(keyCode: nil, modifiers: [.option]))
    }
}
