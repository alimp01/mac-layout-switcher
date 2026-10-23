# Native keyboard regression fixtures

Run `bash tools/test-keyboard-engine.sh` on macOS to exercise the real
EventTap parser, unchanged KeyTranslator, Engine callbacks, InputFocusGuard,
SelectionConverter, Typist and Target replacement. The fixture uses private,
unshown NSTextViews and fresh temporary configuration directories. It does not
register a global event tap, type into another application, change input sources,
request TCC permissions, use the microphone or mutate the clipboard.

The runner prints its scratch directory. It saves compiled source copies,
`seams.patch`, source/compiled hashes in `source-provenance.json`, `run.log` and
`SHA256SUMS`. Every rewrite asserts its exact occurrence count. Production event
handling and replacement decisions are unchanged in those copies.

Explicit system boundaries are injected: frontmost PID and bundle, SecureInput
(false only inside the fixture), AX against the private view, inert event-tap
registration, and in-memory destination layout selection. EventTap.process gets
test-only access; the probe feeds real CGEvents through it. Typist retains its
real Self.post marker and delay; only the final global CGEvent.post is replaced.
Unicode insertion preserves SystemDictationAccessibility event construction,
payload, CGEvent serialization and NSEvent interpretation. Raw physical replays
are recorded with their original keycodes/flags/down-up order, then resolved
through real KeyTranslator into NSEvent.keyEvent at the receiver boundary.
WindowServer is absent from this local fixture; this resolution is an explicit
substitute for that boundary, not proof of actual cross-process delivery.

The current RU/EN source is read without switching it. The fixture checks a
literal wrong-layout word **before** the separator, so a correct final word
cannot be confused with ordinary typing in the correct layout. Tests cover
Space/Enter/Shift+Enter/Tab autorepeat precisely after temporary selection,
repeat counts, original/repeated keyUp ownership, synthetic markers, printable
and Backspace repeats, fast input after Enter/Space, outside-busy reset,
unrelated command/navigation/click cancellation, and uncertain Enter recovery.
Recovery assertions inspect only windows created by the current case.
Changing or locking the real system input source during a run can invalidate
the startup RU/EN assumptions. A source-before-separator failure prints the
startup/current translation, observed per-key characters and actual private
editor value; such a run does not establish a replacement regression.

To reproduce the pre-fix failure using the same fixture and unchanged checkout:

```sh
MLS_ENGINE_BASE_REF=eb11af4 bash tools/test-keyboard-engine.sh
```

This overrides only Engine.swift from that commit; other compiled project files
come from the selected source root. The initial automatic-repeat test fails with
only a separator in the private editor instead of the complete corrected word.
To run from a frozen source tree, use `MLS_ENGINE_SOURCE_ROOT=/absolute/root`.
The runner and fixture always come from this checkout.

`test-keyboard-adapter.sh` separately checks Target/Typist failure and recovery
outcomes plus production Unicode payload generation; its local AppKit checks
also do not establish hardware/WindowServer delivery.

Run `bash tools/test-keyboard-selection-delay.sh` for delayed AX selection and
restoration ACKs through exact Target/Typist/SelectionConverter source copies.
The system seam acknowledges a range before applying it to the private
NSTextView. Physical separators then use native keyDown, so the baseline
source deletion is an actual edit in that view. Unicode uses production
CGEvent generation. Local receiving events run on the main thread, as a native
receiver does; no WindowServer or external posting is involved. Each printed
scratch directory preserves source copies, `SOURCE-SHA256SUMS` and `run.log`.
Baseline: `MLS_SELECTION_BASE_REF=c0be78e bash tools/test-keyboard-selection-delay.sh`.
To isolate preselected conversion, add `MLS_SELECTION_CASE=preselected`.

Run `bash tools/test-keyboard-webkit.sh` for the Safari routing regression.
The baseline command is `MLS_WEBKIT_BASE_REF=ef8be979 bash
tools/test-keyboard-webkit.sh`; it changes only DictationTarget.swift from that
commit. The same real system WebKit input advertises a selected-text setter,
applies AX selection, but the text setter leaves the source unchanged. With the
Safari route selected before mutation, the literal `шднф` becomes `ilya ` once
and the caret reaches 5. This reflects WebCore's empty `setSelectedText`
implementation, unlike its implemented range setter.

This runner uses deprecated in-process WebView deliberately: its actual
WebCore accessibility wrapper is accessible without TCC. WKWebView's remote
AX tree is not accessed. Process bundle lookup is replaced by a private fixture
bundle identifying Safari; input focus/security and observer registration are
injected. Native Unicode construction/serialization is unchanged, but the final
receiver is the fixture's WebHTMLView, with no global or cross-process post.
Enter/ShiftEnter/Tab are inspected at the final post boundary after DOM readback;
ordinary rapid input is interpreted by WebKit. Tests also cover Option word and
selected text, emoji/context, source/focus/cancellation, readonly controls,
partial/no-op recovery, and the shared chunked dictation route. The printed
scratch directory retains original/compiled sources, exact seam description,
SHA256 manifest and run.log. These are local WebKit tests, not live Safari or
physical WindowServer acceptance.

For Option capture regressions, run `MLS_OPTION_ONLY=1 bash
tools/test-keyboard-engine.sh`. The full runner also includes these cases.
The test changes focus between private NSTextViews before the next sampler
turn, verifying literal `context ghbdtn` → `context привет` and unchanged
previous-field content. It covers same-field buffered and preexisting words,
selection precedence, recent undo, empty layout switching, lazy AX bootstrap,
process trust/secure/field/range/text refusal, and field/PID/caret/key/click
cancellation during capture. An external context change during the last AX
read must also cancel before any of the three write routes starts. Bootstrap
may replace a non-editable wrapper, but cannot follow a different text field.

The production base for the fresh-field failure is 99a536c236f18a42e0a8a4bc1291bd74eacd3562.
Use `MLS_ENGINE_SOURCE_ROOT=/absolute/baseline MLS_OPTION_ONLY=1 bash
tools/test-keyboard-engine.sh` with all baseline Sources materialized there;
`MLS_ENGINE_BASE_REF` alone changes only Engine and is insufficient here.
The first Option test fails with unchanged `context ghbdtn` on that base.
Set `CLANG_MODULE_CACHE_PATH=/tmp/mls-swift-module-cache` and
`SWIFT_MODULECACHE_PATH=/tmp/mls-swift-module-cache` in restricted workspaces.
No real cross-process AX trust, live Codex, or general application acceptance
is established by these injected system-boundary tests.
