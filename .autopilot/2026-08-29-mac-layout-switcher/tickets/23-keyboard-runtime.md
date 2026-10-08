# 23 — Восстановить ручную и автоматическую конвертацию

**Требование:** G20
**Status:** in-progress
**Blocked by:** None

Прочитать ../keyboard-runtime-spec.md, CLAUDE.md, применить /implement + /tdd. Зона: InputFocusGuard, SelectionConverter, Engine/Typist/ConversionNotice и общий с диктовкой AX adapter; core policy только при необходимости, тесты/native harness, README/NEXT_SESSION/VERSION1.4.3. Детектор/модель не менять. Root ведёт .autopilot/CLAUDE/git/release.

- [ ] Исправить capture/write/подтверждение клавиатурного runtime.
- [ ] Option с выделением/словом/пустым буфером и auto; сохранить undo/source/разделители.
- [ ] Регрессии failures/partial/focus/source, полный suite и native harness/build.
- [ ] Два независимых ревью, документация и релиз1.4.3.

Не коммитить и не push до сигнала root. Не управлять UI/микрофоном/TCC.
