<!-- autopilot:start -->
# Mac Layout Switcher

Личный аналог Punto/Caramba для macOS, SwiftPM. RU/EN автоисправление,
конвертация/откат по Option, настраиваемые хоткеи, сниппеты, звуки только на
исправление, автозапуск, индикатор RU/EN и утка, самообновление, локальная
диктовка GigaAM v3. Дневника набора нет.

## Текущее состояние — 2026-10-10

Версия v1.4.3, G20: Option и автозамена используют проверяемый keyboard runtime,
сохранение первого слова/удержанного ввода, переключение пустого поля.
Предыдущая1.4.2, G19: видимый fallback диктовки, подготовка AX дерева,
проверяемая вставка и постоянная отмена права вставки при вмешательстве.
Предыдущая1.4.1, G18: системное покрытие восьми однобуквенных RU слов,
41 словарное дополнение, безопасные !?()/исключения, контекстные коллизии.
Предыдущие G15–G17: защита от чужого префикса перед ozon, одиночные
b/B/z/Z → и/И/я/Я, повторное использование модели с runtime cache,
автоматическая подготовка модели, конвертация выделения существующим хоткеем.
Актуальные статусы/доказательства — .autopilot/state.js, manifest.md,
dictation-insertion-spec.md /dictation-insertion-qa.md, word-coverage-qa.md
и input-repair-qa.md в каталоге прогона.
На Mac пользователя установлена1.4.3 (Info.plist проверен10.10); новая версия
не выпускалась, установленное приложение автоматически не заменяем.
Полный Linux XCTest95/95; native panel/adapter/debug/release passed;
mounted DMG1.4.3 version/codesign/helper проверены;
G20 keyboard/Typist/recovery panel и оба независимых ревью PASS;
пользователь сообщил ошибки скриншотами, а не подтвердил полную приёмку.

G21/T24 открыт: пользователь сообщает удаление слова без замены. Причина ещё
не доказана. Защитный поднабор сохраняет исходник, полную замену и held input
до явного Close; VERSION остаётся1.4.3, не публиковать как исправление доставки.
Frozen66file snapshot, native fullspeech, keyboard/CG/notice/G19 harnesses,
Linux95 и два независимых ревью поднабора PASS. См. deletion-repair-qa.md.
Живой CUA тест установленной1.4.3: собственный TextEdit ghbdtn+Space→Привет,
тёплый ChromeMDN textarea ghbdtn+Space→привет. Первый холодный ввод Chrome
не исправился. В этих полях deletion-only не воспроизведён. Приложение/поле
пользователя и триггер Option либо автоматика запрошены, ответа пока нет.
CG→NSEvent→NSTextView harness не доказывает WindowServer delivery. Не менять
транспорт/clipboard по недоказанной гипотезе и не закрывать G21 по recovery-only.

G20/T23 завершён для1.4.3, код d7b003d. Keyboard Target использует
общую AX границу G19: bounded bootstrap, direct/Unicode routing, единый
source/value snapshot и readback текста/каретки. confirmed/untouched/uncertain;
RPC выбора диапазона может примениться даже при ошибке, восстановление тоже
подтверждается. Uncertain блокирует Enter/Tab только текущей очереди; удержанный
ввод сохраняется в selectable/scrollable панели, не в clipboard.
Option: выделение → undo/буфер → свежий ограниченный word-before-caret → RU/EN.
Начальный bind не сбрасывает слово; очень ранний разделитель до первого AX
захвата проходит без поздней замены. Синхронный inputSequence отменяет отложенный
Option при новом вводе; AX/TIS/UI вне event tap.
keyboard-runtime-spec.md / keyboard-runtime-qa.md — текущие доказательства.

## Среда и команды

- Локальный checkout: work/mac-layout-switcher в текущей задаче Codex на Mac.
- Серверный checkout: /home/claudebot/mac-layout-switcher, ssh claudebot-server.
- Mac15.6.1 arm64, Swift6.1.2: native debug/release build доступен. CLT не
  содержит XCTest, поэтому тесты ядра выполняются на Linux в отдельном /tmp
  snapshot; основной checkout сервера не использовать как песочницу.
- Swift на сервере: export PATH=/home/claudebot/swift-toolchain/swift-6.0.3-RELEASE-ubuntu24.04/usr/bin:$PATH
- swift test — публичные тесты SwitcherCore; swift test --filter ClassName
  для targeted red/green. Последний полный прогон:95тестов,0ошибок; доказательства в state/QA.
