#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="$(pwd)"
USER_NAME="admin"
PASSWORD="admin"
CAPTURE_MODE="single"
CAPTURE_PATH="/rays/ui/login"
CAPTURE_NAME="react-login-automation-check"
CAPTURE_PRESET="all"
CAPTURE_BASE_URL="http://localhost:3000"
CAPTURE_DEV_SERVER_PORT=3000
CAPTURE_DEV_SERVER_START_TIMEOUT_SEC=120
DISABLE_AUTO_START_CAPTURE_DEV_SERVER=false
BOOTSTRAP_FRONTEND=false
DISABLE_AUTO_BOOTSTRAP_FRONTEND=false
LEGACY_MODE=false
INSTALL_FRONTEND_DEPS=false
DISABLE_AUTO_INSTALL_FRONTEND_DEPS=false
FRONTEND_INSTALL_TIMEOUT_SEC=900
DISABLE_AUTO_INSTALL_PLAYWRIGHT_BROWSERS=false
SKIP_FRONTEND_COMPILE_CHECK=false
FRONTEND_BUILD_TIMEOUT_SEC=1800
SKIP_SESSION_CONTRACT_CHECK=false
SKIP_FRONTEND_CHECK=false
GIT_COMMIT=false
GIT_COMMIT_MESSAGE=""
GIT_REMOTE_URL=""
GIT_DEFAULT_BRANCH="main"
GIT_INIT_IF_MISSING=false
LEGACY_BASE_URL="http://localhost:8080"
TOMCAT_BASE_URL="http://localhost:8080"
TOMCAT_CONTEXT_PATH="/rays"
TOMCAT_HEALTH_PATH="/ui/"
TOMCAT_HOME="C:/dev/eclipse/bin/apache-tomcat-9.0.100"
TOMCAT_BASE="C:/dev/eclipse/workspace/.metadata/.plugins/org.eclipse.wst.server.core/tmp0"
TOMCAT_JRE_HOME="C:/Users/rays/.p2/pool/plugins/org.eclipse.justj.openjdk.hotspot.jre.full.win32.x86_64_21.0.10.v20260205-0638/jre"
TOMCAT_CONTROL_ACTION="none"
TOMCAT_CONTROL_TIMEOUT_SEC=120
TOMCAT_CONTROL_NO_HEALTH_CHECK=false
SKIP_TOMCAT_CHECK=false
LOG_DIR="automation/logs"
FEEDBACK_FILE="docs/project-docs/MIGRATION_AUTOMATION_FEEDBACK.md"
HISTORY_WINDOW=20
BUILD=false
MIGRATE_SCREEN=""
MIGRATE_BATCH=""
MIGRATION_PLAN_FILE="automation/migration-screen-map.json"
MIGRATION_OUTPUT_DIR="docs/project-docs/migration-checklists"
SKIP_REACT_FUNCTION_COMMENTING=false
SKIP_DOC_SYNC=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    --project-root|-ProjectRoot) PROJECT_ROOT="$2"; shift 2 ;;
    --user|-User) USER_NAME="$2"; shift 2 ;;
    --password|-Password) PASSWORD="$2"; shift 2 ;;
    --capture-mode|-CaptureMode) CAPTURE_MODE="$2"; shift 2 ;;
    --capture-path|-CapturePath) CAPTURE_PATH="$2"; shift 2 ;;
    --capture-name|-CaptureName) CAPTURE_NAME="$2"; shift 2 ;;
    --capture-preset|-CapturePreset) CAPTURE_PRESET="$2"; shift 2 ;;
    --capture-base-url|-CaptureBaseUrl) CAPTURE_BASE_URL="$2"; shift 2 ;;
    --capture-dev-server-port|-CaptureDevServerPort) CAPTURE_DEV_SERVER_PORT="$2"; shift 2 ;;
    --capture-dev-server-start-timeout-sec|-CaptureDevServerStartTimeoutSec) CAPTURE_DEV_SERVER_START_TIMEOUT_SEC="$2"; shift 2 ;;
    --disable-auto-start-capture-dev-server|-DisableAutoStartCaptureDevServer) DISABLE_AUTO_START_CAPTURE_DEV_SERVER=true; shift ;;
    --bootstrap-frontend|-BootstrapFrontend) BOOTSTRAP_FRONTEND=true; shift ;;
    --disable-auto-bootstrap-frontend|-DisableAutoBootstrapFrontend) DISABLE_AUTO_BOOTSTRAP_FRONTEND=true; shift ;;
    --legacy-mode|-LegacyMode) LEGACY_MODE=true; shift ;;
    --install-frontend-deps|-InstallFrontendDeps) INSTALL_FRONTEND_DEPS=true; shift ;;
    --disable-auto-install-frontend-deps|-DisableAutoInstallFrontendDeps) DISABLE_AUTO_INSTALL_FRONTEND_DEPS=true; shift ;;
    --frontend-install-timeout-sec|-FrontendInstallTimeoutSec) FRONTEND_INSTALL_TIMEOUT_SEC="$2"; shift 2 ;;
    --disable-auto-install-playwright-browsers|-DisableAutoInstallPlaywrightBrowsers) DISABLE_AUTO_INSTALL_PLAYWRIGHT_BROWSERS=true; shift ;;
    --skip-frontend-compile-check|-SkipFrontendCompileCheck) SKIP_FRONTEND_COMPILE_CHECK=true; shift ;;
    --frontend-build-timeout-sec|-FrontendBuildTimeoutSec) FRONTEND_BUILD_TIMEOUT_SEC="$2"; shift 2 ;;
    --skip-session-contract-check|-SkipSessionContractCheck) SKIP_SESSION_CONTRACT_CHECK=true; shift ;;
    --skip-frontend-check|-SkipFrontendCheck) SKIP_FRONTEND_CHECK=true; shift ;;
    --git-commit|-GitCommit) GIT_COMMIT=true; shift ;;
    --git-commit-message|-GitCommitMessage) GIT_COMMIT_MESSAGE="$2"; shift 2 ;;
    --git-remote-url|-GitRemoteUrl) GIT_REMOTE_URL="$2"; shift 2 ;;
    --git-default-branch|-GitDefaultBranch) GIT_DEFAULT_BRANCH="$2"; shift 2 ;;
    --git-init-if-missing|-GitInitIfMissing) GIT_INIT_IF_MISSING=true; shift ;;
    --legacy-base-url|-LegacyBaseUrl) LEGACY_BASE_URL="$2"; shift 2 ;;
    --tomcat-base-url|-TomcatBaseUrl) TOMCAT_BASE_URL="$2"; shift 2 ;;
    --tomcat-context-path|-TomcatContextPath) TOMCAT_CONTEXT_PATH="$2"; shift 2 ;;
    --tomcat-health-path|-TomcatHealthPath) TOMCAT_HEALTH_PATH="$2"; shift 2 ;;
    --tomcat-home|-TomcatHome) TOMCAT_HOME="$2"; shift 2 ;;
    --tomcat-base|-TomcatBase) TOMCAT_BASE="$2"; shift 2 ;;
    --tomcat-jre-home|-TomcatJreHome) TOMCAT_JRE_HOME="$2"; shift 2 ;;
    --tomcat-control-action|-TomcatControlAction) TOMCAT_CONTROL_ACTION="$2"; shift 2 ;;
    --tomcat-control-timeout-sec|-TomcatControlTimeoutSec) TOMCAT_CONTROL_TIMEOUT_SEC="$2"; shift 2 ;;
    --tomcat-control-no-health-check|-TomcatControlNoHealthCheck) TOMCAT_CONTROL_NO_HEALTH_CHECK=true; shift ;;
    --skip-tomcat-check|-SkipTomcatCheck) SKIP_TOMCAT_CHECK=true; shift ;;
    --log-dir|-LogDir) LOG_DIR="$2"; shift 2 ;;
    --feedback-file|-FeedbackFile) FEEDBACK_FILE="$2"; shift 2 ;;
    --history-window|-HistoryWindow) HISTORY_WINDOW="$2"; shift 2 ;;
    --build|-Build) BUILD=true; shift ;;
    --migrate-screen|-MigrateScreen) MIGRATE_SCREEN="$2"; shift 2 ;;
    --migrate-batch|-MigrateBatch) MIGRATE_BATCH="$2"; shift 2 ;;
    --migration-plan-file|-MigrationPlanFile) MIGRATION_PLAN_FILE="$2"; shift 2 ;;
    --migration-output-dir|-MigrationOutputDir|--output-dir|-OutputDir) MIGRATION_OUTPUT_DIR="$2"; shift 2 ;;
    --skip-react-function-commenting|-SkipReactFunctionCommenting) SKIP_REACT_FUNCTION_COMMENTING=true; shift ;;
    --skip-doc-sync|-SkipDocSync) SKIP_DOC_SYNC=true; shift ;;
    *) shift ;;
  esac
