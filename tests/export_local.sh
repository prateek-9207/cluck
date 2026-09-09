#!/bin/sh
set -eu
ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
GODOT_BIN=${GODOT_BIN:-/Applications/Godot.app/Contents/MacOS/Godot}
export GODOT_ANDROID_KEYSTORE_DEBUG_PATH="$ROOT/.toolchain/debug.keystore"
export GODOT_ANDROID_KEYSTORE_DEBUG_USER=androiddebugkey
export GODOT_ANDROID_KEYSTORE_DEBUG_PASSWORD=android
# Requires export templates and the Android SDK described in docs/BUILD.md.
"$GODOT_BIN" --headless --path "$ROOT" --export-debug Android "$ROOT/builds/cluck.apk"
"$GODOT_BIN" --headless --path "$ROOT" --export-release macOS "$ROOT/builds/Cluck-macOS.zip"
