# 12 — Звук только на исправление

**Требования:** G10 (сужает G02)
**Blocked by:** 11
**Зона:** `Sources/MacLayoutSwitcher/Engine.swift`, `Sources/MacLayoutSwitcher/UI/Sounds.swift`, `README.md`
**Волна:** 10
**Status:** ready

## Из брифа, дословно

> «Убери на каждое нажатие, оставь только на исправление»

## Детали

- Убрать звук клика на keyDown полностью: вызов `sounds?.playKey()` из Engine
  (ветка .keyDown) и из Sounds — сам `playKey`/`keySound`/`keySoundName`
  (мёртвый API не оставлять).
- Звуки исправления (`playCorrection`) и отката (`playUndo`) остаются как есть,
  включая гейт паузы; тумблер «Звуки» продолжает управлять ими.
- README: поправить описание звуков (без «клика клавиш»).
- Swift-ядро/тесты не трогать; `swift test` остаётся 43 зелёных; всё под #if os(macOS).

## Критерии приёмки

- [ ] Ни одного вызова/остатка playKey/keySound в коде
- [ ] playCorrection/playUndo и тумблер «Звуки» работают как раньше
- [ ] README без упоминания клика клавиш
- [ ] Linux: swift build/test зелёные (43)