done

command -v bash >/dev/null 2>&1 || { echo "Error: bash required" >&2; exit 1; }
command -v curl >/dev/null 2>&1 || { echo "Error: curl required" >&2; exit 1; }
command -v jq >/dev/null 2>&1 || { echo "Error: jq required" >&2; exit 1; }
command -v python3 >/dev/null 2>&1 || { echo "Error: python3 required" >&2; exit 1; }
command -v npm >/dev/null 2>&1 || { echo "Error: npm required" >&2; exit 1; }
command -v npx >/dev/null 2>&1 || { echo "Error: npx required" >&2; exit 1; }

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_DIR_PATH="$PROJECT_ROOT/$LOG_DIR"
FEEDBACK_PATH="$PROJECT_ROOT/$FEEDBACK_FILE"
MANIFEST_PATH="$SCRIPT_DIR/next-session-manifest.json"
RUN_ID="$(date '+%Y%m%d-%H%M%S')"
RUN_STARTED_AT="$(date '+%Y-%m-%dT%H:%M:%S%z')"
RUN_STATUS="success"
AUTO_LEGACY_MODE=false
DEV_SERVER_PID=""

COMMANDS_JSON='[]'
CAPTURES_JSON='[]'
STEPS_JSON='[]'

cleanup() {
  if [[ -n "$DEV_SERVER_PID" ]] && kill -0 "$DEV_SERVER_PID" 2>/dev/null; then
    kill "$DEV_SERVER_PID" 2>/dev/null || true
  fi
}
trap cleanup EXIT

append_string_json() {
  local current="$1"
  local value="$2"
  jq -cn --argjson arr "$current" --arg val "$value" '$arr + [$val]'
}

add_command() {
  COMMANDS_JSON="$(append_string_json "$COMMANDS_JSON" "$1")"
}

add_capture() {
  CAPTURES_JSON="$(append_string_json "$CAPTURES_JSON" "$1")"
}

