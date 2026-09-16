<!-- autopilot:start -->
# Mac Layout Switcher

Аналог Punto Switcher / Caramba Switcher для macOS: меню-бар-приложение,
которое замечает текст в неверной раскладке («ghbdtn» → «привет»),
переключает раскладку и перепечатывает слово. Плюс настраиваемые горячие
клавиши (конвертация/откат и вкл-выкл авто; дефолт конвертации — одиночный
Option), автозамена по шаблонам, звуки. Пары языков — RU/EN. Дневника набора нет.
Swift 5.9 / SwiftPM, без Xcode-проекта. Ядро без внешних зависимостей; для диктовки G14 — отдельный нативный helper GigaSTT/ONNX (ADR 0012).

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
| `swift test` | 71 тест ядра `SwitcherCore` (зелёные на Linux); один класс — `swift test --filter EngineCoreTests` |
| `swift build` | Сборка обоих target'ов (на Linux macOS-слой — пустой executable) |
| `bash -n build.sh` / `bash -n build-dmg.sh` | Шеллчек сборочных скриптов — единственная их проверка на Linux |
| `./build.sh` | ТОЛЬКО macOS 13+ с Xcode CLT (`xcode-select --install`): релиз + `dist/MacLayoutSwitcher.app` (ad-hoc подпись) |
| `./build-dmg.sh` | ТОЛЬКО macOS: собирает `.app` (через `build.sh`, если его нет; `--rebuild` — заново) и упаковывает в `dist/MacLayoutSwitcher.dmg` |
| `open dist/MacLayoutSwitcher.app` | Запуск .app (первый раз — правый клик по .app → «Открыть») |

## Структура

```
Package.swift                 3 target'а: SwitcherCore, MacLayoutSwitcher (exe), SwitcherCoreTests
build.sh                      сборка .app в dist/ + ad-hoc codesign (только macOS)
build-dmg.sh                  упаковка .app в dist/MacLayoutSwitcher.dmg (только macOS)
Sources/
  SwitcherCore/               ядро, платформонезависимое (тестируется на Linux)
    Lang.swift KeyMap.swift KeyMap-раскладки, DetectorBigrams.swift-таблицы
    WordBuffer.swift Detector.swift SnippetStore.swift EngineCore.swift
    Hotkey.swift              модель настраиваемой горячей клавиши (matches/displayName)
  MacLayoutSwitcher/          macOS-слой, весь под #if os(macOS)
    main.swift Engine.swift Config.swift
    System/  EventTap Typist LayoutSwitcher SecureInput FrontApp
             KeyStroke KeyTranslator Permissions LoginItem (автозапуск, SMAppService)
    UI/      StatusBarUI.swift Sounds.swift HotkeyRecorderWindow.swift
Tests/SwitcherCoreTests/      XCTest, только через публичный шов SwitcherCore
```

Настройки — `~/Library/Application Support/MacLayoutSwitcher/`: `config.json`
(`AppConfig`: autoSwitch/sounds/excludedApps/undoThreshold/convertHotkey/
toggleAutoHotkey/launchAtLogin), `snippets.json`, `exclusions.json`, `undo-counts.json`
(счётчики отмен per-word).

## Ключевые файлы

