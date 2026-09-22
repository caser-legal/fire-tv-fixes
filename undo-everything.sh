#!/bin/zsh
# Inverse of restore.sh for a device you name on the command line.
#
#   ./undo-everything.sh <adb-host> [disable-list]
#   ./undo-everything.sh <adb-host> [disable-list] --full
#
# --full also uninstalls the packages this method commonly sideloads.
# Stock UI for the Fire TV Edition fix target is an explicit 1920x1080 size,
# not 'wm size reset' (that clears the override and can leave a 4K UI).

set -euo pipefail

if [ -z "${1:-}" ]; then
  echo "Usage: ./undo-everything.sh <adb-host> [disable-list] [--full]" >&2
  exit 1
fi

SERIAL="$1"
DISABLE_LIST=""
FULL=0
shift
for arg in "$@"; do
  if [ "$arg" = "--full" ]; then
    FULL=1
  else
    DISABLE_LIST="$arg"
  fi
done

ADB="${ADB:-adb}"

"$ADB" connect "$SERIAL" >/dev/null
"$ADB" -s "$SERIAL" get-state >/dev/null

if [ -n "$DISABLE_LIST" ] && [ -f "$DISABLE_LIST" ]; then
  echo "== Re-enabling packages =="
  while IFS= read -r pkg; do
    [ -z "$pkg" ] && continue
    case "$pkg" in \#*) continue ;; esac
    "$ADB" -s "$SERIAL" shell pm enable "$pkg" 2>/dev/null || echo "  skip: $pkg"
  done < "$DISABLE_LIST"
fi

echo "== Stock display + UX =="
"$ADB" -s "$SERIAL" shell wm size 1920x1080
"$ADB" -s "$SERIAL" shell wm density reset
"$ADB" -s "$SERIAL" shell settings put global window_animation_scale 1.0
"$ADB" -s "$SERIAL" shell settings put global transition_animation_scale 1.0
"$ADB" -s "$SERIAL" shell settings put global animator_duration_scale 1.0
"$ADB" -s "$SERIAL" shell settings put secure screensaver_enabled 1
"$ADB" -s "$SERIAL" shell settings put secure enabled_accessibility_services null
"$ADB" -s "$SERIAL" shell settings put secure accessibility_enabled 0

if [ "$FULL" -eq 1 ]; then
  echo "== Uninstalling optional sideloads =="
  for pkg in io.github.toolicious.homeonfire com.example.firetvhome org.smarttube.stable me.efesser.flauncher; do
    "$ADB" -s "$SERIAL" uninstall "$pkg" || true
  done
fi

echo "Done."
