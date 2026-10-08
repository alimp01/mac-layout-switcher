# 22 — Исправить вставку диктовки и отображение результата

**Требование:** G19
**Status:** done
**Blocked by:** None; read-only аудит предоставит дополнительные доказательства.

Прочитать ../dictation-insertion-spec.md и память проекта. Через /implement + /tdd; шов — реальный AppKit panel/native adapter harness и public core policy при необходимости. Не добавлять слои исключительно ради зеркальных тестов.

Зона: DictationTarget/Coordinator/Panel, dictation-only Typist/Engine wiring, узкий public core helper/регрессии при необходимости; native harness tools, README/NEXT_SESSION, VERSION1.4.2. Не менять G18 детектор, модель/download/recognizer без доказанного дефекта. Root ведёт .autopilot/CLAUDE/git/release.

- [x] Воспроизводимые причины отдельно: вставка и видимость fallback.
- [x] Безопасная совместимость полей, устойчивое аннулирование права вставки, полезное сообщение причины.
- [x] Результат отображается, прокручивается/выделяется; явное копирование не теряет текст.
- [x] Meaningful red/green, native AppKit/adapter verification, полный suite root и2ревью.
- [x] Документация/1.4.2; отдельный commit после сигнала root. Не push.

Код e857996;95/95 Linux, native panel/adapter/debug/release, mounted DMG1.4.2 verified; Spec+Standards без блокирующих замечаний. LiveCodex AX+CG/microphone не объявлены проверенными; причины и пределы: ../dictation-insertion-qa.md.
