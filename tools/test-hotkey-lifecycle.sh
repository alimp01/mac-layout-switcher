#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
lifecycle_dir=$(mktemp -d /tmp/mls-hotkey-lifecycle.XXXXXX)
lifecycle_root="${MLS_LIFECYCLE_SOURCE_ROOT:-$PWD}"
printf 'Hotkey lifecycle scratch: %s\n' "$lifecycle_dir"
cp "$lifecycle_root/Sources/MacLayoutSwitcher/Config.swift" "$lifecycle_dir/Config.swift"
cp "$lifecycle_root/Sources/MacLayoutSwitcher/UI/HotkeyRecorderWindow.swift" "$lifecycle_dir/HotkeyRecorderWindow.swift"
if [[ -n "${MLS_LIFECYCLE_BASE_REF:-}" ]]; then
    git show "$MLS_LIFECYCLE_BASE_REF:Sources/MacLayoutSwitcher/UI/HotkeyRecorderWindow.swift" > "$lifecycle_dir/HotkeyRecorderWindow.swift"
fi
python3 - "$lifecycle_dir" <<'PYTHON'
import difflib, sys
from pathlib import Path
root=Path(sys.argv[1]); path=root/'HotkeyRecorderWindow.swift'; before=path.read_text()
old='    private func build() {'
assert before.count(old) == 1
source=before.replace(old, '    func build() {')
(root/'source-HotkeyRecorderWindow.swift.txt').write_text(before)
path.write_text(source)
(root/'seams.patch').write_text(''.join(difflib.unified_diff(before.splitlines(True), source.splitlines(True))))
PYTHON
cp -R "$lifecycle_root/Sources/SwitcherCore" "$lifecycle_dir/SwitcherCore"
cp tools/lifecycle-harness/hotkey.swift "$lifecycle_dir/main.swift"
swiftc -emit-library -emit-module -module-name SwitcherCore "$lifecycle_dir"/SwitcherCore/*.swift -o "$lifecycle_dir/libSwitcherCore.dylib" -emit-module-path "$lifecycle_dir/SwitcherCore.swiftmodule"
swiftc -I "$lifecycle_dir" -L "$lifecycle_dir" -lSwitcherCore -Xlinker -rpath -Xlinker "$lifecycle_dir" "$lifecycle_dir"/*.swift -o "$lifecycle_dir/test-hotkey"
lifecycle_status=0
"$lifecycle_dir/test-hotkey" "$lifecycle_dir/config" > "$lifecycle_dir/run.log" 2>&1 || lifecycle_status=$?
"$lifecycle_dir/test-hotkey" "$lifecycle_dir/config-window" --window > "$lifecycle_dir/window.log" 2>&1 || lifecycle_status=$?
cat "$lifecycle_dir/run.log" "$lifecycle_dir/window.log"
(cd "$lifecycle_dir" && find . -type f ! -name SHA256SUMS -exec shasum -a 256 {} \;) > "$lifecycle_dir/SHA256SUMS"
exit "$lifecycle_status"
