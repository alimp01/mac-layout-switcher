# G29 — исправление раскладки в Spotlight

## Problem Statement
26.10 пользователь показал отказ Option в системном Spotlight (подтвердил ⌘Space).
SystemFocus=foreign-owner при AXFrontmost=ok; AppFocus=not-read. Menu app Claude
остаётся отдельным процессом. В установленном Spotlight Info.plist:
com.apple.Spotlight, /System/Library/CoreServices/Spotlight.app, LSUIElement=true,
NSPrincipalClass=SPApplication. Это другой случай, чем G28 Bitrix noValue.

## Solution
Начальный захват должен распознать подтверждённое системное поле Spotlight
и привязать замену к его фактическому владельцу. Проверка уже захваченной цели
остаётся строгой: нельзя перейти в новое поле/приложение, когда окно закрылось.

## User Stories
1. Нажатие Option исправляет выделение или слово перед кареткой в Spotlight.
2. Автозамена после пробела использует то же подтверждённое поле поиска.
3. Закрытие Spotlight, переход фокуса, ввод/команда отменяют устаревшую замену.
4. Поле приложения под Spotlight остаётся нетронутым.
5. Codex/Bitrix/native/WebKit и существующая обработка диктовки сохраняются.
6. Нет доступа к защищённым полям и нет потери текста при непроверенной записи.

## Implementation Decisions
- Отличать начальный выбор цели от проверки ранее захваченной цели. Не снимать
  exact-PID guard с общего resolver и не делать fallback в stale app field.
- Системный AXFocusedUIElement является источником точного поля. Только узко
  подтверждённый Apple Spotlight может быть новым владельцем вместо foreground.
  Положительная identity: exact bundle ID + canonical system bundle/executable
  identity и живой process instance. Одного имени/ID или любого LSUIElement мало.
- Spotlight может не быть AXFrontmost; допустимость только при точном system
  focus того же владельца. Нет app-focus fallback для неактивного Spotlight.
- Цель хранит actual PID; вставка/Unicode/observer используют actual owner.
  Физический replay сохраняет существующий global HID transport и проверку
  текущего поля/permit, затем прежнюю native navigation policy после Enter/Tab.
  Не подменять маршрут фоновым expectedPID; не менять transport без доказанного
  Spotlight-specific дефекта. Узкая AX/CG race остаётся известным ограничением. Проверка exact element/owner/process/source/range/value/readback до
  записи сохраняется. Повторный resolver не перенаправляет операцию.
- Не подготавливать accessibility фонового Claude вместо Spotlight. Не ждать
  готовности другого поля с намерением выполнить старую операцию. Сохранять G27
  bounded/cancellable bootstrap и fresh request при отсутствующем первом поле.
- AX/filesystem/identity checks вне EventTap callback; без глобального tree walk.
- Shared accessibility path должен быть согласован для keyboard capture/current
  и dictation; либо обоснованно отказать неподдержанному пути без ошибочной записи.

## Testing Decisions
На существующем raw AX seam воспроизвести baseline6241c86 foreign-owner и
кандидат на одном literal fixture. Проверять actual PID маршрута и итоговый
текст/каретку, не только ненулевой target. Spotlight surface с родительским
приложением AXFrontmost=true и Spotlight AXFrontmost=false. Option selected и
без выделения (ghbdtn→привет), автоSpace/Enter/ShiftEnter без лишнего submit,
общий capture для диктовки, прежние Chromium/native fixtures. Негативы: обычный
foreign-owner, stale appfocus, spoof bundle/name/path, invalid/missing systemfocus,
Spotlight закрыт/смена владельца/элемента/process incarnation, cancel, readonly/secure.
Только собственные скрытые fixtures; никаких live private AX/UI и обхода
предыдущих CUA отказов Codex/MLS. Linux95 можно reuse при exact27 unchanged hashes.
Два независимых ревью, полный speech build, signed mounted DMG. Физическая
проверка Spotlight пользователем отдельная; не объявлять все приложения PASS.

## Out of Scope
Словари/thresholds, произвольные overlay apps, clipboard, full AXValue writes,
blind backspace, повтор неопределённой записи, микрофон/TCC, live private UI.

## Further Notes
Root orchestration only; fresh executor T34. Release candidate1.4.12 after
root signal; commit/push/public archive обязательны. Не трогать установленную
.app посреди набора молча; перед заменой предупредить, сохранить rollback.
