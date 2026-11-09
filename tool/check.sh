#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
FLUTTER=(flutter)
command -v fvm >/dev/null && FLUTTER=(fvm flutter)
"${FLUTTER[@]}" pub get
# Tracked existing sources only — skip deleted paths still in the index
existing=()
while IFS= read -r -d '' f; do
  [[ -f "$f" ]] && existing+=("$f")
done < <(git ls-files -z -- '*.dart')
dart format --output=none --set-exit-if-changed "${existing[@]}"
# ponytail: *.g.dart gitignored — codegen before analyze
"${FLUTTER[@]}" pub run build_runner build
"${FLUTTER[@]}" analyze --no-fatal-infos --no-fatal-warnings
"${FLUTTER[@]}" test
