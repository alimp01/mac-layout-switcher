# G28/T33 Standards review — 2026-10-26

**Verdict: APPROVE. 0 documented-standard violations; 0 actionable smell/correctness findings.**

Reviewed against fixed baseline `d82a6748ec1c8b523c77c119bbaed3c6fd4637a4`, using CLAUDE.md, ADR0013, updated browser-family-spec/T33, G27 safeguards, and the code-review smell baseline. Final source: `/tmp/mls-g28-release.hsvy9_f5/source`.

The product diff adds only exact `Yandex Framework.framework` and `Bitrix24 Framework.framework` identities to the existing shared predicate. Preparation and Unicode routing reuse that predicate. Static installed Bitrix metadata, BrowserCrApplication/AX selectors, Chromium147 version, and matching branch7727 source justify its inclusion; Yandex explicitly declares Chromium150. The predicate does not broaden to arbitrary browser names.

PID/launch gates, missing-field fresh-operation requirements, cancellation, source/range/caret/readback and write-once behavior are unchanged. InputFocusGuard, Typist, SelectionConverter, SecureInput and the runner match baseline bytes. Native/Safari handling is unchanged. No speculative abstraction, clipboard, whole-value write, retry, dictionary or permission changes were introduced.

The harness repairs the prior misleading framework fixture by creating each literal directory under Renamed.app. Direct-setter no-op traps prove Unicode selection before mutation. Assertions check complete values, exact carets, write counts, native/lookalike negatives, process replacement and cancellation. Literal Bitrix `зщкефд → portal` is exercised through a fresh production Option request after preparation.

Independent `bash tools/test-system-focus.sh` from the frozen source exited 0: **147 PASS, 0 FAIL**, snapshot `/tmp/mls-system-focus.IkkcMu`, log `/tmp/mls-g28-standards-raw.log`. Its source manifest and result log exactly equal the executor GREEN snapshot. Final RED/GREEN/independent harness bytes match; baseline `/tmp/mls-system-focus.pXkG60` contains 123 PASS/24 FAIL markers (two FAIL markers interleave stdout lines). All 87 frozen hashes verified before and after the run.

This approves the scoped code, not installed Bitrix physical acceptance. Full-speech packaging/release remain root checks. No live private UI/AX, TCC, microphone or global input was used.

Exact SHA256 evidence:

| Artifact | SHA256 |
|---|---|
| 87-file FROZEN-SHA256.json | e0635fa95231c2118c297077d29ffc29f49e88cd1f6ef2be61b25cfb73c1f7b3 |
| DictationTarget.swift | 30ce43c6d471a78200e33ce4be3ced78de4bd89bc2938574b059c4807843de7c |
| system-focus.swift | 38cb64c8579fe1ff01077139d472bd78cd9d9aa3e86f944a229ee1ddcda40f9b |
| keyboard-harness/README.md | 0609bf47a1125790be427697b7279476f015c415e1078278abbcd1dd8cccafef |
| VERSION (1.4.11) | 2145628b86000bcf2753d8b35ffa41b75659de9c8ba72bf7c4e7bb07d4f3bb3a |
| test-system-focus.sh | 7d327221485aeb46b5eb492904dbeebc3a8e18d5268ece7a93e34d5bc5f32754 |
| Independent SOURCE-SHA256SUMS | 4157f04d81f8794bccb18e9c88343ae5ea98abd77679fa2f9f492218d3c75a5d |
| Independent run.log | 524af95197da9ba664251fc6f1b2ceae98aca97de1ad272bda1aa67cb38958f5 |
