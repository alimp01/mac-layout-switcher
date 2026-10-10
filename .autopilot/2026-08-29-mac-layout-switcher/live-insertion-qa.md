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

## После ручной разблокировки

V2: Empty-own-editor, CUA C/H/A/T дали `срфе` до Space; после Space
осталось `срфе `. Приёмник PID46232, но frontPID77421/com.openai.codex
на каждом keyDown. Коды 8/4/0/17/49, marker=0, sourcePID46121;
production KeyTranslator даёт те же символы. AX Raise и щелчок по
заголовку не изменили foreground. CUA launch_app на этом Mac отсутствует;
доступ к Dock завершился timeout. Обходные shell UI вызовы не применялись.
Поэтому этот опыт не проверяет обычный ввод через EventTap MLS.
Пользователю запрошен один физический C/H/A/T+Space в собственном V2;
ответ/события пока ожидаются.

Runtime read-only: установленный executable и один PID45401 те же,
что перед записью. BundleShortVersion1.4.4/BundleVersion1;
binary SHA256=131374d8d25a6e1ec0f01d616d5ba0f65140f5eb9c46461a4fffbe91d940dac2.
Он отличается от root DMG build: автообновление пересобирает исходники
на Mac, поэтому равенство бинарников не ожидается и причина этим
не доказана. Executor нашёл новый G21 retainReplacement symbol,
что исключает очевидный старый 1.4.3 Typist, но не подтверждает exactcommit.

## Физический ввод и отдельный contract RED

Пользователь физически набрал C/H/A/T+Space в V2; root AX readback
показал `chat `. Native журнал содержит source `срфе` до разделителя,
receiverPID46232=frontPID46232, sourcePID0/marker0 и коды 8/4/0/17.
Space не появился в журнале native keyDown, что согласуется с подавлением
разделителя и inline direct AX заменой. Это живой PASS только собственного
AppKit-поля. Пользователь подтвердил, что сбой остаётся именно в Codex.

Executor RED `/tmp/mls-t25-delayed-selection/run.log`: неизменённый
production Target+Typist получает ACK selection RPC, читает старую caret4/0,
возвращает `.untouched`, replay Space приходит после применения range0/4,
native NSTextView теряет `срфе` и содержит лишь пробел. Text writes=0,
recovery original/planned/held пустые. Это доказанный дефект контракта
ACK-before-apply с подставленной AX/CG границей; причина видео этим пока
не доказана. Минимальное исправление подтверждения selection/readback
и удержания всего ввода при pending selection поручено T25 исполнителю.

Отдельная owned HTML страница `/tmp/mls-g22-owned-codex-field/index.html`
открыта в IAB tab2, localhost127.0.0.1:18722. Первый физический опыт оставил
`срфе ` в обоих полях. Однако V1 logger сам генерировал selectionchange
из-за перезаписи readonly textarea (n>2000): его timing недостоверен.
V1 source сохранён отдельно; V2 использует pre+dedupe, root controlled fill
дал 3 нормальных события без цикла. Страница очищена reload, повторный
физический ввод ожидается. Browser pane не равен главному composer;
чужие сообщения/поля не редактировались, никаких внешних запросов нет.

## Owned Codex hardware RED и кандидат 1.4.5

После чистого reload V2 пользователь физически набрал C/H/A/T при RU.
Журнал содержит trusted keyDown 8/4/0/17 (KeyC/H/A/T), без repeat/modifiers.
В 2026-10-10T15:43:50.173Z исходник `срфе`, caret[4,4]. В .803Z
selectionchange[0,4], исходник тот же. В .814Z keyDown Space при выделенном
слове; .816Z beforeinput insertText data=пробел; .817Z input value=` `,
caret[1,1]. Событий вставки `chat` нет. Это реальное удаление в собственном
Chromium поле IAB Codex, не проверка частного главного composer.
Excerpt `/tmp/mls-g22-owned-codex-field/hardware-v2-excerpt.json`, SHA256
81cdbbf9e097e62fb25ffd9b2e08b79c4616b199d49f958372adb5f473c39542.
V2 HTML SHA2568c6dd50e4d25282e7371d8f7c38f21653a1686a2b1d994c3cf98d07fdbc07b15.
События согласуются с concrete contract RED: AX ACK принят, selection
применяется позже старого readback; `.untouched` ошибочно replay-ит separator.
Сам журнал не раскрывает внутренние вызовы приложения.

T25 minimum fix: bounded confirmation selection6×25ms вне EventTap;
новое `.unconfirmedSelection` удерживает всю текущую очередь и сохраняет
original/planned/held. Restoration тоже подтверждается; preselected source
не отправляет повторный selection RPC. Transport и clipboard не менялись.
Sources после review freeze не менялись. Кандидат VERSION1.4.5 собран,
публичная версия остаётся1.4.4 до аппаратной приёмки.

