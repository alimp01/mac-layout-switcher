# 17 — Диктовка по горячей клавише и вставка в поле

**Требование:** G14
**Blocked by:** контракт API T16 согласован (см. ниже); финальная интеграция/сборка и закрытие зависят от готового T16
**Status:** done

## Что должно заработать

Удержание ⌃⌥Space записывает речь, отпускание распознаёт локальным GigaAM и вставляет текст в исходное поле без отправки. Горячая клавиша настраивается, индикатор виден, Esc отменяет. Первая настройка загружает модель. Все 12 историй ../speech-spec.md обязательны.

Зона: SwitcherCore публичное состояние диктовки + тесты; AppConfig/Engine/EventTap/KeyStroke/Typist (keyUp, подавление пары событий хоткея), AVFoundation запись, main/UI, build.sh microphone description, README, VERSION=1.3.0. Не переписывать T16 backend без найденной необходимости.

- [x] Полный путь настройка → загрузка → разрешение микрофона → запись → offline ASR → вставка и повторная запись.
- [x] Настраиваемое сочетание, миграция config, конфликт/голая печатная клавиша отклоняются; autorepeat не перезапускает; раннее отпускание при запросе разрешения не оставляет микрофон включённым; рекордер сочетания не запускает функцию.
- [x] Esc/пауза/выход/ошибки отменяют и чистят запись/процесс; поздние результаты игнорируются. Ограничение записи пять минут.
- [x] Без Enter/clipboard/автоисправления результата; общая очередь вставки, reset буфера и отмены; смена поля показывает результат вместо ввода в другое место; Secure Input блокируется.
- [x] Linux тесты состояния через SwitcherCore: hold/release, cancel во время распознавания и поздний completion, failure/retry, пустой результат, session identity. Старые тесты живы.
- [x] Mac swift build + release .app/.dmg; реальные микрофон/вставка отмечаются отдельно как ручная приёмка, не выдавать их за пройденные.
- [x] Два ревью организует root; не пушить, не коммитить до сигнала root. Релизный ритуал root после проверки.

## Согласованный контракт и границы параллельной работы

T16 предоставил API: `SpeechTask.cancel()`; `SpeechModelStore.modelDirectory: URL`, `static totalDownloadBytes`, `checkInstalled(completion: Result<URL,Error>) -> SpeechTask`, `download(progress: (Double)->Void, completion: Result<URL,Error>) -> SpeechTask`, `cancel()`; `SpeechRecognitionProcess.unavailabilityReason: String?`, `transcribe(wavURL:modelDirectory:timeout:completion: Result<String,Error>) -> SpeechTask`, `cancel()`. Все completion/progress на main. Process копирует source WAV в свою temp-dir, его очищает; исходный WAV очищает recorder T17. Helper в Contents/Helpers/SpeechRecognizer.

До завершения T16 исполнитель T17 правит только свои Sources/Tests/VERSION, не Package.swift/build.sh/README/backend/ADR. Затем последовательно добавляет microphone plist и README после сообщения root. Такой порядок сохраняет непересекающиеся зоны; финальная приёмка всё ещё blocked by T16.

## Сдача

Коммит: 0b378f3. Два независимых ревью и повторная проверка исправления P2 пройдены. Итоговый Linux XCTest: 71/71; Mac debug/release и подписанный DMG проверены. Микрофон пользователя и вставка во внешние поля остаются ручной приёмкой, не заявлены проверенными (см. speech-qa.md).
