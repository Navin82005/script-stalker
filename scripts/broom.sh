#!/bin/bash

# Flutter Project Deep Cleaner for macOS
#
# Usage:
#   ./flutter_cleanup.sh ~/Projects
#
# If no directory is provided, defaults to $HOME.

set -u

ROOT_DIR="${1:-$HOME}"

# Convert to absolute path
ROOT_DIR="$(cd "$ROOT_DIR" 2>/dev/null && pwd)"

if [[ -z "$ROOT_DIR" ]]; then
  echo "❌ Invalid directory."
  exit 1
fi

echo "🧹 Flutter Project Cleaner"
echo "📂 Search root: $ROOT_DIR"
echo
echo "This will remove generated Flutter/Dart/iOS/Android artifacts"
echo "from every Flutter project found under this directory."
echo

read -r -p "Continue? [y/N]: " CONFIRM

if [[ ! "$CONFIRM" =~ ^[Yy]$ ]]; then
  echo "Cancelled."
  exit 0
fi

PROJECT_COUNT=0

while IFS= read -r -d '' PUBSPEC; do

  PROJECT_DIR="$(dirname "$PUBSPEC")"

  # Only treat it as Flutter if pubspec contains Flutter SDK dependency.
  if ! grep -Eq '^[[:space:]]*flutter:[[:space:]]*$' "$PUBSPEC"; then
    continue
  fi

  echo
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "📱 Flutter project: $PROJECT_DIR"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

  # Equivalent project build cleanup
  rm -rf "$PROJECT_DIR/build"

  # Dart / Flutter generated state
  rm -rf "$PROJECT_DIR/.dart_tool"
  rm -f  "$PROJECT_DIR/.flutter-plugins"
  rm -f  "$PROJECT_DIR/.flutter-plugins-dependencies"
  rm -f  "$PROJECT_DIR/.packages"

  # iOS generated artifacts
  rm -rf "$PROJECT_DIR/ios/Pods"
  rm -rf "$PROJECT_DIR/ios/.symlinks"
  rm -rf "$PROJECT_DIR/ios/Flutter/ephemeral"
  rm -f  "$PROJECT_DIR/ios/Podfile.lock"

  # macOS generated artifacts
  rm -rf "$PROJECT_DIR/macos/Pods"
  rm -rf "$PROJECT_DIR/macos/Flutter/ephemeral"
  rm -f  "$PROJECT_DIR/macos/Podfile.lock"

  # Android project-local generated artifacts
  rm -rf "$PROJECT_DIR/android/.gradle"
  rm -rf "$PROJECT_DIR/android/app/build"
  rm -rf "$PROJECT_DIR/android/build"

  # Plugin example projects / nested package build outputs are
  # intentionally NOT recursively deleted here.

  PROJECT_COUNT=$((PROJECT_COUNT + 1))
  echo "✅ Cleaned: $PROJECT_DIR"

done < <(find "$ROOT_DIR" \
  \( \
    -name ".git" -o \
    -name "node_modules" -o \
    -name "Pods" -o \
    -name "build" -o \
    -name ".dart_tool" \
  \) -prune -o \
  -name "pubspec.yaml" -print0)

echo
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✨ Flutter project cleanup complete."
echo "   Projects cleaned: $PROJECT_COUNT"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo
echo "Run 'flutter pub get' in a project before building it again."