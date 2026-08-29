import XCTest
import Foundation
@testable import SwitcherCore

/// Тесты ядра склейки — единственный шов, проверяемый на Linux (spec).
/// Ожидаемые значения взяты из спецификации и разобраны вручную
/// («ghbdtn»→«привет»), а не вычислены тем же кодом, что под тестом.
final class EngineCoreTests: XCTestCase {

    /// Управляемые часы — окно отката проверяем без реального времени.
    private final class Clock {
        var t: Double = 1000
        func now() -> Double { t }
    }

    private func makeSnippetStore(_ json: String?) throws -> SnippetStore {
        let store = SnippetStore()
        guard let json else { return store }
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("engine-snips-\(UUID().uuidString).json")
        try json.write(to: url, atomically: true, encoding: .utf8)
        addTeardownBlock { try? FileManager.default.removeItem(at: url) }
        store.load(from: url)
        return store
    }

    private func type(_ core: EngineCore, _ s: String) {
        for ch in s { _ = core.handle(.char(ch)) }
    }

    // MARK: - Автоисправление

    func testWrongLayoutWordIsCorrectedAndLayoutSwitched() throws {
        let core = EngineCore(detector: Detector(), snippets: SnippetStore())
        type(core, "ghbdtn")
        let out = core.handle(.boundary(" "))
        // «ghbdtn» + пробел → «привет» + сохранённый пробел, раскладка в RU.
        XCTAssertEqual(out.command,
            .replaceLast(len: 7, with: "привет ", switchTo: .ru))
    }

    func testValidWordIsLeftUntouched() throws {
        let core = EngineCore(detector: Detector(), snippets: SnippetStore())
        type(core, "hello")
        let out = core.handle(.boundary(" "))
        XCTAssertEqual(out.command, .none)
    }

    func testCorrectionOnlyAtWordBoundaryNotMidWord() throws {
        let core = EngineCore(detector: Detector(), snippets: SnippetStore())
        // Пока разделитель не пришёл — никаких команд.
        for ch in "ghbdtn" {
            XCTAssertEqual(core.handle(.char(ch)).command, .none)
        }
    }

    // MARK: - Откат по Option

    func testOptionUndoesAutoCorrectionWithinWindowAndExcludes() throws {
        let clock = Clock()
        let detector = Detector()
        // Порог 1 = прежнее поведение: один откат в окне сразу исключает.
        let core = EngineCore(detector: detector, snippets: SnippetStore(),
                              undoWindow: 5, undoThreshold: 1, now: clock.now)
        type(core, "ghbdtn")
        _ = core.handle(.boundary(" "))
        clock.t += 3 // в пределах 5 с
        let out = core.handle(.hotkey(.convert))
        XCTAssertEqual(out.command,
            .replaceLast(len: 7, with: "ghbdtn ", switchTo: .en))
        XCTAssertEqual(out.excludedWordToPersist, "ghbdtn")
        XCTAssertTrue(detector.isExcluded("ghbdtn"))
        // После отката слово больше не исправляется автоматически.
        type(core, "ghbdtn")
        XCTAssertEqual(core.handle(.boundary(" ")).command, .none)
    }

    func testOptionOutsideWindowDoesNotUndo() throws {
        let clock = Clock()
        let core = EngineCore(detector: Detector(), snippets: SnippetStore(),
                              undoWindow: 5, now: clock.now)
        type(core, "ghbdtn")
        _ = core.handle(.boundary(" "))
        clock.t += 6 // окно истекло
        let out = core.handle(.hotkey(.convert))
        XCTAssertNil(out.excludedWordToPersist)
    }

    func testUndoBelowThresholdDoesNotExcludeButStillCorrects() throws {
        let clock = Clock()
        let detector = Detector()
        let core = EngineCore(detector: detector, snippets: SnippetStore(),
                              undoWindow: 5, undoThreshold: 3, now: clock.now)

        // Первый откат: слово возвращается, но в исключения НЕ уходит.
        type(core, "ghbdtn")
        _ = core.handle(.boundary(" "))
        clock.t += 1
        let first = core.handle(.hotkey(.convert))
        XCTAssertEqual(first.command,
            .replaceLast(len: 7, with: "ghbdtn ", switchTo: .en))
        XCTAssertNil(first.excludedWordToPersist)
        XCTAssertFalse(detector.isExcluded("ghbdtn"))
        XCTAssertEqual(first.undoCountUpdate?.word, "ghbdtn")
        XCTAssertEqual(first.undoCountUpdate?.count, 1)

        // Слово всё ещё исправляется автоматически (не исключено).
        type(core, "ghbdtn")
        clock.t += 1
        XCTAssertEqual(core.handle(.boundary(" ")).command,
            .replaceLast(len: 7, with: "привет ", switchTo: .ru))

        // Второй откат — по-прежнему не исключает.
        clock.t += 1
        let second = core.handle(.hotkey(.convert))
        XCTAssertNil(second.excludedWordToPersist)
        XCTAssertEqual(second.undoCountUpdate?.count, 2)
        XCTAssertFalse(detector.isExcluded("ghbdtn"))

        // Третий откат — достигнут порог: исключает и сбрасывает счётчик.
        type(core, "ghbdtn")
        clock.t += 1
        _ = core.handle(.boundary(" "))
        clock.t += 1
        let third = core.handle(.hotkey(.convert))
        XCTAssertEqual(third.excludedWordToPersist, "ghbdtn")
        XCTAssertTrue(detector.isExcluded("ghbdtn"))
        XCTAssertEqual(third.undoCountUpdate?.word, "ghbdtn")
        XCTAssertEqual(third.undoCountUpdate?.count, 0)
    }

