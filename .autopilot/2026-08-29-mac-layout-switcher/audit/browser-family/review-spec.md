G28/T33 independent Spec review — 2026-10-26

Verdict: APPROVE implementation; 0 actionable Spec findings.

Reviewed CLAUDE.md, final browser-family-spec.md and T33, using code-review/SKILL.md against baseline d82a6748ec1c8b523c77c119bbaed3c6fd4637a4. Read-only review; no product edits, commits, live external UI/AX, global input, TCC or microphone access.

The two exact Bitrix24/Yandex framework additions satisfy the narrowly justified identity contract. Independently inspected installed plist identities and matching Chromium branches 7727/7871: BrowserCrApplication supports enhanced activation with a two-second debounce. User-confirmed actual target is native Bitrix24; Yandex is a related omission. The shared predicate already controls preparation and Unicode before mutation. Native/Safari behavior and G27 process, cancellation, source, range, readback and write-once code remain unchanged. No missing implementation, incorrect behavior or scope creep found.

All 87 release files match both workspace and /tmp/mls-g28-release.hsvy9_f5/source. Only the four files below differ from baseline. Root FROZEN-SHA256.json SHA256: e0635fa95231c2118c297077d29ffc29f49e88cd1f6ef2be61b25cfb73c1f7b3.

Exact reviewed file SHA256:
- Sources/MacLayoutSwitcher/Speech/DictationTarget.swift: 30ce43c6d471a78200e33ce4be3ced78de4bd89bc2938574b059c4807843de7c
- tools/keyboard-harness/system-focus.swift: 38cb64c8579fe1ff01077139d472bd78cd9d9aa3e86f944a229ee1ddcda40f9b
- tools/keyboard-harness/README.md: 0609bf47a1125790be427697b7279476f015c415e1078278abbcd1dd8cccafef
- VERSION (1.4.11): 2145628b86000bcf2753d8b35ffa41b75659de9c8ba72bf7c4e7bb07d4f3bb3a

Independently ran bash tools/test-system-focus.sh: exit 0, 147 PASS, 0 FAIL. Snapshot /tmp/mls-system-focus.ypQd1M retains originals, compiled seams and output. Verified literal framework directories under Renamed.app, fresh Bitrix зщкефд→portal, Unicode-before-write, prior families, native/lookalikes, Option/separators, process replacement, cancellation and read-only rejection. Verified baseline snapshot pXkG60 contains exact baseline product and identical final fixture; inspected its 24-failure RED against executor GREEN and independent GREEN.

Independent run.log SHA256: 524af95197da9ba664251fc6f1b2ceae98aca97de1ad272bda1aa67cb38958f5.
Independent SOURCE-SHA256SUMS SHA256: 4157f04d81f8794bccb18e9c88343ae5ea98abd77679fa2f9f492218d3c75a5d.

Acceptance limit: hidden owned NSTextView and substituted raw OS boundaries prove the guarded implementation, not live vendor-fork delivery or resolution of the user's installed Bitrix24 failure. Actual Bitrix24 physical acceptance remains pending; accepted Codex Option/Space is unchanged. Full-speech packaging, installation and publication remain root-owned release checks.
