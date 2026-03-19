#!/usr/bin/env bash
set -euo pipefail

command -v jq &>/dev/null || { echo "Error: jq is required but not installed." >&2; exit 1; }

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(pwd)"
LEGACY_MODE=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    --project-root|-ProjectRoot) PROJECT_ROOT="$2"; shift 2 ;;
    --legacy-mode|-LegacyMode)   LEGACY_MODE=true;   shift ;;
    *) shift ;;
  esac
done

PASS_COUNT=0
FAIL_COUNT=0
WARN_COUNT=0

# result table rows: "name|pass|critical|detail"
RESULTS=()

add_result() {
  local name="$1" pass="$2" critical="$3" detail="$4"
  RESULTS+=("$name|$pass|$critical|$detail")
  if [[ "$pass" == "true" ]]; then
    ((PASS_COUNT++)) || true
  elif [[ "$critical" == "true" ]]; then
    ((FAIL_COUNT++)) || true
  else
    ((WARN_COUNT++)) || true
  fi
}

# 1) Manifest required docs check
MANIFEST_PATH="$SCRIPT_DIR/project-doc-manifest.yml"
if [[ ! -f "$MANIFEST_PATH" ]]; then
  add_result "manifest exists" "false" "true" "Missing $MANIFEST_PATH"
