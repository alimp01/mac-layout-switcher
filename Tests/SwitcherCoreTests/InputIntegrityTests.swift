import XCTest
import SwitcherCore

final class InputIntegrityTests: XCTestCase {
    func testFreshContextCorrectsOnlyRequestedSingleLettersAtBoundary() {
        for (typed, expected) in [("b", "и"), ("B", "И"), ("z", "я"), ("Z", "Я")] {
            let core = EngineCore(detector: Detector(), snippets: SnippetStore())
            typed.forEach { core.handle(.char($0)) }
            XCTAssertEqual(core.handle(.boundary(" ")).command,
                           .replaceLast(len: 1, with: expected, switchTo: .ru))
        }
    }
    func testResetForgetsLanguageAndOldWordBeforeNewField() {
        let core = EngineCore(detector: Detector(), snippets: SnippetStore())
        "plan".forEach { core.handle(.char($0)) }
        core.handle(.boundary(" "))
        core.handle(.reset)
        core.handle(.char("b"))
        XCTAssertEqual(core.handle(.boundary(" ")).command,
                       .replaceLast(len: 1, with: "и", switchTo: .ru))
    }
    func testSubmissionDoesNotLeaveOldUndoInNewInput() {
        for separator: Character in ["\n", "\t", "\r"] {
            let core = EngineCore(detector: Detector(), snippets: SnippetStore())
            "ltymub".forEach { core.handle(.char($0)) }
            XCTAssertEqual(core.handle(.boundary(separator)).command,
                           .replaceLast(len: 6, with: "деньги", switchTo: .ru))
            XCTAssertEqual(core.handle(.hotkey(.convert)).command, .none)
        }
    }
    func testReplacementCarriesExactSourceForExecutorValidation() {
        let core = EngineCore(detector: Detector(), snippets: SnippetStore())
        "ghbdtn".forEach { core.handle(.char($0)) }
        XCTAssertEqual(core.handle(.boundary(" ")).expectedText, "ghbdtn")
        XCTAssertEqual(core.handle(.hotkey(.convert)).expectedText, "привет ")
    }
    func testFailedUndoDoesNotTeachExclusionOrKeepStaleRegion() {
        let detector = Detector()
        let core = EngineCore(detector: detector, snippets: SnippetStore(), undoThreshold: 1)
        "ghbdtn".forEach { core.handle(.char($0)) }
        core.handle(.boundary(" "))
        let undo = core.handle(.hotkey(.convert))
        core.discardReplacement(undo)
        XCTAssertFalse(detector.isExcluded("ghbdtn"))
        XCTAssertEqual(core.handle(.hotkey(.convert)).command, .none)
    }
    func testOzonAndCorrectSingleLettersAreNeverChanged() {
        for word in ["ozon", "Ozon", "OZON", "и", "И", "я", "Я", "I", "a", "d", "q"] {
            let core = EngineCore(detector: Detector(), snippets: SnippetStore())
            word.forEach { core.handle(.char($0)) }
            XCTAssertEqual(core.handle(.boundary(" ")).command, .none, word)
        }
    }

    func testEnglishContextAndUserExclusionsPreserveSingleLetterLabels() {
        for word in ["b", "B", "z", "Z"] {
            let detector = Detector()
            let core = EngineCore(detector: detector, snippets: SnippetStore())
            "plan".forEach { core.handle(.char($0)) }
            core.handle(.boundary(" "))
            word.forEach { core.handle(.char($0)) }
            XCTAssertEqual(core.handle(.boundary(" ")).command, .none)
            core.handle(.reset)
            detector.addExclusion(word)
            word.forEach { core.handle(.char($0)) }
            XCTAssertEqual(core.handle(.boundary(" ")).command, .none)
        }
    }

    func testOldWordCannotBeRestoredAfterClickNavigationOrPause() {
        let core = EngineCore(detector: Detector(), snippets: SnippetStore())
        "ltymub!".forEach { core.handle(.char($0)) }
        core.handle(.reset) // Platform maps clicks/navigation/focus loss to reset.
        "ozon".forEach { core.handle(.char($0)) }
        XCTAssertEqual(core.handle(.boundary(" ")).command, .none)
        core.handle(.backspace) // Crosses the completed-word boundary.
        XCTAssertEqual(core.handle(.hotkey(.convert)).command, .none)
        core.isPaused = true
        core.isPaused = false
        core.handle(.char("b"))
        XCTAssertEqual(core.handle(.boundary(" ")).command,
                       .replaceLast(len: 1, with: "и", switchTo: .ru))
    }

    func testOldFailedTransactionCannotClearNewFieldBuffer() {
        let core = EngineCore(detector: Detector(), snippets: SnippetStore())
        "ghbdtn".forEach { core.handle(.char($0)) }
        let old = core.handle(.boundary(" "))
        core.handle(.reset)
        "ozon".forEach { core.handle(.char($0)) }
        core.discardReplacement(old, resetContext: false)
        XCTAssertEqual(core.handle(.hotkey(.convert)).expectedText, "ozon")
    }

    func testReplacementSourceRejectsSelectionMissingTextAndStalePrefix() {
        let source = ReplacementSource(expected: "ltymub!ozon")
        XCTAssertNil(source.rangeBeforeCaret(location: 4, selectionLength: 0))
        XCTAssertNil(source.rangeBeforeCaret(location: 11, selectionLength: 4))
        XCTAssertFalse(source.matches("ozon"))
        XCTAssertFalse(source.matches(nil))
        let unicode = ReplacementSource(expected: "я🙂")
        XCTAssertEqual(unicode.rangeBeforeCaret(location: 7, selectionLength: 0), 4..<7)
        XCTAssertTrue(unicode.matches("я🙂"))
        let single = ReplacementSource(expected: "b")
        XCTAssertTrue(single.matches("b"))
        XCTAssertTrue(single.matches(" b", atDocumentStart: false))
        XCTAssertFalse(single.matches("ob", atDocumentStart: false))
        XCTAssertFalse(single.matches("b", atDocumentStart: false))
    }
    func testPhysicalKeysFollowDeliveredTabButNeverAnUnrelatedClick() {
        var replay = InputReplayPolicy()
        XCTAssertFalse(replay.allowsReplay(cancelled: false, secure: false, originalTargetCurrent: false))
        replay.didDeliverNavigation()
        for _ in "abc" {
            XCTAssertTrue(replay.allowsReplay(cancelled: false, secure: false, originalTargetCurrent: false))
        }
        XCTAssertFalse(replay.allowsReplay(cancelled: true, secure: false, originalTargetCurrent: false))
        XCTAssertFalse(replay.allowsReplay(cancelled: false, secure: true, originalTargetCurrent: true))
    }
}
