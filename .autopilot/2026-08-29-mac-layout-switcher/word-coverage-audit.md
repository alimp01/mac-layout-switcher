# G18 independent detector audit — baseline bb2ee61 /1.4.0

Read-only project inspection and native `swiftc` diagnostic executables, 2026-10-07. No app/UI acceptance; no user text, credentials, microphone or installed app touched. No external corpus/dependency. Lists were hand-enumerated for diagnostic coverage, not frequency-ranked and not representative accuracy estimates.

## Evidence and reproducibility

- `/tmp/mls-g18-audit/main.swift`: 459 independently enumerated RU tokens /692 independently enumerated EN tokens, additionally unioned with production ShortWords for exhaustive dictionary checks.
- `/tmp/mls-g18-audit/baseline.tsv`: 575 RU /892 EN unique union tokens, each correct and wrong-layout, each on a fresh detector and after `привет` /`hello`. 2,934 rows /8,802 verdicts.
- `/tmp/mls-g18-audit/punctuation-main.swift` and `punctuation.tsv`: word-wrapper matrix and identifiers. Read TSV with quoting disabled (literal quotes are data).
- `/tmp/mls-g18-audit/extra/main.swift` and `extra/baseline.txt`: exact case, one-letter, English-label sequences, люблю and false-positive witnesses.
- Executables `audit`, `punctuation-audit`, `extra/audit` built from baseline Sources/SwitcherCore/{Lang,KeyMap,ShortWords,DetectorBigrams,Detector}.swift plus each main.swift. Recompile against the final revision to compare behavior. A Swift executable's main source must be named main.swift (copy punctuation-main.swift into a separate temporary directory to compile).

## Counts (do not market these as accuracy)

Independent explicit fixtures: RU459, fresh valid-word false positives1 (`файл`);111 wrong-layout forms remain unsure. EN692, fresh valid-token false positives9;298 wrong-layout forms remain unsure. Many misses are deliberate ambiguity, unsupported labels/initialisms, single letters, or conservative threshold limits rather than bugs. Unioning production lists gives RU575 /EN892 with RU116 /EN305 fresh unsure forms; do not describe the extra list-derived checks as independent coverage.

## Conservative additions: baseline all unsure in fresh /RU /EN context

