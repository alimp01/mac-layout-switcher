# T28 — восстановить конвертацию по Option

**Requirement:** G25
**Blocked by:** None — can start immediately
**Status:** in-progress
**What to build:** доказанная починка отказа захвата поля перед конвертацией,
с сохранением последнего слова/выделения/отката и точным безопасным отказом.

- [x] Concrete failure identified, meaningful production baseline RED.
- [x] Minimal repair, full Option behavior/context/cancellation tests GREEN.
- [x] No blind mutation/retry, truthful bounded failure reasons if needed.
- [x] Two final independent reviews and appropriate native/core regressions.
- [x] Fullspeech/DMG/release and explicit actual user acceptance status.
- [ ] Actual user all-app Option acceptance; launch not yet confirmed.

Read ../option-capture-spec.md; root owns planning/state/release/UI. Fresh executor
uses implement/tdd. No commit/push/VERSION without root signal. UI access to Codex
was explicitly denied: no alternative UI/AX probing of that app.
