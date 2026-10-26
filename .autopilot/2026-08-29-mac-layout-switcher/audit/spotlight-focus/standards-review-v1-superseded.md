# Standards review — G29/T34 frozen candidate

**SUPERSEDED — REQUEST CHANGES for v1. Initial approval withdrawn.** A subsequent independent SPEC edge fixture exposes an initially foreground Spotlight path that this initial assessment missed. Final review requires the repaired freeze.

**P1 — DictationTarget.swift:276,289,305:** When initial expectedPID already is Spotlight and AXFrontmost is true/missing, processStart is nil; initial foreground capture can fall back to stale application focus, and retained targets do not detect a new process incarnation. This violates the spec requirement that Spotlight targets retain live process identity and exact system focus. Evidence: `/tmp/mls-g29-spec-edge/run.log`.

The remaining notes below describe the v1 inspection; the 189 existing checks do not cover this edge.

Compared `/tmp/mls-g29-release.xzt21cmz/source` against its frozen `baseline` for commit `6241c86d769382413cbb6e63f59816ada55e2ee5` using file diff; no new commits exist. Read the code-review skill, repository CLAUDE.md, README, ADR0011/0013, and Spotlight spec. No applicable additional AGENTS.md was found in the reviewed source paths.

`DictationTarget.swift:231–309` authenticates cross-owner Spotlight through exact canonical identity and matching-PID kernel start. For stamped targets only, subsequent validation retains process start and requires exact system focus. `InputFocusGuard.swift:88–113` checks current identity before publication and includes process start in target matching. `DictationTarget.swift:550–578` keeps observer/insertion PID consistent and refuses missing initial Spotlight selection without preparing the background application. Native/Chromium bounded bootstrap remains on the existing path.

These changes respect CLAUDE.md:217, “Никакого AX/I/O/sleep в callback,” and ADR0013’s requirement to recheck focus/range/text/permit before writing. Engine and Typist are byte-identical to baseline; metadata checks remain on capture/Typist queues. No new logging of user text, clipboard mutation, whole-value write, or uncertain-write retry was introduced.

All twelve smell heuristics were considered; no actionable smell was identified. The short mirrored selection preserves existing lifecycle policies.

Independent `bash tools/test-system-focus.sh`: **189 PASS, 0 FAIL, exit 0**. All 19 copied production/fixture inputs match frozen hashes; audited `seams.patch` substitutes only raw OS boundaries. Literal text/caret, actual target/observer/Unicode PID, closure/process-change refusal, and native/Chromium regressions pass. Physical replay receiver labels are fixture bookkeeping, not WindowServer evidence.

All 87 frozen hashes match before/after; manifest SHA256 `e189e575698aeef6ef91f24d980e5a5921f6c9528088f3e663a3103f598af16b`.

Evidence: `/tmp/mls-g29-standards-focus.log`, `/tmp/mls-g29-standards-hashes-before.json`, `/tmp/mls-g29-standards-hashes-after.json`, `/tmp/mls-g29-standards-provenance.json`; harness `/tmp/mls-system-focus.U2TsEA`.

Root's separate full-Engine failure remains under investigation; this report does not override it. Hardware Spotlight acceptance remains user-pending. No live private UI/AX, mic/TCC, or denial bypass was used.
