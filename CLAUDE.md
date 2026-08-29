<!-- autopilot:start -->
# Mac Layout Switcher

Аналог Punto Switcher / Caramba Switcher для macOS: меню-бар-приложение,
которое замечает текст в неверной раскладке («ghbdtn» → «привет»),
переключает раскладку и перепечатывает слово. Плюс ручной Option-хоткей,
автозамена по шаблонам, звуки. Пары языков — RU/EN. Дневника набора нет.
Swift 5.9 / SwiftPM, без Xcode-проекта, без внешних зависимостей.

Рабочая машина сборки — Linux; e2e-приёмка только на Mac. Ядро `SwitcherCore`
компилируется и тестируется на Linux, весь macOS-слой — под `#if os(macOS)`
(на Linux target даёт пустой executable).

## Команды (проверенные)

Swift не в PATH — в начале каждой bash-сессии:
```sh
export PATH=/home/claudebot/swift-toolchain/swift-6.0.3-RELEASE-ubuntu24.04/usr/bin:$PATH
```

| Команда | Что делает |
|---------|------------|
| `swift test` | 28 тестов ядра `SwitcherCore` (зелёные на Linux); один класс — `swift test --filter EngineCoreTests` |
| `swift build` | Сборка обоих target'ов (на Linux macOS-слой — пустой executable) |
| `bash -n build.sh` | Шеллчек `build.sh` — единственная проверка сборочного скрипта на Linux |
| `./build.sh` | ТОЛЬКО macOS 13+ с Xcode CLT (`xcode-select --install`): релиз + `dist/MacLayoutSwitcher.app` (ad-hoc подпись) |
| `open dist/MacLayoutSwitcher.app` | Запуск .app (первый раз — правый клик по .app → «Открыть») |

## Структура

```
Package.swift                 3 target'а: SwitcherCore, MacLayoutSwitcher (exe), SwitcherCoreTests
build.sh                      сборка .app в dist/ + ad-hoc codesign (только macOS)
Sources/
  SwitcherCore/               ядро, платформонезависимое (тестируется на Linux)
    Lang.swift KeyMap.swift KeyMap-раскладки, DetectorBigrams.swift-таблицы
    WordBuffer.swift Detector.swift SnippetStore.swift EngineCore.swift
  MacLayoutSwitcher/          macOS-слой, весь под #if os(macOS)
    main.swift Engine.swift Config.swift
    System/  EventTap Typist LayoutSwitcher SecureInput FrontApp
             KeyStroke KeyTranslator Permissions
    UI/      StatusBarUI.swift Sounds.swift
Tests/SwitcherCoreTests/      XCTest, только через публичный шов SwitcherCore
```

## Ключевые файлы

- `Sources/MacLayoutSwitcher/main.swift` — точка входа: `NSApplication(.accessory)`, `AppDelegate` (онбординг разрешений → старт Engine + меню-бар).
- `Sources/SwitcherCore/EngineCore.swift` — вся логика решений «что сделать на событие»; шов тестов. Ниже это `EngineCore`, а не macOS-`Engine`.
- `Sources/MacLayoutSwitcher/Engine.swift` — macOS-обвязка: `EventTap`→`KeyStroke`→события `EngineCore`→исполнение через `Typist`/`LayoutSwitcher`; детекция Option, автопауза.
- `Sources/MacLayoutSwitcher/System/EventTap.swift` — CGEventTap `.listenOnly`, фильтр своей синтетики по маркеру, re-enable после timeout.
- `Sources/MacLayoutSwitcher/System/Typist.swift` — синтетический ввод: Backspace-серия + печать юникодом на своей очереди.
- `Sources/MacLayoutSwitcher/Config.swift` — `AppConfig` (autoSwitch/sounds/excludedApps) + пути к config/snippets/exclusions JSON.
- `Sources/SwitcherCore/Detector.swift` (+ `DetectorBigrams.swift`) — вердикт RU/EN/unsure, исключения.

## Архитектура

Поток: клавиша → `EventTap` (CGEvent) → `Engine.handle(keyEvent:)` транслирует
`KeyStroke` в `InputEvent` (`char/backspace/boundary/optionTap/reset`) →
`EngineCore.handle(_:)` копит слово в `WordBuffer` и возвращает `EngineOutcome`
(`command: .none | .replaceLast(len,with,switchTo)` + `excludedWordToPersist`) →
`Engine.execute` вызывает `LayoutSwitcher.select` затем `Typist.replaceLastWord`.

Граница модулей — `EngineCore`: платформонезависимо и детерминированно, поэтому
тестируется на Linux; macOS-`Engine` только переводит CGEvent-мир в события ядра
и обратно. `EngineCore.init` принимает `now:` для теста окна отката.