get_error_code() {
  local message="${1:-}"
  [[ -z "$message" ]] && { echo "UNKNOWN"; return; }
  [[ "$message" =~ EPERM|browserType\.launch|spawn\ EPERM ]] && { echo "CAPTURE_EPERM"; return; }
  [[ "$message" =~ EADDRINUSE|port\ 3000|port\ 8080|already\ in\ use ]] && { echo "PORT_CONFLICT"; return; }
  [[ "$message" =~ Missing ]] && { echo "SCRIPT_MISSING"; return; }
  [[ "$message" =~ npm\ run\ build\ failed|frontend\ compile\ check\ failed|npm\ ERR! ]] && { echo "NPM_BUILD_FAIL"; return; }
  [[ "$message" =~ UTF8_MOJIBAKE_DETECTED ]] && { echo "UTF8_MOJIBAKE_DETECTED"; return; }
  [[ "$message" =~ FRONTEND_DEVSERVER_START_FAIL|capture\ dev\ server\ start\ failed|capture\ dev\ server\ did\ not\ become\ ready ]] && { echo "FRONTEND_DEVSERVER_START_FAIL"; return; }
  [[ "$message" =~ routing\ check\ failed ]] && { echo "ROUTING_CONTRACT_FAIL"; return; }
  [[ "$message" =~ screen\ migration\ step\ failed ]] && { echo "MIGRATION_EXEC_FAIL"; return; }
  [[ "$message" =~ validate\ step\ failed ]] && { echo "PREFLIGHT_FAIL"; return; }
  [[ "$message" =~ doc-sync\ step\ failed|run-doc-sync ]] && { echo "DOC_SYNC_FAIL"; return; }
  [[ "$message" =~ TOMCAT_NOT_READY ]] && { echo "TOMCAT_NOT_READY"; return; }
  [[ "$message" =~ TOMCAT_UI_NOT_READY ]] && { echo "TOMCAT_UI_NOT_READY"; return; }
  [[ "$message" =~ TOMCAT_CONTROL_FAIL ]] && { echo "TOMCAT_CONTROL_FAIL"; return; }
  [[ "$message" =~ frontend\ deps\ install\ failed|Cannot\ find\ module ]] && { echo "FRONTEND_DEPS_MISSING"; return; }
  [[ "$message" =~ Executable\ doesn\'t\ exist|playwright\ install|browser\ executable ]] && { echo "PLAYWRIGHT_BROWSER_MISSING"; return; }
  [[ "$message" =~ FRONTEND_BOOTSTRAP_REQUIRED ]] && { echo "FRONTEND_BOOTSTRAP_REQUIRED"; return; }
  [[ "$message" =~ session\ contract\ check\ failed|policyCheck\ resultCode|sessionAlive\ resultCode|sessionInfo\ resultCode|sessionInfo\.sessionData ]] && { echo "SESSION_CONTRACT_FAIL"; return; }
  echo "UNKNOWN"
}

add_step_result() {
  local name="$1"
  local status="$2"
  local elapsed="$3"
  local error_code="$4"
  local error_message="$5"
  STEPS_JSON="$(
    jq -cn \
      --argjson arr "$STEPS_JSON" \
      --arg n "$name" \
      --arg s "$status" \
      --argjson e "$elapsed" \
      --arg c "$error_code" \
      --arg m "$error_message" \
      '$arr + [{"name":$n,"status":$s,"duration_sec":$e,"error_code":$c,"error_message":$m}]'
  )"
}

run_step() {
  local name="$1"
  local fn="$2"
  echo
  echo "== $name =="
  local start output rc elapsed code
  start=$(date +%s)
  set +e
  output="$("$fn" 2>&1)"
  rc=$?
  set -e
  [[ -n "$output" ]] && printf '%s\n' "$output"
  elapsed=$(( $(date +%s) - start ))
  if [[ $rc -eq 0 ]]; then
    add_step_result "$name" "success" "$elapsed" "" ""
    return 0
  fi
  code="$(get_error_code "$output")"
  add_step_result "$name" "failed" "$elapsed" "$code" "$output"
  return "$rc"
}

http_ready() {
  local url="$1"
  local code
  code=$(curl -s -o /dev/null -w "%{http_code}" --max-time 8 "$url" 2>/dev/null || echo "000")
  [[ "$code" =~ ^[0-9]+$ ]] && [[ "$code" -ge 200 && "$code" -lt 400 ]]
}

wait_port_listening() {
  local port="$1"
  local timeout="${2:-30}"
  local deadline=$(( $(date +%s) + timeout ))
  while [[ $(date +%s) -lt $deadline ]]; do
    if command -v nc >/dev/null 2>&1; then
      nc -z localhost "$port" 2>/dev/null && return 0
    elif command -v ss >/dev/null 2>&1; then
      ss -ltn | grep -q ":$port " && return 0
    fi
    sleep 1
  done
  return 1
}

run_with_timeout() {
  local timeout_sec="$1"
  shift
  if command -v timeout >/dev/null 2>&1; then
    timeout "${timeout_sec}s" "$@"
  else
    "$@"
  fi
}

get_mojibake_candidates() {
  python3 - "$PROJECT_ROOT" <<'PY'
import os
import re
import sys
from pathlib import Path

root = Path(sys.argv[1])
candidates = [root / "src", root / "automation"]
extensions = {".js", ".jsx", ".ts", ".tsx", ".java", ".xml", ".jsp", ".ps1", ".sh", ".md", ".py"}
replacement = "\ufffd"
question_hangul = re.compile(r"\?[가-힣]")
exclude_parts = {"node_modules", "build", "build_automation_smoke", "target", "dist", "captures", "component"}
# 의도적으로 mojibake 리터럴을 포함하는 파일 (오탐 방지)
exclude_files = {"EncodingFixUtil.java"}

hits = []
for base in candidates:
    if not base.exists():
        continue
    for path in base.rglob("*"):
        if not path.is_file() or path.suffix.lower() not in extensions:
            continue
        if any(part in exclude_parts for part in path.parts):
            continue
        if path.name in exclude_files:
            continue
        try:
            text = path.read_text(encoding="utf-8")
        except Exception:
            continue
        if replacement in text or question_hangul.search(text):
            hits.append(path.relative_to(root).as_posix())

for hit in sorted(set(hits)):
    print(hit)
PY
}

write_feedback_artifacts() {
  mkdir -p "$LOG_DIR_PATH" "$(dirname "$FEEDBACK_PATH")" "$(dirname "$MANIFEST_PATH")"

  local finished_at total_duration failed_steps failure_codes suggestions_json log_file
  finished_at="$(date '+%Y-%m-%dT%H:%M:%S%z')"
  total_duration="$(python3 - "$RUN_STARTED_AT" "$finished_at" <<'PY'
from datetime import datetime
import sys
fmt = "%Y-%m-%dT%H:%M:%S%z"
start = datetime.strptime(sys.argv[1], fmt)
end = datetime.strptime(sys.argv[2], fmt)
print(round((end - start).total_seconds(), 2))
PY
)"
  failed_steps="$(jq '[.[] | select(.status == "failed")]' <<<"$STEPS_JSON")"
  failure_codes="$(jq '[.[] | select(.status == "failed" and .error_code != "") | .error_code] | unique' <<<"$STEPS_JSON")"

  suggestions_json="$(python3 - "$LOG_DIR_PATH" "$HISTORY_WINDOW" <<'PY'
import json
import sys
from collections import Counter
from pathlib import Path

log_dir = Path(sys.argv[1])
window = int(sys.argv[2])
messages = {
    "CAPTURE_EPERM": "Add a pre-check for browser launch permission and a retry path with elevated permission.",
    "PORT_CONFLICT": "Preflight-check ports 3000/8080 and auto-handle conflicts before capture/build.",
    "SCRIPT_MISSING": "Fail fast on missing automation/skills files and print exact remediation steps.",
    "NPM_BUILD_FAIL": "Run dependency verification before build and auto-suggest npm install/ci.",
    "UTF8_MOJIBAKE_DETECTED": "Fail fast on UTF-8 mojibake patterns before build/doc sync and print affected files.",
    "FRONTEND_DEVSERVER_START_FAIL": "Capture dev-server stdout/stderr, set BROWSER=none, and detect early process exit separately from port conflicts.",
    "MIGRATION_EXEC_FAIL": "Validate migration-screen-map entries (id/group/legacyUrl/reactRoute) before orchestration.",
    "ROUTING_CONTRACT_FAIL": "Print focused routing diffs for dispatcher-servlet.xml and controllers on failure.",
    "DOC_SYNC_FAIL": "Search session logs in both root and docs/project-docs paths by default.",
    "TOMCAT_CONTROL_FAIL": "Validate CATALINA_HOME/BASE/JRE paths and automate startup/shutdown with health polling.",
    "TOMCAT_UI_NOT_READY": "Distinguish Tomcat process readiness from SPA /ui deployment readiness and print both URLs.",
    "FRONTEND_DEPS_MISSING": "Auto-run npm install in src/main/frontend before capture/build when dependencies are missing.",
    "PLAYWRIGHT_BROWSER_MISSING": "Auto-run npx playwright install before capture when browser binaries are missing.",
    "FRONTEND_BOOTSTRAP_REQUIRED": "Add frontend bootstrap step before migration run.",
}
counter = Counter()
files = sorted(log_dir.glob("run-*.json"), key=lambda p: p.stat().st_mtime, reverse=True)[:window]
for path in files:
    try:
        obj = json.loads(path.read_text(encoding="utf-8"))
    except Exception:
        continue
    for step in obj.get("steps", []):
        if step.get("status") == "failed" and step.get("error_code"):
            counter[step["error_code"]] += 1
out = []
for code, count in counter.most_common(3):
    out.append({
        "error_code": code,
        "count": count,
        "recommendation": messages.get(code, "Promote recurring failure text patterns into explicit error codes with recoveries.")
    })
print(json.dumps(out, ensure_ascii=False))
PY
)"

  log_file="$LOG_DIR_PATH/run-$RUN_ID.json"
  jq -n \
    --arg run_id "$RUN_ID" \
    --arg started_at "$RUN_STARTED_AT" \
    --arg finished_at "$finished_at" \
    --arg status "$RUN_STATUS" \
    --arg project_root "$PROJECT_ROOT" \
    --arg capture_mode "$CAPTURE_MODE" \
    --arg capture_path "$CAPTURE_PATH" \
    --arg capture_name "$CAPTURE_NAME" \
    --arg capture_preset "$CAPTURE_PRESET" \
    --arg capture_base_url "$CAPTURE_BASE_URL" \
    --arg tomcat_control_action "$TOMCAT_CONTROL_ACTION" \
    --arg migrate_screen "$MIGRATE_SCREEN" \
    --arg migrate_batch "$MIGRATE_BATCH" \
    --arg migration_plan_file "$MIGRATION_PLAN_FILE" \
    --arg migration_output_dir "$MIGRATION_OUTPUT_DIR" \
    --argjson build "$BUILD" \
    --argjson skip_react_function_commenting "$SKIP_REACT_FUNCTION_COMMENTING" \
    --argjson skip_frontend_compile_check "$SKIP_FRONTEND_COMPILE_CHECK" \
    --argjson skip_session_contract_check "$SKIP_SESSION_CONTRACT_CHECK" \
    --argjson skip_doc_sync "$SKIP_DOC_SYNC" \
    --argjson duration_sec "$total_duration" \
    --argjson commands "$COMMANDS_JSON" \
    --argjson captures "$CAPTURES_JSON" \
    --argjson steps "$STEPS_JSON" \
    --argjson failure_codes "$failure_codes" \
    --argjson suggestions "$suggestions_json" \
    '{
      run_id:$run_id,
      started_at:$started_at,
      finished_at:$finished_at,
      status:$status,
      project_root:$project_root,
      options:{
        capture_mode:$capture_mode,
        capture_path:$capture_path,
        capture_name:$capture_name,
        capture_preset:$capture_preset,
        capture_base_url:$capture_base_url,
        tomcat_control_action:$tomcat_control_action,
        build:$build,
        migrate_screen:$migrate_screen,
        migrate_batch:$migrate_batch,
        migration_plan_file:$migration_plan_file,
        migration_output_dir:$migration_output_dir,
        skip_react_function_commenting:$skip_react_function_commenting,
        skip_frontend_compile_check:$skip_frontend_compile_check,
        skip_session_contract_check:$skip_session_contract_check,
        skip_doc_sync:$skip_doc_sync
      },
      duration_sec:$duration_sec,
      commands:$commands,
      captures:$captures,
      steps:$steps,
      failure_codes:$failure_codes,
      suggestions:$suggestions
    }' > "$log_file"

  if [[ ! -f "$FEEDBACK_PATH" ]]; then
    cat > "$FEEDBACK_PATH" <<'EOF'
