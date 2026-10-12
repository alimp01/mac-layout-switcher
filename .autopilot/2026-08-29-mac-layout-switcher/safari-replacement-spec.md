# G24 — надёжная замена в полях Safari

## Problem
User recording on11Oct shows Safari Obsidian signup Full name: шднф stays
in field after attempted correction to ilya, recovery panel appears (about3s).
Earlier screenshot search field пфьуищн→gameboy likewise unchanged. Installed
1.4.6 verified. Screenshot cannot distinguish selection failure from write/
confirmation failure or establish exactphysicaltrigger. Cover auto and Option.

## Required outcome
1. Identify concrete failing stage with evidence. Do not guess from genericnotice
or silently lower safety guards. Own Safari/WebKit text input fixture (including
autocomplete=name) is preferred for reproduction; no submitted forms/private edits.
2. On a supported editable field, source becomes full target once and selection/
caret are correct; Space/Enter occur after correction, ShiftEnter semantics retained.
3. Correctness for selectedword/Option, surroundingtext, rapidtyping and stale/focus
changes. Physical input/focus cancellation and source matching remain mandatory.
4. If write cannot be verified, preserve source/planned/heldtext without blindretry
and show truthful reason when feasible. No whole-field destructive overwrite,
clipboard fallback, synthesized global events fromshell, or permission forcing.
5. Add meaningful baseline RED→final GREEN production regression reflecting
evidence, not implementationmirrors. Existing keyboard/delay/notice/dictation
checks and corefullsuite must stayGREEN. Two independent final reviews required.
6. Build nativefullspeech+DMG, version1.4.7 only after root signal; commit/push/archive
ritual mandatory. Actual Safari/userphysical acceptance distinct from injectedtests.

## Design/testing boundaries
Keep existing Target/Typist/Engine publicseams, AX platforminterface. No unrelated
refactor or arbitrary domain-specific rules. If diagnosticsneeded, prefer bounded
stage/status metadata without recording usertext/clipboard. No universal atomic
claims: AX and nativepost are distinct operations. Root UI only via CUA. Executor
may run isolated owned headless AppKit/WebKit fixtures, never private Safari AX
via shell. Review and inspect existing T25/T26 boundaries before changingsharedcode.

## Out of scope
Dictionary additions (user explicitly cancelled), speechmodel changes, accounts,
login/password changes, telemetry, remote transmission of screenshot/video.
