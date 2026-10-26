T34 / G29 executor handoff — 2026-10-26

Implemented initial Spotlight owner selection shared by keyboard and dictation. Existing validation remains exact PID/element and stored process incarnation. Spotlight requires exact com.apple.Spotlight, canonical system bundle and executable, live process metadata and matching kernel PID/start seconds+microseconds. The kernel token works with the real process's nil Cocoa launchDate. Missing running objects or unusable Spotlight kernel metadata fail closed. Known Spotlight requires current system focus from initial capture onward even when NSWorkspace names Spotlight and AXFrontmost is true or unavailable.

Only initial capture may select Spotlight instead of the menu app. Missing overlay selection or system focus requires a fresh request with no accessibility preparation; native/Chromium retries retain their original PID. Ordinary foreign focus and unknown owners cannot fall back to stale app-focus or prepare an unconfirmed application. Native capture keeps its previous AX round-trip count. Actual owner PID is used for Unicode and observers. Physical key transport and native navigation policy remain unchanged.

Modified nine files: Sources/MacLayoutSwitcher/Speech/DictationTarget.swift; Sources/MacLayoutSwitcher/System/InputFocusGuard.swift; VERSION (authorized 1.4.12); tools/test-system-focus.sh; tools/keyboard-harness/system-focus.swift; tools/keyboard-harness/README.md; tools/test-keyboard-engine.sh; tools/keyboard-harness/engine-boundary.swift; tools/keyboard-harness/engine.swift. No Engine, Typist, SelectionConverter or core product edits. No commit/stage/reset/install/publish. Parent-owned .autopilot and CLAUDE untouched.

Final source manifest: /tmp/mls-g29-final-v3-source-sha256.json (88 files). Diff: /tmp/mls-g29-final-v3-changes.patch. All 76 shared entries match parent FROZEN-SHA256-v3.json; 12 additional test files are frozen here, while parent additionally freezes 11 resources. No manifest mismatches in working tree.

Final product SHA256:
DictationTarget.swift 4767d9a4dca45dede616c5ee89034c06301279e674b6e334d5902fced4251f66
InputFocusGuard.swift a518c09a1d3873689379b32966e67e17ae0ead62849edb3a7ce2f7ea5e0a5eed

Evidence:
- initial-red: PASS 147, FAIL 1; /tmp/mls-g29-initial-red.log
- capture-lock-red: PASS 148, FAIL 2; /tmp/mls-g29-capture-lock-red.log
- final-v3-baseline-red: PASS 166, FAIL 32; /tmp/mls-g29-final-v3-baseline-red.log
- final-v3-green: PASS 199, FAIL 0; /tmp/mls-g29-final-v3-green.log
- final-v3-keyboard-adapter: PASS 20, FAIL 0; /tmp/mls-g29-final-v3-keyboard-adapter.log
- final-v3-dictation-adapter: PASS 2, FAIL 0; /tmp/mls-g29-final-v3-dictation-adapter.log
- final-stable-option: PASS 7, FAIL 0; /tmp/mls-g29-final-stable-option.log
- final-stable-ru-option: PASS 7, FAIL 0; /tmp/mls-g29-final-stable-ru-option.log

The original literal Option regression was baseline RED1 with existing147 PASS, matching AXFrontmost=ok; SystemFocus=foreign-owner; AppFocus=not-read. The next vertical slice produced RED2 for missing initial Spotlight range and late owner hopping. Review supplied RED4 initial same-PID/frontmost identity cases and RED3 missing-process cases; all are included and GREEN in the final raw runner. Final baseline uses literal same fixture plus raw OS substitutions and baseline6241c86d769382413cbb6e63f59816ada55e2ee5. Raw snapshots: final baseline /tmp/mls-system-focus.ZigBsR; final candidate /tmp/mls-system-focus.vtikNb. Each snapshot contains original/compiled sources, seams.patch, SOURCE-SHA256SUMS and run.log.

Engine fixture stabilization is test-only. Retained real TIS source plus immutable copied uchr data prevent live layout changes from altering a running test; native UCKeyTranslate/modifier handling is unchanged. Final ABC and RussianWin Option suites both PASS7. Their logs carry source ID, data size and SHA. US was unavailable on this Mac and rejected as intended; available IDs are com.apple.keylayout.ABC and com.apple.keylayout.RussianWin.

Earlier Engine failures were diagnosed rather than declared product regressions: a debug run recorded startup g changing to п and fixture text привет before the separator; unchanged core approves ghbdtn→ru, руддщ→en and срфе→en. A stable-ABC timing probe then proved .35s startup could still precede initial capture (separator passes natively), whereas the same fixture after readiness suppresses it and produces приветspace. The final fixture waits at most3s for a cached target before ready-field scenarios and for the two successful bootstrap Option texts; assertions and cancellation cases remain. Evidence: /tmp/mls-g29-engine-debug.log, /tmp/mls-g29-core-literals.log, /tmp/mls-g29-engine-timing-proof.log. Parent is running full Engine and fullspeech/DMG against final freeze.

All text/caret/PID outputs in these fixtures come from owned hidden AppKit editors and serialized events. No live private UI/AX, microphone, TCC, clipboard, user-text log, full AXValue write or blind deletion was used. Final physical Spotlight acceptance and release/install remain parent/user steps; these fixtures do not establish WindowServer delivery or universal app compatibility.
