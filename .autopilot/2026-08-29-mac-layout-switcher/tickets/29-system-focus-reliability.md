# T29 — рабочее обнаружение поля для Option и автоисправления

**Requirement:** G26 (G25 actual failure continuation)
**Blocked by:** None — can start immediately
**Status:** in-progress
**What to build:** устранить доказанный отказ unavailableField на системной
границе; восстановить конвертацию без ослабления защиты чужого текста.
Read ../reliability-spec.md; audits of other subsystems feed separate tickets
if independent product defects found.

- [x] Prove two resolver defects with raw system-boundary RED (installed user cause remains unknown).
- [ ] Confirm the installed user failure is resolved with physical keyboard.
- [x] Minimal shared focus/capture repair with truthful diagnostics.
- [x] Auto/Option/dictation/cancellation regressions preserve text.
- [x] Two independent reviews and complete native/Linux/release verification.
- [x] Exact installed version and actual user acceptance status recorded honestly.

Executor uses implement/tdd; no product edits by root. No release/VERSION/commit
without root signal. No live UI/AX probing of denied apps or TCC bypass.

1.4.9 exact reviewed candidate installed; physical acceptance pending. See ../reliability-qa.md.
