#!/usr/bin/env bash
# Builds the Android APK. Run: ./build-android.sh
#
# Everything this needs was installed with Homebrew:
#   brew install openjdk@17
#   brew install --cask android-commandlinetools
# plus Godot's export templates, and a debug keystore at ~/.android/debug.keystore
set -euo pipefail

GODOT="/Applications/Godot.app/Contents/MacOS/Godot"
export JAVA_HOME="/opt/homebrew/opt/openjdk@17"
export ANDROID_HOME="/opt/homebrew/share/android-commandlinetools"
export PATH="$ANDROID_HOME/platform-tools:$JAVA_HOME/bin:$PATH"

cd "$(dirname "$0")"
mkdir -p build

echo "Importing assets..."
"$GODOT" --headless --path . --import >/dev/null 2>&1 || true

echo "Exporting APK..."
# Godot pokes adb looking for a phone to auto-deploy to. When none is plugged in
# it prints a connection-refused line, which is noise, not a failure.
"$GODOT" --headless --path . --export-debug "Android" build/kedai-runtuh.apk 2>&1 \
  | grep -v "cannot connect to daemon" || true

echo
echo "Built: build/kedai-runtuh.apk  ($(du -h build/kedai-runtuh.apk | cut -f1))"
