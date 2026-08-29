# 08 — Настройка горячих клавиш

**Требования:** G05
**Blocked by:** 04, 06
**Зона:** `Sources/SwitcherCore/Hotkey*`, `Sources/SwitcherCore/EngineCore*`, `Sources/MacLayoutSwitcher/Config*`, `Sources/MacLayoutSwitcher/Engine*`, `Sources/MacLayoutSwitcher/UI/*`, `Tests/SwitcherCoreTests/Hotkey*`
**Волна:** 6
**Status:** ready

## Что должно заработать

Пользователь меняет две горячие клавиши через окно-рекордер «нажми клавишу»:
1. **Клавиша конвертации/отката** — сейчас жёстко Option (одиночный tap).
2. **Клавиша вкл/выкл автопереключения** — новая (по умолчанию не назначена).

Выбранные клавиши сохраняются в config.json и применяются после перезапуска
(допустимо — как и порог отмен). Дефолт клавиши конвертации — Option, чтобы
у тех, кто уже пользуется, ничего не сломалось.

## Из брифа, дословно

> «и давай сделаем настройку горячих клавиш»
> уточнение: клавиша конвертации/отката + клавиша вкл/выкл авто; окно-рекордер «нажми клавишу»

## Разделы спецификации

История 16 (G05); «Границы и швы» — Hotkey (новый, SwitcherCore), EngineCore, Config, UI.

## Детали

- **Модель `Hotkey` в SwitcherCore (тестируется на Linux)** — это ключ к тому,
  чтобы сопоставление было проверено, а не собрано вслепую:
  - `struct Hotkey: Codable, Equatable` — описывает либо одиночный модификатор
    (например правый Option), либо клавишу с модификаторами. Достаточно полей:
    `keyCode: UInt16?` (nil = «только модификатор»), `modifiers: Set<Modifier>`
    (или битовая маска), где `enum Modifier { case command, option, control, shift, capsLock, rightOption, rightCommand, ... }` — выбери набор, покрывающий Option/правый Option/правый Cmd/Caps Lock/сочетания.
  - `func matches(keyCode: UInt16?, modifiers: <тип>) -> Bool` — сработал ли
    хоткей на данном описании нажатия. Для «только модификатор» — логика tap
    (нажат-отпущен без других клавиш) остаётся в macOS-Engine, но РЕШЕНИЕ
    «этот tap = сконфигурированный хоткей» принимает `Hotkey.matches`.
  - Человекочитаемое имя: `var displayName: String` («⌥ Option», «⇪ Caps Lock»,
    «⌘⇧ K») — для отображения в меню/окне.
- **EngineCore**: обобщи `InputEvent.optionTap` до `hotkey(HotkeyAction)` где
  `enum HotkeyAction { case convert, toggleAuto }` — или добавь второе событие.
  `convert` делает то, что делал optionTap (конвертация/откат); `toggleAuto`
  переключает autoSwitch. Существующее поведение отката/порога (таск 06) не ломать.
- **Config**: `AppConfig` + `convertHotkey: Hotkey` (дефолт = Option-tap),
  `toggleAutoHotkey: Hotkey?` (дефолт nil). Старый config.json без полей →
  дефолты (Codable с decodeIfPresent). Не сломать undoThreshold и прочее.
- **Engine (macOS)**: из CGEvent строит описание нажатия (keyCode, модификаторы)
  и спрашивает `convertHotkey.matches` / `toggleAutoHotkey?.matches`; шлёт в
  EngineCore соответствующее `hotkey(...)`. Одиночный-модификатор-tap
  сохраняет прежнюю механику (down→up без промежуточных клавиш).
- **UI — окно-рекордер** (macOS, под #if os(macOS), собирается вслепую —
  консервативный AppKit): окно «Настройка горячих клавиш» с двумя строками
  (Конвертация / Вкл-выкл авто), у каждой — текущее значение (displayName) и
  кнопка «Записать»: после нажатия окно ловит следующее сочетание (локальный
  NSEvent-монитор keyDown/flagsChanged в пределах окна), показывает его и
  сохраняет в Config. Кнопка «Сброс» → дефолт. Пункт меню-бара «Горячие
  клавиши…» открывает это окно. Не городи сложного — надёжность важнее.
- **README**: короткий раздел «Горячие клавиши» — где меню, что настраивается,
  что применяется после перезапуска.

## Критерии приёмки

- [ ] `Hotkey.matches` покрыт тестами на Linux: одиночный модификатор срабатывает и не срабатывает при лишних клавишах; клавиша+модификаторы; сравнение/Codable round-trip; displayName для типовых случаев
- [ ] EngineCore: `hotkey(.convert)` воспроизводит прежнее поведение optionTap (конвертация + откат + порог таска 06 целы); `hotkey(.toggleAuto)` переключает autoSwitch — тесты на Linux
- [ ] AppConfig: convertHotkey (дефолт Option) + toggleAutoHotkey (дефолт nil); старый config.json без полей грузится
- [ ] Окно-рекордер: две строки, «Записать»/«Сброс», пункт меню «Горячие клавиши…»; код под #if os(macOS), консервативный AppKit (собираю вслепую)
- [ ] Полный `swift test` на Linux зелёный (был 31 — станет больше)
- [ ] Обратная совместимость: без изменения настроек клавиша конвертации = Option, как раньше