- `Sources/MacLayoutSwitcher/main.swift` — точка входа: `NSApplication(.accessory)`, `AppDelegate` (онбординг разрешений → старт Engine + меню-бар; открывает окно рекордера хоткеев).
- `Sources/SwitcherCore/EngineCore.swift` — вся логика решений «что сделать на событие»; шов тестов. Ниже это `EngineCore`, а не macOS-`Engine`. `InputEvent.hotkey(HotkeyAction{convert,toggleAuto})` — абстрактное хоткей-событие; порог отмен (`undoThreshold`, счётчики `undoCounts`) тоже здесь.
- `Sources/SwitcherCore/Hotkey.swift` — модель настраиваемой клавиши: `keyCode: UInt16?` (nil = только модификатор) + `Set<Modifier>`; `matches(keyCode:modifiers:)` (точное сравнение) и `displayName` для меню/окна. Платформонезависима, покрыта тестами.
- `Sources/MacLayoutSwitcher/Engine.swift` — macOS-обвязка: `EventTap`→`KeyStroke`→события `EngineCore`→исполнение через `Typist`/`LayoutSwitcher`; детекция тапа модификаторов, сопоставление с хоткеями через `Hotkey.matches`, автопауза, персист undo-counts.json.
- `Sources/MacLayoutSwitcher/UI/HotkeyRecorderWindow.swift` — окно «Горячие клавиши…»: две строки (конвертация/откат, вкл-выкл авто), «Записать» ловит следующее сочетание локальным NSEvent-монитором, «Сброс»; пишет в общий `Config`, работающий `Engine` читает живьём (перезапуск не нужен).
- `Sources/MacLayoutSwitcher/System/EventTap.swift` — CGEventTap АКТИВНЫЙ (`.defaultTap`): handler возвращает `TapDecision` (`.pass`/`.suppress`), свою синтетику пропускает по маркеру без обработки, re-enable после timeout.
- `Sources/MacLayoutSwitcher/System/Typist.swift` — синтетический ввод на своей последовательной очереди: `replaceLastWord(len:with:)` (Backspace-серия + юникод) и `send(KeyPress)` — отправка ЗАРАНЕЕ созданного нажатия (`makeKeyPress(keyCode:flags:)` / `makeUnicodePress(_:)`, синхронно, `nil` = система отказала) строго после всего поставленного раньше; `isBusy` — очередь ещё не опустела.
- `Sources/MacLayoutSwitcher/Config.swift` — `AppConfig` (autoSwitch/sounds/excludedApps/undoThreshold/convertHotkey/toggleAutoHotkey/launchAtLogin, свой `init(from:)` — старый config.json без новых полей грузится) + пути к config/snippets/exclusions/undo-counts JSON и load/save undo-counts. `launchAtLogin: Bool` (дефолт false) — лишь ЖЕЛАЕМОЕ состояние автозапуска; факт спрашивается у системы (`LoginItem`).
- `Sources/MacLayoutSwitcher/System/LoginItem.swift` — обёртка `SMAppService.mainApp` (`enable`/`disable`/`isEnabled`/`requiresApproval`/`openLoginItemsSettings`), `@available(macOS 13.0, *)`. Источник истины по автозапуску — `SMAppService.status`, а НЕ config: пользователь мог снять объект входа в Системных настройках. Ошибки `enable/disable` не глотаются — пробрасываются наверх.
- `Sources/SwitcherCore/Detector.swift` (+ `DetectorBigrams.swift`) — вердикт RU/EN/unsure, исключения.

## Архитектура

Поток: клавиша → `EventTap` (CGEvent) → `Engine.handle(keyEvent:)` транслирует
`KeyStroke` в `InputEvent` (`char/backspace/boundary/hotkey(HotkeyAction)/reset`)
→ `EngineCore.handle(_:)` копит слово в `WordBuffer` и возвращает `EngineOutcome`
(`command: .none | .replaceLast(len,with,switchTo)` + `excludedWordToPersist` +
`undoCountUpdate` + `reinjectSeparator`) → `Engine.execute` вызывает
`LayoutSwitcher.select`, затем (если `reinjectSeparator` непуст) СНАЧАЛА
синхронно создаёт событие досылки (`Typist.makeKeyPress` по keyCode/флагам
исходного нажатия) и только при успехе ставит `replaceLastWord` + `send(press)`
и возвращает tap'у `.suppress`; не создалось — `.pass` + NSLog, исправление в
legacy-варианте (слово вместе с доставленным разделителем). Разделитель не
теряется никогда.

Шов — публичный API `SwitcherCore` (`EngineCore`/`Hotkey`/…): платформонезависимо
и детерминированно, поэтому тестируется на Linux; macOS-`Engine` только переводит
CGEvent-мир в события ядра и обратно. `EngineCore.init` принимает `now:` для теста
окна отката.