- swift build — Mac app + native helper (на Linux пустой executable).
- ./build.sh — release .app; ./build-dmg.sh --rebuild — подписанный ad-hoc DMG.
- bash -n build.sh build-dmg.sh tools/self-update.sh — shell syntax.
- MLS_DIST_DIR задаёт каталог .app/.dmg; использовать временный каталог вне
  Documents. iCloud FileProvider может возвращать FinderInfo после codesign,
  а mmap ModuleCache/.git временами зависает. Надёжная финальная сборка —
  из git archive во временном каталоге вне Documents. Упаковщик очищает xattr
  staging и проверяет codesign --verify --deep --strict перед DMG.
- MLS_DISABLE_SPEECH=1 swift build позволяет проверить app без бинарной
  зависимости; SwiftPM при этом может удалить Package.resolved — восстановить
  точный файл HEAD, не коммитить случайное удаление. Финальный DMG включает speech.

## Работа через Autopilot

Любая доработка: дополнение в бриф → G## в manifest → spec/отдельный тикет →
свежий субагент-исполнитель → два независимых ревью (Spec/Standards) → коммит.
Оркестратор код проекта не пишет, работает с .autopilot/, CLAUDE.md и git.
Непересекающиеся зоны можно выполнять параллельно, интеграцию зависимых —
последовательно. Список concerns в state.js исторический; проверять, не
устарела ли находка после ADR0013. Строки manifest снимает только пользователь.
Навык доступен на Mac: /Users/ilyaalimpiev/Documents/Claude/.agents/skills/autopilot/SKILL.md.

## Архитектура и ключевые файлы

Sources/SwitcherCore — чистое платформонезависимое ядро без зависимостей.
Sources/MacLayoutSwitcher целиком под #if os(macOS). Package.swift подключает
закреплённый GigaSTT2.17.0 только speech-helper на Mac arm64. На Intel/Linux
Apple binary не скачивается. Основная app macOS13+, диктовка arm64/macOS13.4+.

- EventTap/KeyStroke/KeyTranslator: активный CGEventTap (.defaultTap), keyDown,
  keyUp, flagsChanged и события изменения контекста (клик/перетаскивание,
  прерывание tap). Перевод клавиш Carbon UCKeyTranslate. Своя синтетика
  помечена eventSourceUserData=0xC0FFEE и не возвращается в ядро.
- Engine переводит события в EngineCore, исполняет outcome через Typist,
  связывает конфигурацию, хоткеи и диктовку. Никакого AX/I/O/sleep в callback.
- EngineCore/WordBuffer/Detector/ShortWords/KeyMap: решения, язык, буфер,
  отмена. Приоритет на пробеле: snippets, авто-детектор, иначе кандидат ручной
  конвертации. Граница слова только пробельные символы; пунктуация может быть
  русскими буквами в неверной EN-раскладке (cgfcb,j=спасибо).
- EngineOutcome.expectedText содержит точный исходник для независимой проверки
  исполнителем. discardReplacement отменяет provisional undo teaching при
  отказе. Старый callback не должен сбрасывать состояние нового поля.
- InputFocusGuard: фоновые AX-снимки, отдельные permits фокуса и исправлений;
  быстрый reset по навигации. ReplacementSource проверяет пустой caret,
  UTF16 диапазон, точный текст и начало слова, а не только совпавший хвост.
- Typist: единая serial queue для targeted AX замены, реальных replay клавиш
  и диктовки. Исправление слова — проверенный диапазон и выбранный до записи
  direct AXSelectedText либо Unicode путь, exact readback текста/каретки.
  Полный AXValue чужого поля не перезаписывать. Backspace-цикла больше нет:
  прерывание цикла оставляло уже стёртый префикс (ADR0013).
- Пробел входит в проверяемую замену; Enter/Tab досылаются исходным keyCode и
  flags только после записи либо безопасного отказа в том же поле. Shift+Enter
  сохраняется. Legacy-перепечатки после доставленного Enter больше нет.
- InputReplayPolicy: физические клавиши за явно queued Tab/Enter следуют
  native-порядку до idle; автозамены в этой части очереди выключены. Ошибка
  исправления отменяет зависимые исправления. Uncertain останавливает Enter/Tab
  этой очереди; недоставленный ввод сохраняется в панели до явного Close.
- SelectionConverter/ConversionNotice: явная конвертация выделения вне tap,
  захват диапазона/текста, приоритет перед undo. Тот же проверяемый AX/Unicode путь;
  без clipboard/Enter. Отказ объясняется неактивирующим окном. KeyMap выбирает
  EN при наличии mapped Cyrillic, иначе RU; неизвестные символы и whitespace
  сохраняются, пунктуация физических RU-буквенных клавиш конвертируется.

## Ввод и ограничения

