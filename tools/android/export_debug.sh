#!/usr/bin/env bash
# Editor SDK/JDK and debug keystore must already be configured outside Git.
set -euo pipefail
cd "$(dirname "$0")/../.."
mkdir -p builds/android
output="${1:-builds/android/NightfallDorm_Android_Test.apk}"
"${GODOT_BIN:-godot}" --headless --path . --editor --import --quit
"${GODOT_BIN:-godot}" --headless --path . --export-debug "Android Test" "$output"
verify_args=("$output")
if [[ -n "${ANDROID_SDK_ROOT:-}" ]]; then verify_args+=(--sdk-root "$ANDROID_SDK_ROOT"); fi
python tools/android/verify_apk.py "${verify_args[@]}"
