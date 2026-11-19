#!/usr/bin/env bash
# Draws the home-screen widgets' preview pictures from their real layouts.
#
# Needs one Android device or emulator connected. Builds and installs the
# debug app, starts WidgetPreviewCapture (debug builds only), and copies the
# pictures into the app's resources:
#   res/drawable-nodpi/*_preview.png     English
#   res/drawable-ar-nodpi/*_preview.png  Arabic
# Usage: tool/capture_widget_previews.sh [device id]
set -euo pipefail
cd "$(dirname "$0")/.."
adb=(adb)
[[ -n "${1:-}" ]] && adb=(adb -s "$1")
app=net.mrecode.mre_quran
res=android/app/src/main/res

flutter build apk --debug
"${adb[@]}" install -r build/app/outputs/flutter-apk/app-debug.apk >/dev/null
"${adb[@]}" shell am start -W -n "$app/.WidgetPreviewCapture" >/dev/null
for _ in $(seq 1 30); do
  "${adb[@]}" shell run-as "$app" ls files/widget_previews/done >/dev/null 2>&1 && break
  sleep 1
done
for language in en ar; do
  folder=$res/drawable-nodpi
  [[ $language == ar ]] && folder=$res/drawable-ar-nodpi
  mkdir -p "$folder"
  for name in prayer_widget prayer_schedule_widget prayer_card_widget adhkar_widget tasbih_widget; do
    "${adb[@]}" exec-out run-as "$app" cat "files/widget_previews/$language/${name}_preview.png" \
      > "$folder/${name}_preview.png"
  done
done
echo "Previews written to $res/drawable-nodpi and $res/drawable-ar-nodpi"