Хоткеи. `Engine` не знает про Option как таковой: он собирает описание нажатия
(`keyCode` + набор модификаторов) — из тапа чистых модификаторов
(`modifierTapEvent`, жест с `peak`/`dirty`) или из keyDown с модификаторами — и
спрашивает `config.convertHotkey`/`toggleAutoHotkey` через `Hotkey.matches`.
Совпало → `.hotkey(.convert)` (приоритет) или `.hotkey(.toggleAuto)`. Дефолт
`convertHotkey` — `[.option]` (одиночный Option, обратная совместимость),
`toggleAutoHotkey` — не назначен. Левый и правый вариант модификатора НЕ
различаются (обе Option → `.option`) — симметрично в `Engine` и в рекордере.
`.toggleAuto` обрабатывается ДО `guard isPaused` — переключает авто даже на
автопаузе, персистит config и дёргает `onAutoSwitchChanged` (галочка в меню).

На границе слова (`boundary`) `EngineCore` в порядке приоритета: (1) сниппет
`SnippetStore.expansion` — если есть, детектор к слову не применяется;
(2) при `autoSwitch` — `Detector.verdict` → авто-исправление; (3) иначе слово
остаётся кандидатом на ручной Option. Разделитель на `boundary` ещё НЕ
доставлен (активный tap перехватил его): `replaceLast(len: word.count)` стирает
только слово, а `EngineOutcome.reinjectSeparator` велит исполнителю дослать
разделитель ПОСЛЕ перепечатки. Legacy-режим `EngineCore(separatorAlreadyTyped:
true)` (ADR 0004: разделитель уже напечатан, стирается и перепечатывается
вместе со словом) сохранён для совместимости и покрыт тестом.

Конвертация/откат (`.hotkey(.convert)`, дефолтом — одиночный Option). В окне
`undoWindow` (5 с) после авто-исправления → откат всегда возвращает как было; в
исключения (`Detector.addExclusion`, персист `exclusions.json`) слово уходит НЕ
с первого раза, а по достижении порога `undoThreshold` (дефолт 3): каждый откат
инкрементит счётчик слова, при `>= порога` слово исключается и счётчик
сбрасывается. Счётчики per-word живут в `undo-counts.json` (ключ — слово в нижнем
регистре) и переживают перезапуск. Порог `1` воспроизводит прежнее поведение
(исключение с первого отката). Вне окна → ручная конвертация текущего/последнего
слова (кириллица → EN, иначе → RU, так повторный хоткей возвращает как было).

Автопауза считается на каждое событие: `core.isPaused = SecureInput.isActive ||
isExcludedApp()` (bundle id из `FrontApp` против `config.excludedApps`). На паузе
ядро молчит и не буферизует.

Своя синтетика `Typist` возвращается в tap — отсекается по маркеру
`EventTap.syntheticMarker = 0xC0FFEE` в `eventSourceUserData` (защита от цикла
перепечатки), не по времени.

Меню-бар (`StatusBarUI`) даёт колбэки: пауза = `engine.stop()/start()` (ручной
паузы внутри Engine нет), автопереключение = `setAutoSwitch` (пишет config;
`setAutoSwitchState` синхронизирует галочку, когда авто переключил хоткей),
звуки, тумблер «Запускать при входе» = `onToggleLaunchAtLogin` (шлёт ЖЕЛАЕМОЕ
состояние; `LoginItem` пробует enable/disable, факт возвращается галочке через
`setLaunchAtLoginState` — галочка по факту `LoginItem.isEnabled`, не по config),
«Горячие клавиши…» = `onOpenHotkeys` → `HotkeyRecorderWindow`, открыть
snippets.json/config.json. Настройки — `~/Library/Application Support/
MacLayoutSwitcher/` (config.json + snippets.json + exclusions.json +
undo-counts.json).

## Соглашения кода