- reset, пауза, смена поля/клик/команда очищают слово/undo/язык. Enter/Tab
  принимают решение исправления, затем не оставляют undo для нового поля.
- Все восемь однобуквенных RU слов а/в/и/к/о/с/у/я исправляются из
  f/d/b/r/j/c/e/z с регистром и без контекста. Явный EN-контекст (plan b,
  drive C), исключения, правильные RU слова и I/a сохраняются. Свежая
  английская метка может быть ошибочно принята за RU: это языковое предпочтение.
- G18: 41 bounded lexical addition без снижения порогов; ShortWords1–4,
  15 длинных слов в Detector.everydayRussian. файл/BBC/BRB/RFC/XML защищены.
  ns↔ты, jq↔ой, herb↔руки, tv↔ем, ev↔ум, ble↔иду: свежий контекст не
  исправляет, предыдущий язык разрешает коллизию. jr/ye/tot сохраняют прежнее RU предпочтение.
- Нормализация только enclosing() затем trailing!?; (yt!) намеренно mixed.
  Не обрезать mapped punctuation ,.;:"[] и т.п. Bare exclusion защищает
  wrapped token; undo учит точный исходный токен, rollback не расширять.
  Полный исходник идёт в expectedText и KeyMap.
- Независимые frozen fixtures и baseline/final audit лежат в
  .autopilot/2026-08-29-mac-layout-switcher/audit/word-coverage/.
  459RU/692EN curated words отдельно от production-union; не выдавать за
  реальную точность. WordCoverageTests — literal регрессии, не генерировать
  ожидаемые пары из production словаря.
- Отсутствующий AXSelectedText допускает Unicode только при проверяемом поле.
  Без доступного источника/диапазона исходный ввод проходит без замены; Option
  объясняет отказ и может переключить RU/EN. Начальный bind не стирает слово;
  первый разделитель до готовности AX может пройти исходным.
- AX+CGEvent не общая транзакция: остаётся узкое окно внешней смены фокуса
  между проверкой и доставкой Enter/Tab. Несвязанная навигация отменяет старые
  pending действия вместо переадресации в произвольное поле. ADR0013.
- Проверяющий командный процесс имеет AXIsProcessTrusted()==false. Нативная
  компиляция и pure core tests НЕ являются живой UI-приёмкой. Не выдавать
  разрешения принудительно, не печатать тесты в текущие тексты пользователя.
- Автопауза: SecureInput либо excludedApps, ядро не накапливает текст.
  toggleAuto работает и в автопаузе. Ручная пауза останавливает tap/диктовку.

## Настройки и пользовательские функции

Application Support/MacLayoutSwitcher/: config.json, snippets.json,
exclusions.json, undo-counts.json. Новые поля AppConfig — decodeIfPresent с
дефолтом. Битые файлы: config.broken/дефолты, прочие пустые наборы. Персист на
фоновой Config queue; не звать load из tap. load() синхронизирует очередь.

convertHotkey по умолчанию одиночный Option: выделение, иначе отмена свежего
автоисправления (5с), иначе текущее/последнее слово (в том числе свежий снимок поля); без слова
переключает RU/EN. Настройка через окно
«Горячие клавиши…». Левая/правая версии модификаторов схлопнуты. Диктовка —
Ctrl+Option+Space. Голые печатные клавиши/конфликты диктовки отклоняются.
undoThreshold по умолчанию3: исключение после повторных откатов, счётчики
переживают запуск. engine.reload не меняет let-порог, нужен перезапуск.

SMAppService.mainApp (macOS13): login item факт берётся из системы, не config;
requiresApproval объяснить и открыть настройки. RU/EN в меню — системное TIS
уведомление + onLayoutSwitched. SVG→icns: tools/make-icns.py, иконка утка.

## Диктовка GigaAM v3

Удержание хоткея записывает, отпускание распознаёт и вставляет без Enter;
Esc отменяет, максимум5мин. Настраивается в общем окне хоткеев.
SpeechModels/gigaam-v3-e2e-2026-06-22 отдельно от обновляемого .app.
Первое открытие/удержание автоматически проверяет и при необходимости
загружает233МБ, с прогрессом/отменой. Ошибка не вызывает бесконечного повтора.
После подготовки/позднего разрешения нужна новая попытка удержания: микрофон
не включается сам. Существующие корректные файлы не перекачиваются.

Проверка размеров+SHA256 обязательна. Runtime создаёт
optimized_cache/v3_e2e_rnnt_encoder_int8_optimized.ort — это не порча модели!
Разрешены только эти производные cache dir/file, без symlinks/лишних моделей;
битый .ort runtime перестраивает из исходных файлов. T19 проверен реальным
повторным offline helper + checkInstalled, download/repair/cancel/offline.

