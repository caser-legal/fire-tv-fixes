#!/bin/zsh
# Apply the Fire TV Edition display fix and optional sideloads.
#
# On at least the Toshiba/Insignia Fire TV Edition (model AFTDCT31, Fire OS 7 /
# Android 9), a 4K UI override makes some apps (Peacock) draw video in the
# upper-left quarter of the panel. The fix is the vendor-style 1920x1080 UI
# at density 320, which the panel still upscales to 4K.
#
# Usage: ./restore.sh <adb-host> [disable-list]
# Example: ./restore.sh 192.0.2.20:5555 examples/disable-packages.example.list
#
# Prereqs:
#   - adb on your PATH (Android SDK platform-tools)
#   - TV and computer on a network you control
#   - ADB debugging on: Settings > Device & Software > About > Network, select
#     until Developer Options appears, then Developer Options > ADB Debugging
#   - Accept the USB debugging prompt on the TV

set -euo pipefail

if [ -z "${1:-}" ]; then
  echo "Usage: ./restore.sh <adb-host> [disable-list]" >&2
  exit 1
fi

SERIAL="$1"
DISABLE_LIST="${2:-}"
ADB="${ADB:-adb}"
PROJ="${0:A:h}"

"$ADB" connect "$SERIAL" >/dev/null
"$ADB" -s "$SERIAL" get-state >/dev/null

echo "== Installing APKs you placed in apks/ and home-proxy/ =="
found=0
for apk in "$PROJ"/apks/*.apk "$PROJ"/home-proxy/fast-home.apk; do
  [ -f "$apk" ] || continue
  found=1
  echo "install $apk"
  "$ADB" -s "$SERIAL" install -r "$apk"
done
if [ "$found" -eq 0 ]; then
  echo "No APKs in the tree. Sideload your own copies, or build Fast Home:"
  echo "  ./home-proxy/build-and-install.sh $SERIAL"
fi

if [ -n "$DISABLE_LIST" ] && [ -f "$DISABLE_LIST" ]; then
  echo "== Disabling packages from $DISABLE_LIST =="
  while IFS= read -r pkg; do
    [ -z "$pkg" ] && continue
    case "$pkg" in \#*) continue ;; esac
    "$ADB" -s "$SERIAL" shell pm disable-user --user 0 "$pkg" 2>/dev/null \
      || echo "  skip: $pkg"
  done < "$DISABLE_LIST"
else
  echo "No disable list given. Pass examples/disable-packages.example.list or your own file."
fi

echo "== Display + UX =="
# Do not force a 4K UI size. Keep 1920x1080 and reset density to the vendor default.
"$ADB" -s "$SERIAL" shell wm size 1920x1080
"$ADB" -s "$SERIAL" shell wm density reset
"$ADB" -s "$SERIAL" shell settings put global window_animation_scale 0.25
"$ADB" -s "$SERIAL" shell settings put global transition_animation_scale 0.25
"$ADB" -s "$SERIAL" shell settings put global animator_duration_scale 0.25
"$ADB" -s "$SERIAL" shell settings put secure screensaver_enabled 0

if "$ADB" -s "$SERIAL" shell pm path io.github.toolicious.homeonfire >/dev/null 2>&1; then
  echo "== Home on Fire accessibility (Home button -> its target) =="
  "$ADB" -s "$SERIAL" shell settings put secure enabled_accessibility_services io.github.toolicious.homeonfire/.HijackService
  "$ADB" -s "$SERIAL" shell settings put secure accessibility_enabled 1
fi

echo "== Verifying =="
"$ADB" -s "$SERIAL" shell wm size
"$ADB" -s "$SERIAL" shell wm density
echo "Done. Arrange launcher tiles on the TV. That layout is device-local and is not stored here."
