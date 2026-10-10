# T26 — диктовка вставляет полную фразу

**Requirement:** G23
**Status:** ready-for-release — frozen4 both reviews approved, native gates passed
**Blocked by:** None — can start immediately

**What to build:** recognized phrase completes once in originaleditablefield
instead of firstchunk only; truthful selectable fullresult on failure.

- [x] Audit concrete actualprefix failure; same meaningfulbaselineRED/finalGREEN.
- [x] Minimalguarded fix, fullUnicode/selection/tail/caret and no duplicatewrites.
- [x] Stickyfocus/input/AXmutation cancel and recovery preserved.
- [x] G19/G22 regressions + nativefullspeech + Linux95 + twofreshreviews.
- [ ] Version1.4.6/release after rootsignal; honestmanualUI boundaries.

Read ../dictation-completion-spec.md and relevant previous G19/G22 specs/ADR.
Fresh single-ticket executor /implement+/tdd. Codezone dictationdelivery/
permit/coordinator/necessarysharedadapter + relevanttools + README/NEXT/VERSION.
Root .autopilot/CLAUDE/git/build/release/CUA. No shellUI/globalCG/privateAX
editing/mic/TCC requests. OwnheadlessAppKit fixture permitted. Readback and
notification defects are hypotheses until literalRED. Do not commit/push
or bumpVERSION until rootsignal. Twoindependent finalSource reviews required.
