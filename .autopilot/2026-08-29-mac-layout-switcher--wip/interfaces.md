# Interfaces — общие границы сборки

## Правила проекта (для каждого субагента)

- Стек: Swift 5.9+, SwiftPM, без Xcode-проекта. Библиотека `SwitcherCore`
  компилируется и тестируется на **Linux** (рабочая машина сборки — Linux!);
  весь macOS-код — в executable `MacLayoutSwitcher`, исходники целиком под
  `#if os(macOS)`.
- Команды: `swift build`, `swift test` — из корня репозитория. Оба обязаны быть
  зелёными на Linux после каждого таска. Swift в PATH нет — в начале каждой
  bash-сессии: `export PATH=/home/claudebot/swift-toolchain/swift-6.0.3-RELEASE-ubuntu24.04/usr/bin:$PATH`.
- macOS-код проверить компиляцией негде — только документированные API,
  консервативный Swift, сверка сигнатур с открытыми проектами (RuSwitcher,
  keyswitcher) допустима, копирование кода — нет.
- Зависимостей нет и не добавлять. Отсутствует инструмент → вернуть `BLOCKED`,
  ничего не устанавливать (исключение: swift-toolchain ставит оркестратор).
- Не трогать: `.autopilot/` (кроме чтения), `CLAUDE.md` вне таблицы «Команды».
- Тесты — XCTest, только через публичные сигнатуры `SwitcherCore` (шов один).

## Границы, решённые в спецификации

| Модуль | Владеет | Выставляет | Прячет |
|---|---|---|---|
| `SwitcherCore.KeyMap` | карты ЙЦУКЕН↔QWERTY | `convert(_ s: String, to: Lang) -> String`, `enum Lang { case ru, en }` | сами таблицы соответствий |
| `SwitcherCore.Detector` | правила + биграммы + исключения | `verdict(for word: String) -> Verdict` (`enum Verdict { case ru, en, unsure }`), `addExclusion(_:)`, `isExcluded(_:)` | частотные таблицы, пороги |
| `SwitcherCore.SnippetStore` | шаблоны автозамены | `expansion(for abbrev: String) -> String?`, `load(from url:)` | формат хранения |
| `SwitcherCore.WordBuffer` | текущее набираемое слово | `append(char:)`, `boundary()`, `backspace()`, `var word: String`, `reset()` | правила границ слова |
| `SwitcherCore.EngineCore` (таск 04) | решение «что сделать на событие» | события `char/backspace/boundary/optionTap` → команды `replaceLast(len:with:switchTo:)/none/...` | окно отката, приоритет сниппетов |
| `app.EventTap` | перехват CGEvent | `start(handler:)`, `stop()`, маркер синтетики `0xC0FFEE` | создание tap, re-enable после timeout |
| `app.Typist` | синтетический ввод | `replaceLastWord(len: Int, with: String)` | Backspace-серия, unicode-печать, маркировка |
| `app.LayoutSwitcher` | системная раскладка | `current() -> Lang?`, `select(_ lang: Lang)` | TIS API |
| `app.Engine` | трансляция CGEvent ⇄ EngineCore, исполнение команд | `handle(keyEvent:)` | склейка, автопауза |
| `app.StatusBarUI` | меню и тумблеры | `show(state:)`, колбэки тумблеров | NSStatusItem |
| `app.Config` | config/snippets/exclusions JSON в `~/Library/Application Support/MacLayoutSwitcher/` | `load()`, `save()`, типизированные поля | пути, дефолты, миграции |

## Что построено (дописывается по мере закрытия тасков)

### Из таска 01 — каркас и ядро

- `enum Lang: String, Codable, Sendable { case ru, en }` (Sources/SwitcherCore/Lang.swift)
- `KeyMap.convert(_ s: String, to: Lang) -> String` — static; символы вне карты не трогаются; покрыты `;:'"[]{},.<>`, ё/Ё/`~, оба регистра
- `final class WordBuffer`: `init()`, `append(char: Character)`, `backspace()`, `boundary()`, `reset()`, `var word: String { get }`
- `final class SnippetStore`: `init()`, `load(from url: URL)`, `expansion(for abbrev: String) -> String?`; битый/отсутствующий JSON → пустой набор; повторный load битого файла обнуляет набор
- Executable `MacLayoutSwitcher` — пустая заглушка под `#if os(macOS)`
- Тесты: `swift test` (12), один класс — `swift test --filter <ClassName>`

### Из таска 02 — детектор (SwitcherCore)

- `public enum Verdict: Equatable, Sendable { case ru, en, unsure }`
- `public final class Detector { public init() }`
- `public func verdict(for word: String) -> Verdict` — алфавит → невозможные сочетания → биграммы; короткие(<3)/смешанные/с цифрами → `.unsure`; перекос в осторожность (редкая лексика вне корпуса → `.unsure`)
- `public func addExclusion(_ word: String)`, `public func isExcluded(_ word: String) -> Bool` (без учёта регистра)
- `public func load(from url: URL)` / `public func save(to url: URL)` — исключения, JSON-массив строк; битый/отсутствующий файл → пустой набор
- Биграммные таблицы — `DetectorBigrams.swift` (сгенерированы по Ципфу из top-300 частотных слов, источник в комментарии)

