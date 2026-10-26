# G29/T34 SPEC review — V2

Status: **CHANGES REQUESTED — one remaining P1 edge**. Original V1 finding is concretely closed: unchanged four-case reproduction now passes.

- **P1 — Refuse initial capture when the process object is unavailable.** `Sources/MacLayoutSwitcher/Speech/DictationTarget.swift:247` leaves `running` optional; line255 classifies nil as ordinary, allowing same-PID Spotlight with true/missing AXFrontmost to publish `processStart=nil`. With true AXFrontmost and missing system focus, stale Spotlight application-focus is again accepted. Spec: “Положительная identity: exact bundle ID + canonical system bundle/executable identity и живой process instance” and “допустимость только при точном system focus того же владельца.” Require a live application object for initial capture while preserving valid objects whose launchDate is nil. Three literal RED cases: `/tmp/mls-g29-spec-edge-final/run.log`; reproduction `/tmp/mls-g29-spec-edge-final/main.swift`.

Independent raw suite: **196 PASS**, `/tmp/mls-g29-spec-system-focus-final.log`; copied sources and seams: `/tmp/mls-system-focus.olS15O/SOURCE-SHA256SUMS`, `/tmp/mls-system-focus.olS15O/seams.patch`. Edge binary compiles these final production copies; reused core library sources were independently confirmed byte-identical.

V2 correctly stamps known Spotlight for initial true/missing AXFrontmost, rejects missing kernel identity/system focus without bootstrap, and preserves strict actual-owner validation. Native capture retains baseline semantics. No unrelated product changes. Engine/Typist remain byte-identical.

The new Engine TIS seam retains a real source and immutable uchr data, preserving UCKeyTranslate/modifier arithmetic, original-event assertions, and literal source-before-separator checks. This stabilizes fixture inputs without replacing translation behavior or claiming live delivery.

Manifest SHA256 `dcb17216d7caeae92ebd034aa02906c42d246b2912e669ac09faaef412f4a823`: **87/87 verified before and after**. No live private UI/AX/microphone/TCC accessed. Physical Spotlight acceptance and root release/build gates remain separate.
