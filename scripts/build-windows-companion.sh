#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP_DIR="$ROOT_DIR/pc-companion/CompanionApp"
OUTPUT_DIR="$ROOT_DIR/pc-companion/dist/win-x64"

if ! command -v dotnet >/dev/null 2>&1; then
  echo "dotnet SDK not found. Run scripts/setup-codespace.sh dotnet first." >&2
  exit 1
fi

cd "$APP_DIR"
dotnet restore

dotnet publish \
  -c Release \
  -r win-x64 \
  --self-contained false \
  -p:EnableWindowsTargeting=true \
  -o "$OUTPUT_DIR"

echo "Windows companion published to: $OUTPUT_DIR"