# Migration Automation Feedback

This file stores run summaries and improvement suggestions generated by `automation/run-all.sh`.
EOF
  fi

  python3 - "$FEEDBACK_PATH" "$RUN_ID" "$RUN_STATUS" "$RUN_STARTED_AT" "$total_duration" "$CAPTURE_MODE" "$TOMCAT_CONTROL_ACTION" "$BUILD" "$STEPS_JSON" "$failed_steps" "$suggestions_json" <<'PY'
import json
import sys
from datetime import datetime
from pathlib import Path

path = Path(sys.argv[1])
run_id = sys.argv[2]
run_status = sys.argv[3]
started = datetime.strptime(sys.argv[4], "%Y-%m-%dT%H:%M:%S%z")
duration = sys.argv[5]
capture_mode = sys.argv[6]
tomcat_control = sys.argv[7]
build = sys.argv[8]
steps = json.loads(sys.argv[9])
failed_steps = json.loads(sys.argv[10])
suggestions = json.loads(sys.argv[11])

step_lines = "\n".join(
    f"- {step['name']}: {step['status']} ({step['duration_sec']}s)" +
    (f", code={step['error_code']}" if step.get('error_code') else "")
    for step in steps
)
failure_lines = "\n".join(
    f"- {step['error_code']}: {step['error_message']}" for step in failed_steps
) or "- none"
suggestion_lines = "\n".join(
    f"- [{item['error_code']}] x{item['count']}: {item['recommendation']}" for item in suggestions
) or "- none"

