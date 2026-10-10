#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
work=$(mktemp -d /tmp/mls-dictation-completion.XXXXXX)
if [[ "${MLS_DICTATION_CASE:-}" == "multi-own" ]]; then
    cp tools/dictation-harness/notification-multi-own.swift "$work/main.swift"
elif [[ "${MLS_DICTATION_CASE:-}" == "race" ]]; then
    cp tools/dictation-harness/notification-race.swift "$work/main.swift"
else
    cp tools/dictation-harness/completion.swift "$work/main.swift"
fi
if [[ -n "${MLS_DICTATION_BASE_SOURCE:-}" ]]; then
    cp "$MLS_DICTATION_BASE_SOURCE" "$work/DictationTarget.swift"
elif [[ -n "${MLS_DICTATION_BASE_REF:-}" ]]; then
    git show "$MLS_DICTATION_BASE_REF:Sources/MacLayoutSwitcher/Speech/DictationTarget.swift" > "$work/DictationTarget.swift"
else
    cp Sources/MacLayoutSwitcher/Speech/DictationTarget.swift "$work/DictationTarget.swift"
fi
cp Sources/MacLayoutSwitcher/System/SecureInput.swift "$work/SecureInput.swift"
shasum -a 256 "$work/DictationTarget.swift" "$work/SecureInput.swift" "$work/main.swift" > "$work/sources.sha256"
printf '%s\n' "Sources snapshot: $work"
swiftc "$work/DictationTarget.swift" "$work/SecureInput.swift" "$work/main.swift" -o "$work/test-completion"
"$work/test-completion" 2>&1 | tee "$work/run.log"
if [[ -z "${MLS_DICTATION_CASE:-}" ]]; then
    for race_kind in foreign-value foreign-range previous-own next-own; do
        MLS_DICTATION_CASE=race MLS_DICTATION_RACE_KIND="$race_kind" bash "$0"
    done
    for scope_kind in four capacity stalled cancel focus cleanup mutate-value mutate-range mutate-field mutate-secure; do
        MLS_DICTATION_CASE=multi-own MLS_DICTATION_RACE_KIND=next-own MLS_DICTATION_MULTI_KIND="$scope_kind" bash "$0"
    done
fi
