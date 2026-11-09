#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
FLUTTER=(flutter)
command -v fvm >/dev/null && FLUTTER=(fvm flutter)
"${FLUTTER[@]}" pub get
# Tracked sources only — generated *.g.dart is gitignored
git ls-files -z '*.dart' | xargs -0 dart format --output=none --set-exit-if-changed
# ponytail: *.g.dart gitignored — codegen before analyze
"${FLUTTER[@]}" pub run build_runner build
"${FLUTTER[@]}" analyze --no-fatal-infos
"${FLUTTER[@]}" test
