#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="$(pwd)"
SESSION_LOG=""
APPLY=false
CHANGED_FILES=()
COMMANDS=()
CAPTURES=()

while [[ $# -gt 0 ]]; do
  case "$1" in
    --project-root|-ProjectRoot) PROJECT_ROOT="$2"; shift 2 ;;
    --session-log|-SessionLog)   SESSION_LOG="$2";  shift 2 ;;
    --apply|-Apply)              APPLY=true;         shift ;;
    --changed-file|-ChangedFiles) CHANGED_FILES+=("$2"); shift 2 ;;
    --command|-Commands)          COMMANDS+=("$2");  shift 2 ;;
    --capture|-Captures)          CAPTURES+=("$2");  shift 2 ;;
    *) shift ;;
  esac
done

if [[ -z "$SESSION_LOG" ]]; then
  SESSION_LOG=$(find "$PROJECT_ROOT/docs/project-docs" "$PROJECT_ROOT" -maxdepth 1 \
    -name 'SESSION_WORKLOG_*.md' 2>/dev/null | sort -r | head -1 || true)
fi

TS=$(date '+%Y-%m-%d %H:%M:%S %z')

build_list() {
  local -n _arr=$1
  if [[ ${#_arr[@]} -eq 0 ]]; then
    echo "  - (none)"
  else
    for item in "${_arr[@]}"; do echo "  - $item"; done
  fi
}

ENTRY=$(printf '\n## %s\n' "$TS")
ENTRY+=$'\n- Changed files:\n'$(build_list CHANGED_FILES)
ENTRY+=$'\n- Commands:\n'$(build_list COMMANDS)
ENTRY+=$'\n- Captures:\n'$(build_list CAPTURES)
ENTRY+=$'\n- Docs to sync:\n  - LATEST_STATE.md\n  - TASK_BOARD.md\n  - docs-migration-backlog.md\n  - docs-main-qa-report.md (if impacted)\n'

if $APPLY && [[ -n "$SESSION_LOG" ]]; then
  printf '%s' "$ENTRY" >> "$SESSION_LOG"
  echo "Appended session log entry: $SESSION_LOG"
else
  printf '%s\n' "$ENTRY"
fi
