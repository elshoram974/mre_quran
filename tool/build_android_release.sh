#!/usr/bin/env bash
# Builds the Android release bundle, obfuscated, and uploads its Dart symbols
# to Crashlytics. Without the upload, the Dart stack traces of an obfuscated
# build stay unreadable in the Crashlytics console (DECISIONS.md D-005).
#
# Needs the Firebase CLI, signed in (`firebase login`).
# Usage: tool/build_android_release.sh
set -euo pipefail
cd "$(dirname "$0")/.."

# The Android app's ID, as FlutterFire generated it.
app_id=$(awk '/static const FirebaseOptions android/,/\);/' lib/firebase_options.dart |
  sed -n "s/.*appId: '\([^']*\)'.*/\1/p")
if [[ -z "$app_id" ]]; then
  echo "Could not read the Android app ID from lib/firebase_options.dart" >&2
  exit 1
fi

flutter build appbundle --release --obfuscate --split-debug-info=build/symbols
firebase crashlytics:symbols:upload --app="$app_id" build/symbols
echo "Built build/app/outputs/bundle/release/app-release.aab; symbols uploaded for $app_id"
