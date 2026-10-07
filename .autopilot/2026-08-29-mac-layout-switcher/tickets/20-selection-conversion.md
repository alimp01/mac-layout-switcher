# 20 — Конвертация выделенного текста существующим хоткеем

**Требование:** G17
**Blocked by:** контракт InputFocusGuard.Target T18 доступен; непересекающиеся KeyMap/new Selection/UI/docs можно параллельно; интеграция Engine/Typist и закрытие — после T18
**Status:** done

## Что построить
Истории 5–6. Полный путь от Option/config hotkey до точной замены выделения. Безопасный async AX, сохранение прежнего поведения без выделения. Понятная ошибка и отсутствие побочных эффектов.

Спецификация: ../input-repair-spec.md. Зона: Engine/Typist, новый SelectionConverter/target, SwitcherCore KeyMap и тесты, рекордер/меню подсказки по необходимости.

- [x] Поведение по связанным историям спецификации, без регрессий.
- [x] Подходящие тесты через публичные API, Mac swift build; фактические ограничения UI отмечены.
- [x] Два независимых ревью организует root, исправления замечаний.
- [x] Отдельный коммит после ревью; не пушить. Root выполняет релиз.

Использовать /implement, /tdd; root orchestrates /code-review. Не трогать соседний тикет, docs/state и VERSION без координации.

Сдача12cc6de. Native debug build, KeyMap focused tests, полный Linux XCTest85/85 (root). Два integrated ревью:0находок; финальная permit-rotation правка отдельно перепроверена Standards. Живой AX UI не заявлен проверенным.
