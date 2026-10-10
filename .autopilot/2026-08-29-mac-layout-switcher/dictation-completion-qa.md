# G23 — диктовка partial insertion QA

## User evidence
Screenshotprovided10.10: fullrecognized «Давай проверим, работает ли вставка.»
in fallback panel, prefix «Давай проверим,» in actualCodexcomposer. Warning:
possiblepartial/allalreadyinfield, no retry. Screenshot itself is not
published; privatecomposer not read/modified by tools. Application installed
reviewed1.4.5 at this stage; keyboardSpace was physicalGREEN in two ownfields.
Prefix15visibleUTF16 plus possibleinvisibletrailingSpace16 aligns with
production max16chunk. Cause notyetproved: readback/caret/notification/permit
or native delivery boundaries need investigation. No claim model failed.

## Concrete baseline RED
Root independently ran the durable production Target/Permit runner with
MLS_DICTATION_BASE_REF=438c8be before final candidate. Own NSTextView fixture
delivers duplicate selected-text notifications after the exact first native
Unicode chunk. Literal recognized phrase returns fallback(unconfirmed),
actual="Давай проверим, ", posts=1, caret={16,0}, exit1. See
audit/dictation-completion/root-baseline-red.log. This proves a concrete
production failure at the adapter boundary matching the screenshot prefix;
it does not prove actual Codex emits that callback sequence. Live speech
acceptance remains pending. No clipboard writes/mic/privatecomposer automation.

## Additional delayed-state RED
The first snapshot-based correction passed duplicate notifications but a
fixture with independently stale value and caret reads during callback still
failed. Executor preserved that RED and subsequent GREEN (extended-red.log /
extended-green.log). Candidate waits boundedly only for known pre/post write
value/range combinations; foreign states are rejected and confirmed chunk
removes transitional allowances. Final independent review/tests pending.

## Initial frozen candidate review — REQUEST CHANGES
Frozen62 files, Target SHA506f8f646524805c7c09927a2354e1e7485ed09b4cc98b10d516ffe7c009e88a.
Root completion/G19adapter/Engine/selection-delay/fullspeech build/Linux95 all
passed; same finalrunner baseline still reproduces exact first16UTF16 RED.
Both fresh independent Spec and Standards reviews found the same P1: observer
positively samples an unrelated foreign value, but concurrent confirmWrite
changes writeRevision and the failed snapshot is discarded. Field restoration
then allows all3posts instead of sticky cancellation. Their independent
production Target/Permit probes are preserved in audit/dictation-completion.
This candidate is NOT approved or published. Executor repair and a new frozen
final review are required. AX work must remain outside main/permit lock.

## Repaired frozen candidate
Source2e8bca24198bc4a1cddee226e92733c8e624308cf46f83924a5b4961738d3341,
63 files in final-source-sha.json. Retain immutable actual AXvalue/range sample
across concurrently published own-write states; classify against captured and
current known states. No false Bool invalidation/reread discards foreign evidence.
Foreignvalue/foreignrange cases now fallback(unconfirmed), one post, cancelled
permit; legitimate previous/next own samples complete3chunks once. Default
durable runner includes all four cases and original literal/Unicode/cancel suite.
Same27 Core/Tests/Package files exactly match rootLinux95-tested snapshot;
linux95-identical-source-proof.json stores all hashes, suite95/0 remains valid.
Final independent reviews/native gates pending; actualCodexspeech still pending.

## Frozen2 review — second repair required
Standards approved0findings after unchanged foreignstate Target probeGREEN;
Spec found own coherent intermediate snapshot crossing more than adjacent
chunkpublications. Callback starts duringchunk1, samples ownchunk2, returns
afterchunk4publication; phrase repeated3times108UTF16 truncates64units/posts4,
no foreignmutation. Twoendpoint classification loses ownchunk2; specmulti-own
RED fixture/log preserved. New bounded in-flight ownstate history or equivalent
coordination required, foreignsticky cancellation must remain. Frozen2 build
and rootcompletion/Engine/delay PASS do not approve release. No publication.

## Frozen3 review — third repair required
Target d32477394a27366bb10b28062f466e16885ac653f01668e52eecff330788a906,
64 frozen files. Spec approved implementation and all 11 groups; root completion,
Engine, delayed selection and full speech native build passed. Standards found
P1: capacity wait between preflight and native post permits stale source.
During chunk17 wait, external value/caret becomes FOREIGN/{0,0}; delayed observer
returns earlier legitimate chunk2 sample. Writer wakes and posts chunk17 into
FOREIGN without checking current exact field. Root independently reproduced
fallback(unconfirmed), posts17, allowed=true, corrupted FOREIGN. Probe and log
preserved. Frozen3 is rejected/unpublished; native DMG is scratch only.
Revalidate exact target/value/range + permit after capacity wait, before native
post, permanently cancelling observed mismatch; AX remains outside lock/main.

## Frozen4 — final approvals and root gates
Target cf3d4d6e29672b1c9601e0cd4234c9253ee94d3214d45f428a65f9429d351c41.
Exact target/secure/value/caret + permit rechecked after expectWrite before
either direct setter or native Unicode post; mismatch permanently cancels.
Same durable capacity mutation fixture asserts RED at17posts on frozen3; final
value/range/samePIDotherfield/secure mutations stop at16, preserve foreign state
and leave cancelled permit without retry. Both independent final reviewers
approved0findings, verified64hashes, unchanged probes and full15group suite.
Root independently completion15groups, Engine, selection-delay, native fullspeech
release build PASS. RootLinux95/0 remains valid: identical27 Core/Tests/Package
hashes checked against frozen source and working tree; exactproof preserved.
Mounted DMG1.4.6 version/helper/deepstrict/symlink/mainbinary exact PASS; see
dmg-verification.json. Publication ritual follows this validation.
Actual speech in Codex/privatecomposer/WindowServer remains pending; this is
a scoped reproducible completion repair, not universal/atomic delivery proof.
