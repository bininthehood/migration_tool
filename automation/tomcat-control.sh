#!/usr/bin/env bash
set -euo pipefail

ACTION="status"
TOMCAT_HOME=""
TOMCAT_BASE=""
TOMCAT_JRE_HOME=""
BASE_URL="http://localhost:8080"
CONTEXT_PATH="/rays"
HEALTH_PATH="/ui/"
TIMEOUT="120"
NO_HEALTH_CHECK=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    --action|-Action) ACTION="$2"; shift 2 ;;
    --tomcat-home|-TomcatHome) TOMCAT_HOME="$2"; shift 2 ;;
    --tomcat-base|-TomcatBase) TOMCAT_BASE="$2"; shift 2 ;;
    --tomcat-jre-home|-TomcatJreHome) TOMCAT_JRE_HOME="$2"; shift 2 ;;
    --base-url|-TomcatBaseUrl) BASE_URL="$2"; shift 2 ;;
    --context-path|-TomcatContextPath) CONTEXT_PATH="$2"; shift 2 ;;
    --health-path|-TomcatHealthPath) HEALTH_PATH="$2"; shift 2 ;;
    --timeout|-TimeoutSec) TIMEOUT="$2"; shift 2 ;;
    --no-health-check|-NoHealthCheck) NO_HEALTH_CHECK=true; shift ;;
    *) shift ;;
  esac
done

[[ -n "$TOMCAT_HOME" ]] || { echo "TOMCAT_CONTROL_FAIL: TomcatHome not provided" >&2; exit 1; }
[[ -n "$TOMCAT_BASE" ]] || { echo "TOMCAT_CONTROL_FAIL: TomcatBase not provided" >&2; exit 1; }
[[ -n "$TOMCAT_JRE_HOME" ]] || { echo "TOMCAT_CONTROL_FAIL: TomcatJreHome not provided" >&2; exit 1; }

[[ -d "$TOMCAT_HOME" ]] || { echo "TOMCAT_CONTROL_FAIL: TomcatHome not found: $TOMCAT_HOME" >&2; exit 1; }
[[ -d "$TOMCAT_BASE" ]] || { echo "TOMCAT_CONTROL_FAIL: TomcatBase not found: $TOMCAT_BASE" >&2; exit 1; }
[[ -d "$TOMCAT_JRE_HOME" ]] || { echo "TOMCAT_CONTROL_FAIL: TomcatJreHome not found: $TOMCAT_JRE_HOME" >&2; exit 1; }

health_url() {
  printf "%s%s%s" "${BASE_URL%/}" "$CONTEXT_PATH" "$HEALTH_PATH"
}

test_tomcat_ready() {
  local code
  code=$(curl -s -o /dev/null -w "%{http_code}" --max-time 6 "$(health_url)" 2>/dev/null || echo "000")
  [[ "$code" =~ ^[0-9]+$ ]] && [[ "$code" -ge 200 && "$code" -lt 400 ]]
}

test_tomcat_stopped() {
  ! test_tomcat_ready
}

wait_until() {
  local condition_fn="$1"
  local timeout="${2:-120}"
  local poll="${3:-2}"
  local deadline=$(( $(date +%s) + timeout ))
  while [[ $(date +%s) -lt $deadline ]]; do
    "$condition_fn" && return 0
    sleep "$poll"
  done
  return 1
}

invoke_catalina() {
  local script_name="$1"
  local script_path="$TOMCAT_HOME/bin/$script_name"
  [[ -f "$script_path" ]] || { echo "TOMCAT_CONTROL_FAIL: missing script $script_path" >&2; exit 1; }
  export CATALINA_HOME="$TOMCAT_HOME"
  export CATALINA_BASE="$TOMCAT_BASE"
  export JRE_HOME="$TOMCAT_JRE_HOME"
  unset JAVA_HOME || true
  bash "$script_path"
}

case "$ACTION" in
  status)
    if test_tomcat_ready; then
      echo "TOMCAT_STATUS=UP URL=$(health_url)"
    else
      echo "TOMCAT_STATUS=DOWN URL=$(health_url)"
      exit 1
    fi
    ;;
  start)
    echo "TOMCAT_ACTION=start"
    invoke_catalina "startup.sh"
    $NO_HEALTH_CHECK && exit 0
    wait_until test_tomcat_ready "$TIMEOUT" 2 || {
      echo "TOMCAT_CONTROL_FAIL: Tomcat did not become ready within ${TIMEOUT}s" >&2
      exit 1
    }
    echo "TOMCAT_READY URL=$(health_url)"
    ;;
  stop)
    echo "TOMCAT_ACTION=stop"
    invoke_catalina "shutdown.sh"
    $NO_HEALTH_CHECK && exit 0
    wait_until test_tomcat_stopped "$TIMEOUT" 2 || {
      echo "TOMCAT_CONTROL_FAIL: Tomcat did not stop within ${TIMEOUT}s" >&2
      exit 1
    }
    echo "TOMCAT_STOPPED"
    ;;
  restart)
    echo "TOMCAT_ACTION=restart"
    invoke_catalina "shutdown.sh"
    $NO_HEALTH_CHECK || wait_until test_tomcat_stopped 60 2 || true
    invoke_catalina "startup.sh"
    $NO_HEALTH_CHECK && exit 0
    wait_until test_tomcat_ready "$TIMEOUT" 2 || {
      echo "TOMCAT_CONTROL_FAIL: Tomcat did not become ready after restart within ${TIMEOUT}s" >&2
      exit 1
    }
    echo "TOMCAT_READY URL=$(health_url)"
    ;;
  *)
    echo "TOMCAT_CONTROL_FAIL: unsupported action: $ACTION" >&2
    exit 1
    ;;
esac
