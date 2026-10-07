# 19 — Автоматическая подготовка модели без ложной порчи

**Требование:** G16
**Blocked by:** None
**Status:** done

## Что построить
Истории 3–4. Воспроизвести отказ на реальном optimized_cache; сохранить проверку целостности и автоматизировать первый setup/recovery. Проверить повторное использование после запуска helper.

Спецификация: ../input-repair-spec.md. Зона: SpeechModelStore, SpeechRecognitionProcess при необходимости, DictationCoordinator, DictationPanel, SpeechRecognizer helper при необходимости. Не менять Engine/Typist/main.

- [x] Поведение по связанным историям спецификации, без регрессий.
- [x] Подходящие тесты через публичные API, Mac swift build; фактические ограничения UI отмечены.
- [x] Два независимых ревью организует root, исправления замечаний.
- [x] Отдельный коммит после ревью; не пушить. Root выполняет релиз.

Использовать /implement, /tdd; root orchestrates /code-review. Не трогать соседний тикет, docs/state и VERSION без координации.

Сдача: 2bb8f1f. Spec/Standards: 0 actionable findings. Реальный native harness: все четыре SHA совпадают; модель принимается с optimized_cache, повторное офлайн распознавание и новая проверка из нового процесса; усечённый cache восстанавливается runtime. Свежая загрузка/repair, offline/cancel staging cleanup и сохранение рабочей модели проверены. Два изменённых файла компилируются; общий Mac build после T18/T20.
