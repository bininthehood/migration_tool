#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="$(pwd)"
AS_JSON=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    --project-root|-ProjectRoot) PROJECT_ROOT="$2"; shift 2 ;;
    --as-json|-AsJson)           AS_JSON=true;       shift ;;
    *) shift ;;
  esac
done

DOCS=("AGENTS.md" "WORKFLOW.md" "LATEST_STATE.md" "TASK_BOARD.md" "docs-migration-backlog.md")

# Resolve migration_tool root: sibling directory named migration_tool, or a subdirectory
MIGRATION_TOOL_ROOT=""
if [[ -d "$PROJECT_ROOT/migration_tool" ]]; then
  MIGRATION_TOOL_ROOT="$PROJECT_ROOT/migration_tool"
fi

# Helper: find a file in project root or migration_tool root
find_doc() {
  local doc="$1"
  if [[ -f "$PROJECT_ROOT/$doc" ]]; then
    echo "$PROJECT_ROOT/$doc"
  elif [[ -n "$MIGRATION_TOOL_ROOT" && -f "$MIGRATION_TOOL_ROOT/$doc" ]]; then
    echo "$MIGRATION_TOOL_ROOT/$doc"
  else
    echo ""
  fi
}

PHASE="Unknown"
LATEST_STATE_PATH="$(find_doc "LATEST_STATE.md")"
if [[ -n "$LATEST_STATE_PATH" ]]; then
  PHASE=$(awk '/^## 진행 단계/{getline; gsub(/^[[:space:]]+|[[:space:]]+$/, "", $0); print; exit}' "$LATEST_STATE_PATH")
  [[ -z "$PHASE" ]] && PHASE="Unknown"
fi

SELECTED_TASK=""
BACKLOG_PATH="$(find_doc "docs-migration-backlog.md")"
if [[ -n "$BACKLOG_PATH" ]]; then
  SELECTED_TASK=$(grep -E '\|\s*진행중\s*\|' "$BACKLOG_PATH" | head -1 || true)
fi
if [[ -z "$SELECTED_TASK" ]]; then
  TASK_BOARD_PATH="$(find_doc "TASK_BOARD.md")"
  if [[ -n "$TASK_BOARD_PATH" ]]; then
    SELECTED_TASK=$(grep -E '^\[ \] ' "$TASK_BOARD_PATH" | head -1 || true)
  fi
fi
[[ -z "$SELECTED_TASK" ]] && SELECTED_TASK="No pending task line found in docs."
SELECTED_TASK=$(echo "$SELECTED_TASK" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')

if $AS_JSON; then
  echo "{"
  echo "  \"ProjectRoot\": \"$PROJECT_ROOT\","
  echo "  \"Phase\": \"$PHASE\","
  echo "  \"SelectedTask\": \"$SELECTED_TASK\","
  echo "  \"Documents\": ["
  FIRST=true
  for D in "${DOCS[@]}"; do
    P="$(find_doc "$D")"
    EXISTS=$([ -n "$P" ] && echo "true" || echo "false")
    RESOLVED="${P:-$PROJECT_ROOT/$D}"
    $FIRST && FIRST=false || echo ","
    printf '    {"File": "%s", "Exists": %s, "Path": "%s"}' "$D" "$EXISTS" "$RESOLVED"
  done
  echo ""
  echo "  ]"
  echo "}"
else
  echo "[BOOTSTRAP]"
  echo "ProjectRoot: $PROJECT_ROOT"
  echo "Phase: $PHASE"
  echo "SelectedTask: $SELECTED_TASK"
  echo "Documents:"
  for D in "${DOCS[@]}"; do
    P="$(find_doc "$D")"
    STATUS=$([ -n "$P" ] && echo "OK" || echo "MISSING")
    echo "- $D: $STATUS"
  done
fi
