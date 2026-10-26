# G29/T34 independent SPEC review — final V3

**APPROVED — zero remaining findings.** Reviewed `/tmp/mls-g29-release.xzt21cmz/source-v3` against frozen baseline commit `6241c86d769382413cbb6e63f59816ada55e2ee5` and `spotlight-focus-spec.md`.

Both prior P1 paths are concretely closed. `DictationTarget.swift:251` now refuses missing initial process objects without bootstrap, while valid objects may retain nil launchDate. Initial canonical Spotlight is stamped independently of true/false/missing AXFrontmost; captured targets retain exact system-field/process validation and cannot fall back to stale application focus. This satisfies the spec's “живой process instance” and “допустимость только при точном system focus того же владельца.” Actual owner PID reaches Unicode and observation; missing ranges, replacement processes, changed fields, cancellation, read-only and secure inputs remain guarded. No unrelated product scope identified; product Engine/Typist are byte-identical to baseline.

Independent evidence:
- Final raw suite **199 PASS**: `/tmp/mls-g29-spec-system-focus-v3.log`.
- Unchanged seven-case reviewer reproduction **7 PASS**, including all prior REDs: `/tmp/mls-g29-spec-edge-v3/run.log`; fixture `/tmp/mls-g29-spec-edge-v3/main.swift`.
- Compiled production copies originate from exact V3 source: `/tmp/mls-system-focus.253mxF/SOURCE-SHA256SUMS` and `seams.patch`. The edge binary reused an independently built core library after confirming all core sources byte-identical.

The Engine harness changes preserve UCKeyTranslate/modifier arithmetic and original text/event assertions. They freeze real read-only TIS data and add bounded cached-readiness/literal-output waits; no product path is replaced by an expected result. The controlled timing evidence supports these synchronization changes. They do not prove WindowServer delivery.

Manifest SHA256: `6170dbc8f72a6754a851a8fa0954be8d1c392ab8ee2f6acffd0250081df0a164`. **87/87 hashes verified before and after.** No product edits, commits, live private UI/AX, microphone, or TCC changes. Physical Spotlight acceptance remains a separate user check; root full Engine/build/release gates are outside this review's approval.
