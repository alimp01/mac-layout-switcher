# 19 — Автоматическая подготовка модели без ложной порчи

**Требование:** G16
**Blocked by:** None
**Status:** ready-for-agent

## Что построить
Истории 3–4. Воспроизвести отказ на реальном optimized_cache; сохранить проверку целостности и автоматизировать первый setup/recovery. Проверить повторное использование после запуска helper.

Спецификация: ../input-repair-spec.md. Зона: SpeechModelStore, SpeechRecognitionProcess при необходимости, DictationCoordinator, DictationPanel, SpeechRecognizer helper при необходимости. Не менять Engine/Typist/main.

- [ ] Поведение по связанным историям спецификации, без регрессий.
- [ ] Подходящие тесты через публичные API, Mac swift build; фактические ограничения UI отмечены.
- [ ] Два независимых ревью организует root, исправления замечаний.
- [ ] Отдельный коммит после ревью; не пушить. Root выполняет релиз.

Использовать /implement, /tdd; root orchestrates /code-review. Не трогать соседний тикет, docs/state и VERSION без координации.
