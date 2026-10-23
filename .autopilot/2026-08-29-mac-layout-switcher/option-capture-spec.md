# G25 — Option действительно исправляет текст

## Problem Statement
В установленной1.4.7 Option вместо конвертации текста в Codex и других приложениях показывает общий
отказ захвата поля/выделения. Текст остаётся неверным. Пользователь явно отверг
трактовку «просто переключить раскладку»: требуется замена набранного текста.
Скриншот подтверждает отказ, но не различает permission/field/range/stale target.

## Solution
Установить конкретную причину отказа и восстановить ручную конвертацию. Не
исправлять задачу одним скрытием предупреждения. Если редактор действительно
не предоставляет нужные данные, сообщать точную доступную причину без ложного
обвинения разрешений. Диагностика не должна писать пользовательский текст.

## User Stories
1. Option преобразует последнее слово при курсоре в конце, без уничтожения контекста.
2. Option преобразует явно выделенный текст, сохраняя остальную часть поля.
3. Повторный Option сохраняет штатный откат, пустое поле — штатную смену RU/EN.
4. Новое поле не отклоняется исключительно из-за устаревшего сохранённого поля,
   но смена поля/текста/курсора во время операции отменяет её безопасно.
5. Недоступное поле, недоступное выделение, secure input и отсутствие разрешения
   не должны ошибочно выдаваться за одну подтверждённую причину.
6. Неуспешная операция не теряет исходник/план/удержанный ввод и не повторяет запись.

## Implementation Decisions
Предпочитать существующие seams Engine/SelectionConverter/Target/platform adapter.
Сначала доказать конкретный production baseline RED; не ослаблять защиту ради
зелёного теста. Никакого clipboard/backspace/whole-field blind fallback. Выбор
текста для конвертации остаётся прежним; не преобразовывать автоматически весь
документ. Нет расширения словарей или подавления всех предупреждений.
Если для реальной диагностики требуется bounded reason/status, никаких текстов,
clipboard, telemetry или persistent keystroke logs.

## Testing Decisions
Регрессия должна пройти через реальный production capture/Option flow и
соответствовать доказанной причине. Тесты последнего слова, выделения, нового
поля, cancellation, protected/denied, bootstrap delay и safe recovery. Сохранить
G22 selection delay/G23 dictation/G24 Safari/WebKit регрессии. Два независимых
ревью, native fullspeech build, Linux core suite и обязательный release ritual
после согласованного root VERSION bump. Не считать mock/harness живой приёмкой.

## Out of Scope
Изменение правил словаря, модель speech, аккаунты, автоматическая отправка сообщений,
доступ к закрытым средствам UI-управления или обход ограничений инструмента.

## Further Notes
CUA explicitly denies access to com.openai.codex for safety; do not bypass via
shell AX/AppleScript/CDP/another agent. Own isolated fixtures and source analysis
remain allowed. Real Codex acceptance requires user manual action/evidence.
User confirmed caret at end WITHOUT selection. Primary flow is last-word Option; retain selected-text flow.
