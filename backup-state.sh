#!/bin/zsh
# Refresh a local state/ snapshot from a Fire TV you choose.
# state/ is gitignored. Do not commit device addresses or serials.
#
# Usage: ./backup-state.sh <adb-host>
# Example: ./backup-state.sh 192.0.2.20:5555

set -euo pipefail

if [ -z "${1:-}" ]; then
  echo "Usage: ./backup-state.sh <adb-host>" >&2
  exit 1
fi

SERIAL="$1"
ADB="${ADB:-adb}"
PROJ="${0:A:h}"

"$ADB" connect "$SERIAL" >/dev/null
"$ADB" -s "$SERIAL" get-state >/dev/null

mkdir -p "$PROJ/state"
"$ADB" -s "$SERIAL" shell pm list packages -d | sed 's/package://' | sort > "$PROJ/state/disabled-packages.list"
"$ADB" -s "$SERIAL" shell pm list packages -3 | sed 's/package://' | sort > "$PROJ/state/installed-thirdparty.list"

{
  echo "model=$("$ADB" -s "$SERIAL" shell getprop ro.product.model | tr -d '\r')"
  echo "fireos=$("$ADB" -s "$SERIAL" shell getprop ro.build.version.fireos | tr -d '\r')"
  echo "android=$("$ADB" -s "$SERIAL" shell getprop ro.build.version.release | tr -d '\r')"
  echo "abi=$("$ADB" -s "$SERIAL" shell getprop ro.product.cpu.abi | tr -d '\r')"
} > "$PROJ/state/device.info"

echo "Wrote state/ on this machine only. Leave it uncommitted."