- Ядро (`Sources/SwitcherCore/`) — без импортов платформы, компилируется на
  Linux. Весь `Sources/MacLayoutSwitcher/` (включая `System/`, `UI/`) целиком
  обёрнут `#if os(macOS)` … `#endif` — на Linux это пустой executable, `swift
  build`/`swift test` обязаны быть зелёными после каждой правки.
- Тесты — только через публичные сигнатуры `SwitcherCore` (шов один). macOS-код
  компиляцией не проверить: писать по документированным API, консервативно.
- Зависимости не добавлять без необходимости. Узкое исключение G14: закреплённый GigaSTT 2.17.0 только для speech-helper на macOS arm64; ядро остаётся без зависимостей. Нет инструмента → вернуть `BLOCKED`, ничего не ставить.
- JSON-файлы: битый/отсутствующий config → бэкап `.broken` рядом + дефолты;
  битый snippets/exclusions/undo-counts → пустой набор. config и undo-counts
  пишутся атомарно с `.sortedKeys`. Новые поля в `AppConfig` — только через
  `decodeIfPresent` с дефолтом (старый config.json обязан грузиться).

## Подводные камни

- Tap АКТИВНЫЙ (`.defaultTap`, с v1.2.0 — G12, ADR 0004 пересмотрен ADR 0011):
  разделитель на границе слова подавляется ТОЛЬКО когда ядро исправляет слово,
  и досылается `Typist.send` после перепечатки (тем же keyCode и флагами —
  Shift+Enter остаётся переносом строки). Хоткеи/flagsChanged — `.pass`. Колбэк
  обязан оставаться быстрым: решение = детектор на одном слове, без I/O —
  весь персист (`Config.save/saveUndoCounts/saveExclusions`) кодирует снимок
  на месте и пишет файл на фоновой `persistQueue`; `load*` ждут её (`sync {}`)
  — не звать `load` из колбэка tap'а.
- Гонка ввода во время перепечатки (~150–200 мс): пока `typist.isBusy`,
  пользовательские keyDown (буквы/Backspace/разделители/команды) подавляются
  и ПЕРЕИГРЫВАЮТСЯ той же очередью следом — в исходном порядке, с маркером
  синтетики (tap повторно не обработает), а ядро получает их сразу, в колбэке.
  Буква переигрывается юникодом (`makeUnicodePress` — то, что ядро уже
  получило), остальное — keyCode+флаги. Не удалось создать событие → обычный
  путь (`.pass`, ляжет посреди синтетики — лучше, чем потерять).
- Граница слова = ТОЛЬКО пробелы (` \t\n\r`). Пунктуация НЕ граница: клавиши
  `;,.[]` в EN дают буквы ЙЦУКЕН внутри слова (`cgfcb,j` = «спасибо»), детектор
  ждёт их частью слова. Не добавлять пунктуацию в `boundaryChars`.
- Звуки только на исправление/откат (клика клавиш нет — убран по просьбе пользователя);
  в паузе тишина сама собой: ядро не выдаёт replaceLast.
- `usleep` внутри колбэка tap'а вызвал бы `tapDisabledByTimeout` — вся синтетика
  `Typist` уходит на отдельную очередь. Не переносить печать в колбэк.
- Ad-hoc подпись (`codesign -s -`): без неё TCC не запомнит выданные разрешения
  между запусками. Gatekeeper при первом запуске ругнётся — правый клик по .app
  → «Открыть» (один раз). Нотаризации нет — это личная сборка.
- Приложению нужны ДВА разрешения (Accessibility + Input Monitoring); после
  выдачи — перезапуск (пункт меню «Я выдал разрешения»), TCC-доверие надёжнее
  подхватывается новым процессом.
