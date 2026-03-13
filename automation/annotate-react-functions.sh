#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="$(pwd)"
TARGET_ROOT="src/main/frontend/src"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --project-root|-ProjectRoot) PROJECT_ROOT="$2"; shift 2 ;;
    --target-root|-TargetRoot) TARGET_ROOT="$2"; shift 2 ;;
    *) shift ;;
  esac
done

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
python3 "$SCRIPT_DIR/annotate-react-functions.py" \
  --project-root "$PROJECT_ROOT" \
  --target-root "$TARGET_ROOT"
