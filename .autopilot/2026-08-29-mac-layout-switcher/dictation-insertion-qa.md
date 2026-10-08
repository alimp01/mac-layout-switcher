# G19 — приёмка исправления диктовки

Дата2026-10-08. База1.4.1 /53111dd. Исходные доказательства: dictation-insertion-audit.md.

## Подтверждено

- Исходная production DictationPanel в независимом AppKit harness: document/textContainer width0 при scroll width382 и непустой строке. Root просмотрел blank/sized renders; проблема видимости воспроизведена.
- Root tools/test-dictation-panel.sh: PASS visibleglyphs/longtext/scroll/selection/nonactivation/clipboardchangeCount unchanged. Render /tmp/mls-dictation-panel.kBbdlw/panel.png просмотрен: русские строки и emoji видимы. Cache bitmap не подтверждает визуальную отрисовку названий кнопок; их bounds/title/actions проверяются отдельно.
- Spec reviewer независимо выполнил native NSTextView capability fixture: AXValue/AXSelectedText/AXSelectedTextRange, targeted mutation с кириллицей/emoji сохраняет соседний текст. Это direct NSAccessibility в собственном процессе, не кросспроцессная AX/TCC-приёмка.

## Границы доказательств

Точный AX-отказ на пользовательском скриншоте неизвестен. Панель1.4.1 схлопывала причины. Непустой ASR результат следует из пути showResult; новый код должен разделить причины и сохранить видимый transcript. Никаких микрофонных записей/печати в пользовательских полях/автоматической записи clipboard диагностикой.

Root подтвердил реальный пакет Codex /Applications/ChatGPT.app, IDcom.openai.codex, версию26.1002.52244 и переименованный Codex Framework.framework. Обработка совместимости учитывает его. Проверка bundle metadata не является доказательством доставки текста в composer.

Диагностический процесс AXIsProcessTrusted=false; разрешения установленной MacLayoutSwitcher не выводятся из этого. Native adapter с подставленным AX boundary проверяет решения/состояния и вызовы production кода, но не системную доставку CGEvent.postToPid или реальное поведение Electron editor. Такие ограничения не скрывать итоговыми формулировками.

## Итоговые проверки

Код e857996ddb925ae4473e276b0a288bbf8178e07f.

- Root tools/test-dictation-adapter.sh PASS: actual Codex framework routing (metadata only), production capture/insert + native NSTextView, lazy tree, capabilities, sticky cancellation, Unicode readback/no-op/partial/no retry/delayed callbacks/clipboard preservation.
- Root полный Linux XCTest95/95,0 failures, snapshot /tmp/mls-v142-tests.zVFNvW. Package/Sources/Tests53files побайтно совпадают с кодом commit. No corechanges.
- Native debug исполнитель: /tmp/mls-g19-build/source. Release root из git archive e857996: /tmp/mls-v142-release.pTAeWo/source,44.97с,без ошибок/предупреждений. Включён speech helper.
- Spec review_dictation_spec и Standards review_dictation_standards независимо проверили finaldiff/harnesses; оба без блокирующих замечаний. Во время ревью исправлены self-cancellation monitor, задержанные собственные AXnotifications, readonly capability checks, refcon lifetime и fixture caretUTF16expectation.
- Mounted read-only DMG: version1.4.2, codesign --verify --deep --strict PASS, helper executable и Applications→/Applications проверены. Текущее установленное приложение не заменялось.
- MacLayoutSwitcher-1.4.2.dmg:10,934,036bytes; SHA256 b99675e8ae289b2b53bd3e118ce0184b3ab9ded94b186077f6e72e9e8f5cff49.

Финальный docscommit публикуется через git bundle/серверный git push; git archive обновляется атомарно. Публичные VERSION/архив/hash/commit проверяются после публикации при завершении выпуска. Это не отменяет ограничения liveCodex выше.
