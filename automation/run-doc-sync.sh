#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(pwd)"
CHANGED_FILES=()
COMMANDS=()
CAPTURES=()
APPLY=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    --project-root|-ProjectRoot) PROJECT_ROOT="$2"; shift 2 ;;
    --changed-file)               CHANGED_FILES+=("$2"); shift 2 ;;
    --command)                    COMMANDS+=("$2");  shift 2 ;;
    --capture)                    CAPTURES+=("$2");  shift 2 ;;
    --apply|-Apply)               APPLY=true;         shift ;;
    *) shift ;;
  esac
done

SYNC_SCRIPT="$SCRIPT_DIR/skills/migration-doc-sync/scripts/sync-doc-stub.sh"
if [[ ! -f "$SYNC_SCRIPT" ]]; then
  echo "Error: Skill script not found: $SYNC_SCRIPT" >&2
  exit 1
fi

# Find or create session log
SESSION_LOG=""
for search_dir in "$PROJECT_ROOT/docs/project-docs" "$PROJECT_ROOT"; do
  if [[ -d "$search_dir" ]]; then
    SESSION_LOG=$(find "$search_dir" -maxdepth 1 -name 'SESSION_WORKLOG_*.md' | sort -r | head -1 || true)
    [[ -n "$SESSION_LOG" ]] && break
  fi
done

if [[ -z "$SESSION_LOG" ]]; then
  LOG_DIR="$PROJECT_ROOT/docs/project-docs"
  mkdir -p "$LOG_DIR"
  SESSION_LOG="$LOG_DIR/SESSION_WORKLOG_$(date '+%Y-%m-%d').md"
  if [[ ! -f "$SESSION_LOG" ]]; then
    printf '# Session Worklog\n\nAuto-created by automation/run-doc-sync.sh on %s.\n' \
      "$(date '+%Y-%m-%d %H:%M:%S %z')" > "$SESSION_LOG"
  fi
fi

ARGS=(--project-root "$PROJECT_ROOT" --session-log "$SESSION_LOG")
for f in "${CHANGED_FILES[@]}"; do ARGS+=(--changed-file "$f"); done
for c in "${COMMANDS[@]}";       do ARGS+=(--command "$c");      done
for p in "${CAPTURES[@]}";       do ARGS+=(--capture "$p");      done
$APPLY && ARGS+=(--apply)

echo "Running doc-sync with SessionLog: $SESSION_LOG"
bash "$SYNC_SCRIPT" "${ARGS[@]}"
