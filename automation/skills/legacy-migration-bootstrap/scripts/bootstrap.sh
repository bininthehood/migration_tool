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

PHASE="Unknown"
LATEST_STATE="$PROJECT_ROOT/LATEST_STATE.md"
if [[ -f "$LATEST_STATE" ]]; then
  PHASE=$(awk '/^## 진행 단계/{getline; gsub(/^[[:space:]]+|[[:space:]]+$/, "", $0); print; exit}' "$LATEST_STATE")
  [[ -z "$PHASE" ]] && PHASE="Unknown"
fi

SELECTED_TASK=""
BACKLOG="$PROJECT_ROOT/docs-migration-backlog.md"
if [[ -f "$BACKLOG" ]]; then
  SELECTED_TASK=$(grep -E '\|\s*진행중\s*\|' "$BACKLOG" | head -1 || true)
fi
if [[ -z "$SELECTED_TASK" ]]; then
  TASK_BOARD="$PROJECT_ROOT/TASK_BOARD.md"
  if [[ -f "$TASK_BOARD" ]]; then
    SELECTED_TASK=$(grep -E '^\[ \] ' "$TASK_BOARD" | head -1 || true)
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
    P="$PROJECT_ROOT/$D"
    EXISTS=$([ -f "$P" ] && echo "true" || echo "false")
    $FIRST && FIRST=false || echo ","
    printf '    {"File": "%s", "Exists": %s, "Path": "%s"}' "$D" "$EXISTS" "$P"
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
    P="$PROJECT_ROOT/$D"
    STATUS=$([ -f "$P" ] && echo "OK" || echo "MISSING")
    echo "- $D: $STATUS"
  done
fi
