#!/usr/bin/env bash
set -euo pipefail
API_BASE="${1:-https://playora-api.onrender.com}"
cd "$(dirname "$0")/.."
flutter pub get
flutter build web --release --dart-define=API_BASE="$API_BASE"
rm -rf publish
mkdir -p publish
cp -R build/web/. publish/
echo "Wrote admin/publish for API_BASE=$API_BASE"
