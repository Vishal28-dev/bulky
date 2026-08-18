#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
mkdir -p "$ROOT/macos/Runner/Resources" "$ROOT/windows/runner/resources"

if [[ "$(uname -s)" == "Darwin" ]]; then
  echo "Downloading macOS ffmpeg..."
  tmp="$(mktemp -d)"
  curl -L "https://evermeet.cx/ffmpeg/getrelease/zip" -o "$tmp/ffmpeg.zip"
  unzip -o "$tmp/ffmpeg.zip" -d "$tmp"
  if [[ -f "$tmp/ffmpeg" ]]; then
    cp "$tmp/ffmpeg" "$ROOT/macos/Runner/Resources/ffmpeg"
    chmod +x "$ROOT/macos/Runner/Resources/ffmpeg"
    echo "Installed macos/Runner/Resources/ffmpeg"
  else
    echo "Unexpected zip layout:" >&2
    ls -la "$tmp" >&2
    exit 1
  fi
fi

echo "For Windows, download a static ffmpeg.exe from https://www.gyan.dev/ffmpeg/builds/ and place it at windows/runner/resources/ffmpeg.exe"
echo "The app also uses ffmpeg from PATH if a bundled binary is missing."
