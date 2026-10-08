#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
work=$(mktemp -d /tmp/mls-dictation-adapter.XXXXXX)
cp tools/dictation-harness/adapter.swift "$work/main.swift"
swiftc Sources/MacLayoutSwitcher/Speech/DictationTarget.swift Sources/MacLayoutSwitcher/System/SecureInput.swift "$work/main.swift" -o "$work/test-adapter"
"$work/test-adapter"
