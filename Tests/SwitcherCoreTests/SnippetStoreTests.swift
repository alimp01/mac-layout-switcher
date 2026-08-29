import XCTest
import Foundation
@testable import SwitcherCore

final class SnippetStoreTests: XCTestCase {

    private func makeTempFile(_ contents: String?) throws -> URL {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("snippets-test-\(UUID().uuidString).json")
        if let contents {
            try contents.write(to: url, atomically: true, encoding: .utf8)
        }
        addTeardownBlock {
            try? FileManager.default.removeItem(at: url)
        }
        return url
    }

    func testLoadsSnippetsFromJSONAndExpands() throws {
        // Формат из спецификации: {"сдр": "С днём рождения!"}
        let url = try makeTempFile(
            #"{"сдр": "С днём рождения!", "sig": "С уважением, Илья"}"#
        )
        let store = SnippetStore()
        store.load(from: url)
        XCTAssertEqual(store.expansion(for: "сдр"), "С днём рождения!")
        XCTAssertEqual(store.expansion(for: "sig"), "С уважением, Илья")
        XCTAssertNil(store.expansion(for: "нет-такого"))
    }

    func testMissingFileMeansEmptySet() throws {
        let url = try makeTempFile(nil) // файл не создан
        let store = SnippetStore()
        store.load(from: url)
        XCTAssertNil(store.expansion(for: "сдр"))
    }

    func testCorruptJSONMeansEmptySet() throws {
        let url = try makeTempFile(#"{"сдр": ["не", "строка"#) // битый JSON
        let store = SnippetStore()
        store.load(from: url)
        XCTAssertNil(store.expansion(for: "сдр"))
    }

    func testReloadReplacesPreviousSetOnCorruptFile() throws {
        let good = try makeTempFile(#"{"сдр": "С днём рождения!"}"#)
        let bad = try makeTempFile("не json вовсе")
        let store = SnippetStore()
        store.load(from: good)
        store.load(from: bad)
        XCTAssertNil(store.expansion(for: "сдр"))
    }
}
