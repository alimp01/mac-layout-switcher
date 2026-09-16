import XCTest
import SwitcherCore

final class DictationTests: XCTestCase {
    func testHoldReleaseAndLateCompletion() {
        var session = DictationSession()
        let first = session.begin(ready: true)!
        XCTAssertEqual(session.phase, .starting)
        XCTAssertTrue(session.recordingStarted(first))
        XCTAssertEqual(session.release(), first)
        XCTAssertEqual(session.phase, .transcribing)
        session.cancel()
        XCTAssertFalse(session.recognized(first, hasText: true))
        let second = session.begin(ready: true)!
        XCTAssertNotEqual(first, second)
        XCTAssertFalse(session.recordingStarted(first))
        XCTAssertTrue(session.recordingStarted(second))
    }

    func testReleaseBeforeMicrophoneStartsNeverRecords() {
        var session = DictationSession()
        let id = session.begin(ready: true)!
        XCTAssertNil(session.release())
        XCTAssertFalse(session.recordingStarted(id))
        XCTAssertEqual(session.phase, .idle)
    }

    func testSetupCompletionRequiresNewHoldEvenWhenStillHeld() {
        var session = DictationSession()
        let id = session.begin(ready: false)!
        XCTAssertEqual(session.phase, .preparing)
        XCTAssertNil(session.release())
        XCTAssertTrue(session.prepared(id))
        XCTAssertEqual(session.phase, .idle)
        XCTAssertFalse(session.recordingStarted(id))
        XCTAssertNotNil(session.begin(ready: true))
    }

    func testFailureEmptyResultAndRetry() {
        var session = DictationSession()
        let first = session.begin(ready: true)!
        XCTAssertTrue(session.failed(first))
        let second = session.begin(ready: true)!
        XCTAssertTrue(session.recordingStarted(second))
        XCTAssertEqual(session.release(), second)
        XCTAssertFalse(session.recognized(second, hasText: false))
        XCTAssertEqual(session.phase, .idle)
        XCTAssertNotNil(session.begin(ready: true))
    }

    func testRepeatedPressDoesNotRestartSession() {
        var session = DictationSession()
        let id = session.begin(ready: true)!
        XCTAssertNil(session.begin(ready: true))
        XCTAssertEqual(session.id, id)
        XCTAssertTrue(session.recordingStarted(id))
        XCTAssertNil(session.begin(ready: true))
        XCTAssertEqual(session.release(), id)
        XCTAssertNil(session.release())
    }

    func testHoldGestureSuppressesAutorepeatAndMatchingKeyUpAfterModifierRelease() {
        var gesture = DictationGesture()
        let hotkey = Hotkey.defaultDictation
        XCTAssertEqual(gesture.handle(.down(49, repeatKey: false), modifiers: [.control, .option], hotkey: hotkey), .begin)
        XCTAssertEqual(gesture.handle(.down(49, repeatKey: true), modifiers: [.control, .option], hotkey: hotkey), .consume)
        XCTAssertEqual(gesture.handle(.modifiers, modifiers: [.control], hotkey: hotkey), .endPassingEvent)
        XCTAssertEqual(gesture.handle(.down(49, repeatKey: true), modifiers: [.control], hotkey: hotkey), .consume)
        XCTAssertEqual(gesture.handle(.up(49), modifiers: [], hotkey: hotkey), .consume)
        XCTAssertEqual(gesture.handle(.up(12), modifiers: [], hotkey: hotkey), .pass)
    }

    func testResetAfterLostKeyUpPreservesOrdinarySpaceAndNextHold() {
        var gesture = DictationGesture()
        XCTAssertEqual(gesture.handle(.down(49, repeatKey: false), modifiers: [.control, .option], hotkey: .defaultDictation), .begin)
        // The tap is paused or shortcut recording takes over before key-up.
        gesture.reset()
        XCTAssertEqual(gesture.handle(.down(49, repeatKey: false), modifiers: [], hotkey: .defaultDictation), .pass)
        XCTAssertEqual(gesture.handle(.up(49), modifiers: [], hotkey: .defaultDictation), .pass)
        XCTAssertEqual(gesture.handle(.down(49, repeatKey: false), modifiers: [.control, .option], hotkey: .defaultDictation), .begin)
        XCTAssertEqual(gesture.handle(.up(49), modifiers: [.control, .option], hotkey: .defaultDictation), .end)
    }