- `dist/` пересобирается `build.sh` с нуля (`rm -rf` бандла) каждый раз.
- Хоткей с обычной клавишей (например ⌘⇧K) по-прежнему физически напечатается:
  Engine возвращает `.pass` для хоткеев (подавление в этом таске не вводилось,
  хотя активный tap теперь это позволяет). Для конвертации это не мешает (мы
  стираем и перепечатываем), но назначать «печатающий» keyCode-хоткей стоит
  осознанно — дефолт `[.option]` ничего не печатает.
- Левый и правый вариант модификатора НЕ различаются: рекордер и `Engine`
  сводят обе Option к `.option`. Правые `Modifier`-кейсы в модели есть, но
  назначить «только правый Option» нынешний слой не даст — так дефолт срабатывает
  на любой Option.
- `HotkeyRecorderWindow` и правки Engine/UI/main собраны ВСЛЕПУЮ (компиляции
  macOS-слоя на Linux нет). Вся проверяемая логика хоткеев вынесена в
  `SwitcherCore.Hotkey` и покрыта тестами; AppKit-обвязка — по документированным
  API, консервативно.
- Автозапуск: на современных macOS `SMAppService.mainApp.register()` часто НЕ
  бросает ошибку, а переводит статус в `.requiresApproval` (объект входа создан,
  но выключен, пока пользователь не подтвердит его в «Системные настройки →
  Основные → Объекты входа») — это НЕ ошибка. Приложение показывает подсказку и
  открывает панель «Объекты входа» (`openLoginItemsSettings`). Факт из
  `SMAppService.status` — источник истины, галочка меню ставится по факту
  (`LoginItem.isEnabled`), а не по желаемому config-флагу; `requiresApproval` →
  галочка НЕ загорается (не показываем ложный успех). `AppConfig.launchAtLogin`
  синхронизируется с фактом при старте и после каждой попытки.
- `Engine.reload()` НЕ переприменяет `undoThreshold` (в `EngineCore` он `let`) —
  правка порога в config.json подхватывается только перезапуском. Сами хоткеи,
  наоборот, читаются живьём из `Config` при каждом событии.

## Тесты

`swift test` — 71 XCTest через публичный SwitcherCore: прежние 58 и 13 тестов состояния/жестов/нормализации диктовки. Финальный прогон на Linux 2026-09-16 зелёный. На Mac есть Swift 6.1.2 и рабочая сборка, но CLT без XCTest: тесты запускаются на Linux-сервере. Микрофон/TCC/вставка в чужие поля — отдельная ручная приёмка.

- Иконка приложения: `Resources/AppIcon.svg` (утка) → `python3 tools/make-icns.py` → `Resources/AppIcon.icns`; build.sh кладёт её в бандл (CFBundleIconFile=AppIcon).
- Меню-бар показывает текущую раскладку текстом «RU»/«EN» (attributedTitle, в паузе серый + ⏸); обновление по DistributedNotificationCenter (TISNotifySelectedKeyboardInputSourceChanged) + колбэк Engine.onLayoutSwitched после select; поллинга нет.

- Короткие слова: `ShortWords.swift` — словари частотных RU/EN слов 1–4 букв; Detector проверяет их ДО порога длины и биграмм. Контекст (язык предыдущего слова) решает коллизии (of↔ща и т.п.) и обязателен для однобуквенных («plan b» не трогается, «Rfr ns b z» → «Как ты и я» по инерции).

## Диктовка G14 (v1.3.0, ADR 0012)