На границе слова (`boundary`) `EngineCore` в порядке приоритета: (1) сниппет
`SnippetStore.expansion` — если есть, детектор к слову не применяется;
(2) при `autoSwitch` — `Detector.verdict` → авто-исправление; (3) иначе слово
остаётся кандидатом на ручной Option. Разделитель уже напечатан пользователем,
поэтому `replaceLast` стирает слово вместе с ним и перепечатывает оба.

Option: одиночный чистый тап (детектится в `Engine.optionTapEvent` по
`flagsChanged`). В окне `undoWindow` (5 с) после авто-исправления → откат +
слово уходит в исключения (`Detector.addExclusion`, персист `exclusions.json`).
Вне окна → ручная конвертация текущего/последнего слова (кириллица → EN, иначе
→ RU, так повторный Option возвращает как было).

Автопауза считается на каждое событие: `core.isPaused = SecureInput.isActive ||
isExcludedApp()` (bundle id из `FrontApp` против `config.excludedApps`). На паузе
ядро молчит и не буферизует; звук клика тоже молчит.

Своя синтетика `Typist` возвращается в tap — отсекается по маркеру
`EventTap.syntheticMarker = 0xC0FFEE` в `eventSourceUserData` (защита от цикла
перепечатки), не по времени.

Меню-бар (`StatusBarUI`) даёт колбэки: пауза = `engine.stop()/start()` (ручной
паузы внутри Engine нет), автопереключение = `setAutoSwitch` (пишет config),
звуки, открыть snippets.json/config.json. Настройки — `~/Library/Application
Support/MacLayoutSwitcher/` (config.json + snippets.json + exclusions.json).

## Соглашения кода

- Ядро (`Sources/SwitcherCore/`) — без импортов платформы, компилируется на
  Linux. Весь `Sources/MacLayoutSwitcher/` (включая `System/`, `UI/`) целиком
  обёрнут `#if os(macOS)` … `#endif` — на Linux это пустой executable, `swift
  build`/`swift test` обязаны быть зелёными после каждой правки.
- Тесты — только через публичные сигнатуры `SwitcherCore` (шов один). macOS-код
  компиляцией не проверить: писать по документированным API, консервативно.
- Зависимостей нет и не добавлять. Нет инструмента → вернуть `BLOCKED`, ничего
  не ставить.
- JSON-файлы: битый/отсутствующий config → бэкап `.broken` рядом + дефолты;
  битый snippets/exclusions → пустой набор. config пишется атомарно с
  `.sortedKeys`.

## Подводные камни

- Tap создан `.listenOnly` — событий не подавляет. Поэтому Enter-как-разделитель
  входит в перепечатку и в chat-полях (Slack/Telegram) может улететь как
  отправка; это осознанная плата, задокументирована в `Engine.swift`.
- Граница слова = ТОЛЬКО пробелы (` \t\n\r`). Пунктуация НЕ граница: клавиши
  `;,.[]` в EN дают буквы ЙЦУКЕН внутри слова (`cgfcb,j` = «спасибо»), детектор
  ждёт их частью слова. Не добавлять пунктуацию в `boundaryChars`.
- Звук клика молчит в паузе (secure input / приложение-исключение) — так задумано
  (`handle`: клик только при `!core.isPaused`), это не баг.
- `usleep` внутри колбэка tap'а вызвал бы `tapDisabledByTimeout` — вся синтетика
  `Typist` уходит на отдельную очередь. Не переносить печать в колбэк.
- Ad-hoc подпись (`codesign -s -`): без неё TCC не запомнит выданные разрешения
  между запусками. Gatekeeper при первом запуске ругнётся — правый клик по .app
  → «Открыть» (один раз). Нотаризации нет — это личная сборка.
- Приложению нужны ДВА разрешения (Accessibility + Input Monitoring); после
  выдачи — перезапуск (пункт меню «Я выдал разрешения»), TCC-доверие надёжнее
  подхватывается новым процессом.
- `dist/` пересобирается `build.sh` с нуля (`rm -rf` бандла) каждый раз.

## Тесты

`swift test` — 28 тестов в `Tests/SwitcherCoreTests/`: `EngineCoreTests` (11,
поток решений + окно отката через инъекцию `now:`), `KeyMapTests` (5),
`DetectorTests` (5), `SnippetStoreTests` (4), `WordBufferTests` (3). macOS-слой
тестами не покрыт (компиляции нет на Linux) — только ручной чек-лист в
`README.md`.

## Как здесь работает Autopilot

Сборка ведётся навыком `/autopilot`. Требования, спецификация и таски — в `.autopilot/`.
Прогресс — `.autopilot/dashboard.html`. Правило: требование из `manifest.md`
может снять только пользователь.

Если работа продолжается — скажи «продолжи автопилот»: состояние поднимется
из `.autopilot/state.js`, переспрашивать ничего не нужно.
<!-- autopilot:end -->
