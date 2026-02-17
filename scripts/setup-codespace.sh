#!/usr/bin/env bash
set -euo pipefail

MODE="${1:-all}"
ANDROID_SDK_ROOT_DEFAULT="$HOME/android-sdk"
ANDROID_SDK_ROOT="${ANDROID_SDK_ROOT:-$ANDROID_SDK_ROOT_DEFAULT}"
ANDROID_CMDLINE_TOOLS_DIR="$ANDROID_SDK_ROOT/cmdline-tools/latest"
ANDROID_ZIP_URL="https://dl.google.com/android/repository/commandlinetools-linux-11076708_latest.zip"
GRADLE_VERSION="8.14.3"
GRADLE_DIR="$HOME/.local/gradle"
GRADLE_HOME="$GRADLE_DIR/gradle-$GRADLE_VERSION"
GRADLE_ZIP_URL="https://services.gradle.org/distributions/gradle-${GRADLE_VERSION}-bin.zip"
JAVA17_HOME=""

log() {
  printf '\n[setup] %s\n' "$1"
}

require_cmd() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "Missing required command: $1" >&2
    exit 1
  fi
}

usage() {
  cat <<USAGE
Usage: $(basename "$0") [all|android|dotnet]

all     : install Android + .NET prerequisites (default)
android : install Android build prerequisites only
dotnet  : install .NET build prerequisites only
USAGE
}

resolve_java17_home() {
  local candidates=(
    "/usr/lib/jvm/java-17-openjdk-amd64"
    "/usr/lib/jvm/java-17-openjdk"
    "$HOME/.local/share/mise/installs/java/17.0.2"
    "$HOME/.local/share/mise/installs/java/17"
  )

  for c in "${candidates[@]}"; do
    if [[ -x "$c/bin/java" ]]; then
      JAVA17_HOME="$c"
      return
    fi
  done

  local found
  found="$(find "$HOME/.local/share/mise/installs/java" -maxdepth 1 -type d -name '17*' 2>/dev/null | sort -V | head -n 1 || true)"
  if [[ -n "$found" && -x "$found/bin/java" ]]; then
    JAVA17_HOME="$found"
  fi
}

install_base_packages() {
  log "Installing base packages"
  apt_update_with_fallback
  sudo DEBIAN_FRONTEND=noninteractive apt-get install -y \
    curl wget unzip zip jq ca-certificates git \
    openjdk-17-jdk

  resolve_java17_home
}

disable_problematic_yarn_repo() {
  local yarn_list="/etc/apt/sources.list.d/yarn.list"
  if [[ -f "$yarn_list" ]]; then
    log "Disabling problematic Yarn apt source ($yarn_list)"
    sudo sed -i 's|^deb |# deb |g' "$yarn_list"
  fi
}

apt_update_with_fallback() {
  local log_file
  log_file="$(mktemp)"
  if sudo apt-get update 2>&1 | tee "$log_file"; then
    rm -f "$log_file"
    return
  fi

  if grep -q "dl.yarnpkg.com/debian" "$log_file" || grep -q "NO_PUBKEY 62D54FD4003F6525" "$log_file"; then
    disable_problematic_yarn_repo
    log "Retrying apt-get update after disabling Yarn apt source"
    sudo apt-get update
  else
    echo "apt-get update failed. See logs above." >&2
    rm -f "$log_file"
    exit 1
  fi
  rm -f "$log_file"
}

install_dotnet() {
  log "Installing .NET 8 SDK"
  if command -v dotnet >/dev/null 2>&1 && dotnet --list-sdks | grep -q '^8\.'; then
    log ".NET 8 SDK already installed"
    return
  fi

  wget -q "https://packages.microsoft.com/config/ubuntu/$(. /etc/os-release && echo "$VERSION_ID")/packages-microsoft-prod.deb" -O /tmp/packages-microsoft-prod.deb
  sudo dpkg -i /tmp/packages-microsoft-prod.deb
  rm -f /tmp/packages-microsoft-prod.deb
  apt_update_with_fallback
  sudo DEBIAN_FRONTEND=noninteractive apt-get install -y dotnet-sdk-8.0
}

