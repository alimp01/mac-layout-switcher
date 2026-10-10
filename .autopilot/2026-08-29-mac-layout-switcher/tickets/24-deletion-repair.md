# 24 — Исправить удаление вместо замены

**Требование:** G21
**Status:** done
**Blocked by:** None

Прочитать ../deletion-repair-spec.md и CLAUDE. Через /implement + /tdd. Зона: production text transport, Target/Typist/SelectionConverter/DictationTarget и recovery UI, только необходимые core policies; meaningful native/transport tests; README/NEXT_SESSION/VERSION1.4.4. Root ведёт .autopilot/CLAUDE/git/release. Сначала аудит/доказательство причины, затем минимальный код.

- [x] Причина deletion-only и regression до исправления: autorepeat проходит в temporary selection.
- [x] Исправить воспроизведённую гонку доставки; безопасно сохранять исходник/замену при неопределённости.
- [x] Проверить защитный поднабор: keyboard/selection/dictation/queue, native/core suite.
- [x] Два независимых финальных ревью: Spec+Standards approved; коммит/релиз по ритуалу root.

Защитный поднабор проверен Spec и Standards без blocking замечаний: сохраняются
исходный сегмент, полный текст замены и удержанный ввод. Настоящая генерация
CGEvent покрыта тестом; post в WindowServer подставлен. Native fullspeech и
Linux95 PASS, frozen66files совпали с checkout. VERSION1.4.3, релиза нет.
Прежние CUA утверждения о доказанной автозамене TextEdit/Chrome отозваны:
исходник до разделителя не снимался, RussianWin уже был активен.
Пользователь уточнил «да во всех» приложениях. Локальный protective commit
c57e700 не опубликован; не закрывать T24 по recovery-only.

Триггер отвечен: «при автоматическом исправлении после пробела/Enter».
Нужен аудит настоящего EventTap→KeyTranslator и физических keyDown/keyUp,
timing/очереди автоисправления; прошлый Engine probe их подменял. Option manual
fixture отменён, пользователю тестировать Option не требуется. Mac заблокирован; собственный документ пока открыт.

Без UI/mic/TCC/private text; root владеет CUA. Не коммитить до сигнала root, не push.

RED: /tmp/mls-g21-repeat.3xn__0zm/red.log, AX/Unicode × Space/Enter 4/4.
Real EventTap.process/KeyTranslator/Engine; собственный NSTextView получает
реальный повтор CG→NSEvent и стирает руддщ во временном выделении. Ранний
reset инвалидирует permit до busy replay. Локальная AppKit доставка, не
физический WindowServer e2e. Исполнитель добавляет regression и минимальный fix.

Финал: frozen /tmp/mls-g21-autorepeat-final.v8tpedvg, 160checksums PASS;
тот же runner baselineRED и finalGREEN. Root и оба freshreviewers независимо
повторили native suites/Engine; Linux95 и fullspeech build PASS. Исправлена
конкретная autorepeat race + separator keyUp ownership; hardware/WindowServer
и все случаи жалобы пользователя не заявлены проверенными. VERSION1.4.4
готовится исполнителем после approval; публикация отдельно по ритуалу root.
