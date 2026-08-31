import XCTest
@testable import SwitcherCore

/// Тесты сравнения версий для автообновления (таск 13). Шов — публичный
/// `SemVer.compare`; ожидаемые значения разобраны вручную по правилам semver.
final class SemVerTests: XCTestCase {

    func testGreaterAndLess() {
        // 1.2.0 новее 1.1.9 — второй компонент решает раньше третьего.
        XCTAssertEqual(SemVer.compare("1.2.0", "1.1.9"), .orderedDescending)
        // 1.1.0 старее 2.0.0 — мажорный компонент главнее всех остальных.
        XCTAssertEqual(SemVer.compare("1.1.0", "2.0.0"), .orderedAscending)
    }

    func testEqual() {
        XCTAssertEqual(SemVer.compare("1.1.0", "1.1.0"), .orderedSame)
    }

    func testNumericNotLexicographic() {
        // Лексикографически "1.10.0" < "1.9.0"; по semver — новее.
        XCTAssertEqual(SemVer.compare("1.10.0", "1.9.0"), .orderedDescending)
    }

    func testDifferentLength() {
        // Недостающие компоненты = 0: 1.1 == 1.1.0, а 1.1.0.1 новее 1.1.0.
        XCTAssertEqual(SemVer.compare("1.1", "1.1.0"), .orderedSame)
        XCTAssertEqual(SemVer.compare("1.1.0", "1.1.0.1"), .orderedAscending)
    }

    func testTrimsWhitespace() {
        // Raw VERSION с GitHub приходит с '\n' на конце — сравнение обязано
        // его пережить, иначе «1.2.0\n» перестанет быть новее «1.1.0».
        XCTAssertEqual(SemVer.compare(" 1.2.0\n", "1.1.0"), .orderedDescending)
        XCTAssertEqual(SemVer.compare("1.1.0\n", "1.1.0"), .orderedSame)
    }

    func testGarbageComponentIsZero() {
        // Нечисловой компонент считается нулём (документированное поведение):
        // «1.x.0» == «1.0.0», и он СТАРЕЕ нормального «1.1.0» — кривой VERSION
        // с GitHub не может «предложить обновление» на мусор.
        XCTAssertEqual(SemVer.compare("1.x.0", "1.0.0"), .orderedSame)
        XCTAssertEqual(SemVer.compare("1.x.0", "1.1.0"), .orderedAscending)
    }
}
