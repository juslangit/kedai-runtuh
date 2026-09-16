#!/usr/bin/env bash
# Builds two APKs so a black screen can be narrowed down to the renderer.
#   build/kedai-runtuh-vulkan.apk  - Forward Mobile, best on a real phone
#   build/kedai-runtuh-gles.apk    - GL Compatibility, best odds in an emulator
#
# Whichever renderer project.godot is currently set to, that is what the project
# is put back to at the end. The script used to assume Vulkan was the default and
# strip the setting on its way out, which silently flipped the project off
# gl_compatibility - the setting the Android build actually ships with today.
set -euo pipefail
GODOT="/Applications/Godot.app/Contents/MacOS/Godot"
export JAVA_HOME="/opt/homebrew/opt/openjdk@17"
export ANDROID_HOME="/opt/homebrew/share/android-commandlinetools"
cd "$(dirname "$0")"
mkdir -p build

# Keep the project file exactly as we found it, and put it back however we exit.
SAVED="$(mktemp -t kedai-project-godot)"
cp project.godot "$SAVED"
restore () {
  cp "$SAVED" project.godot
  rm -f "$SAVED"
  "$GODOT" --headless --path . --import >/dev/null 2>&1 || true
  echo "project.godot restored to the setting it had before this run"
}
trap restore EXIT

build () {  # $1 = suffix
  "$GODOT" --headless --path . --import >/dev/null 2>&1 || true
  "$GODOT" --headless --path . --export-debug "Android" "build/kedai-runtuh-$1.apk" 2>&1 \
    | grep -viE "^\[|ADDING|cannot connect to daemon" | grep -iE "error" || true
  echo "  built build/kedai-runtuh-$1.apk ($(du -h "build/kedai-runtuh-$1.apk" | cut -f1))"
}

echo "1/2 Vulkan (Forward Mobile)..."
python3 - <<'PY'
import re
s = open('project.godot').read()
s = re.sub(r'\nrenderer/rendering_method\.mobile=.*', '', s)
open('project.godot', 'w').write(s)
PY
build vulkan

echo "2/2 OpenGL (GL Compatibility)..."
python3 - <<'PY'
s = open('project.godot').read()
if 'rendering_method.mobile' not in s:
    s = s.replace('[rendering]\n', '[rendering]\n\nrenderer/rendering_method.mobile="gl_compatibility"\n')
open('project.godot', 'w').write(s)
PY
build gles

echo "done"
