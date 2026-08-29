import XCTest
import Foundation
@testable import SwitcherCore

/// Тесты обобщённого хоткей-события `EngineCore` (таск 08): `.hotkey(.convert)`
/// воспроизводит прежнее поведение одиночного Option, `.hotkey(.toggleAuto)`
/// переключает автопереключение. Проверяется на Linux через публичный шов.
final class HotkeyEngineTests: XCTestCase {

    private func type(_ core: EngineCore, _ s: String) {
        for ch in s { _ = core.handle(.char(ch)) }
    }

    // MARK: - .convert = прежний optionTap

    func testConvertReproducesManualOption() {
        let core = EngineCore(detector: Detector(), snippets: SnippetStore())
        type(core, "ghbdtn")
        let first = core.handle(.hotkey(.convert))
        XCTAssertEqual(first.command,
            .replaceLast(len: 6, with: "привет", switchTo: .ru))
        // Повторный .convert возвращает как было.
        let second = core.handle(.hotkey(.convert))
        XCTAssertEqual(second.command,
            .replaceLast(len: 6, with: "ghbdtn", switchTo: .en))
    }

    func testConvertUndoStillHitsThresholdFromTask06() {
        let detector = Detector()
        // Порог 1 — прежнее поведение: отком в окне сразу исключает.
        let core = EngineCore(detector: detector, snippets: SnippetStore(),
                              undoWindow: 5, undoThreshold: 1)
        type(core, "ghbdtn")
        _ = core.handle(.boundary(" "))
        let out = core.handle(.hotkey(.convert))
        XCTAssertEqual(out.excludedWordToPersist, "ghbdtn")
        XCTAssertTrue(detector.isExcluded("ghbdtn"))
    }

    // MARK: - .toggleAuto

    func testToggleAutoFlipsAutoSwitch() {
        let core = EngineCore(detector: Detector(), snippets: SnippetStore(),
                              autoSwitch: true)
        _ = core.handle(.hotkey(.toggleAuto))
        XCTAssertFalse(core.autoSwitch)
        _ = core.handle(.hotkey(.toggleAuto))
        XCTAssertTrue(core.autoSwitch)
    }

    func testToggleAutoWorksEvenWhenPaused() {
        // Переключение авто — глобальная настройка, срабатывает и на паузе,
        // где обычные события ядро игнорирует.
        let core = EngineCore(detector: Detector(), snippets: SnippetStore(),
                              autoSwitch: true)
        core.isPaused = true
        _ = core.handle(.hotkey(.toggleAuto))
        XCTAssertFalse(core.autoSwitch)
    }

    func testToggleAutoOffThenBoundaryDoesNotAutoCorrect() {
        let core = EngineCore(detector: Detector(), snippets: SnippetStore(),
                              autoSwitch: true)
        _ = core.handle(.hotkey(.toggleAuto)) // выключили авто
        type(core, "ghbdtn")
        XCTAssertEqual(core.handle(.boundary(" ")).command, .none)
    }
}