entry = f"""

## Run {run_id} - {run_status}
- Started: {started.strftime('%Y-%m-%d %H:%M:%S %z')}
- Duration: {duration}s
- CaptureMode: {capture_mode}
- TomcatControlAction: {tomcat_control}
- Build: {build}
- Log: automation/logs/run-{run_id}.json

### Steps
{step_lines if step_lines else '- none'}

### Failure Codes
{failure_lines}

### Improvement Suggestions
{suggestion_lines}
"""
path.write_text(path.read_text(encoding="utf-8") + entry, encoding="utf-8")
PY

  local latest_failed_step
  latest_failed_step="$(jq -r 'first(.[] | select(.status == "failed")) | .name // ""' <<<"$STEPS_JSON")"
  local latest_failed_code
  latest_failed_code="$(jq -r 'first(.[] | select(.status == "failed")) | .error_code // ""' <<<"$STEPS_JSON")"

  # Read existing manifest to preserve manually-managed fields (preferred_flow, dev_workflow, etc.)
  # Only update: updated_at, phase (from LATEST_STATE), latest_run fields
  local current_phase
  current_phase="$(grep -m1 '^## 진행 단계' -A1 "$PROJECT_ROOT/migration_tool/LATEST_STATE.md" 2>/dev/null | tail -1 | tr -d '\r' | sed 's/^[[:space:]]*//' || echo "Inventory")"

  if [[ -f "$MANIFEST_PATH" ]]; then
    jq \
      --arg updated_at "$finished_at" \
      --arg phase "$current_phase" \
      --arg run_id "$RUN_ID" \
      --arg status "$RUN_STATUS" \
      --arg duration_sec "$total_duration" \
      --arg failed_step "$latest_failed_step" \
      --arg failed_code "$latest_failed_code" \
      '.updated_at = $updated_at
      | .phase = $phase
      | .latest_run = {
          run_id: $run_id,
          status: $status,
          log: ("automation/logs/run-" + $run_id + ".json"),
          duration_sec: ($duration_sec | tonumber),
          failed_step: $failed_step,
          failed_code: $failed_code
        }' \
      "$MANIFEST_PATH" > "${MANIFEST_PATH}.tmp" && mv "${MANIFEST_PATH}.tmp" "$MANIFEST_PATH"
  fi
}

step_utf8_mojibake_check() {
  local hits
  hits="$(get_mojibake_candidates)"
  if [[ -n "$hits" ]]; then
    local top_hits
    top_hits="$(printf '%s\n' "$hits" | head -n 10 | paste -sd ', ' -)"
    echo "UTF8_MOJIBAKE_DETECTED: UTF-8 mojibake pattern found in affected files: $top_hits" >&2
    return 1
  fi
}

