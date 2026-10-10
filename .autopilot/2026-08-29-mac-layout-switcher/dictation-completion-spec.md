# G23 — полная вставка диктовки после 1.4.5

## Problem Statement
Uservoice recognized a complete phrase, but Codex composer received only its
first part. Recovery panel retained full recognized text and unconfirmed
warning. Installed1.4.5 keyboardSpace acceptance does not validate dictation.

## Solution
Deliver the complete recognized phrase once into the captured original field
with exact text/caret confirmation. Preserve all recognized text visibly if
delivery cannot be confirmed; explain partial state without blindretry.

## User Stories
1. As user I dictate a phrase longer than one nativeUnicode chunk and receive
the complete phrase, punctuation/whitespace included, once in my field.
2. As user I dictate multiple paragraphs/emoji without truncated chunks.
3. As user I select text and dictated replacement preserves surrounding text.
4. As user I change focus/type/click/cancel during recognition or insertion
and stale operations stop permanently instead of writing into another field.
5. As user I can inspect/copy the entire recognized phrase after uncertain or
partial delivery, with a truthful warning to avoid duplicate insertion.
6. As user I keep working keyboardSpace/Enter/Option behavior from1.4.5.

## Implementation Decisions
Fresh T26 audit first, reproduce concrete baselineRED at production adapter
seam matching actual firstchunk failure, then minimum fix. First16UTF16 is
a clue, not proof: investigate stale value/caret readback, own asynchronous
duplicate/coalesced AX notifications, stickypermit and native transport.
Do not simply increase sleep/remove guards/ignore notifications blindly.
Exact original target identity/value/range is required, never PID alone.
No rewriting entireforeignAXValue or retry after possibly-applied writes; no
unconditionalclipboard fallback. If directroute is demonstrably unsuitable,
propose concrete guarded alternative before changing transport.
Physicalinput/focus/secureinput/pause/Esc cancellation remains sticky; external
AX value/selection changes must be discriminated as far as boundaries allow.
Late/duplicate own notifications must not truncate proven successful delivery.
Existing boundedbackground work/eventtap responsiveness and G22selectionguard
contracts remain intact. Recognition/modelcache/hotkeyUX unchanged.

## Testing Decisions
Prefer existing production DictationTarget+Permit adapter, injected AXboundary
and own native NSTextView. Same saved runner baselineRED/finalGREEN, exact
fullphrase/prefix/suffix/caret/deliverycount. Literal usertestphrase valid
non-sensitive fixture; no privateusertext logging. Cover1/2/3/long chunks,
Unicode/scalars/emoji/newline, replacingselection, delayed/duplicate/coalesced
notifications and delayedvalue/caret, stale/focus/external mutation/cancel at
chunkboundaries, no-op/partial/unconfirmed and no duplicates/retry/clipboard.
Previous G19panel+adapter/G22 keyboardEngine+selectiondelay, fullnative speech
release + coreLinux95 and two freshindependent finalreviews. Root real UI
checks use owned fields through CUA; do not call injected native fixtures
actual WindowServer proof. Hardware acceptance after reviewedcandidate, user
can manually dictate the same harmless testphrase into ownfield; root never
starts mic/privatecomposer. Preserve actual lack of live proof if blocked.

## Out of Scope
Model changes, cloudSTT, new recording UX/hotkeys, blanket permissions/TCC
forcing, privatecomposer automation, separate deletion loops, global blind
paste/retry or assuming arbitrary AX/CG races are atomic.

## Further Notes
Orchestrator onlydocs/git/build/release/CUA; freshexecutor owns projectcode.
VERSION1.4.6 only after concretefix ready and root signal; finaltwoSource
reviews required before commit/publication. Release ritual mandatory: VERSION
→commit→push→atomicpublicgitarchive→raw/archive/DMG verification. Existing
installedapp only reviewedcandidate after quiet/manualQuit, no silentreplace
whiletyping. No new permissiongrant/mic activation by diagnostictools.
