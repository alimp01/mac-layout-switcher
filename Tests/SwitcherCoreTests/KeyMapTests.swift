import XCTest
@testable import SwitcherCore

final class KeyMapTests: XCTestCase {

    // Ожидаемые значения — разобранные вручную пары по раскладке
    // ЙЦУКЕН/QWERTY (пример из спецификации: ghbdtn → привет).

    func testConvertEnToRuLowercase() {
        XCTAssertEqual(KeyMap.convert("ghbdtn", to: .ru), "привет")
        XCTAssertEqual(KeyMap.convert("vjcrdf", to: .ru), "москва")
    }

    func testConvertRuToEnLowercase() {
        XCTAssertEqual(KeyMap.convert("привет", to: .en), "ghbdtn")
        XCTAssertEqual(KeyMap.convert("ытфшд", to: .en), "snail")
    }

    func testConvertKeepsCase() {
        XCTAssertEqual(KeyMap.convert("Ghbdtn", to: .ru), "Привет")
        XCTAssertEqual(KeyMap.convert("GHBDTN", to: .ru), "ПРИВЕТ")
        XCTAssertEqual(KeyMap.convert("МоСкВа", to: .en), "VjCrDf")
    }

    func testConvertPunctuationKeys() {
        // объём: о→j б→, ъ→] ё→` м→v
        XCTAssertEqual(KeyMap.convert("j,]`v", to: .ru), "объём")
        XCTAssertEqual(KeyMap.convert("объём", to: .en), "j,]`v")
        // жизнь: ж→; з→p и→b н→y ь→m
        XCTAssertEqual(KeyMap.convert(";bpym", to: .ru), "жизнь")
        // заглавные на пунктуационных клавишах
        XCTAssertEqual(KeyMap.convert("{J:", to: .ru), "ХОЖ")
        XCTAssertEqual(KeyMap.convert("ЭЮБЁ", to: .en), "\"><~")
        // юг: ю→. г→u
        XCTAssertEqual(KeyMap.convert(".u", to: .ru), "юг")
    }

    func testConvertLeavesUnmappedCharactersAlone() {
        XCTAssertEqual(KeyMap.convert("123 !@# ghbdtn", to: .ru), "123 !@# привет")
        XCTAssertEqual(KeyMap.convert("сумма=100%", to: .en), "cevvf=100%")
    }
}
