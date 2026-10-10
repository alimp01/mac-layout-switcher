# G21 / T24 — проверка исчезающей замены

Дата: 2026-10-10. Baseline release: 1.4.3 / 963b387. Planning: 61c7e16.

## Граница живой проверки — исправленная запись

- На Mac установлена 1.4.3; собственные TextEdit/MDN поля проверялись через CUA, без изменения установленного приложения, новых разрешений и пользовательских полей.
- Ранее записанные `ghbdtn+Space → Привет/привет` НЕ доказывают замену: исходник до разделителя не снимался. Контрольный набор без разделителя уже дал `привет`; read-only TIS показал RussianWin. Прежние утверждения о доказанной доставке в TextEdit/Chrome отозваны.
- Browser-extension ввод также не доказывает Mac EventTap. MDN тестовая вкладка закрыта; собственный `/tmp/mls-g21-input.rtf` сохранён и закрыт.
- Пользователь уточнил оба условия: «да во всех» приложениях и «при автоматическом исправлении после пробела/Enter». Тест физического Option отменён, повторный вопрос о триггере не нужен. Собственный `/tmp/MLS-Option-Test.rtf` использован для контроля раскладки; ещё открыт. CUA остановилась из-за заблокированного Mac, документ не закрыт.
- Локальная CGEvent → serialization → NSEvent → NSTextView проверка не подтверждает межпроцессную WindowServer доставку. Новые TCC разрешения/микрофон/пользовательские редакторы не используются.

## Воспроизведённая причина — автоматический autorepeat

Исполнитель получил RED в `/tmp/mls-g21-repeat.3xn__0zm/red.log`: настоящий `EventTap.process → KeyTranslator → Engine` и собственный NSTextView, исходник `руддщ` снят до разделителя. Повтор Space/Enter точно во время временного выделения проходит раннюю ветку `.reset`, инвалидирует право замены и нативно заменяет исходник разделителем. Итог `" "` вместо `"hello  "` либо `"\n"` вместо `"hello\n\n"`; обе AX/production Unicode ветки — 4/4 RED. Это воспроизводимая гонка production state machine; физическое совпадение с каждым случаем пользователя пока не доказано.

## Граница текущей доработки

Исполнитель добавляет сохранение исходного сегмента и полного текста замены при неподтверждённой попытке и проверяет настоящую генерацию CGEvent в production transport. Это защита восстановления и улучшение регрессии, а не доказанное исправление доставки. G21 / T24 остаются открытыми; VERSION и публичный релиз не меняются до установленной причины и проверки исправления.

## Проверки защитного поднабора

- Frozen `/tmp/mls-g21-native.3fapzn4w`: все 66 SHA256 совпали с checkout; root и оба независимых ревьюера проверили соответствие.
- Исполнитель: keyboard/notice/real CG transport, G19 adapter/panel PASS; полный native speech release PASS (43.16с свежая сборка, 4.94с финальная инкрементальная).
- Spec reviewer независимо повторил все пять native harnesses — PASS. Standards reviewer независимо повторил notice/retention/layout/clipboard — PASS.
- Root: Linux XCTest 95/95, 0 ошибок, из frozen payload; server scratch `/tmp/mls-g21-tests.fKQES6`, копия лога `/tmp/mls-g21-linux-test.log`. Серверный checkout не изменялся.
- Spec: защитный поднабор безопасен для коммита; критерии доказательства причины и исправления доставки не выполнены, закрытие G21/релиз запрещены по существу требований.
- Standards: 0 документированных нарушений, 0 существенных smells, нет blocking correctness/security замечаний к защитному поднабору.
- VERSION остаётся 1.4.3. Установленная версия и публичный архив не изменены; DMG для поднабора не выпускается.
- Защитный код закоммичен локально исполнителем: `c57e700f9f44f62dd79d2576e88300d994932ccb`. Это сохранение текста после отказа и regression payload, не исправление причины. Push не выполнялся.

## Независимый аудит транспорта

### Продолжение после «да во всех»

Свежий исполнитель `implement_deletion_system` проверил полный production
`Engine.handle` и его callbacks в scratch `/tmp/mls-g21-engine.wvh4ck3e`.
Direct AX fixture и настоящая CGEvent→serialization→NSEvent локальная доставка:
selected ghbdtn с prefix/tail, right Option после cold bind, повторный Option,
автоматическая Space, undo и повторная конвертация, удержанный/dirty Option,
ввод до deferred capture и после temporary selection — PASS. Ввод после выбора
диапазона безопасно отменил замену, replay сохранил ghbdtnx. Red deletion-only
не получен, исходники checkout исполнителем не изменены.

Граница scratch: transformed injection seams только для final post/frontPID/AX
adapter; EventTap registration и TIS — stubs. Engine handler/callback тела
неизменны, конфигурация временная; реальные global post/AX/физический Option
не использовались. Это интеграционное покрытие, не живая приёмка пользователя.

Freeze provenance: README.md, source-provenance.json, seams.patch, SHA256SUMS,
run.log в scratch. Все 29 исходных production/core файлов совпали с baseline
57f54d3. Root независимо повторил `/tmp/mls-g21-engine.wvh4ck3e/test-engine`
с логом root-run.log — exit0/PASS. Ни одного изменения проектного кода в этом
продолжении; Spec/Standards approvals protectivec57e700 сохраняют прежнюю границу.

Root metadata: один MLS PID33371, запуск10.10 после mtime бинарника08.10;
версия установленной.app1.4.3. Не обнаружены именованные процессы Punto,
Caramba, Whisper, Karabiner, BetterTouch или TextExpander. Это исключает только
очевидный старый процесс/второй известный корректор, не доказывает причину.

