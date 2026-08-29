<!-- autopilot:start -->
# Mac Layout Switcher

Собственный аналог Punto Switcher / Caramba Switcher для macOS — автоматическое
исправление текста, набранного не в той раскладке.

## Команды

| Команда | Что делает |
|---------|------------|
| `swift test` | Юнит-тесты ядра `SwitcherCore` (проходят на Linux и macOS) |
| `swift build` | Сборка обоих target'ов (на Linux macOS-слой — пустой executable) |
| `./build.sh` | macOS 13+: релизная сборка + `MacLayoutSwitcher.app` (ad-hoc подпись) в `dist/` |
| `open dist/MacLayoutSwitcher.app` | Запуск собранного приложения (первый раз — правый клик → «Открыть») |

## Как здесь работает Autopilot

Сборка ведётся навыком `/autopilot`. Требования, спецификация и таски — в `.autopilot/`.
Прогресс — `.autopilot/dashboard.html`. Правило: требование из `manifest.md`
может снять только пользователь.

Если работа продолжается — скажи «продолжи автопилот»: состояние поднимется
из `.autopilot/state.js`, переспрашивать ничего не нужно.
<!-- autopilot:end -->
