#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
work=$(mktemp -d /tmp/mls-dictation-panel.XXXXXX)
cp tools/dictation-harness/panel.swift "$work/main.swift"
swiftc Sources/MacLayoutSwitcher/UI/DictationPanel.swift "$work/main.swift" -o "$work/test-panel"
"$work/test-panel" "$work/panel.png"
printf 'Panel image: %s/panel.png\n' "$work"
