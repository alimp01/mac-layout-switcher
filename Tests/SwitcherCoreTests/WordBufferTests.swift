import XCTest
@testable import SwitcherCore

final class WordBufferTests: XCTestCase {

    func testAppendAccumulatesWord() {
        let buffer = WordBuffer()
        XCTAssertEqual(buffer.word, "")
        buffer.append(char: "п")
        buffer.append(char: "р")
        buffer.append(char: "и")
        XCTAssertEqual(buffer.word, "при")
    }

    func testBackspaceRemovesLastCharAndSurvivesEmptyWord() {
        let buffer = WordBuffer()
        buffer.append(char: "п")
        buffer.append(char: "р")
        buffer.backspace()
        XCTAssertEqual(buffer.word, "п")
        // backspace за границу слова: пустое слово, не крэш
        buffer.backspace()
        buffer.backspace()
        XCTAssertEqual(buffer.word, "")
        buffer.append(char: "х")
        XCTAssertEqual(buffer.word, "х")
    }

    func testBoundaryAndResetClearWord() {
        let buffer = WordBuffer()
        buffer.append(char: "d")
        buffer.append(char: "f")
        buffer.boundary()
        XCTAssertEqual(buffer.word, "")
        buffer.append(char: "q")
        XCTAssertEqual(buffer.word, "q")
        buffer.reset()
        XCTAssertEqual(buffer.word, "")
    }
}
