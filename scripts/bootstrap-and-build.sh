#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

"$ROOT_DIR/scripts/setup-codespace.sh" all
source "$HOME/.bashrc"
"$ROOT_DIR/scripts/build-android-apk.sh"
"$ROOT_DIR/scripts/build-windows-companion.sh"

echo "Bootstrap + builds completed successfully."
