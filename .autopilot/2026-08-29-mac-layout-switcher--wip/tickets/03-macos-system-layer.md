# 03 — Системный слой macOS: перехват, перепечатка, раскладка

**Требования:** R06i (R06i.1), R03
**Blocked by:** 01
**Зона:** `Sources/MacLayoutSwitcher/System/`
**Волна:** 2
**Status:** ready

## Что должно заработать

macOS-обвязка, через которую всё общение с системой: слушать клавиатуру во всех
приложениях, узнавать символ по коду клавиши, переключать раскладку, стирать и
перепечатывать слово синтетическими событиями — не зацикливаясь на собственном
вводе. Код компилируется только на macOS (`#if os(macOS)`); на Linux пакет
по-прежнему собирается и тестируется.

**Важно: проверить компиляцию этого кода негде — macOS-машины у агента нет.**
Поэтому: только документированные API (CGEventTap, UCKeyTranslate,
TISSelectInputSource, IsSecureEventInputEnabled), консервативный Swift без
экзотики, сверяйся с сигнатурами из открытых проектов (RuSwitcher
github.com/rashn/RuSwitcher, keyswitcher github.com/graninilya/keyswitcher,
разбор habr.com/ru/articles/1050394) — можно скачать их исходники для сверки
сигнатур, но код пиши свой.

## Из брифа, дословно

> «две программы для mac» — работают системно, в любом приложении

## Разделы спецификации

Истории 7–8 (частично — Permissions); «Решения по реализации» — CGEventTap,
UCKeyTranslate, TIS, синтетические события с маркером; «Границы и швы» —
EventTap, Typist, LayoutSwitcher.

## Детали

- `EventTap`: `start(handler: (KeyStroke) -> Void) -> Bool`, `stop()`.
  CGEventTap на `keyDown` + `flagsChanged`, `.cgSessionEventTap`,
  `.listenOnly` для наблюдения. `KeyStroke`: keyCode, символ(ы) через
  UCKeyTranslate по текущей раскладке, флаги модификаторов, признак
  autorepeat. Обработка `tapDisabledByTimeout` → re-enable. Синтетические
  события с нашим маркером (`CGEventField.eventSourceUserData == 0xC0FFEE`)
  игнорируются.
- `Typist`: `replaceLastWord(len: Int, with: String)` — len × Backspace, затем
  посимвольная печать строки юникодом (`CGEvent.keyboardSetUnicodeString` —
  не зависит от активной раскладки); все события помечены маркером и идут
  через `CGEvent.post(tap: .cghidEventTap)` с микрозадержками.
- `LayoutSwitcher`: `current() -> Lang?` (по id источника: `.ru` если
  содержит "Russian", `.en` если "U.S."/"ABC"/"British"), `select(_ lang:)`
  через TISCreateInputSourceList + TISSelectInputSource. Нет подходящего
  источника → nil/false, не крэш.
- `SecureInput`: `var isActive: Bool` — обёртка IsSecureEventInputEnabled().
- `FrontApp`: `var bundleID: String?` — NSWorkspace.frontmostApplication.
- `Permissions`: `var trusted: Bool` (AXIsProcessTrustedWithOptions с
  prompt-опцией), `openAccessibilitySettings()`,
  `openInputMonitoringSettings()` (x-apple.systempreferences URL).
- Никакой логики решения «исправлять или нет» — это Engine (таск 04).

## Критерии приёмки

- [ ] На Linux `swift build`/`swift test` остаются зелёными (весь код под `#if os(macOS)`)
- [ ] EventTap игнорирует события с маркером и переживает tapDisabledByTimeout
- [ ] Typist печатает юникодом (независимо от активной раскладки), все события маркированы
- [ ] LayoutSwitcher находит RU/EN источники и деградирует без крэша, если их нет
- [ ] Permissions умеет спросить доверие и открыть обе панели настроек
- [ ] Каждый публичный тип — с doc-комментарием: что от какого API и зачем