else
  add_result "manifest exists" "true" "true" "$MANIFEST_PATH"
  # Parse required: section (simple grep/awk, no YAML parser needed)
  REQUIRED_DOCS=$(awk '/^[[:space:]]*required:[[:space:]]*$/{flag=1;next} flag && /^[[:space:]]*optional:/{flag=0} flag && /^[[:space:]]*-[[:space:]]/{gsub(/^[[:space:]]*-[[:space:]]*/,""); print}' "$MANIFEST_PATH")
  MIGRATION_TOOL_ROOT="$(dirname "$SCRIPT_DIR")"
  MISSING_DOCS=()
  while IFS= read -r doc; do
    doc="${doc%$'\r'}"  # CRLF 방어
    [[ -z "$doc" ]] && continue
    # project_root 또는 migration_tool_root 어느 쪽에 있어도 통과
    [[ ! -f "$PROJECT_ROOT/$doc" ]] && [[ ! -f "$MIGRATION_TOOL_ROOT/$doc" ]] && MISSING_DOCS+=("$doc")
  done <<< "$REQUIRED_DOCS"
  if [[ ${#MISSING_DOCS[@]} -eq 0 ]]; then
    REQUIRED_COUNT=$(echo "$REQUIRED_DOCS" | grep -c '\S' || true)
    add_result "required docs present" "true" "true" "count=$REQUIRED_COUNT"
  else
    add_result "required docs present" "false" "true" "missing: ${MISSING_DOCS[*]}"
  fi
fi

# 2) legacy-migration-bootstrap
BOOTSTRAP_SCRIPT="$SCRIPT_DIR/skills/legacy-migration-bootstrap/scripts/bootstrap.sh"
if [[ ! -f "$BOOTSTRAP_SCRIPT" ]]; then
  add_result "bootstrap skill script exists" "false" "true" "$BOOTSTRAP_SCRIPT"
else
  add_result "bootstrap skill script exists" "true" "true" "$BOOTSTRAP_SCRIPT"
  BOOTSTRAP_JSON=$(bash "$BOOTSTRAP_SCRIPT" --project-root "$PROJECT_ROOT" --as-json 2>&1) || true
  if [[ -z "$BOOTSTRAP_JSON" ]] || ! echo "$BOOTSTRAP_JSON" | jq . &>/dev/null; then
    add_result "bootstrap run" "false" "true" "bootstrap command failed"
  else
    PHASE=$(echo "$BOOTSTRAP_JSON" | jq -r '.Phase // ""')
    if [[ -n "$PHASE" && "$PHASE" != "Unknown" ]]; then
      add_result "bootstrap run" "true" "true" "phase=$PHASE"
    else
      add_result "bootstrap run" "false" "true" "phase=$PHASE"
    fi
    MISSING_COUNT=$(echo "$BOOTSTRAP_JSON" | jq '[.Documents[] | select(.Exists == false)] | length')
    if [[ "$MISSING_COUNT" -eq 0 ]]; then
      add_result "bootstrap docs status" "true" "true" "all docs OK"
    else
      MISSING_NAMES=$(echo "$BOOTSTRAP_JSON" | jq -r '[.Documents[] | select(.Exists == false) | .File] | join(", ")')
      add_result "bootstrap docs status" "false" "true" "missing: $MISSING_NAMES"
    fi
  fi
fi

# 3) springmvc-spa-routing-guard
ROUTING_SCRIPT="$SCRIPT_DIR/skills/springmvc-spa-routing-guard/scripts/check-routing-contract.sh"
if [[ ! -f "$ROUTING_SCRIPT" ]]; then
  add_result "routing-guard skill script exists" "false" "true" "$ROUTING_SCRIPT"
else
  ROUTING_OUT=$(bash "$ROUTING_SCRIPT" --project-root "$PROJECT_ROOT" --no-fail 2>&1 || true)
  if echo "$ROUTING_OUT" | grep -q "FAILED CHECKS"; then
    add_result "routing-guard run" "false" "$( $LEGACY_MODE && echo false || echo true)" "contains FAILED CHECKS"
  else
    add_result "routing-guard run" "true" "$( $LEGACY_MODE && echo false || echo true)" "all routing checks passed"
  fi
fi

# 4) react-capture-qa-runner prerequisites
CAPTURE_SCRIPT="$SCRIPT_DIR/skills/react-capture-qa-runner/scripts/run-capture.sh"
FRONTEND_PKG="$PROJECT_ROOT/src/main/frontend/package.json"
if [[ ! -f "$CAPTURE_SCRIPT" ]]; then
  add_result "capture skill script exists" "false" "true" "$CAPTURE_SCRIPT"
elif [[ ! -f "$FRONTEND_PKG" ]]; then
  add_result "frontend package exists" "false" "true" "$FRONTEND_PKG"
else
  HAS_CAPTURE=$(jq -r '.scripts["capture:react"] // ""' "$FRONTEND_PKG")
  if [[ -n "$HAS_CAPTURE" ]]; then
    add_result "capture:react npm script" "true" "true" "present"
  else
    add_result "capture:react npm script" "false" "true" "missing in package.json"
  fi
  CAPTURE_DIR="$PROJECT_ROOT/captures/main"
  if [[ -d "$CAPTURE_DIR" ]]; then
    add_result "capture output directory exists" "true" "false" "$CAPTURE_DIR"
  else
    add_result "capture output directory exists" "false" "false" "$CAPTURE_DIR"
  fi
fi

# 5) migration-doc-sync session log check
SYNC_SCRIPT="$SCRIPT_DIR/skills/migration-doc-sync/scripts/sync-doc-stub.sh"
if [[ ! -f "$SYNC_SCRIPT" ]]; then
  add_result "doc-sync skill script exists" "false" "true" "$SYNC_SCRIPT"
else
  ROOT_LOGS=$(find "$PROJECT_ROOT" -maxdepth 1 -name 'SESSION_WORKLOG_*.md' 2>/dev/null | wc -l | tr -d ' ')
  MOVED_LOGS=$(find "$PROJECT_ROOT/docs/project-docs" -maxdepth 1 -name 'SESSION_WORKLOG_*.md' 2>/dev/null | wc -l | tr -d ' ')
  if [[ "$ROOT_LOGS" -gt 0 ]]; then
    add_result "doc-sync sessionlog autodetect" "true" "false" "root logs=$ROOT_LOGS"
  elif [[ "$MOVED_LOGS" -gt 0 ]]; then
    add_result "doc-sync sessionlog autodetect" "true" "false" "docs/project-docs logs=$MOVED_LOGS"
  else
    add_result "doc-sync sessionlog autodetect" "false" "false" "no session log found"
  fi
  if [[ "$MOVED_LOGS" -gt 0 ]]; then
    add_result "doc-sync moved session log exists" "true" "false" "docs/project-docs logs=$MOVED_LOGS"
  else
    add_result "doc-sync moved session log exists" "false" "false" "missing docs/project-docs/SESSION_WORKLOG_*.md"
  fi
fi

# 6) frontend session/login/logout guard policy
# Search for LoginPage and MainPage regardless of extension (.jsx preferred, .js fallback) or subdirectory
LOGIN_PAGE=$(find "$PROJECT_ROOT/src/main/frontend/src/pages" \
  -maxdepth 3 \( -name "LoginPage.jsx" -o -name "LoginPage.js" \) 2>/dev/null | sort | head -1)
MAIN_PAGE=$(find "$PROJECT_ROOT/src/main/frontend/src/pages" \
  -maxdepth 3 \( -name "MainPage.jsx" -o -name "MainPage.js" \) 2>/dev/null | sort | head -1)
if [[ -z "$LOGIN_PAGE" ]]; then
  add_result "login page exists for session guard" "false" "true" "not found under pages/ (.jsx or .js)"
else
  add_result "login page exists for session guard" "true" "true" "$LOGIN_PAGE"
  grep -qE 'policyCheck|sessionChecker' "$LOGIN_PAGE" \
    && add_result "login page calls auth endpoint" "true" "true" "policyCheck or sessionChecker call present" \
    || add_result "login page calls auth endpoint" "false" "true" "missing policyCheck and sessionChecker"
  grep -qE "navigate\(|window\.location" "$LOGIN_PAGE" \
    && add_result "login page navigates after auth" "true" "false" "navigation after login present" \
    || add_result "login page navigates after auth" "false" "false" "no navigation after login"
fi
if [[ -z "$MAIN_PAGE" ]]; then
  add_result "main page exists for logout guard" "false" "true" "not found under pages/ (.jsx or .js)"
else
  add_result "main page exists for logout guard" "true" "true" "$MAIN_PAGE"
  grep -q '/user/v1/logout' "$MAIN_PAGE" \
    && add_result "main logout calls backend api" "true" "true" "logout API call present" \
    || add_result "main logout calls backend api" "false" "true" "logout API call missing"
  grep -qE "navigate\(.*['\"/]login" "$MAIN_PAGE" \
    && add_result "main logout navigates to login" "true" "true" "login redirect after logout present" \
    || add_result "main logout navigates to login" "false" "true" "no login redirect after logout"
fi

# Print results table
echo ""
printf "%-55s %-8s %-10s %s\n" "Check" "Pass" "Critical" "Detail"
printf "%-55s %-8s %-10s %s\n" "-----" "----" "--------" "------"
for row in "${RESULTS[@]}"; do
  IFS='|' read -r name pass critical detail <<< "$row"
  printf "%-55s %-8s %-10s %s\n" "$name" "$pass" "$critical" "$detail"
done

echo ""
CRITICAL_FAILED=$(printf '%s\n' "${RESULTS[@]}" | awk -F'|' '$2=="false" && $3=="true"' | wc -l | tr -d ' ')
if [[ "$CRITICAL_FAILED" -gt 0 ]]; then
  echo "SUMMARY: FAIL (critical=$CRITICAL_FAILED)"
  exit 1
fi
if [[ "$WARN_COUNT" -gt 0 ]]; then
  echo "SUMMARY: PASS_WITH_WARNINGS (warnings=$WARN_COUNT)"
else
  echo "SUMMARY: PASS"
fi
