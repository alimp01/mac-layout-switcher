# G27 Standards review — final candidate

**APPROVED: zero remaining findings.** Independent Standards/correctness review against baseline `cd68fedfe0cd2996a4f6f1383d2c03929d3deec2` using read-only baseline blobs. Standards: `CLAUDE.md`, ADR0013, G27 focus constraints, and the code-review skill's Fowler smell baseline. No actionable documented-standard violations or smell findings remain.

The initial P2 process-replacement defect is fixed. Chromium classification and launch identity are revalidated after acquiring the shared lock and before enhanced activation; both capture callers refuse the invalidated operation. My unchanged raw-boundary counterexample is RED on the first product and GREEN on the final product: enhanced setters after replacement dropped from 1 to 0, with `process-changed` diagnosis. Evidence: `/tmp/mls-g27-standards-process-race.log` and `/tmp/mls-g27-standards-final-process-race.log`; compiled snapshots `/tmp/mls-system-focus.hDjmD5` and `/tmp/mls-system-focus.bK8Huj`. Initial report preserved at `/tmp/mls-g27-standards-review-initial.md`.

Independent final PASS logs:
- `/tmp/mls-g27-standards-final-system-focus.log` (snapshot `/tmp/mls-system-focus.9enK8Y`): production resolver, bootstrap, negative ownership/cancellation/secure/read-only cases, process replacement, cache capacity, fresh Option and separator paths.
- `/tmp/mls-g27-standards-final-keyboard-adapter.log`: keyboard replacement, recovery UI and serialized CG transport.
- `/tmp/mls-g27-standards-final-dictation-adapter.log`: dictation capture/insertion and cancellation.

The shared gate is bounded to 32 process instances, serialized, and does not restart pending enhanced activation. Waits are bounded and cancellable; production callers run off EventTap/main. Error/readback metadata remains text-free. Unknown initial field preparation cannot license a delayed explicit edit; existing identity, source/caret, permission and exact readback checks remain in the write path. No blind writes, tree walker, automatic clipboard use or write retry was introduced.

**Installed acceptance remains unverified.** These tests used raw fixtures/own unshown controls; they do not establish real Codex/WindowServer success. No denied UI/AX access, TCC change, microphone or global typing occurred.

Final documentation-only delta reviewed: `tools/keyboard-harness/README.md` accurately describes the raw seams, fresh-operation rule, negative cases and installed-acceptance limitation. It is the only changed manifest entry; production and executable tests are unchanged. No test rerun was needed. Verdict remains APPROVED, zero remaining findings.

## Exact audited SHA-256

87 entries independently copied and verified in `/tmp/mls-g27-standards-final-SHA256.json`; root manifest SHA-256 `bf30a557698b2af3fd0eeec39f60aa92bedb517cb16ed9b91eac64b6f1a231cc`.

`Sources/MacLayoutSwitcher/Speech/DictationTarget.swift` — `066a26bbf79b858649d0dffaf2ca42be039cf0633cc06953b58d2015138b5929`
`Sources/MacLayoutSwitcher/System/InputFocusGuard.swift` — `31a4323f35aa55d2f016b7ddb7820652811d0c21cec3f50e39d22ff2a8d82383`
`Sources/MacLayoutSwitcher/System/SelectionConverter.swift` — `a22a3ae2ecf58646069e5d3446c553e717dad6e755df6c650601bc70c39b7482`
`tools/test-system-focus.sh` — `7d327221485aeb46b5eb492904dbeebc3a8e18d5268ece7a93e34d5bc5f32754`
`tools/keyboard-harness/system-focus.swift` — `21dfb0c53e1499bf6df4a0da3d67bd83a2e7bae1a43d3cd9e007fc14b40ae882`
`VERSION` — `ca0eb65c1e54347a8a433a5c76b9127deeffaa1966953c3e92c0ca41aaad237d`

`tools/keyboard-harness/README.md` — `ba1bead81657d20ddd2212522ce1fac4a20fe127b56c69b913ddfaaa09386b15`
