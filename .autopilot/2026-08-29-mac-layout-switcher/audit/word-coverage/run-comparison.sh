#!/bin/bash
set -euo pipefail
script_dir=$(cd "$(dirname "$0")" && pwd)
repo_dir=$(git -C "$script_dir" rev-parse --show-toplevel)
output_dir=${1:-"$script_dir/final"}
mkdir -p "$output_dir"
build_dir=$(mktemp -d /tmp/mls-word-coverage.XXXXXX)
trap 'rm -rf "$build_dir"' EXIT
cp "$script_dir/frozen-main.swift" "$build_dir/main.swift"
swiftc "$repo_dir"/Sources/SwitcherCore/*.swift "$build_dir/main.swift" -o "$build_dir/audit"
"$build_dir/audit" "$script_dir/frozen-fixtures.tsv" > "$output_dir/final.tsv"
python3 "$script_dir/compare.py" "$output_dir/final.tsv" --output "$output_dir/comparison.json"
git -C "$repo_dir" rev-parse HEAD > "$output_dir/source-head.txt"
git -C "$repo_dir" diff -- Sources/SwitcherCore > "$output_dir/source-working-diff.patch"