    func testUndoThresholdOfOneReproducesImmediateExclusion() throws {
        let clock = Clock()
        let detector = Detector()
        let core = EngineCore(detector: detector, snippets: SnippetStore(),
                              undoWindow: 5, undoThreshold: 1, now: clock.now)
        type(core, "ghbdtn")
        _ = core.handle(.boundary(" "))
        clock.t += 1
        let out = core.handle(.hotkey(.convert))
        XCTAssertEqual(out.excludedWordToPersist, "ghbdtn")
        XCTAssertTrue(detector.isExcluded("ghbdtn"))
    }

    func testUndoCountsAreIndependentPerWordAndCaseInsensitive() throws {
        let clock = Clock()
        let detector = Detector()
        // Начальные счётчики приходят из персиста; ключ «GHBDTN» в верхнем
        // регистре должен нормализоваться и совпасть с набранным «ghbdtn».
        let core = EngineCore(detector: detector, snippets: SnippetStore(),
                              undoWindow: 5, undoThreshold: 3,
                              undoCounts: ["GHBDTN": 2], now: clock.now)

        // Другое слово «cgfcb,j» (спасибо) считается независимо — первый откат
        // его не исключает.
        type(core, "cgfcb,j")
        _ = core.handle(.boundary(" "))
        clock.t += 1
        let other = core.handle(.hotkey(.convert))
        XCTAssertNil(other.excludedWordToPersist)
        XCTAssertFalse(detector.isExcluded("cgfcb,j"))

        // «ghbdtn» стартует с 2 (из персиста, регистронезависимо) → первый же
        // откат достигает порога 3 и исключает.
        type(core, "ghbdtn")
        clock.t += 1
        _ = core.handle(.boundary(" "))
        clock.t += 1
        let out = core.handle(.hotkey(.convert))
        XCTAssertEqual(out.excludedWordToPersist, "ghbdtn")
        XCTAssertTrue(detector.isExcluded("ghbdtn"))
    }

    // MARK: - Ручная конвертация по Option

    func testOptionConvertsInProgressWordAndTogglesBack() throws {
        let core = EngineCore(detector: Detector(), snippets: SnippetStore())
        type(core, "ghbdtn")
        let first = core.handle(.hotkey(.convert))
        XCTAssertEqual(first.command,
            .replaceLast(len: 6, with: "привет", switchTo: .ru))
        // Повторный Option возвращает как было.
        let second = core.handle(.hotkey(.convert))
        XCTAssertEqual(second.command,
            .replaceLast(len: 6, with: "ghbdtn", switchTo: .en))
    }

    func testOptionConvertsLastCompletedWord() throws {
        // Валидное английское слово детектор не трогает, но Option конвертирует
        // его безусловно, вместе с сохранённым разделителем.
        let core = EngineCore(detector: Detector(), snippets: SnippetStore())
        type(core, "hello")
        XCTAssertEqual(core.handle(.boundary(" ")).command, .none)
        let out = core.handle(.hotkey(.convert))
        XCTAssertEqual(out.command,
            .replaceLast(len: 6, with: "руддщ ", switchTo: .ru))
    }

    // MARK: - Сниппеты

    func testSnippetExpansionTakesPriorityOverDetector() throws {
        let store = try makeSnippetStore(#"{"сдр": "С днём рождения!"}"#)
        let core = EngineCore(detector: Detector(), snippets: store)
        type(core, "сдр")
        let out = core.handle(.boundary(" "))
        XCTAssertEqual(out.command,
            .replaceLast(len: 4, with: "С днём рождения! ", switchTo: nil))
    }

    // MARK: - Автопауза / сброс / тумблер

    func testPausedStaysSilentAndDoesNotBuffer() throws {
        let core = EngineCore(detector: Detector(), snippets: SnippetStore())
        core.isPaused = true
        type(core, "ghbdtn")
        XCTAssertEqual(core.handle(.boundary(" ")).command, .none)
        // Сняли паузу — старое слово не должно всплыть (буфер был сброшен).
        core.isPaused = false
        XCTAssertEqual(core.handle(.hotkey(.convert)).command, .none)
    }

    func testResetPreventsCorrection() throws {
        // Cmd/Ctrl-комбинация и автоповтор транслируются Engine'ом в .reset.
        let core = EngineCore(detector: Detector(), snippets: SnippetStore())
        type(core, "ghbdtn")
        _ = core.handle(.reset)
        XCTAssertEqual(core.handle(.boundary(" ")).command, .none)
    }

    func testAutoSwitchOffSilencesDetectorButOptionStillWorks() throws {
        let core = EngineCore(detector: Detector(), snippets: SnippetStore(),
                              autoSwitch: false)
        type(core, "ghbdtn")
        XCTAssertEqual(core.handle(.boundary(" ")).command, .none)
        // Option по-прежнему конвертирует последнее слово.
        let out = core.handle(.hotkey(.convert))
        XCTAssertEqual(out.command,
            .replaceLast(len: 7, with: "привет ", switchTo: .ru))
    }
}
