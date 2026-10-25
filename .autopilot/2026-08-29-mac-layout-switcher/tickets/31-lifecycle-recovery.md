# T31 — приложение остаётся работоспособным после ошибки обновления или возобновления
**Requirement:** G26
**Blocked by:** T30 if Engine changes needed; Updater/script/main edits can proceed independently
**Status:** implemented, reviewed and verified
**What to build:** failed selfupdate preserves and restarts previous app and
shows actionable failure; resume cannot silently mark disabled EventTap active.

- [x] Real script owned subprocess RED→GREEN for offline/badarchive/buildfail,
  successfulhandoff exactlyonce, safe path quoting/rollback and no doubleinstance.
- [x] Pause/resume rejectedengine.start fixture RED→GREEN, correct visualstate
  and stopped partialworkers, properpermission recovery, no paused voiceactivation.
- [x] Hotkey recorder cancels on focus loss and releases processing; owned
  actualwindow baselineRED/finalGREEN, no accidental hotkey save.
- [x] Relevant integrated keyboard/speech/update regressions and shellsyntax PASS.
- [x] Two final independent reviews, signed release and actualstatus recorded.

Read ../reliability-spec.md and /tmp/mls-g26-speech-lifecycle-audit.txt whenready;
implement/tdd skills. Own Updater/self-update/main lifecycle+own tests. Coordinate
Engine edits with T30executor (root willsequence); no T29focusfile edits.
No version/commit/push/install/liveUI/TCC/privateAX/mic/globalinput untilroot.

Final evidence: ../reliability-qa.md and ../audit/reliability. Both independent reviewers approved exact99-file manifest. Physical installed acceptance remains separate.
