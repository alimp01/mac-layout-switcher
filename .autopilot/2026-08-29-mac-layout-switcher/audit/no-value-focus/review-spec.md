# G27/T32 Spec review — corrected final candidate

**Verdict: APPROVE, zero outstanding findings.** The independently reproduced P2 process-replacement issue was fixed and rechecked. Actual installed acceptance remains pending and is not inferred from these fixtures.

Compared the three changed product files with literal baseline `cd68fedfe0cd2996a4f6f1383d2c03929d3deec2` using blobs from `/tmp/mls-g26-git-store`; reviewed CLAUDE.md, no-value-focus-spec/qa, T32, and the code-review skill. The final 87-file manifest `/tmp/mls-g27-release.tkr6ubd_/FROZEN-SHA256.json` has SHA256 `bf30a557698b2af3fd0eeec39f60aa92bedb517cb16ed9b91eac64b6f1a231cc`; independently verified all manifest entries against its source snapshot.

The candidate follows the scoped bootstrap requirements: existing resolver retained; enhanced activation limited to detected Chromium after unsupported manual activation; bounded shared PID/launch gate; process revalidation before alternate side effects; cancellation propagated to both captures; missing initial field returns preparation/retry instead of authorizing a delayed explicit edit. Existing field/value/caret validation and write/readback bodies are unchanged. No tree walking, clipboard mutation, whole-value writes, text/audio logs, or write retries were added. No unrequested feature scope found. Final README-only delta accurately describes fixture seams and limits; product/tests are unchanged.

Independent evidence:

- Final owned raw-focus suite: `/tmp/mls-system-focus.qt9jk0/run.log`, **77 PASS, 0 FAIL**, exit 0. Saved sources and main fixture match frozen hashes; includes cancellation, foreign/malformed focus, secure/read-only fields, once-per-instance/capacity, replacement during metadata/manual RPC, and Option/automatic separators.
- Independent replacement counterexample: first freeze `f517ecb2…` failed with `native=true enhanced=1 writes=0` at `/var/folders/s7/blf5jdcs7q7bfjjxbt621w500000gn/T/mls-g27-spec-replaced-bwp7a4l8/run.log`; unchanged fixture against final sources passes with `enhanced=0` at `/tmp/mls-g27-spec-replaced-green-vi6_egxj/run.log`.
- The same final fixture against literal 1.4.9 baseline: `/tmp/mls-system-focus.fbThyK/run.log`, **13 FAIL, 64 PASS**, exit 1, including literal noValue recovery. Main fixture bytes match the final GREEN run; all three product sources match baseline blobs.

Audited final SHA256:

| File | SHA256 |
|---|---|
| Speech/DictationTarget.swift | `066a26bbf79b858649d0dffaf2ca42be039cf0633cc06953b58d2015138b5929` |
| System/InputFocusGuard.swift | `31a4323f35aa55d2f016b7ddb7820652811d0c21cec3f50e39d22ff2a8d82383` |
| System/SelectionConverter.swift | `a22a3ae2ecf58646069e5d3446c553e717dad6e755df6c650601bc70c39b7482` |
| tools/test-system-focus.sh | `7d327221485aeb46b5eb492904dbeebc3a8e18d5268ece7a93e34d5bc5f32754` |
| tools/keyboard-harness/system-focus.swift | `21dfb0c53e1499bf6df4a0da3d67bd83a2e7bae1a43d3cd9e007fc14b40ae882` |
| tools/keyboard-harness/README.md | `ba1bead81657d20ddd2212522ce1fac4a20fe127b56c69b913ddfaaa09386b15` |
| VERSION (1.4.10) | `ca0eb65c1e54347a8a433a5c76b9127deeffaa1966953c3e92c0ca41aaad237d` |

Limitations: owned unshown NSTextView and injected raw OS boundaries only. No live Codex/MLS AX/UI, TCC changes, microphone, global input, installation, or publication performed. Root owns broader build/release evidence and physical user acceptance.
