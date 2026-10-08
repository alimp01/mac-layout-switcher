# G19 — исходный аудит 2026-10-08

Основа:1.4.1 /53111dd; установленная версия Info.plist1.4.1. Скриншот пользователя показывает отказ автовставки и пустую область результата. Сообщение появляется после непустого recognized text/непустого остатка — это не доказательство пустого результата модели.

## Подтверждённый дефект панели

Независимый audit_dictation_insertion скомпилировал production DictationPanel.swift в изолированном AppKit harness. NSTextView создан с нулевым frame и без width autoresizing; NSScrollView имеет ширину382, document view и text container имеют ширину0. Строка содержит78символов. Поэтому glyphs обрезаются. При установке ширины документа382 в эксперименте тот же текст появился. Артефакты harness/original.png/sized.png: /tmp/mls-g19-panel.qwZROD/. Root просмотрел оба render и подтвердил наблюдение. Микрофон/clipboard/поля пользователя не затрагивались.

Apple setup: https://developer.apple.com/library/archive/documentation/Cocoa/Conceptual/TextUILayer/Tasks/TextInScrollView.html

## Причина отказа вставки требует дифференциации

DictationTarget требует system-wide focusedAXelement, PID и AXSelectedTextRange, затем идентичное поле+range. Сейчас причины схлопываются в одно сообщение. Возможны неинициализированное AXдерево Electron, недоступный range, transient lookup, смена поля/выделения. Точная причина в пользовательском Codex не доказана.

Официальный Electron механизм AXManualAccessibility=true на applicationAXelement, с последующим повторным чтением: https://www.electronjs.org/docs/latest/tutorial/accessibility . Запрос ограничить временем/целевым приложением/наличием permission. Не подменять range нулём, не принимать один PID, не искать произвольного потомка. Negative/overflow ranges запрещены.

Диагностический процесс AXIsProcessTrusted=false; это НЕ доказательство отсутствия разрешения у установленного переключателя. Не выдавать mock/native compile за liveCodexприёмку.

## Дополнительные риски исправления

Текущий permit создаётся после распознавания, поэтому не помнит раннее вмешательство пользователя; требуется стойкая инвалидизация. Текущий CGEvent.post считает отправленные символы, не подтверждает получение редактором. Не делать автоматический retry после потенциальной частичной записи. Причины fallback нужны отдельно: permission, unsupported, changed, interrupted; transcript не логировать.

## Реальное приложение пользователя

LaunchServices (osascript path to application Codex) возвращает /Applications/ChatGPT.app/. Info.plist: com.openai.codex,26.1002.52244. Frameworks содержит Codex Framework.framework (com.openai.codex.framework,155.0.8059.27) и Sparkle.framework; Resources содержит app.asar/electron.icns/owl-electron-app.json. Поэтому проверка исключительно наличия Electron Framework.framework пропустила бы реальный случай. Метаданные пакета прочитаны без чтения пользовательских данных. Маршрут выбирается по совместимости, но не ослабляет проверки конкретного поля/selection/permission.