step_frontend_bootstrap_check() {
  local frontend_dir="$PROJECT_ROOT/src/main/frontend"
  local pkg_path="$frontend_dir/package.json"
  local capture_path="$frontend_dir/scripts/capture-react.cjs"
  local public_index="$frontend_dir/public/index.html"
  local src_index="$frontend_dir/src/index.js"
  local ui_index="$PROJECT_ROOT/src/main/webapp/ui/index.html"
  local missing=()
  [[ -d "$frontend_dir" ]] || missing+=("src/main/frontend")
  [[ -f "$pkg_path" ]] || missing+=("src/main/frontend/package.json")
  [[ -f "$capture_path" ]] || missing+=("src/main/frontend/scripts/capture-react.cjs")
  [[ -f "$public_index" ]] || missing+=("src/main/frontend/public/index.html")
  [[ -f "$src_index" ]] || missing+=("src/main/frontend/src/index.js")
  if [[ "$CAPTURE_MODE" != "none" ]] && [[ ! "$CAPTURE_BASE_URL" =~ ^https?://(localhost|127\.0\.0\.1):3000/?$ ]] && [[ ! -f "$ui_index" ]]; then
    missing+=("src/main/webapp/ui/index.html")
  fi
  [[ ${#missing[@]} -eq 0 ]] && return 0

  AUTO_LEGACY_MODE=true
  local bootstrap_script="$SCRIPT_DIR/bootstrap-frontend.sh"
  [[ -f "$bootstrap_script" ]] || {
    echo "FRONTEND_BOOTSTRAP_REQUIRED: missing frontend artifacts (${missing[*]}) and missing bootstrap script." >&2
    return 1
  }

  if ! $BOOTSTRAP_FRONTEND && $DISABLE_AUTO_BOOTSTRAP_FRONTEND; then
    echo "FRONTEND_BOOTSTRAP_REQUIRED: missing frontend artifacts (${missing[*]}). Run automation/bootstrap-frontend.sh --project-root \"$PROJECT_ROOT\" --apply" >&2
    return 1
  fi

  add_command "bash automation/bootstrap-frontend.sh --project-root \"$PROJECT_ROOT\" --apply"
  local args=(bash "$bootstrap_script" --project-root "$PROJECT_ROOT" --apply)
  $INSTALL_FRONTEND_DEPS && args+=(--install-deps)
  "${args[@]}"
}

step_tomcat_control() {
  local script="$SCRIPT_DIR/tomcat-control.sh"
  [[ -f "$script" ]] || { echo "Missing $script" >&2; return 1; }
  local args=(bash "$script" --action "$TOMCAT_CONTROL_ACTION" --tomcat-home "$TOMCAT_HOME" --tomcat-base "$TOMCAT_BASE" --tomcat-jre-home "$TOMCAT_JRE_HOME" --base-url "$TOMCAT_BASE_URL" --context-path "$TOMCAT_CONTEXT_PATH" --health-path "$TOMCAT_HEALTH_PATH" --timeout "$TOMCAT_CONTROL_TIMEOUT_SEC")
  $TOMCAT_CONTROL_NO_HEALTH_CHECK && args+=(--no-health-check)
  add_command "bash automation/tomcat-control.sh --action $TOMCAT_CONTROL_ACTION"
  "${args[@]}"
}

step_tomcat_ready_check() {
  local health_url="${TOMCAT_BASE_URL%/}${TOMCAT_CONTEXT_PATH}${TOMCAT_HEALTH_PATH}"
  local login_url="${TOMCAT_BASE_URL%/}${TOMCAT_CONTEXT_PATH}/login"
  add_command "GET $health_url"
  if http_ready "$health_url"; then
    return 0
  fi
  if http_ready "$login_url"; then
    echo "TOMCAT_UI_NOT_READY: Tomcat responds at $login_url but SPA entry $health_url is not ready." >&2
    return 1
  fi
  echo "TOMCAT_NOT_READY: cannot reach $health_url. Please start Tomcat once, then rerun." >&2
  return 1
}

step_verify_session_contract() {
  local script="$SCRIPT_DIR/verify-session-contract.sh"
  [[ -f "$script" ]] || { echo "Missing $script" >&2; return 1; }
  add_command "bash automation/verify-session-contract.sh --project-root \"$PROJECT_ROOT\" --base-url $TOMCAT_BASE_URL --context-path $TOMCAT_CONTEXT_PATH --user $USER_NAME --password *****"
  bash "$script" --project-root "$PROJECT_ROOT" --base-url "$TOMCAT_BASE_URL" --context-path "$TOMCAT_CONTEXT_PATH" --user "$USER_NAME" --password "$PASSWORD"
}

step_ensure_frontend_dependencies() {
  local frontend_dir="$PROJECT_ROOT/src/main/frontend"
  local pkg_path="$frontend_dir/package.json"
  [[ -f "$pkg_path" ]] || { echo "frontend deps install failed: missing $pkg_path" >&2; return 1; }
  local node_modules="$frontend_dir/node_modules"
  local react_scripts="$node_modules/react-scripts"
  local react_scripts_bin="$node_modules/.bin/react-scripts"
  local playwright_module="$node_modules/playwright"
  local need_install=false
  $INSTALL_FRONTEND_DEPS && need_install=true
  [[ -d "$node_modules" ]] || need_install=true
  [[ -d "$react_scripts" && -f "$react_scripts_bin" ]] || need_install=true
  if [[ "$CAPTURE_MODE" != "none" && ! -d "$playwright_module" ]]; then
    need_install=true
  fi
  $need_install || return 0
  add_command "cd src/main/frontend && npm install"
  (
    cd "$frontend_dir"
    run_with_timeout "$FRONTEND_INSTALL_TIMEOUT_SEC" npm install
  )
}

step_ensure_playwright_browsers() {
  local frontend_dir="$PROJECT_ROOT/src/main/frontend"
  local playwright_cache="${XDG_CACHE_HOME:-$HOME/.cache}/ms-playwright"
  if find "$playwright_cache" -name 'chromium_headless_shell-*' -type d 2>/dev/null | grep -q .; then
    return 0
  fi
  add_command "cd src/main/frontend && npx playwright install"
  (
    cd "$frontend_dir"
    npx playwright install
  )
}

step_frontend_compile_check() {
  local frontend_dir="$PROJECT_ROOT/src/main/frontend"
  add_command "cd src/main/frontend && BUILD_PATH=build_automation_smoke npm run build"
  (
    cd "$frontend_dir"
    BUILD_PATH=build_automation_smoke run_with_timeout "$FRONTEND_BUILD_TIMEOUT_SEC" npm run build
    rm -rf build_automation_smoke
  )
}

step_ensure_capture_frontend_server() {
  local target="${CAPTURE_BASE_URL%/}"
  [[ "$target" =~ ^https?://(localhost|127\.0\.0\.1):${CAPTURE_DEV_SERVER_PORT}$ ]] || return 0
  wait_port_listening "$CAPTURE_DEV_SERVER_PORT" 1 && return 0

  local frontend_dir="$PROJECT_ROOT/src/main/frontend"
  mkdir -p "$LOG_DIR_PATH"
  local dev_log="$LOG_DIR_PATH/devserver-$RUN_ID.log"
  add_command "cd src/main/frontend && BROWSER=none npm run dev"
  (
    cd "$frontend_dir"
    BROWSER=none npm run dev >"$dev_log" 2>&1
  ) &
  DEV_SERVER_PID=$!
  local deadline=$(( $(date +%s) + CAPTURE_DEV_SERVER_START_TIMEOUT_SEC ))
  while [[ $(date +%s) -lt $deadline ]]; do
    wait_port_listening "$CAPTURE_DEV_SERVER_PORT" 2 && return 0
    if ! kill -0 "$DEV_SERVER_PID" 2>/dev/null; then
      echo "FRONTEND_DEVSERVER_START_FAIL: pid $DEV_SERVER_PID exited. $(tail -n 20 "$dev_log" 2>/dev/null | tr '\n' ' ')" >&2
      return 1
    fi
    sleep 2
  done
  echo "FRONTEND_DEVSERVER_START_FAIL: port $CAPTURE_DEV_SERVER_PORT not ready within ${CAPTURE_DEV_SERVER_START_TIMEOUT_SEC}s. $(tail -n 20 "$dev_log" 2>/dev/null | tr '\n' ' ')" >&2
  return 1
}

step_validate_skill_integration() {
  local script="$SCRIPT_DIR/validate-skill-integration.sh"
  [[ -f "$script" ]] || { echo "Missing $script" >&2; return 1; }
  local effective_legacy=false
  if $LEGACY_MODE || $AUTO_LEGACY_MODE; then
    effective_legacy=true
  fi
  add_command "bash automation/validate-skill-integration.sh --project-root \"$PROJECT_ROOT\""
  if $effective_legacy; then
    bash "$script" --project-root "$PROJECT_ROOT" --legacy-mode
    return 0
  fi
  if bash "$script" --project-root "$PROJECT_ROOT"; then
    return 0
  fi
  add_command "bash automation/validate-skill-integration.sh --project-root \"$PROJECT_ROOT\" --legacy-mode"
  bash "$script" --project-root "$PROJECT_ROOT" --legacy-mode
  AUTO_LEGACY_MODE=true
}

step_check_routing_contract() {
  local script="$SCRIPT_DIR/skills/springmvc-spa-routing-guard/scripts/check-routing-contract.sh"
  [[ -f "$script" ]] || { echo "Missing $script" >&2; return 1; }
  if $LEGACY_MODE || $AUTO_LEGACY_MODE; then
    add_command "bash automation/skills/springmvc-spa-routing-guard/scripts/check-routing-contract.sh --project-root \"$PROJECT_ROOT\" --no-fail"
    bash "$script" --project-root "$PROJECT_ROOT" --no-fail
  else
    add_command "bash automation/skills/springmvc-spa-routing-guard/scripts/check-routing-contract.sh --project-root \"$PROJECT_ROOT\""
    bash "$script" --project-root "$PROJECT_ROOT"
  fi
}

step_run_screen_migration() {
  local script="$SCRIPT_DIR/run-screen-migration.sh"
  [[ -f "$script" ]] || { echo "Missing $script" >&2; return 1; }
  local args=(bash "$script" --project-root "$PROJECT_ROOT" --migration-plan-file "$MIGRATION_PLAN_FILE" --output-dir "$MIGRATION_OUTPUT_DIR")
  [[ -n "$MIGRATE_SCREEN" ]] && args+=(--migrate-screen "$MIGRATE_SCREEN")
  [[ -n "$MIGRATE_BATCH" ]] && args+=(--migrate-batch "$MIGRATE_BATCH")
  add_command "bash automation/run-screen-migration.sh --project-root \"$PROJECT_ROOT\""
  "${args[@]}"
}

step_annotate_react_functions() {
  local script="$SCRIPT_DIR/annotate-react-functions.sh"
  [[ -f "$script" ]] || { echo "Missing $script" >&2; return 1; }
  add_command "bash automation/annotate-react-functions.sh --project-root \"$PROJECT_ROOT\""
  bash "$script" --project-root "$PROJECT_ROOT"
}

step_run_capture() {
  local script="$SCRIPT_DIR/skills/react-capture-qa-runner/scripts/run-capture.sh"
  [[ -f "$script" ]] || { echo "Missing $script" >&2; return 1; }
  local capture_start
  capture_start=$(date +%s)
  local args=(bash "$script" --project-root "$PROJECT_ROOT" --mode "$CAPTURE_MODE")
  if [[ "$CAPTURE_MODE" == "single" ]]; then
    args+=(--path "$CAPTURE_PATH" --name "$CAPTURE_NAME")
  else
    args+=(--preset "$CAPTURE_PRESET")
  fi
  [[ -n "$CAPTURE_BASE_URL" ]] && args+=(--base-url "$CAPTURE_BASE_URL")
  # compare 모드: 레거시(JSP) URL 전달
  if [[ "$CAPTURE_MODE" == "compare" ]]; then
    args+=(--legacy-url "$LEGACY_BASE_URL" --context-path "$TOMCAT_CONTEXT_PATH")
  fi
  [[ -n "$USER_NAME" ]] && args+=(--user "$USER_NAME")
  [[ -n "$PASSWORD" ]] && args+=(--password "$PASSWORD")
  add_command "bash automation/skills/react-capture-qa-runner/scripts/run-capture.sh --project-root \"$PROJECT_ROOT\" --mode $CAPTURE_MODE"
  "${args[@]}"
  local capture_dir="$PROJECT_ROOT/captures/main"
  if [[ -d "$capture_dir" ]]; then
    while IFS= read -r -d '' file; do
      local file_ts
      file_ts=$(stat -c %Y "$file" 2>/dev/null || stat -f %m "$file")
      if [[ "$file_ts" -ge "$capture_start" ]]; then
        add_capture "${file#$PROJECT_ROOT/}"
      fi
    done < <(find "$capture_dir" -maxdepth 1 -name '*.png' -print0 2>/dev/null)
  fi
}

step_build_frontend() {
  local frontend_dir="$PROJECT_ROOT/src/main/frontend"
  add_command "cd src/main/frontend && npm run build"
  (
    cd "$frontend_dir"
    run_with_timeout "$FRONTEND_BUILD_TIMEOUT_SEC" npm run build
  )
}

step_sync_session_log() {
  local script="$SCRIPT_DIR/run-doc-sync.sh"
  [[ -f "$script" ]] || { echo "Missing $script" >&2; return 1; }
  local args=(bash "$script" --project-root "$PROJECT_ROOT")
  local changed_files=(
    "automation/run-all.sh"
    "automation/annotate-react-functions.py"
    "automation/annotate-react-functions.sh"
    "automation/run-screen-migration.sh"
    "automation/migration-screen-map.json"
    "automation/tomcat-control.sh"
    "automation/verify-session-contract.sh"
    "automation/validate-skill-integration.sh"
    "automation/run-doc-sync.sh"
    "README.md"
    "WORKFLOW.md"
    "TASK_BOARD.md"
    "docs-migration-backlog.md"
  )
  local item
  for item in "${changed_files[@]}"; do
    args+=(--changed-file "$item")
  done
  while IFS= read -r item; do
    args+=(--command "$item")
  done < <(jq -r '.[]' <<<"$COMMANDS_JSON")
  if [[ "$(jq 'length' <<<"$CAPTURES_JSON")" -gt 0 ]]; then
    while IFS= read -r item; do
      args+=(--capture "$item")
    done < <(jq -r '.[]' <<<"$CAPTURES_JSON")
  else
    args+=(--capture "none")
  fi
  args+=(--apply)
  bash "$script" "${args[@]}"
}

main_pipeline() {
  run_step "UTF-8 Mojibake Check" step_utf8_mojibake_check || return 1

  if ! $SKIP_FRONTEND_CHECK; then
    run_step "Frontend Bootstrap Check" step_frontend_bootstrap_check || return 1
  fi

  if [[ "$TOMCAT_CONTROL_ACTION" != "none" ]]; then
    run_step "Tomcat Control ($TOMCAT_CONTROL_ACTION)" step_tomcat_control || return 1
  fi

  if ! $SKIP_TOMCAT_CHECK; then
    run_step "Tomcat Ready Check" step_tomcat_ready_check || return 1
  fi

  if ! $SKIP_SESSION_CONTRACT_CHECK; then
    run_step "Verify Session Contract" step_verify_session_contract || return 1
  fi

  if ! $DISABLE_AUTO_INSTALL_FRONTEND_DEPS; then
    run_step "Ensure Frontend Dependencies" step_ensure_frontend_dependencies || return 1
  fi

  if [[ "$CAPTURE_MODE" != "none" ]] && ! $DISABLE_AUTO_INSTALL_PLAYWRIGHT_BROWSERS; then
    run_step "Ensure Playwright Browsers" step_ensure_playwright_browsers || return 1
  fi

  if ! $SKIP_FRONTEND_COMPILE_CHECK; then
    run_step "Frontend Compile Check" step_frontend_compile_check || return 1
  fi

  if [[ "$CAPTURE_MODE" != "none" ]] && ! $DISABLE_AUTO_START_CAPTURE_DEV_SERVER; then
    run_step "Ensure Capture Frontend Server" step_ensure_capture_frontend_server || return 1
  fi

  run_step "Validate Skill Integration" step_validate_skill_integration || return 1
  run_step "Check Routing Contract" step_check_routing_contract || return 1

  if [[ -n "$MIGRATE_SCREEN" || -n "$MIGRATE_BATCH" ]]; then
    run_step "Run Screen Migration" step_run_screen_migration || return 1
    if ! $SKIP_REACT_FUNCTION_COMMENTING; then
      run_step "Annotate React Function Comments" step_annotate_react_functions || return 1
    fi
  fi

  if [[ "$CAPTURE_MODE" != "none" ]]; then
    run_step "Run Capture" step_run_capture || return 1
  fi

  if $BUILD; then
    run_step "Build Frontend" step_build_frontend || return 1
  fi

  if ! $SKIP_DOC_SYNC; then
    run_step "Sync Session Log" step_sync_session_log || return 1
  fi

  if $GIT_COMMIT; then
    echo "Git commit options are parsed but not implemented in run-all.sh yet." >&2
  fi

  return 0
}

set +e
main_pipeline
MAIN_RC=$?
set -e
if [[ $MAIN_RC -ne 0 ]]; then
  RUN_STATUS="failed"
fi

write_feedback_artifacts

echo
echo "== DONE =="
echo "ProjectRoot: $PROJECT_ROOT"
echo "CaptureMode: $CAPTURE_MODE"
if [[ "$(jq 'length' <<<"$CAPTURES_JSON")" -gt 0 ]]; then
  echo "CaptureFiles: $(jq -r 'join(", ")' <<<"$CAPTURES_JSON")"
fi

exit "$MAIN_RC"
