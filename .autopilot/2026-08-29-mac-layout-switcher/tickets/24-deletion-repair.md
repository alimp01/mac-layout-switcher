# 24 — Исправить удаление вместо замены

**Требование:** G21
**Status:** in-progress
**Blocked by:** None

Прочитать ../deletion-repair-spec.md и CLAUDE. Через /implement + /tdd. Зона: production text transport, Target/Typist/SelectionConverter/DictationTarget и recovery UI, только необходимые core policies; meaningful native/transport tests; README/NEXT_SESSION/VERSION1.4.4. Root ведёт .autopilot/CLAUDE/git/release. Сначала аудит/доказательство причины, затем минимальный код.

- [ ] Причина deletion-only и regression до исправления.
- [ ] Исправить доставку; безопасно сохранять исходник/замену при неопределённости.
- [x] Проверить защитный поднабор: keyboard/selection/dictation/queue, native/core suite.
- [ ] Два независимых ревью, коммит по сигналу root, релиз.

Защитный поднабор проверен Spec и Standards без blocking замечаний: сохраняются
исходный сегмент, полный текст замены и удержанный ввод. Настоящая генерация
CGEvent покрыта тестом; post в WindowServer подставлен. Native fullspeech и
Linux95 PASS, frozen66files совпали с checkout. VERSION1.4.3, релиза нет.
Тесты установленной1.4.3 через CUA дали успешную автозамену в TextEdit и тёплом
ChromeMDN поле, но пользовательское deletion-only не воспроизвели. Точное
приложение/поле и запуск Option либо автоматика запрошены; причина/доставка
остаются открытыми. См. ../deletion-repair-qa.md. Не закрывать T24 по recovery-only.
Локальный коммит защитного кода: c57e700; push и релиз не выполнялись.

Без UI/mic/TCC/private text; root владеет CUA. Не коммитить до сигнала root, не push.
