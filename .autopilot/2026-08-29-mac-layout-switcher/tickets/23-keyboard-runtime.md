# 23 — Восстановить ручную и автоматическую конвертацию

**Требование:** G20
**Status:** done
**Blocked by:** None

Прочитать ../keyboard-runtime-spec.md, CLAUDE.md, применить /implement + /tdd. Зона: InputFocusGuard, SelectionConverter, Engine/Typist/ConversionNotice и общий с диктовкой AX adapter; core policy только при необходимости, тесты/native harness, README/NEXT_SESSION/VERSION1.4.3. Детектор/модель не менять. Root ведёт .autopilot/CLAUDE/git/release.

- [x] Исправить capture/write/подтверждение клавиатурного runtime.
- [x] Option с выделением/словом/пустым буфером и auto; сохранить undo/source/разделители.
- [x] Регрессии failures/partial/focus/source, полный suite и native harness/build.
- [x] Два независимых ревью, документация и релиз1.4.3.

Не коммитить и не push до сигнала root. Не управлять UI/микрофоном/TCC.

Код d7b003d; Spec + Standards APPROVED. Root95/95 Linux, полный speech release/DMG, production keyboard/Typist/recovery panel + G19 harnesses PASS. Mounted DMG1.4.3 version/signature/helper verified. Live Option/Codex не проверены; session locked. См. keyboard-runtime-qa.md.
