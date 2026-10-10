# G21 / T24 — проверка исчезающей замены

Дата: 2026-10-10. Baseline release: 1.4.3 / 963b387. Planning: 61c7e16.

## Что доказано живой проверкой

- На Mac установлена 1.4.3. Тесты ниже выполнялись через CUA, без изменения установленного приложения, новых разрешений и пользовательских полей.
- Собственный новый документ TextEdit: отдельные клавиши `g h b d t n Space` дали `Привет `. Это подтверждает реальный перехват и замену в нативном редакторе. Документ сохранён в `/tmp/mls-g21-input.rtf` и закрыт; существующий документ не изменялся.
- Собственное поле официального MDN textarea в Chrome: первый ввод после смены фокуса оставил `ghbdtn `; повторный ввод без Cmd+A дал `ghbdtn привет `. Сразу после ввода AX показывал промежуточное `ghbdtn при`, после завершения — весь текст. Это подтверждает успешную реальную доставку в Chrome после прогрева; промежуточный снимок не является итоговым результатом.
- Ввод через browser-extension API оставлял `ghbdtn ` и не доказывает работу Mac EventTap. Для успешного Chrome теста использован native app `pressKey`.
- Только официальный HTTPS пример MDN; custom data URL запрещён политикой браузера и не использовался. Тестовая вкладка закрыта.

## Что пока НЕ доказано

- Пользователь сообщает deletion-only, но в этих двух scratch редакторах оно не воспроизвелось. Точное приложение/поле и триггер (автоматика либо Option) запрошены, ответа пока нет.
- Уточнение10.10: пользователь ответил «да во всех» о приложениях; вопрос о
  триггере задан отдельно. Новый собственный TextEdit документ сохранён в
  `/tmp/MLS-Option-Test.rtf`, значение `ghbdtn`, оно выделено; пользователь
  приглашён нажать физический Option. Документ оставлен открытым для проверки,
  текущие пользовательские документы не изменялись.
- Локальный CGEvent → serialization → NSEvent → NSTextView тест не подтверждает межпроцессную WindowServer доставку. Собственный postToPid probe не имеет AX trust и не получил событий; принудительное TCC не применяется.
- Нет оснований приписывать дефект модели, правам, обязательной несовместимости Chromium с Unicode или размеру порции. Не заменять транспорт догадкой.

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

Собственный документ `MLS-Option-Test.rtf` остаётся открытым с выделенным ghbdtn;
последний CUA readback: слово и выделение неизменны. Ответ физического Option
пользователя и уточнение триггера ожидаются. VERSION/установленная.app/публичный
архив не изменены, новые core/build прогоны не требуются без изменения кода.

### Результаты прошлого аудитора

Аудитор `audit_deletion_transport` не нашёл безусловного удаления в Target: выбор диапазона предшествует одному AXSelectedText write либо Unicode replacement. Не найден доказанный универсальный дефект транспорта.

Apple допускает, что принимающий framework игнорирует Unicode и переводит virtual key/state; это не доказательство конкретного отказа: [официальная документация](https://developer.apple.com/documentation/coregraphics/cgevent/keyboardsetunicodestring%28stringlength%3Aunicodestring%3A%29).

Chromium сознательно направляет multi-unit Unicode через ImeCommitText, single BMP — через Char; поэтому сравнение этих путей в проблемном редакторе может быть полезно, но порции сами по себе не доказаны сломанными: [Cocoa event handling, строки 1652–1691](https://chromium.googlesource.com/chromium/src/+/b208f5ab862e42b3ea75c2f4b1724178c2fa6c5b/content/app_shim_remote_cocoa/render_widget_host_view_cocoa.mm#1652). Обычный Blink commit отправляет beforeinput до замены; его отмена сама по себе должна оставлять источник: [InputMethodController](https://chromium.googlesource.com/chromium/src/+/b208f5ab862e42b3ea75c2f4b1724178c2fa6c5b/third_party/blink/renderer/core/editing/ime/input_method_controller.cc#624).

Остаются гипотезы конкретного редактора/IME или AXSelectedText. Для следующего шага нужны точное приложение/поле и триггер пользовательского deletion-only. Нет основания менять postToPid/vk0/chunking или внедрять clipboard по догадке.
