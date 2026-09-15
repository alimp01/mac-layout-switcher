import XCTest
import SwitcherCore

final class ShortWordsTests: XCTestCase {

    // MARK: - Состав словарей

    func testDictionariesAreLargeEnoughAndShort() {
        XCTAssertGreaterThanOrEqual(ShortWords.ru.count, 120, "RU-словарь коротких слов")
        XCTAssertGreaterThanOrEqual(ShortWords.en.count, 120, "EN-словарь коротких слов")

        for word in ShortWords.ru {
            XCTAssertTrue((1...4).contains(word.count), "RU «\(word)» длиной 1–4")
            XCTAssertEqual(word, word.lowercased(), "RU «\(word)» в нижнем регистре")
        }
        for word in ShortWords.en {
            XCTAssertTrue((1...4).contains(word.count), "EN «\(word)» длиной 1–4")
            XCTAssertEqual(word, word.lowercased(), "EN «\(word)» в нижнем регистре")
        }

        // Слова из брифа и тикета обязаны быть в словарях.
        for word in ["и", "в", "на", "не", "я", "ты", "он", "как", "что", "это", "ща", "щас", "ок"] {
            XCTAssertTrue(ShortWords.ru.contains(word), "RU-словарь без «\(word)»")
        }
        for word in ["a", "i", "of", "to", "is", "it", "in", "on", "we", "the", "and", "ok"] {
            XCTAssertTrue(ShortWords.en.contains(word), "EN-словарь без «\(word)»")
        }
    }

    // MARK: - Коллизии словарей

    /// Коллизия — слово одного словаря, чья конверсия в другую раскладку есть
    /// в другом словаре. Их решает контекст в Detector, поэтому множество
    /// должно быть известным и маленьким: любое расширение словарей, которое
    /// добавит коллизию, обязано сюда попасть осознанно.
    func testCollisionSetIsExactlyTheDocumentedOne() {
        var collisions: Set<String> = []
        for en in ShortWords.en {
            let ru = KeyMap.convert(en, to: .ru)
            if ShortWords.ru.contains(ru) { collisions.insert("\(en)↔\(ru)") }
        }
        for ru in ShortWords.ru {
            let en = KeyMap.convert(ru, to: .en)
            if ShortWords.en.contains(en) { collisions.insert("\(en)↔\(ru)") }
        }
        XCTAssertEqual(collisions, ["of↔ща", "vs↔мы", "her↔рук", "here↔руку", "dj↔во", "ofc↔щас"])
    }

    func testContainsIsCaseInsensitive() {
        XCTAssertTrue(ShortWords.contains("Как", lang: .ru))
        XCTAssertTrue(ShortWords.contains("КАК", lang: .ru))
        XCTAssertTrue(ShortWords.contains("The", lang: .en))
        XCTAssertTrue(ShortWords.contains("I", lang: .en))
        XCTAssertFalse(ShortWords.contains("rfr", lang: .en))
        XCTAssertFalse(ShortWords.contains("привет", lang: .ru))
    }
}