### Из таска 07 — .dmg-дистрибутив

- `build-dmg.sh` (macOS-скрипт): вход — опц. `--rebuild`; собирает `dist/MacLayoutSwitcher.app` через `./build.sh` при отсутствии, затем `dist/MacLayoutSwitcher.dmg` (staging через mktemp+trap, симлинк `/Applications`, `hdiutil -format UDZO`). Константы `VOL_NAME`/`DMG_PATH`.
- `build.sh` — подсказка про `./build-dmg.sh` в конце
- README — раздел «Установка через .dmg» + предупреждение про первый запуск без нотаризации
- Не запускался (hdiutil только на macOS), только `bash -n`

### Из таска 06 — порог отмен перед авто-исключением

- `EngineCore.init(..., undoThreshold: Int = 3, undoCounts: [String:Int] = [:], now:)` — ключи undoCounts нормализуются к нижнему регистру
- `EngineOutcome.undoCountUpdate: (word: String, count: Int)?` — обновлённый/сброшенный счётчик для персиста; ручной `==` (кортеж блокирует синтез Equatable)
- `AppConfig.undoThreshold: Int` (дефолт 3); custom `init(from:)` — старый config.json без поля грузится
- `Config.undoCountsURL`, `loadUndoCounts() -> [String:Int]`, `saveUndoCounts(_:)` — undo-counts.json, битый/отсутствующий → пустой словарь
- Поведение: откат считает отмены per-word; < порога — просто откат без исключения; >= порога — addExclusion + excludedWordToPersist + сброс счётчика. Порог 1 = прежнее поведение
- Грабля: `Engine.reload()` не переприменяет undoThreshold (в EngineCore он `let`) — правка порога подхватывается перезапуском

### Из таска 05 — UI, звуки, сборка (весь под `#if os(macOS)`)

- `final class Sounds { init(enabled: Bool); var enabled: Bool; playKey(); playCorrection(); playUndo() }` — системные звуки NSSound
- `final class StatusBarUI: NSObject { struct State{paused,autoSwitch,sounds}; init(state:version:); install(); show(state:); onTogglePause/onToggleAutoSwitch/onToggleSounds/onOpenSnippets/onOpenConfig/onQuit }`
- `Engine.sounds: Sounds?` — аддитивная инъекция звуков в handle (звук correction на авто/Option/сниппет, undo — по excludedWordToPersist)
- main.swift: NSApplication `.accessory` (LSUIElement), AppDelegate — онбординг разрешений + старт Engine; пауза = stop()/start() перехвата
- `build.sh` — `swift build -c release` + сборка `MacLayoutSwitcher.app` в `dist/` + ad-hoc codesign; README со сравнением Punto/Caramba и чек-листом приёмки на Mac

### Из таска 04 — Engine (ядро на Linux + macOS-обвязка)

- `SwitcherCore.EngineCore` (тестируется на Linux):
  - `enum InputEvent { case char(Character), backspace, boundary(Character), optionTap, reset }`
  - `enum EngineCommand { case none; case replaceLast(len: Int, with: String, switchTo: Lang?) }`
  - `struct EngineOutcome { let command; let excludedWordToPersist: String? }`
  - `final class EngineCore { init(detector:snippets:autoSwitch:undoWindow:now:); var autoSwitch; var isPaused; func handle(_:) -> EngineOutcome }`
- macOS (`#if os(macOS)`): `struct AppConfig: Codable`; `final class Config { load/save/update; snippetsURL; exclusionsURL }` (config.json → дефолты + `.broken`-бэкап при битом); `final class Engine { init(config:); start()->Bool; stop(); setAutoSwitch(_:); reload(); handle(keyEvent:) }`
- Решение по долгу active-tap: EventTap оставлен `.listenOnly`; исправление стирает слово вместе с уже напечатанным разделителем и перепечатывает (подавлять нечего). Плата: Enter-как-разделитель может перепечататься в chat-полях — задокументировано в Engine.swift.
- Граница слова в macOS-Engine = только пробелы (space/tab/enter); пунктуация НЕ граница (клавиши `;,.[]` в EN дают буквы ЙЦУКЕН внутри слова).

### Из таска 03 — системный слой macOS (весь под `#if os(macOS)`)

- `struct KeyStroke { enum Kind { keyDown, flagsChanged }; kind, keyCode: UInt16, characters: String, flags: CGEventFlags, isAutorepeat: Bool }`
- `final class EventTap { static let syntheticMarker: Int64 = 0xC0FFEE; init(); start(handler: @escaping (KeyStroke) -> Void) -> Bool; stop() }` — tap в `.listenOnly`; для подавления событий (Option-хоткей) таску 04 нужен active-tap или доработка
- `final class Typist { init(); replaceLastWord(len: Int, with text: String) }` — асинхронно, своя очередь
- `enum LayoutSwitcher { static func current() -> Lang?; @discardableResult static func select(_ lang: Lang) -> Bool }`
- `enum SecureInput { static var isActive: Bool }`
- `enum FrontApp { static var bundleID: String? }`
- `enum Permissions { static var trusted: Bool; @discardableResult static func requestTrust() -> Bool; static func openAccessibilitySettings(); static func openInputMonitoringSettings() }`
