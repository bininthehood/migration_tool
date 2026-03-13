#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="$(pwd)"
LEGACY_URL=""
REACT_ROUTE=""
OUTPUT_PATH=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --project-root|-ProjectRoot) PROJECT_ROOT="$2"; shift 2 ;;
    --legacy-url|-LegacyUrl)     LEGACY_URL="$2";   shift 2 ;;
    --react-route|-ReactRoute)   REACT_ROUTE="$2";  shift 2 ;;
    --output-path|-OutputPath)   OUTPUT_PATH="$2";  shift 2 ;;
    *) shift ;;
  esac
done

if [[ -z "$LEGACY_URL" || -z "$REACT_ROUTE" ]]; then
  echo "Error: --legacy-url and --react-route are required" >&2
  exit 1
fi

BACKLOG="$PROJECT_ROOT/docs-migration-backlog.md"
ENDPOINT_MAP="$PROJECT_ROOT/ENDPOINT_MAP.md"

BACKLOG_HINT=""
if [[ -f "$BACKLOG" ]]; then
  BACKLOG_HINT=$(grep -F "$LEGACY_URL" "$BACKLOG" | head -1 || true)
fi

ENDPOINT_HINT=""
if [[ -f "$ENDPOINT_MAP" ]]; then
  FIRST_KEY=$(echo "$REACT_ROUTE" | sed 's|^/ui/||' | cut -d'/' -f1)
  ENDPOINT_HINT=$(grep -F "$FIRST_KEY" "$ENDPOINT_MAP" | head -1 || true)
fi

TS=$(date '+%Y-%m-%d %H:%M:%S %z')

MD=$(cat <<EOF
# Migration Checklist

- Legacy URL: $LEGACY_URL
- React Route: $REACT_ROUTE
- Date: $TS

## Pre-check
- [ ] Confirm routing contract files
- [ ] Confirm API dependencies
- [ ] Confirm auth/session behavior

## Implementation
- [ ] Add/adjust React route and page component
- [ ] Keep JSP entry URL unchanged
- [ ] Keep backend API contract unchanged

## Validation
- [ ] Direct access $REACT_ROUTE returns 200
- [ ] Refresh on $REACT_ROUTE returns 200
- [ ] No basename mismatch or console errors
- [ ] Capture evidence collected

## Evidence Hints
- Backlog line: ${BACKLOG_HINT}
- Endpoint hint: ${ENDPOINT_HINT}
EOF
)

if [[ -n "$OUTPUT_PATH" ]]; then
  mkdir -p "$(dirname "$OUTPUT_PATH")"
  printf '%s\n' "$MD" > "$OUTPUT_PATH"
  echo "Wrote checklist: $OUTPUT_PATH"
else
  printf '%s\n' "$MD"
fi
