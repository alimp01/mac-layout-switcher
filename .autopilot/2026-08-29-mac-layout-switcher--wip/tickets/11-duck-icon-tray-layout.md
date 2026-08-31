# 11 — Утка-иконка + индикация раскладки в трее

**Требования:** G08, G09
**Blocked by:** 10
**Зона:** `Resources/AppIcon.icns` (перегенерация), `Sources/MacLayoutSwitcher/UI/StatusBarUI*`, `Sources/MacLayoutSwitcher/Engine*` (колбэк раскладки), `Sources/MacLayoutSwitcher/main.swift`, `README.md`
**Волна:** 9
**Status:** ready

## Что должно заработать

1. Иконка приложения — утка (Resources/AppIcon.svg уже заменён оркестратором,
   НЕ менять): перегенерировать Resources/AppIcon.icns → `python3 tools/make-icns.py`.
2. Иконка в меню-баре показывает ТЕКУЩУЮ раскладку: вместо/поверх значка —
   текст «RU» или «EN» (жирный, короткий). Меняется сразу при смене раскладки
   любым способом (сам пользователь, автоисправление, Option). В паузе —
   приглушённо (например серым или «⏸ RU»).

## Из брифа, дословно

> «Нет, давай сделаем утку в профиль и сделаем чтобы иконка в трее показывала текущую раскладку»

## Детали

- Текущая раскладка: `LayoutSwitcher.current() -> Lang?` уже есть (таск 03).
- Обновление по событию, не поллингом: подпишись на системное уведомление
  смены источника ввода — `DistributedNotificationCenter.default()` с именем
  `kTISNotifySelectedKeyboardInputSourceChanged`
  ("com.apple.Carbon.TISNotifySelectedKeyboardInputSourceChanged"); плюс
  обнови индикатор после каждого programmatic `LayoutSwitcher.select`.
- `StatusBarUI`: метод `setLayoutIndicator(_ lang: Lang?, paused: Bool)` —
  ставит `button.title` («RU»/«EN», nil → «--»), моноширинный/жирный мелкий
  шрифт; в паузе — серый (attributedTitle) или префикс паузы. Утку в трее
  рисовать не нужно — там текст раскладки (иконка приложения — отдельно).
- main.swift: подписка на уведомление + начальная установка при старте.
- README: строка про индикатор раскладки в меню-баре.
- Всё под `#if os(macOS)`; Linux `swift build`/`swift test` зелёные (43).
  Собирается вслепую — только документированные API.

## Критерии приёмки

- [ ] Resources/AppIcon.icns перегенерирован из утки (self-check make-icns.py OK; PNG чанков 7)
- [ ] Меню-бар показывает RU/EN, обновляется по kTISNotify... и после select()
- [ ] В паузе индикатор визуально приглушён
- [ ] Нет поллинга по таймеру
- [ ] README дополнен; на Linux сборка и 43 теста зелёные
