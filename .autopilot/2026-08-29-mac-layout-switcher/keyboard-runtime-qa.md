# G20 — проверка клавиатурного runtime

## До исправления
- HEAD bd9b025, опубликовано1.4.2; установленная.app1.4.1. Код keyboard runtime не менялся вG19.
- Независимый read-only audit: production InputFocusGuard.Target с подменённой AX границей и собственным NSTextView: отсутствующий AXSelectedText setter → отказ; no-op setter с .success → ложный успех при неизменённом тексте; lazy tree → nil без bootstrap. Exact ghbdtn принимается, suffix bdtn отвергается. Это проверка production алгоритма, не настоящего межпроцессного AX.
- Root CUA: отдельный новый TextEdit документ, последовательность g/h/b/d/t/n/space дала Ghbdtn без замены. CUA ввод синтетический, не доказательство hardware-path. Modifier-only Alt_L инструмент отверг keyPressIncludedNoNonModifierKeys. Собственный документ сохранён в /tmp/MLS-keyboard-baseline.rtf и закрыт; пользовательские документы не менялись.
- Установленный процесс работает, autoSwitch true; Codex/TextEdit не в exclusions. AX trust отдельного диагностического бинарника не доказывает разрешения установленной.app.

## Приёмка после изменений
Завершено программными проверками ниже; live Option/Codex delivery остаётся pending.

## Раннее независимое ревью
- Spec: uncertain флаг жил весь focus route и мог поглощать последующий Enter уже после удачной замены; ограничить ошибочным batch/явным восстановлением и проверить.
- Standards: исходное ожидаемое слово проверялось по одному AXValue, снимок для изменения брался вторым чтением. Нужна единая snapshot-проверка exact substring и границы слова с регрессией на изменение между чтениями.
- Оба замечания переданы исполнителю до финальной приёмки.
- Standards подтвердил исправление snapshot race независимой adversarial fixture (редактор меняет значение сразу после первого чтения): untouched, zero writes.
- Оба ревью воспроизвели apply-then-fail selection RPC: нельзя возвращать untouched с выделенным источником, требуется проверенное восстановление либо uncertain.
- Дополнительные замечания: TIS/UI не выполнять внутри tap; mint cancellation до deferred Option; не терять физические символы/разделители при отказе очереди.

## Root frozen snapshot verification
Snapshot /tmp/mls-v143-release.ou7Xqq/source:77 whitelisted files; SHA256 map source-sha256.json. First comparison to workspace: zero deltas.
- Linux /tmp/mls-v143-tests.N7fyR5:95 XCTest,0failures (05:47 UTC08.10). Core/Test/Package unchanged from tested snapshot must be rechecked before release.
- Native full speech release + DMG build PASS (outside Documents; no iCloud mmap issues).
- tools/test-keyboard-adapter.sh PASS: no-op/no retry, lazy tree, missing setter Unicode, native exact replacement/source boundary, cancel/focus, partial delivery, selection RPC apply/fail/restoration, fresh bounded word, production Typist Shift+Enter/fast order, retained dependent separators, first bind/core and idle uncertainty reset. Uses substituted AX/post boundary + own NSTextView, not actual foreign-app delivery.
- tools/test-dictation-adapter.sh and tools/test-dictation-panel.sh PASS; G19 readback/observer/UI regressions retained.
- At final checks Mac session is locked (read-only system status); no unlock/TCC change attempted. Live Option and Codex delivery pending.

## Финальная приёмка и артефакт
- Код d7b003dba5f2e293dceb766e0d498451cad5919a. Spec и Standards: APPROVED,0 blockers. Оба независимо запускали production keyboard harness и финальную recovery panel.
- Последний delta: ConversionNotice + notice harness сохраняют несколько порций ввода при последующих ошибках и программном hide; только явное Close очищает. Root финальный keyboard+panel PASS. Width/glyphs/scroll/selection и неизменность clipboard проверены headless, без UI взаимодействия с пользовательскими полями.
-78 файлов финальной сборки сверены SHA256 с repo:0различий. Sources/SwitcherCore, Tests и Package не менялись после95/95 Linux.
- Финальный full speech release:4.91s incremental after39.59s clean; no warnings/errors. DMG смонтирован readonly: VERSION1.4.3, codesign --verify --deep --strict, helper executable, Applications symlink PASS, затем unmount.
- MacLayoutSwitcher-1.4.3.dmg:10955271 bytes, SHA256 cf6944a789d707bfb4328dcf3b35793cce5eed18f48581546be447c99c8aca6a. Доступен в outputs задачи. Установленная.app1.4.1 не подменялась.
- Для публикации этого QA коммита: fast-forward server, git push, атомарный git archive; внешнюю версию/архив сверить после публикации. Архив не может включать собственный итоговый SHA256.
