# G27 — AX noValue на реальном1.4.9
## Problem
Screenshot25.10 from Codex response field: typed ghbdtn remains after Option;
AXFrontmost=ok, SystemFocus=-25212, AppFocus=-25212. AXError.noValue means
requested value/AXelement does not exist; it does not identify deniedpermission
or timeout. Installed1.4.9 FAILED physical acceptance. Prior two resolver
repairs were valid but did not resolve this missing-focus condition.

## Required behavior
Find the current editable focused field where the app omits its top-level
focusedUIElement but exposes equivalent trustworthy focus metadata, or where
documented accessibility bootstrap has not completed. Preserve exact PID/field
identity, active app/window, source/value/caret, cancellation and readback guards.
No cached arbitraryfield, firsteditablechild, blindbackspace, clipboard, whole
AXValue write, write retry, or generalized AX-tree dump. No user text/audio logs.

## Investigation and implementation
1. Verify relevant SDK and primary Electron/Chromium sources, installed framework
metadata if useful. No live AX/UI probe of Codex/MLS: prior CUA denial remains.
2. First reproduce noValue using raw AX RPC boundary while leaving production
resolver intact; capture/bootstrap outcomes must be realistic and bounded.
3. Implement the smallest supported recovery. If focused-window traversal is
necessary: only positively current expected-owner window, bounded nodes/depth/
time, exact AXFocused=true editable leaf, reject ambiguous/missing/foreign or
changed focus and secure fields. Never choose an editable candidate merely by role.
Revalidation must use the same resolver and protect against stale window/field.
4. If bootstrap adjustment is supported by source evidence, use bounded off-main
waiting. Record setter/readback outcomes, but the authority for proceeding is a
fresh exact focused field, value and caret: Chromium can schedule activation
before returning a superclass setter error. Any alternate Chromium-only attribute
must be scoped to positively identified framework and not applied to native apps.
Keep error stage readable and preserve noValue info instead of advice to regrant
permissions for every failure. Diagnose unavailable bootstrap distinctly if useful.
5. Chromium 155 debounces AXEnhancedUserInterface activation for two seconds.
Do not reset this timer from repeated captures or the background sampler. Share a
bounded once-per-process-instance gate, keyed by PID plus launch identity; reject
an unidentifiable/replaced process. Delayed acquisition must remain cancellable,
off the EventTap/main thread, and cannot authorize an edit in a later field.
Prefer this scoped bootstrap to a tree walker; no new tree traversal is planned.
6. If no initial editable field identity exists, activating enhanced accessibility
is preparation only, not permission to edit a field discovered two seconds later.
The background sampler may prepare the app; a fresh operation then captures the
ready field normally. If an explicit request is the first preparation trigger,
return a precise temporary/retry-needed result without text mutation. Do not
pretend matching PID/window establishes continuity of an originally missing field.
Keep known-field identity guards when a field was already observed.

## Evidence / release
Same fixture baselineRED→candidateGREEN; negative stale/foreign/ambiguous/
secure/read-only/cancel/limit cases. Actual Option and autoSpace/Enter/dictation
paths share capture; run relevant existing native regressions without gratuitous
repeated full-audits. Two fresh reviews Spec+Standards, Linux95 (exactunchanged
Core hash reuse allowed), fullspeech signedbuild/DMG, VERSION/commit/push/archive.
Root owns planning/review/release, fresh executor owns product. Candidate1.4.10
only on root signal. Actual installed acceptance separate and not implied by
mocked noValue recovery. If evidence cannot establish safe recovery, report
what remains unavailable rather than broaden write privileges.
