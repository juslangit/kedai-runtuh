#!/usr/bin/env bash
# Starts the Android emulator and installs the game. Run: ./run-emulator.sh
#
# The emulator only works with the GL Compatibility renderer, which is now the
# default for Android. It will NOT render the Vulkan build - see the README.
set -euo pipefail
export ANDROID_HOME="/opt/homebrew/share/android-commandlinetools"
ADB="$ANDROID_HOME/platform-tools/adb"
cd "$(dirname "$0")"

# a killed emulator leaves a lock behind that stops the next one starting
rm -rf "$HOME/.android/avd/kedai_phone.avd/"*.lock 2>/dev/null || true

if ! "$ADB" devices | grep -qw device; then
  echo "Starting the emulator (a window will open)..."
  nohup "$ANDROID_HOME/emulator/emulator" -avd kedai_phone -gpu host -no-boot-anim > /tmp/kedai-emulator.log 2>&1 &
  sleep 5
  "$ADB" wait-for-device
  echo -n "waiting for Android to boot"
  for _ in $(seq 60); do
    [ "$("$ADB" shell getprop sys.boot_completed 2>/dev/null | tr -d '\r')" = "1" ] && break
    echo -n "."; sleep 5
  done
  echo
fi

[ -f build/kedai-runtuh.apk ] || ./build-android.sh
"$ADB" install -r build/kedai-runtuh.apk
"$ADB" shell am start -n com.juslangit.kedairuntuh/com.godot.game.GodotAppLauncher
echo "Running. To stop the emulator:  $ADB emu kill"
