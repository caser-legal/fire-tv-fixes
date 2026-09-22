#!/bin/zsh
# Build and sign Fast Home locally. Install only when you pass an adb host.
#
# Required tools on your machine:
#   JAVA_HOME          JDK 17
#   ANDROID_HOME       Android SDK with build-tools and platforms; android-34
# Optional:
#   ANDROID_BUILD_TOOLS   default: 36.1.0
#   FIRETV_KEYSTORE_PASS  password for a debug keystore created in signing/
#                         (gitignored). Default: local-debug-keystore
#
# Usage:
#   ./home-proxy/build-and-install.sh
#   ./home-proxy/build-and-install.sh 192.0.2.20:5555

set -euo pipefail

if [ -z "${JAVA_HOME:-}" ] || [ ! -x "$JAVA_HOME/bin/javac" ]; then
  echo "Set JAVA_HOME to a JDK 17 install." >&2
  exit 1
fi
SDK="${ANDROID_HOME:-${ANDROID_SDK_ROOT:-}}"
if [ -z "$SDK" ]; then
  echo "Set ANDROID_HOME to your Android SDK." >&2
  exit 1
fi

BT_VER="${ANDROID_BUILD_TOOLS:-36.1.0}"
BT="$SDK/build-tools/$BT_VER"
PLATFORM="$SDK/platforms/android-34/android.jar"
if [ ! -d "$BT" ] || [ ! -f "$PLATFORM" ]; then
  echo "Need build-tools/$BT_VER and platforms/android-34 under ANDROID_HOME." >&2
  exit 1
fi

ADB="${ADB:-adb}"
SERIAL="${1:-}"
PASS="${FIRETV_KEYSTORE_PASS:-local-debug-keystore}"

PROJ="${0:A:h}"
BUILD="$PROJ/build"
KEYSTORE="$PROJ/../signing/fire-tv-fixes.keystore"

/bin/rm -rf "$BUILD"
/bin/mkdir -p "$BUILD/gen" "$BUILD/classes" "$BUILD/dex" "$PROJ/../signing"

"$BT/aapt2" compile --dir "$PROJ/res" -o "$BUILD/res.zip"
"$BT/aapt2" link \
    -o "$BUILD/unsigned.apk" \
    -I "$PLATFORM" \
    --manifest "$PROJ/AndroidManifest.xml" \
    -R "$BUILD/res.zip" \
    --java "$BUILD/gen" \
    --auto-add-overlay \
    --min-sdk-version 21 \
    --target-sdk-version 28

find "$PROJ/src" "$BUILD/gen" -name '*.java' > "$BUILD/sources.txt"
"$JAVA_HOME/bin/javac" -encoding UTF-8 -source 8 -target 8 \
    -classpath "$PLATFORM" \
    -d "$BUILD/classes" \
    @"$BUILD/sources.txt"

cd "$BUILD/classes"
"$JAVA_HOME/bin/jar" cf "$BUILD/classes.jar" .
"$BT/d8" --lib "$PLATFORM" --output "$BUILD/dex" "$BUILD/classes.jar"

cd "$BUILD/dex"
/usr/bin/zip -q "$BUILD/unsigned.apk" classes.dex
"$BT/zipalign" -f -p 4 "$BUILD/unsigned.apk" "$BUILD/aligned.apk"

if [ ! -f "$KEYSTORE" ]; then
    "$JAVA_HOME/bin/keytool" -genkeypair -v \
        -keystore "$KEYSTORE" \
        -storepass "$PASS" \
        -keypass "$PASS" \
        -alias firetv \
        -keyalg RSA -keysize 2048 -validity 10000 \
        -dname 'CN=Fast Home Debug'
fi

"$BT/apksigner" sign \
    --ks "$KEYSTORE" \
    --ks-pass "pass:$PASS" \
    --key-pass "pass:$PASS" \
    --out "$PROJ/fast-home.apk" \
    "$BUILD/aligned.apk"

echo "Built $PROJ/fast-home.apk (gitignored)."
if [ -n "$SERIAL" ]; then
  "$ADB" connect "$SERIAL" >/dev/null
  "$ADB" -s "$SERIAL" install -r "$PROJ/fast-home.apk"
fi
