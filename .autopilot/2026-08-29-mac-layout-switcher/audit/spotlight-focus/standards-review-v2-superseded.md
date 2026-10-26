# Standards review — v2 superseded

**REQUEST CHANGES; final approval pending the missing-process-object repair.**

P1 — `Sources/MacLayoutSwitcher/Speech/DictationTarget.swift:247–259`: a nil initial NSRunningApplication object sets isSpotlight=false and permits an unstamped same-PID target. With AXFrontmost=true, this also permits stale app-focus when system focus is missing. The initial PID comes from a previously known NSWorkspace application; unavailable process metadata must not license capture or preparation. Preserve valid nonnil native objects with nil launchDate. The spec requires “canonical system bundle/executable identity и живой process instance.” Independent SPEC evidence: `/tmp/mls-g29-spec-edge-final/run.log` (three failures). Original v1 P1 cases now pass.

The other reviewed changes comply with CLAUDE.md and ADR0013. Known Spotlight is stamped for true/false/missing AXFrontmost and remains system-focus-only; invalid kernel metadata fails closed. Actual target/observer/Unicode PID routing, cancellation, secure-field checks, exact text/range readback, and no-retry behavior remain intact. All twelve smell heuristics considered; no actionable smell findings.

The new Engine harness TIS seam is acceptable: retained real TIS source plus immutable CFData copy, source ID/length/SHA256 evidence, and only two raw input substitutions. UCKeyTranslate, modifier math, literal source-before-separator assertions, and production Engine/Typist/KeyTranslator are unchanged. It does not manufacture expected text or change the user's input source.

Independent v2 validation: full raw focus **196 PASS, 0 FAIL, exit 0**; additional own known-Spotlight identity matrix **81 PASS, 0 FAIL**, covering three frontmost states, invalid initial identity/system cases, and postcapture mutations. All 19 copied harness inputs match frozen files; seams were audited. These tests do not cover the separately reproduced missing-object failure.

All 87 frozen inputs match before/after. Manifest SHA256 `dcb17216d7caeae92ebd034aa02906c42d246b2912e669ac09faaef412f4a823`.

Evidence: `/tmp/mls-g29-standards-v2-focus.log`, `/tmp/mls-g29-standards-v2-identity/run.log`, `/tmp/mls-g29-standards-v2-hashes-before.json`, `/tmp/mls-g29-standards-v2-hashes-after.json`, `/tmp/mls-g29-standards-v2-provenance.json`. Raw scratch: `/tmp/mls-system-focus.LalFTs`.

No live private UI/AX, mic/TCC, denial bypass, product edits, or git mutations. Hardware Spotlight acceptance remains user-pending. Root's Engine/full-speech checks are separate.
