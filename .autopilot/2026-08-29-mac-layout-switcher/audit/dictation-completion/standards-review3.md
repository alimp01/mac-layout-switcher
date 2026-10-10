REQUEST CHANGES — one documented-standard breach in frozen3.

[P1] Recheck the field after capacity waiting — Sources/MacLayoutSwitcher/Speech/DictationTarget.swift:353–355. Unicode preflight checks exact value/caret before `expectWrite`, but that method can now release its lock and wait up to 0.6 seconds. After waiting, insertion posts immediately without revalidating the field. An external mutation during that known wait can therefore receive the next chunk at its changed caret.

Rule: CLAUDE.md:260–261 requires the exact new value and caret to be verified before the next portion; the G23 spec additionally requires exact original target identity/value/range and sticky external cancellation. This is a stale preflight created by the new intentional wait, beyond the documented narrow last-check/delivery race.

Deterministic production Target/Permit probe: /tmp/mls-g23-capacity-stale.5hyyg502/main.swift, binary /tmp/mls-g23-capacity-stale-probe. Run with MLS_DICTATION_MULTI_KIND=capacity MLS_DICTATION_RACE_KIND=next-own. At capacity, the existing read returns a legitimately captured chunk-two state; during the wait an external mutation changes value/caret to FOREIGN/{0,0}. The writer then posts chunk 17 into that changed state. Actual: posts=17, allowed=true, fallback(unconfirmed), value="й проверим, рабоFOREIGN". Expected: stop at posts=16 and preserve FOREIGN.

Revalidate focused identity, value, caret and permit after expectWrite returns, immediately before postUnicode; permanently cancel a mismatch. Keep AX outside the condition lock/main loop.

Independent checks: original unchanged foreign-state race probe PASS; full completion runner's 11 groups PASS; G19 adapter/panel PASS. All 64 manifest hashes match before/after review. No heuristic smell findings. Injected fixtures provide no actual Codex/WindowServer speech acceptance.
