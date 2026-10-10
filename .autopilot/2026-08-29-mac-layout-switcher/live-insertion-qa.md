# G22 — live insertion QA

Запись прочитана root из Desktop, frames в /tmp/mls-screen-review-20261010/:
contact.png; first-change.png (3.5–5.5с,10fps), second-change.png (9–11с,10fps).
Два срфе→пустота, chat отсутствует, prefix/пзе сохранены. No audio stream.
Неверно утверждать, что запись доказывает repeat/точную физическуюклавишу.
InstalledCFBundleVersion1.4.4, binarymtime17:56:29.637, единственныйPID45401
launched17:57:06; recording17:57:37–58. Root actions read-onlyfile/metadata,
никаких модификаций privatecomposer или публикации записи.

## Дополнительная диагностика 10.10

В собственном документе TextEdit `/tmp/MLS-Option-Test.rtf` root через CUA
проверил физические C/H/A/T при RussianWin. До Space наблюдалось `срфе`;
после Space — `Срфе ` (автокапитализация TextEdit) и во втором опыте
`test срфе `. Автозамена не сработала: это не PASS и не воспроизведение
удаления. Документ сохранён и закрыт; чужие документы не редактировались.
CUA-доставка в приёмник не доказывает прохождение глобального EventTap.

Read-only проверка настроек: autoSwitch=true, TextEdit не исключён;
Input Monitoring и Accessibility для MacLayoutSwitcher включены.
Другие настройки/значения шаблонов не выводились. В snippets.json
ключи `срфе`, `chat`, `ghbdtn`, `привет` отсутствуют: пустой snippet
не объясняет удаление `срфе` на записи.

Собственный V1 `/tmp/mls-t25-own-transport/TransportProbe.app`
вызывал неизменённый production postUnicode только в собственный PID
по явному нажатию root CUA. Trusted=false, событий приёмник не получил,
seed не изменился. Это отказ/ограничение нового диагностического процесса,
не доказательство неисправности разрешённого установленного MLS.
Полученные отдельно CUA keyDown имели marker=0. Read-only NSWorkspace
frontmost вернул com.openai.codex, хотя CUA обращался к V1: foreground
и прохождение EventTap требуют отдельной проверки.

V2 `/tmp/mls-t25-own-key-events/TransportProbe.app` подготовлен и открыт
через CUA. В собственном окне он показывает Trusted=false,
preflightPost=false, preflightListen=false; API запроса разрешений нет.
Добавлены счётчики/metadata приёмника и перевод неизменённым KeyTranslator,
кнопка очистки только собственного поля, стандартный Quit.
Следующая CUA-проверка остановлена: Mac заблокирован, автоматическая
разблокировка недоступна. Новые разрешения, микрофон и чужие поля
не использовались. Для дальнейшего живого опыта нужна разблокировка Mac.

Headless CG→NSEvent→собственный NSTextView остаётся лишь проверкой
локального AppKit, не доставки через WindowServer. Причина G22 пока
не доказана; код/VERSION не изменены, 1.4.5 не выпущена.
