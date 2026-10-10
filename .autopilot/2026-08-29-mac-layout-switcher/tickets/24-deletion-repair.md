# 24 — Исправить удаление вместо замены

**Требование:** G21
**Status:** in-progress
**Blocked by:** None

Прочитать ../deletion-repair-spec.md и CLAUDE. Через /implement + /tdd. Зона: production text transport, Target/Typist/SelectionConverter/DictationTarget и recovery UI, только необходимые core policies; meaningful native/transport tests; README/NEXT_SESSION/VERSION1.4.4. Root ведёт .autopilot/CLAUDE/git/release. Сначала аудит/доказательство причины, затем минимальный код.

- [ ] Причина deletion-only и regression до исправления.
- [ ] Исправить доставку; безопасно сохранять исходник/замену при неопределённости.
- [ ] Проверить keyboard/selection/dictation/queue и полный native/core suite.
- [ ] Два независимых ревью, коммит по сигналу root, релиз.

Без UI/mic/TCC/private text; root владеет CUA. Не коммитить до сигнала root, не push.
