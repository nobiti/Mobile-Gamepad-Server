#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP_DIR="$ROOT_DIR/android-app"

export ANDROID_SDK_ROOT="${ANDROID_SDK_ROOT:-$HOME/android-sdk}"
export ANDROID_HOME="${ANDROID_HOME:-$ANDROID_SDK_ROOT}"

resolve_java17_home() {
  local candidates=(
    "${JAVA_HOME:-}"
    "/usr/lib/jvm/java-17-openjdk-amd64"
    "/usr/lib/jvm/java-17-openjdk"
    "$HOME/.local/share/mise/installs/java/17.0.2"
    "$HOME/.local/share/mise/installs/java/17"
  )

  for c in "${candidates[@]}"; do
    if [[ -n "$c" && -x "$c/bin/java" ]]; then
      "$c/bin/java" -version 2>&1 | grep -q 'version "17' || continue
      echo "$c"
      return
    fi
  done

  local found
  found="$(find "$HOME/.local/share/mise/installs/java" -maxdepth 1 -type d -name '17*' 2>/dev/null | sort -V | head -n 1 || true)"
  if [[ -n "$found" && -x "$found/bin/java" ]]; then
    echo "$found"
  fi
}

JAVA17_HOME="$(resolve_java17_home)"
if [[ -z "$JAVA17_HOME" ]]; then
  echo "Java 17 not found. Run scripts/setup-codespace.sh android first." >&2
  exit 1
fi
export JAVA_HOME="$JAVA17_HOME"
export PATH="$JAVA_HOME/bin:$PATH"
export ORG_GRADLE_JAVA_HOME="$JAVA_HOME"
unset JAVA_TOOL_OPTIONS JDK_JAVA_OPTIONS _JAVA_OPTIONS

# Prevent stale daemon/caches from previous Java versions (e.g. Java 25) from being reused.
export GRADLE_USER_HOME="${GRADLE_USER_HOME:-$HOME/.gradle-mobile-gamepad}"
mkdir -p "$GRADLE_USER_HOME"

GRADLE_JAVA_OPTS=("-Dorg.gradle.java.home=$JAVA_HOME")
echo "Using JAVA_HOME=$JAVA_HOME"
"$JAVA_HOME/bin/java" -version
if ! java -version 2>&1 | grep -q 'version "17'; then
  echo "Java 17 enforcement failed (active java is not 17)." >&2
  exit 1
fi

if ! curl -fsSLI "https://dl.google.com/dl/android/maven2/" >/dev/null 2>&1; then
  echo "Cannot reach Google Android Maven (https://dl.google.com/dl/android/maven2/)." >&2
  echo "Your environment/network is blocking Android Gradle plugin downloads (often HTTP 403)." >&2
  echo "Use a network/proxy that allows dl.google.com, then re-run this script." >&2
  exit 1
fi

cd "$APP_DIR"
chmod +x ./gradlew || true

if [[ -x "$HOME/.local/gradle/gradle-8.14.3/bin/gradle" ]]; then
  "$HOME/.local/gradle/gradle-8.14.3/bin/gradle" --stop >/dev/null 2>&1 || true
elif command -v gradle >/dev/null 2>&1; then
  gradle --stop >/dev/null 2>&1 || true
fi

if [[ -f "$APP_DIR/gradle/wrapper/gradle-wrapper.jar" ]]; then
  ./gradlew --no-daemon "${GRADLE_JAVA_OPTS[@]}" clean assembleDebug
elif [[ -x "$HOME/.local/gradle/gradle-8.14.3/bin/gradle" ]]; then
  "$HOME/.local/gradle/gradle-8.14.3/bin/gradle" --no-daemon "${GRADLE_JAVA_OPTS[@]}" -p "$APP_DIR" clean assembleDebug
elif command -v gradle >/dev/null 2>&1; then
  gradle --no-daemon "${GRADLE_JAVA_OPTS[@]}" -p "$APP_DIR" clean assembleDebug
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
