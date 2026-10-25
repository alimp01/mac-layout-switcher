# T30 — не портить и не блокировать физический ввод
**Requirement:** G26
**Blocked by:** None — disjoint from T29 shared focus repair
**Status:** implemented, reviewed and verified
**What to build:** normal navigation must cancel pending rewrite and remain a
native navigation event; EventTap interruption must not leave stale shortcut
ownership/gestures blocking future ordinary typing.

- [x] Baseline RED and finalGREEN for Left/Right/Home/End/Escape/function keys,
  non-repeat and repeat, during auto/Option/busy and idle. No C0 injection.
- [x] Timeout/userInput tap interruptions retire consumed-key/keyUp ownership
  and activehotkey/dictation gestures safely; ordinary click semantics unchanged.
- [x] Existing typing, separatorownership, modifier/toggle/recording regressions pass.
- [x] Two independent final reviews, final integratedvalidation.

Read ../reliability-spec.md, implement/tdd skills. Scope Engine/EventTap/KeyTranslator
inputclassification/ownership + tests. Do not edit T29focus files. No codeversion/
commit/release/UI/TCC/privateAX/microphone without root. Own inprocess fixtures only.
Audit proof /tmp/mls-g26-keyboard-audit-probe/tools and logs in spec.

Final evidence: ../reliability-qa.md and ../audit/reliability. Both independent reviewers approved exact99-file manifest. Physical installed acceptance remains separate.
