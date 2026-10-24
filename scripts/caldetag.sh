#!/usr/bin/env bash
# Removes device-calendar events whose description carries a given bracket
# tag, e.g. "[TeacherApp:12345]" — the convention apps use to mark events
# they created, so they can be found again later (including by this script).
#
# Usage:
#   ./caldetag.sh <tag> [-n|--dry-run] [-s <device-serial>]
#
# Example:
#   ./caldetag.sh TeacherApp --dry-run
#   ./caldetag.sh TeacherApp -s emulator-5554

set -euo pipefail

ADB=(adb)
DRY_RUN=0
TAG=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    -n|--dry-run) DRY_RUN=1; shift ;;
    -s) ADB=(adb -s "$2"); shift 2 ;;
    -h|--help)
      sed -n '2,10p' "$0"
      exit 0
      ;;
    -*)
      echo "Unknown option: $1" >&2
      exit 1
      ;;
    *)
      if [[ -n "$TAG" ]]; then
        echo "Unexpected extra argument: $1" >&2
        exit 1
      fi
      TAG="$1"
      shift
      ;;
  esac
done

if [[ -z "$TAG" ]]; then
  echo "Usage: $(basename "$0") <tag> [-n|--dry-run] [-s <device-serial>]" >&2
  echo "Example: $(basename "$0") TeacherApp --dry-run" >&2
  exit 1
fi

URI="content://com.android.calendar/events"
WHERE="description LIKE '%[$TAG:%'"

# Lists every distinct bracket tag ("[Foo:" -> "Foo") found across ALL events'
# descriptions, so a no-match case can suggest tags that actually exist.
suggest_tags() {
  local all
  all="$("${ADB[@]}" shell content query --uri "$URI" \
    --projection description \
    --where "\"description LIKE '%[%:%]%'\"" 2>&1)" || true

  echo "$all" | grep -oE '\[[A-Za-z0-9_.-]+:' | sed -E 's/^\[//; s/:$//' | sort -u
}

echo "Querying events tagged [$TAG:...]..."
RESULT="$("${ADB[@]}" shell content query --uri "$URI" \
  --projection _id:title:description \
  --where "\"$WHERE\"" 2>&1)" || true

COUNT=0
if [[ "$RESULT" != *"No result found"* && -n "$RESULT" ]]; then
  IDS=$(echo "$RESULT" | grep -oE '_id=[0-9]+' | cut -d= -f2)
  COUNT=$(echo "$IDS" | grep -c . || true)
fi

if [[ "$COUNT" -eq 0 ]]; then
  echo "No events tagged [$TAG:...] found."

  ALL_TAGS="$(suggest_tags)"
  if [[ -n "$ALL_TAGS" ]]; then
    CLOSE_MATCHES="$(echo "$ALL_TAGS" | grep -i -- "$TAG" || true)"
    if [[ -n "$CLOSE_MATCHES" ]]; then
      echo
      echo "Did you mean one of these?"
      echo "$CLOSE_MATCHES" | sed 's/^/  /'
    else
      echo
      echo "Tags actually found on this device:"
      echo "$ALL_TAGS" | sed 's/^/  /'
    fi
  fi

  exit 0
fi

echo "$RESULT"
echo
echo "Found $COUNT event(s)."

if [[ "$DRY_RUN" -eq 1 ]]; then
  echo "Dry run, not deleting."
  exit 0
fi

for id in $IDS; do
  echo "Deleting event id=$id"
  "${ADB[@]}" shell content delete --uri "$URI/$id"
done

echo "Done. Deleted $COUNT event(s)."
