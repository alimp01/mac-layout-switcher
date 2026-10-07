# Frozen word coverage audit

Baseline: release1.4.0, commit bb2ee61. No project implementation changes in this directory. The fixtures were explicitly hand-enumerated; they are diagnostic examples, not a statistical language corpus.

`independent-words.json` freezes the original459 RU and692 EN explicit literal words independently of the production dictionaries. `frozen-fixtures.tsv` freezes the exact baseline union of575 RU /892 EN words, each in valid and wrong-layout form (2,934 rows, three contexts =8,802 verdicts). Never rebuild this union using the final dictionaries: doing so would change the denominator.

`baseline.tsv`, `punctuation-baseline.tsv` and `extra-baseline.txt` contain observed baseline output. The three `original-*-main.swift` files preserve the original diagnostics, but original-audit-main.swift must NOT generate the final comparison because it dynamically unions the current ShortWords dictionaries. `report.md` is the baseline human audit. Literal quotes in TSV data must not be processed as CSV escape characters.

When the final source is ready, run from any directory:

```sh
/path/to/audit/word-coverage/run-comparison.sh /path/to/audit/word-coverage/final
```

The runner compiles the current pure Swift core into a temporary directory and evaluates only the frozen inputs through `frozen-main.swift`. It writes final.tsv, comparison.json, source-head.txt and source-working-diff.patch. It does not modify project implementation or run the app. The JSON gives baseline/final independent counts and union counts separately for all three contexts; lists new valid-word corrections, resolved valid-word corrections, previously detected forms now missed, wrong directions and newly detected forms. Existing ambiguous dictionary pairs and conservative misses remain visible in counts; none is silently labelled a bug.

If the implementation consciously introduces a new collision, add an explicit review entry to `intentional-new-collisions.json` before interpreting the final report:

```json
[{"en":"spell","ru":"exact mapped spelling","reason":"Reviewed product decision"}]
```

Only explicitly declared pairs are separated into `new_valid_word_corrections_intentional_collisions`; undeclared changes remain potential regressions. Do not declare a collision intentional merely to suppress an unexpected failure. One-letter product changes and punctuation/engine integration have separate tests and original evidence because the frozen broad corpus is word oriented.

`self-check.json` compares baseline.tsv with itself to validate fixture identity and comparison machinery only; it is not a final implementation result.