- Пользователь выбрал локальное распознавание GigaAM v3 и **удержание** хоткея: ⌃⌥Space записывает, отпускание распознаёт/вставляет. Esc отменяет. Сочетание меняется в существующем окне; конфликты/голые печатные клавиши отклоняются. Максимум 5 минут.
- Новый пункт «Диктовка…»: явная однократная загрузка 233 MB, SHA256/прогресс/отмена, затем разрешение микрофона. После настройки нужно заново удержать сочетание; запоздавшее разрешение не включает микрофон.
- GigaSTT 2.17.0 закреплён SwiftPM только на macOS arm64; отдельный Contents/Helpers/SpeechRecognizer связан статически с ONNX. Основная .app по-прежнему macOS13+, диктовка требует Apple Silicon/macOS13.4+ (реальный minimum OS XCFramework выше заявленного package13.0). Intel/Linux не скачивают бинарную зависимость.
- Helper выполняется Process с приватным CWD и относительным WAV; нет сетевого fallback. Все процессы/загрузки/AX/запись вне EventTap. Записи временные, удаляются при завершении/отмене; текста/аудио в логах нет. Модель живёт в Application Support/MacLayoutSwitcher/SpeechModels отдельно от обновляемого бандла.
- Sources/SwitcherCore/DictationSession.swift: публичные session/gesture и тесты; Sources/MacLayoutSwitcher/Speech/: coordinator/AVAudioRecorder/AX target; System/SpeechModelStore.swift и SpeechRecognitionProcess.swift; UI/DictationPanel.swift — неактивирующая панель.
- EventTap теперь слушает keyUp для пары хоткея. При остановке/старте tap и на границах рекордера сочетаний **полный reset** жеста и suppressedKeyUps: cancelHold сохраняет ожидаемый keyUp и здесь недостаточен (исправлено ревью P2).
- Вставка на общей очереди Typist, Unicode с маркером, без Enter/clipboard/автоконвертации. Контроль фокуса и Secure Input, reset буфера/undo. Если поле сменилось или AX не отдаёт выделение — панель результата с явной кнопкой «Копировать». Пауза/выход отменяют все операции; выход ждёт cleanup.
- Проверено: 71 Linux XCTest, Mac debug/release, настоящий офлайн ASR, поздняя речь после32с, тишина, ошибки/отмена/таймауты, подпись внутри DMG. Микрофон и вставка в реальные приложения ещё требуют ручной приёмки Ильи; v1.2.0 он также не проверял.
- iCloud FileProvider в Documents возвращает FinderInfo после codesign. Для проверяемого артефакта задавать `MLS_DIST_DIR` на временный каталог вне Documents и запускать `./build-dmg.sh --rebuild`. Скрипты понимают одинаковый override; DMG staging очищается от xattr и проверяется codesign до упаковки. Автообновление уже собирает во временной папке.

## Релиз новой версии (ОБЯЗАТЕЛЬНЫЙ ритуал)

Приложения пользователей проверяют raw `VERSION` с main GitHub. Любое изменение,
которое должно доехать до пользователей:
1. Бампни `VERSION` (semver, одна строка).
2. commit + `git push` (репо публичное: github.com/alimp01/mac-layout-switcher).
3. Обнови архив: `git archive --format=tar.gz --prefix=mac-layout-switcher/ -o /var/www/cat.alimp.space/mac-layout-switcher.tar.gz HEAD`
Не бампнул VERSION → приложения обновления НЕ увидят.

- Автообновление: Updater (raw VERSION с GitHub, при старте + раз в 24 ч + пункт меню)
  → алерт → tools/self-update.sh (скачивает main.tar.gz, собирает во временном,
  атомарно заменяет .app, перезапускает; лог ~/Library/Logs/MacLayoutSwitcher-update.log).
  После обновления TCC-разрешения выдаются заново (ad-hoc). Вне .app-бандла
  Updater обновление не предлагает.

## Репозиторий

GitHub: https://github.com/alimp01/mac-layout-switcher (публичный). Push по HTTPS,
креды в ~/.git-credentials (аккаунт alimp01). Публичный архив для скачивания на Mac:
https://cat.alimp.space/mac-layout-switcher.tar.gz (обновлять `git archive` после изменений).

## Как здесь работает Autopilot

Сборка ведётся навыком `/autopilot`. Требования, спецификация и таски — в `.autopilot/`.
Прогресс — `.autopilot/dashboard.html`. Правило: требование из `manifest.md`
может снять только пользователь.

Если работа продолжается — скажи «продолжи автопилот»: состояние поднимется
из `.autopilot/state.js`, переспрашивать ничего не нужно.
<!-- autopilot:end -->