install_android_cmdline_tools() {
  log "Installing Android command-line tools"
  mkdir -p "$ANDROID_SDK_ROOT/cmdline-tools"

  if [[ ! -x "$ANDROID_CMDLINE_TOOLS_DIR/bin/sdkmanager" ]]; then
    local tmp_zip="/tmp/android-cmdline-tools.zip"
    local tmp_dir="/tmp/android-cmdline-tools"
    rm -rf "$tmp_dir"
    mkdir -p "$tmp_dir"
    curl -fsSL "$ANDROID_ZIP_URL" -o "$tmp_zip"
    unzip -q "$tmp_zip" -d "$tmp_dir"
    rm -f "$tmp_zip"

    rm -rf "$ANDROID_CMDLINE_TOOLS_DIR"
    mkdir -p "$ANDROID_CMDLINE_TOOLS_DIR"
    cp -R "$tmp_dir/cmdline-tools/." "$ANDROID_CMDLINE_TOOLS_DIR/"
  fi

  export ANDROID_SDK_ROOT
  export ANDROID_HOME="$ANDROID_SDK_ROOT"
  export PATH="$ANDROID_CMDLINE_TOOLS_DIR/bin:$ANDROID_SDK_ROOT/platform-tools:$PATH"

  log "Accepting Android SDK licenses"
  yes | sdkmanager --licenses >/dev/null || true

  log "Installing Android SDK packages"
  sdkmanager \
    "platform-tools" \
    "platforms;android-34" \
    "build-tools;34.0.0"
}

install_gradle() {
  log "Installing Gradle ${GRADLE_VERSION}"
  mkdir -p "$GRADLE_DIR"
  if [[ ! -x "$GRADLE_HOME/bin/gradle" ]]; then
    local tmp_zip="/tmp/gradle-${GRADLE_VERSION}-bin.zip"
    curl -fsSL "$GRADLE_ZIP_URL" -o "$tmp_zip"
    unzip -q "$tmp_zip" -d "$GRADLE_DIR"
    rm -f "$tmp_zip"
  fi
}

write_android_gradle_properties() {
  local project_gradle_props="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/android-app/gradle.properties"
  log "Writing android-app/gradle.properties"
  cat > "$project_gradle_props" <<EOF
# Standard Gradle settings
org.gradle.jvmargs=-Xmx2048m -Dfile.encoding=UTF-8
android.useAndroidX=true
kotlin.code.style=official
EOF
}

persist_env() {
  log "Persisting environment variables to ~/.bashrc"
  local start="# >>> Mobile-Gamepad-Server build environment >>>"
  local end="# <<< Mobile-Gamepad-Server build environment <<<"
  if grep -Fq "$start" "$HOME/.bashrc"; then
    return
  fi

  cat <<ENV_SNIPPET >> "$HOME/.bashrc"

$start
export ANDROID_SDK_ROOT="${ANDROID_SDK_ROOT}"
export ANDROID_HOME="${ANDROID_SDK_ROOT}"
export JAVA_HOME="${JAVA17_HOME}"
export PATH="${ANDROID_CMDLINE_TOOLS_DIR}/bin:${ANDROID_SDK_ROOT}/platform-tools:${GRADLE_HOME}/bin:\$PATH"
$end
ENV_SNIPPET
}

main() {
  if [[ "$MODE" == "-h" || "$MODE" == "--help" ]]; then
    usage
    exit 0
  fi

  case "$MODE" in
    all|android|dotnet) ;;
    *)
      usage
      exit 1
      ;;
  esac

  require_cmd sudo
  require_cmd apt-get
  require_cmd curl
  require_cmd unzip

  install_base_packages

  if [[ "$MODE" == "all" || "$MODE" == "dotnet" ]]; then
    install_dotnet
  fi

  if [[ "$MODE" == "all" || "$MODE" == "android" ]]; then
    install_android_cmdline_tools
    install_gradle
    if [[ -z "$JAVA17_HOME" ]]; then
      resolve_java17_home
    fi
    if [[ -z "$JAVA17_HOME" ]]; then
      echo "Could not locate a Java 17 installation. Please install JDK 17 and set JAVA_HOME." >&2
      exit 1
    fi
    write_android_gradle_properties
    persist_env
  fi

  log "Setup complete"
  if [[ "$MODE" == "all" || "$MODE" == "android" ]]; then
    echo "Run: source ~/.bashrc"
  fi
}

main "$@"
