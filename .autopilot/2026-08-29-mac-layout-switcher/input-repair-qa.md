# G15–G17 — проверки 2026-10-07

## Подтверждённая исходная среда
macOS15.6.1 arm64, Swift6.1.2; установленная и работающая .app1.3.0, один процесс. Исходники Mac, origin/main и Linux сервера исходно d90464d; чистые checkout. macOS CLT без XCTest; финальный XCTest на изолированной копии Linux Swift6.0.3. Основной серверный checkout не используется как тестовый песочница.

## Установленные причины
- G16: четыре исходных файла модели имеют правильные размеры и SHA256. Реальный SpeechModelStore.checkInstalled отклоняет их из-за optimized_cache/v3_e2e_rnnt_encoder_int8_optimized.ort, который создаёт сам runtime. Предыдущая проверка cache не включала проверку после появления оптимизированного runtime cache; теперь проверять именно этот цикл.
- G15: старый EventTap не сбрасывает буфер по клику/фокусу. Enter/Tab сохраняют область предыдущего слова; очередь перепечатки не проверяет поле/ожидаемый исходник. Точный пользовательский сценарий скриншота не воспроизведён, причинность конкретного префикса не утверждается.
- G15: fresh b/B/z/Z не конвертируются; reset ядра не сбрасывает языковую инерцию, backspace после границы оставляет устаревшую область. Регрессионные тесты сначала воспроизводят эти отказы.

## План окончательной проверки
- Публичные тесты ядра: короткие слова/ozon/изменение области, RU↔EN выделение/регистр/переносы, прежние тесты.
- Native model check: реальная модель с cache, повторные helper/check/new store; битый размер/хэш/чужая модель/symlink/отмена. Авто-подготовка не запускает микрофон без нового удержания.
- Native debug/release + проверка подписанного DMG.
- Два ревью Spec/Standards и повторная проверка замечаний.
- Manual acceptance: ozon после переходов между полями; b/B/z/Z и английское plan b; Option по выделению и без выделения; Enter/Shift+Enter; быстрый набор; диктовка после перезапуска без загрузки.

## Ограничение
Микрофон, текущие тексты пользователя и буфер обмена не используются для автоматических тестов. Реальная внешняя UI-приёмка отмечается отдельно.

## T19 — выполнено
- Исходный реальный store возвращал damagedModel при валидных четырёх SHA256; после исправления success.
- Четыре офлайн распознавания (sandbox-denied network): cache, второй процесс, усечённый cache, восстановленный cache. После каждого отдельный process store.checkInstalled — PASS.
- Отвергнуты manifest/лишний encoder/лишняя модель в cache, symlink cache dir/cache file/артефакт, порча с тем же размером/усечение.
- Реальная загрузка233МБ и repair усечённого vocab — PASS; offline/cancel завершаются однократно, убирают staging и сохраняют предыдущую модель.
- Два независимых ревью — 0 находок. TCC/настоящий микрофон не тестировались; проверка coordinator lifecycle — по коду. Временные harness/logs: /tmp/mls-t19/QA.txt. Коммит2bb8f1f.

## T18 — выполнено
- TDD red/green: fresh b/B/z/Z; reset английского контекста; Enter/Tab не сохраняют undo; source validation; failed replacement undo rollback; whole-token source; физические replay после Tab. 36 focused Linux XCTest /0failures.
- Mac native build успешен; git diff --check чистый.
- Ревью нашли P1: совпадение хвоста внутри большего слова; P1: прерывание Backspace оставляло стёртый префикс; P2: post-Tab replay терял abc. Устранено whole-token boundary, одной targeted AXSelectedText записью, отдельной bounded physical replay route. Оба повторных ревью —0находок.
- Коммит321eba8; временные логи /tmp/mls-t18-verification.txt и /tmp/mls-t18-core-tests.log.
- AXIsProcessTrusted()==false: нет live Accessibility UI теста. После нового фокуса самое первое быстрое слово может быть пропущено до async binding; суффикс чужого слова при этом не исправляется. ADR0013 фиксирует узкое OS-окно доставки separator и отмену queued input при несвязанной навигации.

## T20 и общая проверка
- Существующий хоткей приоритетно конвертирует выделение, пустое выделение допускает прежний undo/word. Подавлены keyDown/repeat/keyUp обычного shortcut. No clipboard/Enter; проверка конкретного range/text/focus.
- Исправлены root-находки: stale selected completion сбрасывал новый buffer; ошибка ручной пустой selection не показывала объяснение; canceled manual request мог навсегда оставить replacement permit отменённым. Оба integrated ревью одобрили; последняя правка отдельно rechecked Standards.
- Native debug build прошёл. Полный Linux85XCTest/0failures: claudebot-server:/tmp/mls-v140-tests.pws4Le/test.log. SSH-сессия закрылась после тестов; сохранённый лог при повторном подключении подтверждает All tests passed. Проверено побайтное соответствие core/tests snapshot финальному коду.
- Code commit12cc6de. Живой AX UI/микрофон не тестировались.

## Финальная поставка1.4.0
- Release app+helper собраны из git archive12cc6de вне Documents, без MLS_DISABLE_SPEECH. Закреплённая зависимость2.17.0. Build и упаковкаDMG прошли.
- DMG смонтирован readonly: версия1.4.0, microphone purpose string, Applications symlink; codesign --verify --deep --strict успешен. Helper именно из смонтированного DMG распознал фиксированный русский WAV под запретом сети. Образ отключён после проверки.
- MacLayoutSwitcher-1.4.0.dmg:10,909,995bytes; SHA25687e8726fdbbd47575be2423b7f06b5231471723be137648e3e80e5e144570046. Копия в outputs текущей задачи.
- Готовность UI подтверждается только ручной приёмкой после обновления: текущая установленная1.3.0 не заменялась и не перезапускалась посреди пользовательского набора.
