# Standards review — G29/T34 final v3

**APPROVE: 0 hard violations; 0 actionable smell findings.** Both earlier P1 identity findings are closed in this exact freeze. Source review and isolated tests do not constitute hardware acceptance.

Compared `/tmp/mls-g29-release.xzt21cmz/source-v3` with frozen baseline commit `6241c86d769382413cbb6e63f59816ada55e2ee5`. Standards: code-review skill, CLAUDE.md, README, ADR0011/0013; Spotlight spec also reviewed.

`DictationTarget.swift:246–263` now rejects a missing initial process object before resolution/bootstrap. Recognized Spotlight receives canonical bundle/executable and kernel-start validation regardless of true/false/missing AXFrontmost; valid objects with nil Cocoa launchDate remain supported. `:268–330` retains exact owner/process/system-focus validation; stale app-focus cannot redirect stamped targets. `InputFocusGuard.swift:101–113` verifies Spotlight before publication and includes process start in matching. Keyboard/dictation share actual owner PID and refuse invalid or changed identity without writing.

The diff respects CLAUDE.md:217, “Никакого AX/I/O/sleep в callback,” and ADR0013’s repeated focus/range/text/permit checks. Metadata remains off EventTap; secure/read-only, cancellation, exact readback, and no uncertain-write retry are preserved. Engine, Typist, and KeyTranslator production files are byte-identical to baseline. Native/Chromium regressions pass.

All twelve smell heuristics considered: Mysterious Name, Duplication, Feature Envy, Data Clumps, Primitive Obsession, Repeated Switches, Shotgun Surgery, Divergent Change, Speculative Generality, Message Chains, Middle Man, Refused Bequest. No justified finding. Small mirrored capture selection preserves the two existing lifecycles; identity validation is centralized.

Harness changes are sound: retained real TIS source and immutable layout data replace only raw TIS reads; UCKeyTranslate/modifiers and literal expected text remain intact. Bounded readiness waits observe cached state or existing literal outcomes, preserve assertions, and do not mutate production policy or the user's layout. Raw seams remain OS-boundary substitutions; physical receiver labels are synthetic, not WindowServer proof.

Independent validation: **199 raw-focus checks + 95 additional identity checks PASS; zero failures, exit 0.** The matrix includes missing process objects, all three frontmost states, stale app-focus, invalid identity, process replacement, keyboard/dictation, and valid nil-launchDate objects. All 19 raw harness inputs match frozen sources. All **87 hashes** match before/after; manifest SHA256 `6170dbc8f72a6754a851a8fa0954be8d1c392ab8ee2f6acffd0250081df0a164`.

Evidence: `/tmp/mls-g29-standards-v3-focus.log`, `/tmp/mls-g29-standards-v3-identity/run.log`, `/tmp/mls-g29-standards-v3-hashes-before.json`, `/tmp/mls-g29-standards-v3-hashes-after.json`, `/tmp/mls-g29-standards-v3-provenance.json`; raw scratch `/tmp/mls-system-focus.70xsmJ`.

No product edits, git mutations, live private UI/AX, mic/TCC, or denial bypass. Root Engine/full-speech validation is separate; hardware Spotlight acceptance remains user-pending.
