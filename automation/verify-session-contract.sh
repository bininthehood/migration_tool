#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="$(pwd)"
BASE_URL="http://localhost:8080"
CONTEXT_PATH="/rays"
USER_NAME="admin"
PASSWORD="admin"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --project-root|-ProjectRoot) PROJECT_ROOT="$2"; shift 2 ;;
    --base-url|-TomcatBaseUrl) BASE_URL="$2"; shift 2 ;;
    --context-path|-TomcatContextPath) CONTEXT_PATH="$2"; shift 2 ;;
    --user|-User) USER_NAME="$2"; shift 2 ;;
    --password|-Password) PASSWORD="$2"; shift 2 ;;
    *) shift ;;
  esac
done

command -v curl >/dev/null 2>&1 || { echo "Error: curl required" >&2; exit 1; }
command -v jq >/dev/null 2>&1 || { echo "Error: jq required" >&2; exit 1; }
command -v python3 >/dev/null 2>&1 || { echo "Error: python3 required" >&2; exit 1; }

COOKIE_JAR=$(mktemp /tmp/session-contract-XXXXXX.txt)
trap 'rm -f "$COOKIE_JAR"' EXIT

url_encode() {
  python3 -c "import urllib.parse, sys; print(urllib.parse.quote(sys.argv[1], safe=''))" "$1"
}

ROOT_URL="${BASE_URL%/}${CONTEXT_PATH%/}"
echo "[session-contract] base=$ROOT_URL"

curl -s -o /dev/null -c "$COOKIE_JAR" -b "$COOKIE_JAR" \
  --max-time 15 "${ROOT_URL}/login" || true

ENCODED_USER=$(url_encode "$USER_NAME")
ENCODED_PASS=$(url_encode "$PASSWORD")
POLICY_BODY="userId=${ENCODED_USER}&userPwd=${ENCODED_PASS}&userLang=ko"

policy_resp=$(curl -s -c "$COOKIE_JAR" -b "$COOKIE_JAR" \
  -X POST "${ROOT_URL}/user/v1/policyCheck" \
  -H 'Content-Type: application/x-www-form-urlencoded; charset=UTF-8' \
  -d "$POLICY_BODY" --max-time 15)

policy_code=$(echo "$policy_resp" | jq -r '.resultCode // 1')
[[ "$policy_code" -eq 0 ]] || {
  msg=$(echo "$policy_resp" | jq -r '.resultMessage // "unknown"')
  echo "policyCheck resultCode=$policy_code resultMessage=$msg" >&2
  exit 1
}

alive_resp=$(curl -s -c "$COOKIE_JAR" -b "$COOKIE_JAR" \
  -X POST "${ROOT_URL}/user/v1/sessionAlive" \
  -H 'Content-Type: application/x-www-form-urlencoded; charset=UTF-8' \
  -d '' --max-time 15)

alive_code=$(echo "$alive_resp" | jq -r '.resultCode // 1')
[[ "$alive_code" -eq 0 ]] || {
  msg=$(echo "$alive_resp" | jq -r '.resultMessage // "unknown"')
  echo "sessionAlive resultCode=$alive_code resultMessage=$msg" >&2
  exit 1
}

info_resp=$(curl -s -c "$COOKIE_JAR" -b "$COOKIE_JAR" \
  -X POST "${ROOT_URL}/user/v1/sessionInfo" \
  -H 'Content-Type: application/x-www-form-urlencoded; charset=UTF-8' \
  -d '' --max-time 15)

info_code=$(echo "$info_resp" | jq -r '.resultCode // 1')
[[ "$info_code" -eq 0 ]] || {
  msg=$(echo "$info_resp" | jq -r '.resultMessage // "unknown"')
  echo "sessionInfo resultCode=$info_code resultMessage=$msg" >&2
  exit 1
}

session_data=$(echo "$info_resp" | jq -r '.sessionData // empty')
[[ -n "$session_data" ]] || { echo "sessionInfo.sessionData missing" >&2; exit 1; }

for field in siteCode levelCode userId; do
  val=$(echo "$info_resp" | jq -r ".sessionData.${field} // \"\"")
  [[ -n "$val" && "$val" != "null" ]] || {
    echo "sessionInfo.sessionData.${field} missing" >&2
    exit 1
  }
done

echo "[session-contract] PASS"
