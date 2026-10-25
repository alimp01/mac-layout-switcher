# G26 — восстановление работы установленного приложения

## Problem Statement
После1.4.8 ghbdtn не исправился автоматически, Option без выделения показал
«Текст не изменён: Редактор не предоставил доступное поле ввода». Установленный
бинарник exact reviewed1.4.8, один процесс1462 на25.10. Старые fixturePASS
не доказывают работу реального системного поиска поля. Пользователь просит
проверить всё приложение и перестать перекладывать поиск одинаковых ошибок на него.

## Solution
Доказать и устранить причину отказа общей границы захвата поля. Проверить
последовательность от клавиатуры/микрофона до результата в редакторе, startup,
модель, хоткеи, настройки и обновление. Каждую найденную поломку привязать к
воспроизведению и самостоятельной проверке, отдельные дефекты — отдельные tickets.

## User Stories
1. Как пользователь, я набираю ghbdtn и получаю привет после Space/Enter.
2. Я нажимаю Option в конце слова без выделения и получаю конвертацию.
3. Выделение, undo и пустое поле сохраняют прежнее поведение.
4. Я могу быстро печатать и менять поле без удаления или чужой вставки.
5. Диктовка вставляется целиком один раз, без повторной загрузки готовой модели.
6. После запуска/обновления приложение либо работает, либо объясняет реальную причину.
7. Проверки охватывают реальные системные границы, а не только подставленный focus.

## Implementation Decisions
- Сначала проверить SystemDictationAccessibility focusedElement, AXFrontmost,
  ownerPID, timeouts/bootstrap и сравнить их с AppKit, Electron/WebKit semantics.
- Никаких blind clipboard/backspace/wholefield-write retry, утраты отмены или
  разрешения записи в чужую цель ради успешного теста.
- Ошибки focus/AX/trust должны быть различимы; техническая диагностика при
  необходимости ограничена metadata, без текста пользователя/записи аудио.
- Сохранить прежние реальные event, core, capture и insertion boundaries.
- Не расширять словарь (пользователь отменил), не менять продукт без причины.
- Оркестратор только planning/audit/release; свежий executor реализует T29.

## Testing Decisions
- Наивысший production seam с literal source/result. Baseline must fail for
  identified defect; final same scenario must pass. Проверять именно пропущенную
  системную границу, не подменять focusedElement готовым результатом в единственном
  доказательстве. Own in-process AppKit/WebKit fixtures allowed.
- Проверить nil/unsupported/error/timeout/frontend mismatch, bootstrap, field
  PID ownership, selection/value/caret/focus mutations, stale/foreign snapshots.
- AutoSpace/Enter/ShiftEnter/Tab; Option buffered/fallback/selected/undo/empty;
  rapid typing, all cancellation, readonly/secure; full dictation and no duplicates.
- Audit startup/config/hotkeys/model/update/autostart, fix only proven issues.
- Two fresh independent reviews, relevant native and fullLinux suite, fullspeech
  release/DMG. Actual real-app acceptance separately from fixture/compile PASS.

## Out of Scope
App Store, dictionary expansion, UX redesign, unrelated refactoring.

## Further Notes
CUA previously denied Codex (safety) and MLS (approval). Do not bypass using shell
AX, AppleScript, CDP, injected helper, another tool or agent. No private editor
probe or microphone capture. Root can test source and owned fixtures; real
app checks only via permitted CUA or user. Exact error supplied25.10; don't ask
user to repeat old repro/trigger/app questions. No universal fixed claim without evidence.

## Concrete audit additions — keyboard input25.10
Production normal Left translates to U+001C; during Typist busy Engine treats
it as printable, suppresses navigation and replays Unicode. RED exactfixture
/tmp/mls-keyboard-engine.d3iUU2/run.log yields "hello \u{1C}". Nonrepeat
navigation must cancel replacement, pass original key, never inject controls.
TapDisabled timeout/userinput currently emits ordinary contextChanged and does
not reset physical key ownership; lost keyUp leaves CmdShiftK consuming next
unmodifiedK. RED /tmp/mls-keyboard-engine.ypfecB/run.log. Distinguish actualtap
interruption from clicks and reset ownership/gestures for interruption safely.
T30 addresses these input-integrity paths; no changes to T29focus files.

## Concrete audit additions — lifecycle25.10
Updater quits immediately after launching selfupdate; curl/tar/build failure
exits script without reopening intact old app. Owned subprocessfixture
/tmp/mls-g26-lifecycle-audit/update-results.json reproduces offline6, badtar1,
build71 → originalexecutable preserved but no open; success restarts once.
Update failures must preserve/relaunch previousinstalledapp with visible reason;
never destructive rollback after confirmednewappstart, and no pathinjection.
Pause-resume main handler ignores engine.start false and advertises active UI.
T31 must reproduce rejectedstart at owned boundary and keep honest paused/error
state with recovery; startup failure also must stop partial workers.

Unfinished hotkey recording remains armed on window/application resign, keeping
all keyboard/dictation processing disabled. Owned actualwindow RED in
/tmp/mls-g26-lifecycle-audit; closing clears flag, resigning does not. T31 includes
cancelling recording on loss of editorwindow focus with callback/gesture cleanup.
