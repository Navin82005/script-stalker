#!/bin/bash

# install-macos-linux.sh
#
# Scans the scripts/ folder, and installs every Bash script it finds as a
# command on macOS / Linux, removing the .sh extension from the command name.
#
# Usage:
#   ./install-macos-linux.sh
#   INSTALL_DIR=/usr/local/bin ./install-macos-linux.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPTS_SRC_DIR="$SCRIPT_DIR/scripts"
INSTALL_DIR="${INSTALL_DIR:-$HOME/.local/bin}"

if [[ ! -d "$SCRIPTS_SRC_DIR" ]]; then
  echo "❌ No 'scripts' folder found next to this installer: $SCRIPTS_SRC_DIR"
  exit 1
fi

# A file counts as a Bash script if its first line is a bash shebang,
# e.g. "#!/bin/bash" or "#!/usr/bin/env bash".
is_bash_script() {
  local FILE="$1"

  [[ -f "$FILE" ]] || return 1

  local FIRST_LINE
  FIRST_LINE="$(head -n 1 "$FILE" 2>/dev/null || true)"

  [[ "$FIRST_LINE" =~ ^#!.*(/|[[:space:]])bash([[:space:]]|$) ]]
}

echo "📦 Installing CLI tools to: $INSTALL_DIR"
mkdir -p "$INSTALL_DIR"

INSTALLED=()

shopt -s nullglob

for SRC in "$SCRIPTS_SRC_DIR"/*; do
  SOURCE_NAME="$(basename "$SRC")"

  if ! is_bash_script "$SRC"; then
    echo "⏭️  Skipping (not a Bash script): $SOURCE_NAME"
    continue
  fi

  # Remove the .sh extension from the installed command name.
  TOOL="${SOURCE_NAME%.sh}"

  DEST="$INSTALL_DIR/$TOOL"

  cp "$SRC" "$DEST"
  chmod +x "$DEST"

  INSTALLED+=("$TOOL")

  echo "✅ Installed: $DEST"
done

shopt -u nullglob

if [[ ${#INSTALLED[@]} -eq 0 ]]; then
  echo "❌ No Bash scripts found in $SCRIPTS_SRC_DIR"
  exit 1
fi

echo

# Check whether INSTALL_DIR is on PATH
if [[ ":$PATH:" != *":$INSTALL_DIR:"* ]]; then
  echo "⚠️  $INSTALL_DIR is not currently on your PATH."
  echo

  SHELL_RC=""

  case "$(basename "${SHELL:-}")" in
    zsh)  SHELL_RC="$HOME/.zshrc" ;;
    bash) SHELL_RC="$HOME/.bashrc" ;;
    *)    SHELL_RC="$HOME/.profile" ;;
  esac

  echo "Add this line to $SHELL_RC to use the commands from anywhere:"
  echo
  echo "  export PATH=\"$INSTALL_DIR:\$PATH\""
  echo

  read -r -p "Add it automatically now? [y/N]: " ADD_PATH

  if [[ "$ADD_PATH" =~ ^[Yy]$ ]]; then
    echo "export PATH=\"$INSTALL_DIR:\$PATH\"" >> "$SHELL_RC"
    echo "✅ Added. Run: source $SHELL_RC  (or open a new terminal)"
  fi
else
  echo "✅ $INSTALL_DIR is already on your PATH."
fi

echo
echo "🎉 Done. Installed commands:"

for TOOL in "${INSTALLED[@]}"; do
  echo "   $TOOL"
done