    func testResetClearsCancelledModifierHoldAwaitingUnobservedRelease() {
        var gesture = DictationGesture()
        let hotkey = Hotkey(modifiers: [.control, .shift])
        XCTAssertEqual(gesture.handle(.modifiers, modifiers: [.control, .shift], hotkey: hotkey), .begin)
        gesture.cancelHold()
        // All modifiers are released while this tracker is disconnected.
        gesture.reset()
        XCTAssertEqual(gesture.handle(.modifiers, modifiers: [.control, .shift], hotkey: hotkey), .begin)
        XCTAssertEqual(gesture.handle(.modifiers, modifiers: [], hotkey: hotkey), .endPassingEvent)
    }

    func testMissedModifierReleaseDoesNotConsumeAnUnrelatedKey() {
        var gesture = DictationGesture()
        XCTAssertEqual(gesture.handle(.down(49, repeatKey: false), modifiers: [.control, .option], hotkey: .defaultDictation), .begin)
        XCTAssertEqual(gesture.handle(.up(12), modifiers: [], hotkey: .defaultDictation), .endPassingEvent)
        XCTAssertEqual(gesture.handle(.up(49), modifiers: [], hotkey: .defaultDictation), .consume)
    }

    func testModifierOnlyHoldAndEscapeCannotRestartUntilRelease() {
        var gesture = DictationGesture()
        let hotkey = Hotkey(modifiers: [.control, .shift])
        XCTAssertEqual(gesture.handle(.modifiers, modifiers: [.control], hotkey: hotkey), .pass)
        XCTAssertEqual(gesture.handle(.modifiers, modifiers: [.control, .shift], hotkey: hotkey), .begin)
        gesture.cancelHold()
        XCTAssertEqual(gesture.handle(.modifiers, modifiers: [.control, .shift], hotkey: hotkey), .pass)
        XCTAssertEqual(gesture.handle(.modifiers, modifiers: [.control], hotkey: hotkey), .pass)
        XCTAssertEqual(gesture.handle(.modifiers, modifiers: [], hotkey: hotkey), .pass)
        XCTAssertEqual(gesture.handle(.modifiers, modifiers: [.control, .shift], hotkey: hotkey), .begin)
    }

    func testHotkeyValidationRejectsBareKeysAndOverlappingModifierGestures() {
        XCTAssertNotNil(Hotkey(keyCode: 49).dictationValidationError(convert: .defaultConvert, toggleAuto: nil))
        XCTAssertNotNil(Hotkey(modifiers: [.option]).dictationValidationError(convert: .defaultConvert, toggleAuto: nil))
        XCTAssertNotNil(Hotkey(modifiers: [.control]).dictationValidationError(convert: .defaultDictation, toggleAuto: nil))
        XCTAssertNil(Hotkey.defaultDictation.dictationValidationError(convert: .defaultConvert, toggleAuto: nil))
        XCTAssertNil(Hotkey(modifiers: [.control, .shift]).dictationValidationError(convert: .defaultConvert, toggleAuto: nil))
    }

    func testModelControlCharactersCannotSubmitOrTabAway() {
        XCTAssertEqual(DictationText.insertionText("  Привет!\n\r\tЭто  тест.\u{0}\u{1b}  "), "Привет! Это тест.")
        XCTAssertEqual(DictationText.insertionText("\n\t\u{0}"), "")
    }

    func testResetAfterDictationPreventsUndoAndNextSpaceCorrection() {
        let core = EngineCore(detector: Detector(), snippets: SnippetStore())
        for ch in "ghbdtn" { _ = core.handle(.char(ch)) }
        _ = core.handle(.boundary(" "))
        _ = core.handle(.reset)
        XCTAssertEqual(core.handle(.hotkey(.convert)).command, .none)
        XCTAssertEqual(core.handle(.boundary(" ")).command, .none)
    }
}
