# 14 — Исправление ДО доставки разделителя (активный EventTap)

**Требования:** G12 (переигрывает решение ADR 0004 / таск 04)
**Blocked by:** 13
**Зона:** `Sources/SwitcherCore/EngineCore*`, `Tests/SwitcherCoreTests/EngineCore*`, `Sources/MacLayoutSwitcher/System/EventTap.swift`, `Sources/MacLayoutSwitcher/System/Typist.swift`, `Sources/MacLayoutSwitcher/Engine.swift`, `README.md`, `VERSION`
**Волна:** 12
**Status:** ready

## Что должно заработать

Пользователь набирает «j,yjdbkcz» и жмёт Enter в чате. СЕЙЧАС: Enter уходит в
приложение (сообщение отправляется с ошибкой), и только потом слово
перепечатывается — в уже пустое поле. ДОЛЖНО: Enter перехватывается ДО
доставки; если слово надо исправить — Enter не доходит, слово стирается и
перепечатывается в правильной раскладке, раскладка переключается, и ТОЛЬКО
ПОТОМ Enter отправляется синтетически. Если исправлять нечего — Enter
проходит как есть, без задержки. То же для пробела и Tab (единая схема).

## Из брифа, дословно

> «смотри я набрал обновиться и нажал enter, а замена произошла позже»

## Детали

- **EventTap → активный** (`.defaultTap` вместо `.listenOnly`): колбэк
  возвращает `Unmanaged<CGEvent>?` — `nil` = событие подавлено. Handler
  теперь синхронно решает: `start(handler: (KeyStroke) -> TapDecision)`,
  `enum TapDecision { case pass, suppress }`. Синтетика с маркером 0xC0FFEE
  по-прежнему пропускается без обработки. Re-enable по timeout/userInput —
  как было. Решение должно быть БЫСТРЫМ (детектор на одном слове —
  микросекунды; никакого I/O в колбэке).
- **EngineCore**: для boundary добавь режим «разделитель ещё не доставлен».
  Предлагаемый шов: `handle(.boundary(sep))` возвращает
  `.replaceLast(len: word.count, with: converted, switchTo:)` + новое поле
  `EngineOutcome.reinjectSeparator: Character?` — что напечатать ПОСЛЕ
  перепечатки. Сохрани обратную совместимость тестов: параметр
  `separatorAlreadyTyped: Bool` в init (дефолт — новое поведение `false`;
  старые тесты, ожидающие `word+sep`, переведи или параметризуй). Откат по
  хоткею и порог отмен (таск 06) должны учитывать, что в тексте после
  исправления стоит `converted + sep` — как и раньше, ничего не ломается.
  Сниппеты — та же схема (подавить разделитель, развернуть, реинжектить).
- **Engine**: в колбэке tap'а на keyDown-разделителе: `outcome = core.handle(.boundary)`;
  если `command == .replaceLast` → `return .suppress`, затем асинхронно
  `Typist.replaceLastWord(len:with:)` + `LayoutSwitcher.select` + после
  завершения перепечатки `Typist.type(sep)` (синтетический keyDown/keyUp
  разделителя с маркером; для Enter — keyCode 36, Tab 48, Space 49).
  Иначе → `.pass`. Порядок в Typist гарантирует очередь: backspaces →
  символы → разделитель.
- **Typist**: `replaceLastWord(len:with:then:)` или отдельный
  `typeKey(keyCode:)` в той же очереди, чтобы разделитель ушёл строго после
  перепечатки.
- Хоткеи (Option-tap, keyCode-хоткей) — без изменений; `.pass` для всего,
  что не разделитель на границе слова.
- **README**: обновить описание («исправление до отправки Enter»), убрать
  старую оговорку про Enter-в-чатах. **ADR**: пометка в docs/adr/0004 —
  «Пересмотрено ADR 0011» (оркестратор напишет 0011).
- **VERSION → 1.2.0** (релиз для автообновления).
- Тесты EngineCore на Linux: boundary без доставленного разделителя даёт
  `len: word.count` и `reinjectSeparator == sep`; сниппет — то же; валидное
  слово → `.none`/pass; откат после нового исправления работает.

## Критерии приёмки

- [ ] EventTap активный, `.suppress` реально подавляет событие; синтетика с маркером не обрабатывается; re-enable сохранён
- [ ] EngineCore: replaceLast без разделителя + reinjectSeparator; тесты на Linux (полный прогон зелёный, было 49)
- [ ] Engine: разделитель уходит ТОЛЬКО после перепечатки (очередь Typist); если исправлять нечего — pass без задержки
- [ ] Откат/порог отмен/сниппеты/хоткеи не сломаны (старые тесты живы, при необходимости параметризованы)
- [ ] README обновлён, VERSION=1.2.0