Contents/Helpers/SpeechRecognizer — статически связанный ONNX helper.
SpeechRecognitionProcess запускает Process в приватном CWD с относительным
WAV, без сетевого fallback. Записи временные, удаляются; текст/аудио не логируют.
DictationSession/DictationGesture в core: session identity, отмена, hotkey
keyUp/autorepeat. reset жестов при остановке tap/рекордере хоткея обязательный.
DictationTarget проверяет защищённое поле/фокус/выделение; Typist выполняет
проверяемую вставку через AX/Unicode на общей очереди. Если поле поменялось или AX
недоступен, результат в панели с явным «Копировать»; автоматическая вставка
clipboard не трогает.

G19: прежний NSTextView имел нулевую ширину и скрывал непустой результат.
Теперь document width/container tracking задаются после layout, длинный текст
выделяется/прокручивается. tools/test-dictation-panel.sh воспроизводит productionUI.

DictationTarget сохраняет точный AXelement/PID/selection/value, отслеживает
изменения с hold (Engine.armInsertion) через permit, AXObserver и workspace/
physical events. Не принимать один PID, не выдумывать range(0,0), не писать
весь AXValue. Missing selection/value/capability/observation даёт причину fallback.
AXManualAccessibility включается bounded/off-main с повторным захватом.

Нативный AXSelectedText путь проверяет итоговый value. Распознанные
Chromium/Electron пакеты предпочитают Unicode: <=16UTF16/chunk, postToPid,
проверка точного нового value и caret перед следующей порцией. Реальный Codex
лежит /Applications/ChatGPT.app, bundleIDcom.openai.codex и переименованный
Codex Framework.framework — учтён. Не полагаться только на setter capability:
наследуемый selector не гарантирует реализацию действия web node.

Никаких повторов после попытки записи с неизвестным исходом. При частичной/
неподтверждённой доставке сохраняется ВЕСЬ результат с предупреждением проверить
поле перед копированием. Callback теперь DictationInsertionResult, не String suffix.
Readback подтверждает текст, CGEvent.post сам по себе — нет. Права отмены sticky,
монитор исходного snapshot остановить перед вставкой, поздние samples не должны
отменять собственные chunks. Ожидаемые value/selection notifications ограничены
по одному на write/150мс, focus/physical events всегда отменяют. Остаётся AX/CG
race и неоднозначность уведомлений собственного/внешнего изменения; не объявлять
атомарность. AX refcon живёт до удаления observer source на main run loop.

tools/test-dictation-adapter.sh компилирует production target с подставленным
AX boundary + собственным NSTextView: exact capture/mutation, permissions,
capabilities, delayed notifications, no-op/partial delivery, no retry, clipboard.
Это не живая AX+CG доставка в пользовательский Codex. Диагностический процесс
не имеет AX trust; не принуждать TCC и не печатать в пользовательских полях.

## Релиз — обязательно

1. Бамп VERSION, commit, git push в public https://github.com/alimp01/mac-layout-switcher.
2. Fast-forward чистого серверного checkout и git archive --format=tar.gz
   --prefix=mac-layout-switcher/ в /var/www/cat.alimp.space/mac-layout-switcher.tar.gz.
   Публиковать атомарно через временный файл + mv.
   Локальный HTTPS push может не иметь credentials; рабочий путь — git bundle
   с новыми коммитами, scp на сервер, fetch bundle + merge --ff-only чистого
   серверного checkout, git push origin main существующей серверной авторизацией.
3. Проверить raw VERSION main и содержимое публичного архива
   https://cat.alimp.space/mac-layout-switcher.tar.gz. Без VERSION клиенты не увидят релиз.
4. Mac DMG из финального кода, mounted read-only проверить версию,
   codesign --verify --deep --strict, helper, symlink Applications.

Updater проверяет raw VERSION при запуске/раз в сутки/по меню. По согласию
запускает Resources/self-update.sh: скачатьmain, собрать вtemp, атомарно
заменить.app, перезапустить. Лог ~/Library/Logs/MacLayoutSwitcher-update.log.
Вне.app обновление не предлагается. Подпись ad-hoc, DeveloperID/notarization
нет. После обновления TCC может снова запросить Accessibility/Input Monitoring;
микрофон — отдельно. Полную установленную.app пользователя не заменять молча
посреди набора: выдать обновление/DMG и точные шаги. Не обещать AppStore
совместимость (sandbox + cross-app AX + self-updater требуют отдельного проекта).
<!-- autopilot:end -->
