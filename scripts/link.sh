#!/usr/bin/env bash
# Build the release binary, put it where the manifest's commands expect it, link the plugin, and
# put `herdr-reviewr` on PATH.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

win_path() {
  if command -v cygpath >/dev/null 2>&1; then
    cygpath -w "$1"
  else
    printf '%s\n' "$1"
  fi
}

ensure_windows_user_path() {
  local win
  win="$(win_path "$1")"
  HERDR_REVIEWR_PATH_DIR="$win" powershell.exe -NoProfile -Command '
    $dir = $env:HERDR_REVIEWR_PATH_DIR
    $user = [Environment]::GetEnvironmentVariable("Path", "User")
    if ($null -eq $user) { $user = "" }
    $parts = @($user -split ";" | Where-Object { $_ -ne "" })
    if ($parts | Where-Object { $_.TrimEnd([char]92) -ieq $dir.TrimEnd([char]92) }) { exit 0 }
    $new = if ($user -eq "") { $dir } else { $user.TrimEnd(";") + ";" + $dir }
    [Environment]::SetEnvironmentVariable("Path", $new, "User")
  '
}

cargo build --release
mkdir -p bin "$HOME/.local/bin"

if [ "${OS-}" = Windows_NT ]; then
  "$ROOT/scripts/swap-binary.sh" target/release/herdr-reviewr.exe bin/herdr-reviewr.exe
  cp -f bin/herdr-reviewr.exe "$HOME/.local/bin/herdr-reviewr.exe"
  ensure_windows_user_path "$HOME/.local/bin"
  export PATH="$HOME/.local/bin:$PATH"
  herdr plugin link "$(win_path "$ROOT")"
else
  "$ROOT/scripts/swap-binary.sh" target/release/herdr-reviewr bin/herdr-reviewr
  if [ -d "$HOME/.local/bin" ]; then
    ln -sfn "$ROOT/bin/herdr-reviewr" "$HOME/.local/bin/herdr-reviewr"
  fi
  herdr plugin link "$ROOT"
fi
