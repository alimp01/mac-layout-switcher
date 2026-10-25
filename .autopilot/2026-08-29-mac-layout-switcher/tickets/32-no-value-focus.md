# T32 — восстановить захват поля при AX noValue
**Requirement:** G27
**Status:** reviewed; installed 1.4.10; publication in progress
**Blocked by:** none
Read ../no-value-focus-spec.md and G26 raw-system-focus tests.
- [x] Explain exact noValue failure path and source-supported recovery.
- [x] Literal raw RPC baselineRED and finalGREEN; no mocked focusedElement.
- [x] Shared capture safely handles valid alternatefocus/lazybootstrap.
- [x] Stale/foreign/ambiguous/secure/limit/cancel cases fail without text mutation.
- [ ] Relevant native checks, two independent reviews, signed release/publication.
- [ ] Actual installed keyboard result recorded separately.
Fresh executor follows implement/tdd. No root product edits; no live private UI/AX,
TCC, microphone, global input, helper bypass of prior CUA denial. No version/
commit/install/push until root signal. Scope focus capture + necessary tests/docs.


Executor evidence (2026-10-25): `../audit/no-value-focus/T32-evidence.txt` and
`T32-final-source-sha256.json`. Chromium155 source confirms removed manual hook
and enhanced2s debounce. Exact final fixture: baseline1.4.9 RED13 at
`/tmp/mls-system-focus.hdFIuI`; final GREEN77 at `/tmp/mls-system-focus.IdMm8Z`.
Native keyboard/dictation adapters and full Engine27/navigation160 PASS.
Independent PID-replacement counterexample fixed; final product hashes
DictationTarget066a26bb / InputFocusGuard31a4323f. VERSION1.4.10 authorized by
root; no executor commit/install/push. Root finalreviews/release and physical
acceptance remain separate; no installed-app success is inferred from fixtures.

Final implementation uses scoped bootstrap, not traversal. Both reviews approve;
77 final raw checks pass; final signed full-speech build and mounted DMG verified.
Actual installed acceptance remains pending; see no-value-focus-qa.md.
