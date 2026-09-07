#!/usr/bin/env bash
# Builds and installs onto a phone plugged in over USB. Run: ./install-android.sh
#
# The phone needs Developer Options and USB debugging turned on:
#   Settings > About phone > tap "Build number" seven times
#   Settings > Developer options > USB debugging
# Then plug it in and accept the "Allow USB debugging?" prompt on the phone.
set -euo pipefail

export ANDROID_HOME="/opt/homebrew/share/android-commandlinetools"
ADB="$ANDROID_HOME/platform-tools/adb"

cd "$(dirname "$0")"
./build-android.sh

echo
echo "Looking for a phone..."
"$ADB" start-server >/dev/null 2>&1 || true
DEVICES=$("$ADB" devices | grep -w "device" | wc -l | tr -d ' ')
if [ "$DEVICES" -eq 0 ]; then
  echo "No phone found. Check that:"
  echo "  - it is plugged in with a cable that carries data, not just power"
  echo "  - USB debugging is on"
  echo "  - you accepted the 'Allow USB debugging?' prompt on the phone"
  echo
  echo "You can also just copy build/kedai-runtuh.apk to the phone and tap it."
  exit 1
fi

echo "Installing..."
"$ADB" install -r build/kedai-runtuh.apk
echo
echo "Installed. Look for 'Kedai Runtuh' in your app list."
echo "To watch for errors while you play:  $ADB logcat -s godot"
