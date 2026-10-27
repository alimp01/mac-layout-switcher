# T34 — конвертация в системном Spotlight
**Requirement:** G29
**Blocked by:** none
**Status:** done; actual Spotlight Option accepted by user27.10
**What to build:** Option/автозамена работают в подтверждённом поле Spotlight,
не затрагивая приложение под ним и не ослабляя защиту чужого поля.
Read ../spotlight-focus-spec.md; follow implement/tdd.
- [x] Same baseline raw foreign-owner RED → candidate GREEN with actual text/PID.
- [x] Narrow validated initial overlay capture, strict existing-target validation.
- [x] Negative identity/focus/process/selection/cancel and existing app regressions.
- [x] Fresh Spec + Standards reviews, fullspeech/DMG/root release.
- [x] Actual Spotlight physical acceptance recorded separately.
No git/version/install/publish before root signal. No private AX/UI/TCC/mic.

Published code dba351ccdd82cd737661531e744dc0bd2c5b33e7; raw VERSION/public archive/PAX/all384 Git blobs verified.

Actual acceptance27.10: user replied «Да, получилось «привет»» for ghbdtn+Option
without selection in Spotlight1.4.12. Auto separators/dictation remain separate.
