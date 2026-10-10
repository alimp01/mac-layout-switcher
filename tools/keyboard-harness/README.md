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
