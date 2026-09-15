# 09 — Автозапуск при входе (launch at login)

**Требования:** G06
**Blocked by:** 05, 08
**Зона:** `Sources/MacLayoutSwitcher/System/LoginItem*` (новый), `Sources/MacLayoutSwitcher/Config*`, `Sources/MacLayoutSwitcher/UI/StatusBarUI*`, `Sources/MacLayoutSwitcher/main.swift`, `README.md`
**Волна:** 7
**Status:** ready

## Что должно заработать

Пользователь включает в меню-баре «Запускать при входе» — после перезагрузки
Mac (входа в систему) приложение стартует само, без ручного запуска. Выключает —
перестаёт. По умолчанию выключено.

## Из брифа, дословно

> «Давай добавим автозапуск после перезагрузки мак»

## Разделы спецификации

История 17 (G06); «Решения по реализации» (SMAppService).

## Детали

- **Обёртка `LoginItem`** (macOS, `#if os(macOS)`, `import ServiceManagement`):
  - `var isEnabled: Bool` — статус (SMAppService.mainApp.status == .enabled).
  - `func enable() throws` → `SMAppService.mainApp.register()`.
  - `func disable() throws` → `SMAppService.mainApp.unregister()`.
  - `@available(macOS 13.0, *)` — минимум проекта и так 13, но пометь явно.
  - Ошибки register/unregister не глотать молча — прокинуть/залогировать так,
    чтобы тумблер не показывал ложный успех (если register бросил — состояние
    в конфиге не менять, вернуть тумблер в прежнее положение).
- **Config**: `AppConfig.launchAtLogin: Bool` (дефолт false), decodeIfPresent —
  старый config.json без поля грузится. Config хранит ЖЕЛАЕМОЕ состояние;
  фактический источник истины — SMAppService.status.
- **StatusBarUI**: пункт-тумблер «Запускать при входе» с галочкой по факту
  (`LoginItem.isEnabled`), колбэк `onToggleLaunchAtLogin: ((Bool) -> Void)?`.
- **main.swift**: связать тумблер с LoginItem.enable()/disable(); при старте
  синхронизировать галочку с фактическим статусом (не только с config).
  Расхождение config↔факт (пользователь снял login item в Системных настройках)
  — доверять факту SMAppService, обновить config.
- **README**: короткий раздел «Автозапуск при входе» — где тумблер; что при
  ad-hoc-подписи macOS может показать login item в Системных настройках →
  Основные → Объекты входа, и там его тоже можно выключить.
- Ядра/тестов на Linux здесь практически нет (SMAppService — только macOS).
  Если вынесешь что-то тестируемое (например маппинг status→Bool) — хорошо,
  но не выдумывай искусственный шов. Главное — `swift test` остаётся зелёным (43)
  и `swift build` на Linux не падает (весь новый код под `#if os(macOS)`).

## Критерии приёмки

- [ ] LoginItem: enable/disable/isEnabled через SMAppService.mainApp, @available(macOS 13)
- [ ] Тумблер «Запускать при входе» в меню-баре, галочка по фактическому статусу
- [ ] AppConfig.launchAtLogin (дефолт false); старый config.json без поля грузится
- [ ] Ошибка register/unregister не выглядит успехом: тумблер откатывается, config не лжёт
- [ ] При старте галочка синхронизируется с фактическим SMAppService.status
- [ ] README: раздел про автозапуск (+ где выключить в Системных настройках)
- [ ] На Linux `swift build`/`swift test` зелёные (43), весь код под `#if os(macOS)`
