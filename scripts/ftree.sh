#!/bin/bash

# ftree - Display a copyable tree structure of a folder or ZIP file.
#
# Usage:
#   ftree <folder>
#   ftree <file.zip>
#
# Examples:
#   ftree .
#   ftree ./my_project
#   ftree ./archive.zip

set -e

INPUT="$1"

if [ -z "$INPUT" ]; then
    echo "Usage: ftree <folder|zip-file>"
    exit 1
fi

# ─────────────────────────────────────────────
# Folder
# ─────────────────────────────────────────────

print_folder() {
    local ROOT="$1"

    echo "$(basename "$(cd "$ROOT" && pwd)")/"

    cd "$ROOT" || exit 1

    find . -mindepth 1 \
        \( \
            -name ".git" -o \
            -name "node_modules" -o \
            -name ".dart_tool" -o \
            -name "build" -o \
            -name "Pods" -o \
            -name ".gradle" \
        \) -prune -o \
        -print |
        sed 's#^\./##' |
        sort |
        awk '
        {
            n = split($0, parts, "/")

            indent = ""

            for (i = 1; i < n; i++) {
                indent = indent "│   "
            }

            if (substr($0, length($0), 1) == "/") {
                print indent "├── " parts[n]
            } else {
                print indent "├── " parts[n]
            }
        }'
}

# ─────────────────────────────────────────────
# ZIP file
# ─────────────────────────────────────────────

print_zip() {
    local ZIP="$1"

    if ! command -v unzip >/dev/null 2>&1; then
        echo "Error: 'unzip' is required to inspect ZIP files."
        exit 1
    fi

    echo "$(basename "$ZIP")"

    unzip -Z1 "$ZIP" |
        sed 's#/$##' |
        sort |
        awk '
        {
            n = split($0, parts, "/")

            indent = ""

            for (i = 1; i < n; i++) {
                indent = indent "│   "
            }

            print indent "├── " parts[n]
        }'
}

# ─────────────────────────────────────────────
# Input detection
# ─────────────────────────────────────────────

if [ -d "$INPUT" ]; then

    print_folder "$INPUT"

elif [ -f "$INPUT" ] && [[ "$INPUT" =~ \.zip$ ]]; then

    print_zip "$INPUT"

else

    echo "Error: '$INPUT' is not a supported folder or ZIP file."
    exit 1

fi