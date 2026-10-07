#!/usr/bin/env python3
"""Compare frozen diagnostic fixtures; no accuracy/generalization claims."""
import argparse
import json
from pathlib import Path

HERE = Path(__file__).resolve().parent
CONTEXTS = ("fresh", "ruContext", "enContext")
KEYS = ("kind", "lang", "word", "input")

def read_tsv(path):
    # Literal apostrophes/double quotes are data, never CSV escape syntax.
    lines = Path(path).read_text().splitlines()
    columns = lines[0].split("\t")
    records = [dict(zip(columns, line.split("\t"), strict=True)) for line in lines[1:]]
    indexed = {tuple(row[k] for k in KEYS): row for row in records}
    assert len(indexed) == len(records), "duplicate fixture keys"
    return indexed

def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("final_tsv", type=Path)
    parser.add_argument("--output", type=Path, required=True)
    parser.add_argument("--intentional-collisions", type=Path, default=HERE / "intentional-new-collisions.json")
    args = parser.parse_args()
    baseline = read_tsv(HERE / "baseline.tsv")
    final = read_tsv(args.final_tsv)
    assert baseline.keys() == final.keys(), "fixture set changed: final must use frozen inputs"
    independent = json.loads((HERE / "independent-words.json").read_text())
    assert {lang: len(words) for lang, words in independent.items()} == {"ru": 459, "en": 692}
    intentional = json.loads(args.intentional_collisions.read_text())
    intentional_pairs = {(p["en"], p["ru"]): p["reason"] for p in intentional}
    for pair, reason in intentional_pairs.items():
        assert all(pair) and reason.strip(), "each intentional collision needs both spellings and a reason"
    report = {
        "baseline_head": "bb2ee61", "scope": "Frozen curated diagnostic fixtures, not statistical accuracy",
        "independent_words": {lang: len(words) for lang, words in independent.items()},
        "frozen_union_words": {lang: sum(row["kind"] == "valid" and row["lang"] == lang for row in baseline.values()) for lang in ("ru", "en")},
        "independent_counts": {}, "frozen_union_counts": {},
        "new_valid_word_corrections": [], "new_valid_word_corrections_intentional_collisions": [],
        "resolved_valid_word_corrections": [], "previously_detected_now_unsure": [],
        "new_wrong_direction": [], "newly_detected": [], "declared_intentional_collisions": intentional,
    }
    for name, members in [("independent_counts", independent), ("frozen_union_counts", None)]:
        for lang in ("ru", "en"):
            report[name][lang] = {}
            for context in CONTEXTS:
                count = {}
                for revision, records in [("baseline", baseline), ("final", final)]:
                    rows = [r for r in records.values() if r["lang"] == lang and (members is None or r["word"] in members[lang])]
                    count[revision] = {
                        "valid_words_corrected": sum(r["kind"] == "valid" and r[context] != "unsure" for r in rows),
                        "mapped_forms_unsure": sum(r["kind"] == "wrong" and r[context] == "unsure" for r in rows),
                        "mapped_forms_detected": sum(r["kind"] == "wrong" and r[context] == lang for r in rows),
                        "mapped_forms_wrong_direction": sum(r["kind"] == "wrong" and r[context] not in (lang, "unsure") for r in rows),
                    }
                report[name][lang][context] = count
    for key, before in baseline.items():
        after = final[key]
        for context in CONTEXTS:
            old, new = before[context], after[context]
            if old == new:
                continue
            change = {**{k: before[k] for k in KEYS}, "context": context, "baseline": old, "final": new,
                      "independent": before["word"] in independent[before["lang"]]}
            if before["kind"] == "valid":
                if old == "unsure" and new != "unsure":
                    counterpart_key = ("wrong", before["lang"], before["word"], next(r["input"] for r in baseline.values() if r["kind"] == "wrong" and r["lang"] == before["lang"] and r["word"] == before["word"]))
                    counterpart = baseline[counterpart_key]["input"]
                    pair = (before["word"], counterpart) if before["lang"] == "en" else (counterpart, before["word"])
                    if pair in intentional_pairs:
                        change["collision"] = {"en": pair[0], "ru": pair[1], "reason": intentional_pairs[pair]}
                        report["new_valid_word_corrections_intentional_collisions"].append(change)
                    else:
                        report["new_valid_word_corrections"].append(change)
                elif old != "unsure" and new == "unsure":
                    report["resolved_valid_word_corrections"].append(change)
            elif old == before["lang"] and new == "unsure":
                report["previously_detected_now_unsure"].append(change)
            elif new not in (before["lang"], "unsure"):
                report["new_wrong_direction"].append(change)
            elif old == "unsure" and new == before["lang"]:
                report["newly_detected"].append(change)
    args.output.write_text(json.dumps(report, ensure_ascii=False, indent=2) + "\n")
    print(json.dumps({"output": str(args.output), "fixture_rows": len(final), "changed_categories": {key: len(report[key]) for key in ("new_valid_word_corrections", "new_valid_word_corrections_intentional_collisions", "resolved_valid_word_corrections", "previously_detected_now_unsure", "new_wrong_direction", "newly_detected")}}, ensure_ascii=False))

if __name__ == "__main__":
    main()
