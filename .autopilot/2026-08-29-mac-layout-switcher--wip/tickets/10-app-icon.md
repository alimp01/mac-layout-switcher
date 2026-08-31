# 10 — Иконка приложения (.icns в бандле)

**Требования:** G07
**Blocked by:** 05, 07
**Зона:** `Resources/`, `tools/make-icns.py` (новый), `build.sh`, `README.md`
**Волна:** 8
**Status:** ready

## Что должно заработать

.app и .dmg несут иконку приложения (Resources/AppIcon.svg уже нарисован
оркестратором и одобряется пользователем отдельно). Иконка видна в Finder,
Dock (при запуске), «Программах» и на .dmg.

## Из брифа, дословно

> «нарисуй иконку для приложения в виде пальца похоже на пальцы микимауса с поднятым среднем пальцем»

## Детали

- **`tools/make-icns.py`** (новый, python3 + cairosvg — он установлен):
  рендерит Resources/AppIcon.svg в PNG 16/32/64/128/256/512/1024 и собирает
  `Resources/AppIcon.icns` БЕЗ iconutil — формат icns прост: заголовок
  b'icns' + big-endian длина файла, затем чанки [4-байт тип][4-байт длина
  чанка вкл. заголовок][PNG-данные]. Типы: icp4=16, icp5=32, icp6=64,
  ic07=128, ic08=256, ic09=512, ic10=1024. Прогони скрипт, положи готовый
  `Resources/AppIcon.icns` в репозиторий (коммитить будет оркестратор;
  файл должен существовать после тебя).
- Проверь результат: файл начинается с b'icns', размер >100КБ разумен;
  python-скриптом распарси свои же чанки обратно (self-check в make-icns.py).
- **build.sh**: копировать `Resources/AppIcon.icns` в
  `Contents/Resources/AppIcon.icns` и добавить в Info.plist
  `CFBundleIconFile = AppIcon`. Если icns отсутствует — собирать без иконки
  с предупреждением, не падать.
- **README**: одна строка про иконку (Resources/AppIcon.svg — исходник,
  make-icns.py — пересборка icns после правки SVG).
- Resources/AppIcon.svg НЕ менять — он уже одобряется пользователем.

## Критерии приёмки

- [ ] `python3 tools/make-icns.py` создаёт валидный Resources/AppIcon.icns (self-check парсит чанки)
- [ ] build.sh: CFBundleIconFile + копирование icns; без icns — предупреждение, не падение; `bash -n` чист
- [ ] На Linux `swift build`/`swift test` зелёные (43) — Swift не тронут
- [ ] README дополнен строкой про иконку
