#!/usr/bin/env bash
set -euo pipefail

command -v jq &>/dev/null || { echo "Error: jq is required but not installed." >&2; exit 1; }

PROJECT_ROOT="$(pwd)"
MIGRATE_SCREEN=""
MIGRATE_BATCH=""
MIGRATION_PLAN_FILE="automation/migration-screen-map.json"
OUTPUT_DIR="docs/project-docs/migration-checklists"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --project-root|-ProjectRoot)         PROJECT_ROOT="$2";        shift 2 ;;
    --migrate-screen|-MigrateScreen)     MIGRATE_SCREEN="$2";      shift 2 ;;
    --migrate-batch|-MigrateBatch)       MIGRATE_BATCH="$2";       shift 2 ;;
    --migration-plan-file|-MigrationPlanFile) MIGRATION_PLAN_FILE="$2"; shift 2 ;;
    --output-dir|-OutputDir)             OUTPUT_DIR="$2";           shift 2 ;;
    *) shift ;;
  esac
done

if [[ -z "$MIGRATE_SCREEN" && -z "$MIGRATE_BATCH" ]]; then
  echo "Error: --migrate-screen or --migrate-batch is required." >&2
  exit 1
fi

PLAN_PATH="$PROJECT_ROOT/$MIGRATION_PLAN_FILE"
if [[ ! -f "$PLAN_PATH" ]]; then
  echo "Error: Migration plan file not found: $PLAN_PATH" >&2
  exit 1
fi

CHECKLIST_SCRIPT="$PROJECT_ROOT/automation/skills/jsp-react-screen-migrator/scripts/migrate-screen-checklist.sh"
if [[ ! -f "$CHECKLIST_SCRIPT" ]]; then
  echo "Error: Checklist script not found: $CHECKLIST_SCRIPT" >&2
  exit 1
fi

# Build list of target screens
TARGETS_JSON="[]"
if [[ -n "$MIGRATE_SCREEN" ]]; then
  TARGETS_JSON=$(jq --arg id "$MIGRATE_SCREEN" '[.screens[] | select(.id == $id)]' "$PLAN_PATH")
fi
if [[ -n "$MIGRATE_BATCH" ]]; then
  if [[ "$MIGRATE_BATCH" == "all" ]]; then
    BATCH_JSON=$(jq '.screens' "$PLAN_PATH")
  else
    BATCH_JSON=$(jq --arg grp "$MIGRATE_BATCH" '[.screens[] | select(.group == $grp)]' "$PLAN_PATH")
  fi
  TARGETS_JSON=$(jq -n --argjson a "$TARGETS_JSON" --argjson b "$BATCH_JSON" \
    '$a + $b | unique_by(.id)')
fi

TARGET_COUNT=$(echo "$TARGETS_JSON" | jq 'length')
if [[ "$TARGET_COUNT" -eq 0 ]]; then
  echo "Error: No migration targets selected (screen='$MIGRATE_SCREEN', batch='$MIGRATE_BATCH')." >&2
  exit 1
fi

RESOLVED_OUT_DIR="$PROJECT_ROOT/$OUTPUT_DIR"
mkdir -p "$RESOLVED_OUT_DIR"

echo "$TARGETS_JSON" | jq -c '.[]' | while IFS= read -r screen; do
  ID=$(echo "$screen" | jq -r '.id')
  LEGACY_URL=$(echo "$screen" | jq -r '.legacyUrl')
  REACT_ROUTE=$(echo "$screen" | jq -r '.reactRoute')

  if [[ -z "$ID" || -z "$LEGACY_URL" || -z "$REACT_ROUTE" ]]; then
    echo "Error: Invalid plan entry (missing id/legacyUrl/reactRoute): $screen" >&2
    exit 1
  fi

  OUT_PATH="$RESOLVED_OUT_DIR/${ID}-checklist.md"
  bash "$CHECKLIST_SCRIPT" \
    --project-root "$PROJECT_ROOT" \
    --legacy-url "$LEGACY_URL" \
    --react-route "$REACT_ROUTE" \
    --output-path "$OUT_PATH"
done

echo "MIGRATION_TARGETS=$TARGET_COUNT"
echo "OUTPUT_DIR=$RESOLVED_OUT_DIR"
