#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP_DIR="$ROOT_DIR/android-app"

export ANDROID_SDK_ROOT="${ANDROID_SDK_ROOT:-$HOME/android-sdk}"
export ANDROID_HOME="${ANDROID_HOME:-$ANDROID_SDK_ROOT}"

cd "$APP_DIR"
chmod +x ./gradlew || true

if [[ -f "$APP_DIR/gradle/wrapper/gradle-wrapper.jar" ]]; then
  ./gradlew --no-daemon clean assembleDebug
elif command -v gradle >/dev/null 2>&1; then
  gradle --no-daemon -p "$APP_DIR" clean assembleDebug
elif [[ -x "$HOME/.local/gradle/gradle-8.14.3/bin/gradle" ]]; then
  "$HOME/.local/gradle/gradle-8.14.3/bin/gradle" --no-daemon -p "$APP_DIR" clean assembleDebug
else
  echo "No Gradle runtime found. Run scripts/setup-codespace.sh android first." >&2
  exit 1
fi

APK_PATH="$APP_DIR/app/build/outputs/apk/debug/app-debug.apk"
if [[ -f "$APK_PATH" ]]; then
  echo "APK built: $APK_PATH"
else
  echo "Build completed but APK not found at expected path: $APK_PATH" >&2
  exit 1
fi
