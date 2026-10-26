# G29 / T34 — Spotlight focus QA

## Result and actual scope
1.4.12 installed/published (code dba351ccdd82cd737661531e744dc0bd2c5b33e7).
Raw VERSION/public HTTPS SHA/PAX/all384 Git blobs verified. Metadata-only
follow-up archive receipt is stored in outputs. Actual Spotlight hardware
acceptance pending: user asked ghbdtn + Option in Spotlight after permissions.
Prior accepted Codex1.4.10 Option/Space and Bitrix1.4.11 Option remain valid.

## Evidence and implementation
User explicitly confirmed Spotlight (⌘Space); supplied screenshot had
AXFrontmost=ok; SystemFocus=foreign-owner; AppFocus=not-read. No live AX trace
was collected. Narrow initial capture recognizes canonical Apple Spotlight
bundle/executable/ID and binds exact field + actualPID + kernel process start.
Already captured targets cannot follow another process/field. Spotlight requires
system focus, even when AXFrontmost true/missing; stale app-focus cannot substitute.
Missing initial process object or kernel identity fails closed; missing initial
Spotlight selection needs fresh capture. Native/Chromium bootstrap remains bounded.
Two product files changed; Engine/Typist/KeyTranslator/dictionaries unchanged.

Read-only NSRunningApplication metadata showed actual Spotlight launchDate=nil.
Darwin proc_pidinfo full136byte structure with exactPID/nonzero start verified
independently, no AX/UI. Primary Apple API docs do not themselves document the
Spotlight foreground mismatch:
https://developer.apple.com/documentation/appkit/nsworkspace/frontmostapplication
https://developer.apple.com/documentation/bundleresources/information-property-list/lsuielement

## Validation
- Same final raw fixture: baseline32 failures/166 passes → final199 passes.
  Positive/negative paths branch, so totals need not be identical. Raw OS boundary
  faults + own hidden AppKit; no hardware/WindowServer claim.
- Final adapters20keyboard +2dictation PASS; pinned real ABC/RussianWin Option7+7.
- Root full EventTap→KeyTranslator→Engine:27groups PASS, including160navigation
  cases, separators/repeats/undo/selection/cancel/recovery.
- Core95 reused only with27 exact unchanged Core/Tests/Package hashes.
- Spec independent199+7edge PASS; Standards independent199+95identity PASS.
  Both final reviews approved0 findings after two P1 repairs; superseded
  reports/REDs kept. Final87input manifest6170dbc8f72a6754a851a8fa0954be8d1c392ab8ee2f6acffd0250081df0a164.
- Fullspeech release, mounted DMG version/helper/symlink and deep strict signatures
  verified; installed exact binary032e5f19… single newPID46563 after4817 stopped.
  Rollback1.4.11 zip in outputs and /Applications/.MacLayoutSwitcher-G29-7ifbvr4v/previous.app.

## Harness findings and limits
Initial fullEngine failures were not silently accepted: live TIS changed mid-run,
and same fixed.35s setup failed while +1s reached correct replacement. Harness
now pins an enabled real source + immutable uchr at raw OS read boundary and waits
boundedly for cached readiness / two literal bootstrap results. Actual modifier
math, UCKeyTranslate and outcome assertions remain. No production Engine changes.
Full final root run passed; no claim that fixtures prove physical delivery.
No private UI/AX/CUA denial bypass, microphone, TCC changes, user screenshots
committed, text/audio logging, clipboard use, blind deletion or write retries.
Final logs, manifests, review findings and fixture seams in audit/spotlight-focus.