Executor: `/tmp/mls-g22-executor-regression-report.txt`, SHA256
7da2496c8a53bbd385ca38f7b1f8a12017504620404eec035697e0d6bfbd5263.
Selection-delay same runner baselineRED `/tmp/mls-keyboard-selection-delay.eBof51`
(actual ` x`, untouched, no recovery), candidateGREEN
`/tmp/mls-keyboard-selection-delay.Q5NZVR`; preselected baselineRED M5VdRj.
Root независимый final fixtureGREEN `/tmp/mls-keyboard-selection-delay.2TBufd`.
Это production Target/Typist+подставленная AX/CG граница+own NSTextView,
не физическая WindowServer доставка. Проверены Space/Enter/ShiftEnter/Tab,
fastinput, delayed restoration, cancellation, preselected Unicode и recovery.

Spec approve: frozen Sources, delayed baselineRED/finalGREEN, G19+keyboard+panel
PASS; Engine unchanged rerunPASS yrXsXA. Standards approve, 0 blockers:
final selection-delay nOud6L GREEN, same fixture baselineRED
mls-g22-standards-baseline.9q95ezio, EnginePEb12U fullPASS, G19+keyboard+panelPASS.
Ранние Engine source-before-separator assertions FAILED при смене TIS: actual
`привет`, expected`ghbdtn`, nowG`п`. Эта предпосылка правильно отказала;
не считать эти прогоныPASS и не менять product ради fixture. Диагностика
ошибки уточнена; whole runs executorAWA36G/OoscIn и reviewerPEb12U PASS.

Root fullspeech swiftreleasePASS39.11s, .app buildPASS, deepstrict codesignPASS,
ShortVersion1.4.5. Root Linux95/95PASS в `/tmp/mls-g22-linux.HdVgbk/run.log`
из изолированного архива тех же Sources. Native binary SHA256
c0d8f234e223623cda80149e3c43eec6a8b520798e09a63c2ffb06633b81dfe9.
Mac вновь заблокирован; запрос ручной разблокировки отправлен. Кандидат
ещё не установлен, hardwareGREEN остаётся обязательным release gate.

Final Spec supplemental tool review APPROVE, 0 blockers. Root final Engine
`/tmp/mls-keyboard-engine.KPSkna/run.log` fullPASS. DMG candidate mounted
read-only:1.4.5/codesign deepstrict/nativehelper/Applicationssymlink and
mainbinarymatch PASS. Artifact `outputs/MacLayoutSwitcher-1.4.5-candidate.dmg`,
bytes10958211, SHA25658e067a3d42eed8ba5db44c29202f8becf6d7f249b7fac6cc945f6609c9641b7.
Durable Sourcesmanifest, ownhardwareRED excerpt, rootGREEN logs and approvals
в `audit/live-insertion/`. Кандидат не опубликован; hardware gate pending.

Reviewed candidate locally committed2163e0a3e7fa7f388ba551ef97b69d9a6f0a3126.
No push/archive; installed/public1.4.4 unchanged. Hardware gate blocks release.

## Продолжение после «готово»

Mac разблокирован. CUA getApp `/Applications/MacLayoutSwitcher.app` дважды
возвращает timeout; SystemUIServer тоже timeout. Inventory и ownedIAB DOM
доступны. Не обходить UI через shell/CG/osascript. Read-only PID45401 всё ещё
старый1.4.4; пользователь попросен выбрать менюMLS→Выйти и ответить «закрыл».
Backup старой.app сохранён в candidate scratch/installed-1.4.4-backup.app,
mainbinary точный; candidate deepstrict повторноPASS. Installed.app не менялась.
После подтверждённого отсутствия oldPID разрешена замена reviewedcandidate
по текущему user-ready workflow, запуск толькоCUA; затем физический ownCodex
срфе+Space с before-source/readback. Tab2 повторноhandoff.

## Reviewed candidate installed after «закрыл»

OldPID45401 confirmedabsent. Root filesystemcopy/deepstrict candidate stage,
preserved oldinstalled.app in scratch/replaced-installed-1.4.4.app thenrename
reviewedcandidate into /Applications/MacLayoutSwitcher.app. Deepstrict and
exactbinarySHA c0d8f234… PASS; Info.plist1.4.5. CUAgetApp fullpath launched
newPID49664 at19:09:02 and displayed actual permissionsalert: Accessibility +
InputMonitoring. Binding assignmentfailed, later nativegetApp timedout again;
no shellUI launch/permissionsforce. Useraskedrestore twoapppermissions and
menu«Я выдал разрешения». No mic/clipboard/privatefield use.
OwnedIABtab2 cleanreload, bothfields/log empty, markedhandoff for nextphysical
candidatecheck. Public1.4.4 unchanged; candidate1.4.5 not yet hardwareGREEN.