| Intended RU | Actual EN keyboard input |
|---|---|
| ни | yb |
| буду | ,ele |
| могу | vjue |
| едва | tldf |
| выше | dsit |
| вашу | dfie |
| нашу | yfie |
| нему | ytve |
| взял | dpzk |
| двум | ldev |
| двух | lde[ |
| еда | tlf |
| едим | tlbv |
| едят | tlzn |
| ест | tcn |
| знал | pyfk |
| рад | hfl |
| рады | hfls |
| сел | ctk |
| спят | cgzn |
| угу | eue |
| хм | [v |
| хз | [p |
| хлеб | [kt, |
| кофе | rjat |
| файл | afqk |
| когда | rjulf |
| тогда | njulf |
| иногда | byjulf |
| пусть | gecnm |
| перед | gthtl |
| среди | chtlb |
| лучше | kexit |
| меньше | vtymit |
| супер | cegth |
| круто | rhenj |
| вечер | dtxth |
| файлы | afqks |
| могут | vjuen |
| будут | ,elen |
| люблю | k.,k. |

Use bounded curated lexical additions (ShortWords remains1–4 or refactor its name/invariant to accurately describe longer words); do not lower the global score threshold. Include each intended valid RU form as an unchanged negative and its lower/title/uppercase keyboard mapping as positive. For uppercase use KeyMap.convert(word.uppercased(), to:.en), not uppercasing EN punctuation: люблю /Люблю /ЛЮБЛЮ map to k.,k. /K.,k. /K><K>.

## Proven false positives

All fresh /RU /EN contexts: `файл`→`afqk` (.en), `Файл`→`Afqk`, `ФАЙЛ`→`AFQK`. Add RU protection via own dictionary.
All fresh /RU /EN contexts: `bbc`→`иис`, `brb`→`ики`, `rfc`→`кас`, `xml`→`чьд` (.ru). Protect these known legitimate English tokens, including lowercase/title/uppercase. Do not blanket-protect every alphabetic identifier: many intended Russian keyboard forms are themselves possible abbreviations.

Fresh false-positive list also includes jq→ой, ns→ты, jr→ок, ye→ну, tot→еще; those are semantic ambiguities/asymmetries, not safe unconditional protections. Preserving fresh ns would break existing required ns→ты. Existing known pairs of↔ща, vs↔мы, her↔рук, here↔руку, dj↔во, ofc↔щас remain governed by context. Explicitly do not treat their fresh unsure verdicts as missing coverage.

Keep other obvious collision candidates out of unconditional additions: еды↔tls, руки↔herb, ем↔tv, ум↔ev. `иду`↔ble and `че`↔xt are useful Russian additions but collide with legitimate BLE /XT technical labels due case-insensitive detection; decide this consciously rather than claiming no collision. `чё`→x` /`чо`→xj are less ambiguous conversational alternatives if desired.

## One-letter family

Current baseline fresh/RU/EN:
- b/B→и/И and z/Z→я/Я: ru /ru /unsure.
- f/F→а/А, d/D→в/В, e/E→у/У, r/R→к/К, c/C→с/С, j/J→о/О: unsure /ru /unsure.
- a/A/i/I: unsure in all three contexts.
- All actual correct RU one-letter function words remain unsure.
- Standalone comma, semicolon, dot, quote, brackets, backtick, tilde remain unsure in all contexts.

If the product choice is to generalize fresh single-letter correction, derive the target from the approved RU one-letter-function-word dictionary and require Latin alphabetic source + RU dictionary target + target language context or no context; do not blanket-convert every single-letter map entry or standalone punctuation. This extends the b/z preference consistently but intrinsically guesses on fresh English C/R/D/etc labels. Explicit English context must still win.

Verified English sequences all unchanged in baseline: `plan b`, `drive c`, `vitamin d`, `option f`, `model r`, `team e`, `channel j`; add uppercase variants. Also preserve user exclusions case-insensitively, reset semantics, I/a and unmapped single letters q/w/t/y/u/o/p/g/h/k/l/x/v/n/m/s. Add explicit positive tests in RU context and fresh-context tests according to chosen rule.

## Safe punctuation coverage

Baseline all unsure (fresh/RU/EN): ghbdtn!, rfr?, (yt), (yt)!, ((yt)), руддщ!, ерфе?, Rfr?, GHBDTN!, b!, (z). Under safe lexical wrapper parsing expected outputs: привет!, как?, (не), (не)!, ((не)), hello!, that?, Как?, ПРИВЕТ!, и!, (я). KeyMap already retains !?() exactly when mapping entire token, so no executor rewrite required.

Recognize a deliberately bounded grammar: trailing !/? run and balanced enclosing parentheses around one lexical core (optionally nested). Do not delete interior punctuation, trailing empty parentheses, leading shell !, or malformed parentheses. Pass the original token into exclusion checks before any core handling; consider checking the extracted core too so exclusion `b` also protects `(B)!`. Mixed alphabet/digits/URLs/identifiers remain protected after extraction. Update language context using the core's alphabet, not whole mixed wrapper token; do not invoke public verdict recursively and update it twice.

Required unchanged negatives: hello!, ozon?, (api), привет!, файл!, https://example.com, user@example.com, example.com, node.js, hello_world, snake_case, camelCase, someVariable, HTTPServer, b2b, ghbdtn123, a+b=c, foo(bar), ghbdtn(), !ghbdtn, ?ghbdtn, (ghbdtn, ghbdtn), ghbdtn?key=value, C++, C#; punctuation-only !?! /() /(()) remain unchanged. Existing cgfcb,j→спасибо must survive; k.,k.→люблю must retain every mapping punctuation mark. Quotes/commas/dots/semicolons/brackets are RU letters and must not be indiscriminately stripped.

## Integration regressions

Use EngineCore space/Enter/Tab variants to prove the full original expectedText and original token length stay exact with wrappers and capitalization; corrections preserve wrappers and selection integrity. Existing reset, exclusions, snippets-first priority, paused/autocorrect-off, undo restoration, and context reset on Enter/Tab must remain. No claim that finite dictionaries remove every language/identifier ambiguity.