Позднее пользователь уточнил автоматический Space/Enter; Option fixture отменён.
Первоначальный аудит не включал separator autorepeat во время temporary selection.
Новая проверка выше воспроизвела именно этот пропущенный путь.

### Результаты прошлого аудитора

Аудитор `audit_deletion_transport` не нашёл безусловного удаления в Target: выбор диапазона предшествует одному AXSelectedText write либо Unicode replacement. Не найден доказанный универсальный дефект транспорта.

Apple допускает, что принимающий framework игнорирует Unicode и переводит virtual key/state; это не доказательство конкретного отказа: [официальная документация](https://developer.apple.com/documentation/coregraphics/cgevent/keyboardsetunicodestring%28stringlength%3Aunicodestring%3A%29).

Chromium сознательно направляет multi-unit Unicode через ImeCommitText, single BMP — через Char; поэтому сравнение этих путей в проблемном редакторе может быть полезно, но порции сами по себе не доказаны сломанными: [Cocoa event handling, строки 1652–1691](https://chromium.googlesource.com/chromium/src/+/b208f5ab862e42b3ea75c2f4b1724178c2fa6c5b/content/app_shim_remote_cocoa/render_widget_host_view_cocoa.mm#1652). Обычный Blink commit отправляет beforeinput до замены; его отмена сама по себе должна оставлять источник: [InputMethodController](https://chromium.googlesource.com/chromium/src/+/b208f5ab862e42b3ea75c2f4b1724178c2fa6c5b/third_party/blink/renderer/core/editing/ime/input_method_controller.cc#624).

Остаются гипотезы конкретного редактора/IME или AXSelectedText. Триггер теперь известен: автоматический Space/Enter; новая regression выявила гонку autorepeat. Нет основания менять postToPid/vk0/chunking или внедрять clipboard по догадке.

## Root финальные production проверки нового Engine

Frozen production `/tmp/mls-g21-final.8ijwtyc9`, Engine SHA256
`5a91543b9a2a92dfc0e473d6949792890b92170944a8362926cc6cd461b8c7b3`.
Полная native speech release сборка PASS; keyboard/notice/real Unicode transport
PASS; G19 dictation adapter и panel PASS. Linux XCTest95/95, 0ошибок из отдельного
серверного /tmp snapshot, checkout сервера не изменялся. Логи build.log,
keyboard.log, dictation-adapter.log, dictation-panel.log, linux-test.log.
Проверка production SHA перед финальным ревью: ни одного изменения исходников
относительно протестированного snapshot. Новый runner и reviews ещё pending;
VERSION1.4.3 до approval. Новая запись не утверждает живую приёмку пользователя.

## Финальные независимые ревью — APPROVED

`review_autorepeat_spec` и `review_autorepeat_standards`: 0 блокирующих замечаний.
Frozen `/tmp/mls-g21-autorepeat-final.v8tpedvg`: 160checksums PASS, manifest
`a257b5c2a653c281c755a2969eb0c27f870dda674ef8dbca95a9e83f5f0111ce`.
Baseline eb11af4 и final одним сохранённым runner: baseline actual=" " RED,
final GREEN. Отдельные локальные предыдущие RED покрыли Space/Enter обе routes.
Root самостоятельно скомпилировал frozen runner и получил GREEN;
лог `/tmp/mls-g21-final.8ijwtyc9/engine-root.log`. Оба reviewers независимо
повторили Engine, keyboard/notice/CG и G19 adapter/panel — PASS.
Сценарии: Space/Enter/ShiftEnter/Tab, серии повторов exactonce, printable/
Backspace, down/up/flags/marker, fastnextword/letter, outsidebusyreset,
Cmd/Ctrl/navigation/click cancellation, per-case uncertain recovery и удержанный
Enter. Замечание Spec про смешивание recoverypanels в fixture исправлено до freeze.

Разрешён scoped release1.4.4: исправлена доказанная productionautorepeat race,
transport не заменён. Hardware/WindowServer и совпадение причины со всеми
случаями пользователя не доказаны; обновление и физическая приёмка впереди.

## DMG1.4.4

Codecommit `d14e8027c36dc015ba7e6cc46fba4849599e00a2`; полный speech build
из gitarchive этого коммита. Образ readonly смонтирован: VERSION1.4.4,
codesign deep/strict PASS, Helpers/SpeechRecognizer присутствует,
Applications → /Applications. SHA256 `30ff210e387dd92da7a1293c278a3af67cdc75871582c0a0b4b3112ce94ba140`.
Artifact `outputs/MacLayoutSwitcher-1.4.4.dmg`; сборочный provenance/logs
в /tmp/mls-g21-final.8ijwtyc9. Установленная.app не заменена. Push и публичный
архив проверяются отдельно после этого metadata commit.

## Публикация проверена

Push36bd75d выполнен через чистый servercheckout+bundle; атомарный publicarchive
опубликован. Скачать archive и rawGitHubVERSION: обеверсии1.4.4, archiveSHA
91b69edfc2c196f4c2052e16736eed17d8b82e870c34557c85c841efb98fadcd,
embeddedgitcommit36bd75d85c2fe5202f0a3bb0104fa3c620495070 совпал.
Localfetch: clean, HEAD/origin0/0. Финальный metadata commit повторно проходит
push+archive; финальный publication.json сохраняется вне checkout в release scratch.
Установленная1.4.3 не менялась, физическая приёмка после обновления pending.
