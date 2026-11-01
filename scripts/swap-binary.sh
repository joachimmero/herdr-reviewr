#!/usr/bin/env bash
# swap-binary.sh <src> <dst>: replace through a fresh inode (macOS SIGKILL) and re-sign on Darwin.
# On Windows, a stem argument resolves to the `.exe` Cargo writes.
set -euo pipefail

src="$1"
dst="$2"
if [ "${OS-}" = Windows_NT ]; then
  case "$src" in *.exe) ;; *) [ -f "$src.exe" ] && src="$src.exe" ;; esac
  case "$dst" in *.exe) ;; *) dst="$dst.exe" ;; esac
fi
[ -f "$src" ] || { echo "swap-binary: missing source $src" >&2; exit 1; }

rm -f "$dst"
cp "$src" "$dst.staging"
mv "$dst.staging" "$dst"
[ "$(uname)" = "Darwin" ] && codesign --force --sign - "$dst"
exit 0
