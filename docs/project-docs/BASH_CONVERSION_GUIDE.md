# Bash Conversion Guide — automation/*.ps1

> 이 문서는 다른 에이전트가 참고하여 남은 PowerShell 스크립트를 bash로 전환하기 위한 정확한 구현 가이드입니다.

---

## 현재 상태 (변환 완료 목록)

아래 스크립트는 이미 bash 전환 완료 + 기존 .ps1은 thin wrapper로 교체됨:

| 완료 | 경로 |
|------|------|
| ✅ | `automation/skills/jsp-react-screen-migrator/scripts/migrate-screen-checklist.sh` |
| ✅ | `automation/skills/legacy-migration-bootstrap/scripts/bootstrap.sh` |
| ✅ | `automation/skills/migration-doc-sync/scripts/sync-doc-stub.sh` |
| ✅ | `automation/skills/react-capture-qa-runner/scripts/run-capture.sh` |
| ✅ | `automation/skills/springmvc-spa-routing-guard/scripts/check-routing-contract.sh` |
| ✅ | `automation/run-doc-sync.sh` |
| ✅ | `automation/run-screen-migration.sh` |
| ✅ | `automation/validate-skill-integration.sh` |

---

## 남은 변환 대상 (우선순위 순)

| 우선순위 | 파일 | 난이도 | 비고 |
|---------|------|--------|------|
| 1 | `automation/tomcat-control.sh` | 보통 | run-all.ps1의 Tomcat 제어 |
| 2 | `automation/verify-session-contract.sh` | 보통 | curl + jq로 대체 |
| 3 | `automation/bootstrap-frontend.sh` | 쉬움 | 파일 복사/스캐폴딩 |
| 4 | `automation/annotate-react-functions.sh` | 어려움 | Python 권장 |
| 5 | `automation/run-all.sh` | 복잡 | 전체 오케스트레이션 (마지막) |

---

## 공통 규칙

### 파일 헤더 (모든 .sh에 적용)
```bash
#!/usr/bin/env bash
set -euo pipefail
```

### 인자 파싱 패턴
```bash
while [[ $# -gt 0 ]]; do
  case "$1" in
    --project-root|-ProjectRoot) PROJECT_ROOT="$2"; shift 2 ;;
    --flag|-Flag)                FLAG=true;          shift ;;
    *) shift ;;
  esac
done
```

### thin wrapper .ps1 패턴 (기존 .ps1 교체)
```powershell
param([string]$ProjectRoot = (Get-Location).Path, [switch]$SomeFlag)
$sh = Join-Path $PSScriptRoot 'script-name.sh'
$linuxSh   = (wsl wslpath -u "$sh").Trim()
$linuxRoot = (wsl wslpath -u "$ProjectRoot").Trim()
$args = @("--project-root", $linuxRoot)
if ($SomeFlag) { $args += "--some-flag" }
wsl bash $linuxSh @args
exit $LASTEXITCODE
```

### 실행 권한
```bash
chmod +x automation/script-name.sh
```

---

## 1. tomcat-control.sh

### 원본 파일
`automation/tomcat-control.ps1`

### 파라미터

| PS1 파라미터 | bash 플래그 | 기본값 |
|-------------|------------|--------|
| `-Action` | `--action` | `status` |
| `-TomcatHome` | `--tomcat-home` | (없음, 필수) |
| `-TomcatBase` | `--tomcat-base` | (없음, 필수) |
| `-TomcatJreHome` | `--tomcat-jre-home` | (없음, 필수) |
| `-TomcatBaseUrl` | `--base-url` | `http://localhost:8080` |
| `-TomcatContextPath` | `--context-path` | `/rays` |
| `-TomcatHealthPath` | `--health-path` | `/ui/` |
| `-TimeoutSec` | `--timeout` | `120` |
| `-NoHealthCheck` | `--no-health-check` | false |

### 구현 로직

**경로 설정 및 유효성 검사:**
```bash
# Tomcat 디렉토리 존재 확인
[[ -d "$TOMCAT_HOME" ]] || { echo "TOMCAT_CONTROL_FAIL: TomcatHome not found: $TOMCAT_HOME" >&2; exit 1; }
[[ -d "$TOMCAT_BASE" ]] || { echo "TOMCAT_CONTROL_FAIL: TomcatBase not found: $TOMCAT_BASE" >&2; exit 1; }
[[ -d "$TOMCAT_JRE_HOME" ]] || { echo "TOMCAT_CONTROL_FAIL: TomcatJreHome not found: $TOMCAT_JRE_HOME" >&2; exit 1; }
```

**헬스 체크 함수:**
```bash
test_tomcat_ready() {
  local url="${BASE_URL%/}${CONTEXT_PATH}${HEALTH_PATH}"
  local code
  code=$(curl -s -o /dev/null -w "%{http_code}" --max-time 6 "$url" 2>/dev/null || echo "000")
  [[ "$code" -ge 200 && "$code" -lt 400 ]]
}
```

**Wait-Until 대체 패턴:**
```bash
wait_until() {
  local condition_fn="$1"
  local timeout="${2:-120}"
  local poll="${3:-2}"
  local deadline=$(( $(date +%s) + timeout ))
  while [[ $(date +%s) -lt $deadline ]]; do
    $condition_fn && return 0
    sleep "$poll"
  done
  return 1
}
```

**Tomcat 스크립트 실행 (Linux에서는 .sh 사용):**
```bash
invoke_catalina() {
  local script_name="$1"
  local script_path="$TOMCAT_HOME/bin/$script_name"
  [[ -f "$script_path" ]] || { echo "TOMCAT_CONTROL_FAIL: missing script $script_path" >&2; exit 1; }
  export CATALINA_HOME="$TOMCAT_HOME"
  export CATALINA_BASE="$TOMCAT_BASE"
  export JRE_HOME="$TOMCAT_JRE_HOME"
  unset JAVA_HOME
  bash "$script_path"
}
```

**Action 분기:**
```bash
case "$ACTION" in
  status)
    test_tomcat_ready \
      && echo "TOMCAT_STATUS=UP URL=${BASE_URL%/}${CONTEXT_PATH}${HEALTH_PATH}" \
      || { echo "TOMCAT_STATUS=DOWN URL=${BASE_URL%/}${CONTEXT_PATH}${HEALTH_PATH}"; exit 1; }
    ;;
  start)
    echo "TOMCAT_ACTION=start"
    invoke_catalina "startup.sh"
    $NO_HEALTH_CHECK && exit 0
    wait_until test_tomcat_ready "$TIMEOUT" 2 \
      || { echo "TOMCAT_CONTROL_FAIL: Tomcat did not become ready within ${TIMEOUT}s" >&2; exit 1; }
    echo "TOMCAT_READY URL=${BASE_URL%/}${CONTEXT_PATH}${HEALTH_PATH}"
    ;;
  stop)
    echo "TOMCAT_ACTION=stop"
    invoke_catalina "shutdown.sh"
    $NO_HEALTH_CHECK && exit 0
    wait_until "! test_tomcat_ready" "$TIMEOUT" 2 \
      || { echo "TOMCAT_CONTROL_FAIL: Tomcat did not stop within ${TIMEOUT}s" >&2; exit 1; }
    echo "TOMCAT_STOPPED"
    ;;
  restart)
    echo "TOMCAT_ACTION=restart"
    invoke_catalina "shutdown.sh"
    $NO_HEALTH_CHECK || wait_until "! test_tomcat_ready" 60 2 || true
    invoke_catalina "startup.sh"
    $NO_HEALTH_CHECK && exit 0
    wait_until test_tomcat_ready "$TIMEOUT" 2 \
      || { echo "TOMCAT_CONTROL_FAIL: Tomcat did not become ready after restart within ${TIMEOUT}s" >&2; exit 1; }
    echo "TOMCAT_READY URL=${BASE_URL%/}${CONTEXT_PATH}${HEALTH_PATH}"
    ;;
esac
```

### thin wrapper (tomcat-control.ps1 교체)
```powershell
param(
  [ValidateSet('start','stop','restart','status')][string]$Action = 'status',
  [string]$TomcatHome,
  [string]$TomcatBase,
  [string]$TomcatJreHome,
  [string]$TomcatBaseUrl = 'http://localhost:8080',
  [string]$TomcatContextPath = '/rays',
  [string]$TomcatHealthPath = '/ui/',
  [int]$TimeoutSec = 120,
  [switch]$NoHealthCheck
)
$sh = Join-Path $PSScriptRoot 'tomcat-control.sh'
$linuxSh = (wsl wslpath -u "$sh").Trim()
$args = @("--action", $Action, "--base-url", $TomcatBaseUrl,
          "--context-path", $TomcatContextPath, "--health-path", $TomcatHealthPath,
          "--timeout", $TimeoutSec)
if ($TomcatHome)    { $args += @("--tomcat-home",    (wsl wslpath -u "$TomcatHome").Trim()) }
if ($TomcatBase)    { $args += @("--tomcat-base",    (wsl wslpath -u "$TomcatBase").Trim()) }
if ($TomcatJreHome) { $args += @("--tomcat-jre-home",(wsl wslpath -u "$TomcatJreHome").Trim()) }
if ($NoHealthCheck) { $args += "--no-health-check" }
wsl bash $linuxSh @args
exit $LASTEXITCODE
```

---

## 2. verify-session-contract.sh

### 원본 파일
`automation/verify-session-contract.ps1`

### 파라미터

| PS1 파라미터 | bash 플래그 | 기본값 |
|-------------|------------|--------|
| `-ProjectRoot` | `--project-root` | `$(pwd)` |
| `-TomcatBaseUrl` | `--base-url` | `http://localhost:8080` |
| `-TomcatContextPath` | `--context-path` | `/rays` |
| `-User` | `--user` | `admin` |
| `-Password` | `--password` | `admin` |

### 의존성
```bash
command -v curl &>/dev/null || { echo "Error: curl required" >&2; exit 1; }
command -v jq   &>/dev/null || { echo "Error: jq required" >&2; exit 1; }
```

### 구현 로직

**쿠키 jar 파일 생성:**
```bash
COOKIE_JAR=$(mktemp /tmp/session-contract-XXXXXX.txt)
trap 'rm -f "$COOKIE_JAR"' EXIT
```

**URL 인코딩 함수:**
```bash
url_encode() {
  python3 -c "import urllib.parse, sys; print(urllib.parse.quote(sys.argv[1], safe=''))" "$1"
}
```

**세션 흐름 구현:**
```bash
ROOT_URL="${BASE_URL%/}${CONTEXT_PATH%/}"
echo "[session-contract] base=$ROOT_URL"

# 1) GET /login — 쿠키 초기화
curl -s -o /dev/null -c "$COOKIE_JAR" -b "$COOKIE_JAR" \
  --max-time 15 "${ROOT_URL}/login" || true

# 2) POST /user/v1/policyCheck
ENCODED_USER=$(url_encode "$USER")
ENCODED_PASS=$(url_encode "$PASSWORD")
POLICY_BODY="userId=${ENCODED_USER}&userPwd=${ENCODED_PASS}&userLang=ko"

policy_resp=$(curl -s -c "$COOKIE_JAR" -b "$COOKIE_JAR" \
  -X POST "${ROOT_URL}/user/v1/policyCheck" \
  -H 'Content-Type: application/x-www-form-urlencoded; charset=UTF-8' \
  -d "$POLICY_BODY" --max-time 15)

policy_code=$(echo "$policy_resp" | jq -r '.resultCode // 1')
[[ "$policy_code" -eq 0 ]] || {
  msg=$(echo "$policy_resp" | jq -r '.resultMessage // "unknown"')
  echo "policyCheck resultCode=$policy_code resultMessage=$msg" >&2; exit 1
}

# 3) POST /user/v1/sessionAlive
alive_resp=$(curl -s -c "$COOKIE_JAR" -b "$COOKIE_JAR" \
  -X POST "${ROOT_URL}/user/v1/sessionAlive" \
  -H 'Content-Type: application/x-www-form-urlencoded; charset=UTF-8' \
  -d '' --max-time 15)

alive_code=$(echo "$alive_resp" | jq -r '.resultCode // 1')
[[ "$alive_code" -eq 0 ]] || {
  msg=$(echo "$alive_resp" | jq -r '.resultMessage // "unknown"')
  echo "sessionAlive resultCode=$alive_code resultMessage=$msg" >&2; exit 1
}

# 4) POST /user/v1/sessionInfo
info_resp=$(curl -s -c "$COOKIE_JAR" -b "$COOKIE_JAR" \
  -X POST "${ROOT_URL}/user/v1/sessionInfo" \
  -H 'Content-Type: application/x-www-form-urlencoded; charset=UTF-8' \
  -d '' --max-time 15)

info_code=$(echo "$info_resp" | jq -r '.resultCode // 1')
[[ "$info_code" -eq 0 ]] || {
  msg=$(echo "$info_resp" | jq -r '.resultMessage // "unknown"')
  echo "sessionInfo resultCode=$info_code resultMessage=$msg" >&2; exit 1
}

# 5) sessionData 필드 검증
session_data=$(echo "$info_resp" | jq -r '.sessionData // empty')
[[ -n "$session_data" ]] || { echo "sessionInfo.sessionData missing" >&2; exit 1; }

for field in siteCode levelCode userId; do
  val=$(echo "$info_resp" | jq -r ".sessionData.${field} // \"\"")
  [[ -n "$val" && "$val" != "null" ]] || {
    echo "sessionInfo.sessionData.${field} missing" >&2; exit 1
  }
done

echo "[session-contract] PASS"
```

### thin wrapper (verify-session-contract.ps1 교체)
```powershell
param(
  [string]$ProjectRoot = (Get-Location).Path,
  [string]$TomcatBaseUrl = 'http://localhost:8080',
  [string]$TomcatContextPath = '/rays',
  [string]$User = 'admin',
  [string]$Password = 'admin'
)
$sh = Join-Path $PSScriptRoot 'verify-session-contract.sh'
$linuxSh   = (wsl wslpath -u "$sh").Trim()
$linuxRoot = (wsl wslpath -u "$ProjectRoot").Trim()
wsl bash $linuxSh --project-root $linuxRoot --base-url $TomcatBaseUrl `
  --context-path $TomcatContextPath --user $User --password $Password
exit $LASTEXITCODE
```

---

## 3. bootstrap-frontend.sh

### 원본 파일
`automation/bootstrap-frontend.ps1`

### 파라미터

| PS1 파라미터 | bash 플래그 | 기본값 |
|-------------|------------|--------|
| `-ProjectRoot` | `--project-root` | `$(pwd)` |
| `-Apply` | `--apply` | false |
| `-InstallDeps` | `--install-deps` | false |
| `-TemplateFrontendRoot` | `--template-frontend-root` | `""` |
| `-TemplateUiRoot` | `--template-ui-root` | `""` |

### 구현 로직

**디렉토리/파일 경로 설정:**
```bash
FRONTEND_DIR="$PROJECT_ROOT/src/main/frontend"
SCRIPTS_DIR="$FRONTEND_DIR/scripts"
SRC_DIR="$FRONTEND_DIR/src"
PUBLIC_DIR="$FRONTEND_DIR/public"
PKG_PATH="$FRONTEND_DIR/package.json"
CAPTURE_PATH="$SCRIPTS_DIR/capture-react.cjs"
UI_DIR="$PROJECT_ROOT/src/main/webapp/ui"
UI_INDEX="$UI_DIR/index.html"
```

**상태 출력 함수:**
```bash
print_status() {
  printf "%-30s %s\n" "frontend_dir:"       "$([[ -d $FRONTEND_DIR ]] && echo OK || echo MISSING)"
  printf "%-30s %s\n" "package_json:"       "$([[ -f $PKG_PATH    ]] && echo OK || echo MISSING)"
  printf "%-30s %s\n" "capture_script:"     "$([[ -f $CAPTURE_PATH ]] && echo OK || echo MISSING)"
  printf "%-30s %s\n" "public_index_html:"  "$([[ -f $PUBLIC_DIR/index.html ]] && echo OK || echo MISSING)"
  printf "%-30s %s\n" "src_index_js:"       "$([[ -f $SRC_DIR/index.js ]] && echo OK || echo MISSING)"
  printf "%-30s %s\n" "webapp_ui_index:"    "$([[ -f $UI_INDEX ]] && echo OK || echo MISSING)"
}
```

**dry-run 처리:**
```bash
if ! $APPLY; then
  echo "[bootstrap-frontend] Dry run"
  print_status
  echo "TemplateFrontendRoot: $TEMPLATE_FRONTEND_ROOT"
  echo "TemplateUiRoot: $TEMPLATE_UI_ROOT"
  echo "Run with --apply to scaffold missing frontend files."
  exit 0
fi
```

**디렉토리 생성:**
```bash
mkdir -p "$FRONTEND_DIR" "$SCRIPTS_DIR" "$SRC_DIR" "$PUBLIC_DIR" "$UI_DIR"
```

**템플릿 복사 함수들:**
```bash
copy_dir_if_missing_or_empty() {
  local src="$1" dst="$2"
  [[ -d "$src" ]] || return 0
  if [[ ! -d "$dst" ]] || [[ -z "$(ls -A "$dst" 2>/dev/null)" ]]; then
    cp -r "$src/." "$dst/"
  fi
}

copy_file_if_missing() {
  local src="$1" dst="$2"
  [[ -f "$src" ]] && [[ ! -f "$dst" ]] && { mkdir -p "$(dirname "$dst")"; cp "$src" "$dst"; }
}

flatten_one_level() {
  local parent="$1" nested_name="$2"
  local nested="$parent/$nested_name"
  [[ -d "$nested" ]] || return 0
  mv "$nested"/* "$parent/" 2>/dev/null || true
  rm -rf "$nested"
}
```

**package.json fallback 내용:**
```bash
# TEMPLATE_FRONTEND_ROOT 없을 경우 package.json 생성
if [[ ! -f "$PKG_PATH" ]]; then
  cat > "$PKG_PATH" << 'PKGJSON'
{
  "name": "frontend",
  "version": "0.1.0",
  "private": true,
  "scripts": {
    "dev": "react-scripts start",
    "start": "react-scripts start",
    "build": "react-scripts build",
    "capture:react": "node scripts/capture-react.cjs",
    "test": "react-scripts test"
  },
  "dependencies": {
    "react": "^19.2.4",
    "react-dom": "^19.2.4",
    "react-scripts": "5.0.1"
  },
  "devDependencies": {
    "playwright": "^1.58.2"
  }
}
PKGJSON
fi
```

**capture-react.cjs fallback 내용:** 원본 bootstrap-frontend.ps1의 라인 162-196의 JS 코드를 그대로 파일에 작성.

**npm install:**
```bash
if $INSTALL_DEPS; then
  pushd "$FRONTEND_DIR" > /dev/null
  npm install
  popd > /dev/null
fi
```

### thin wrapper (bootstrap-frontend.ps1 교체)
```powershell
param(
  [string]$ProjectRoot = (Get-Location).Path,
  [switch]$Apply,
  [switch]$InstallDeps,
  [string]$TemplateFrontendRoot = '',
  [string]$TemplateUiRoot = ''
)
$sh = Join-Path $PSScriptRoot 'bootstrap-frontend.sh'
$linuxSh   = (wsl wslpath -u "$sh").Trim()
$linuxRoot = (wsl wslpath -u "$ProjectRoot").Trim()
$args = @("--project-root", $linuxRoot)
if ($Apply)       { $args += "--apply" }
if ($InstallDeps) { $args += "--install-deps" }
if ($TemplateFrontendRoot) { $args += @("--template-frontend-root", (wsl wslpath -u "$TemplateFrontendRoot").Trim()) }
if ($TemplateUiRoot)       { $args += @("--template-ui-root",       (wsl wslpath -u "$TemplateUiRoot").Trim()) }
wsl bash $linuxSh @args
exit $LASTEXITCODE
```

---

## 4. annotate-react-functions.sh (Python 권장)

### 원본 파일
`automation/annotate-react-functions.ps1`

### 구현 방식 — Python 스크립트 권장
이 스크립트는 복잡한 텍스트 파싱(brace depth 추적, 라인별 함수 정의 감지)을 수행합니다.
bash보다 **Python 3**으로 구현하는 것이 훨씬 안정적입니다.

파일 이름: `automation/annotate-react-functions.py`

### 파라미터

| PS1 파라미터 | Python 플래그 | 기본값 |
|-------------|-------------|--------|
| `-ProjectRoot` | `--project-root` | `os.getcwd()` |
| `-TargetRoot` | `--target-root` | `src/main/frontend/src` |

### 구현 로직

**한국어 코멘트 접미사 매핑:**
```python
PHRASES = {
    "legacy":    "마이그레이션된 React 흐름을 처리합니다.",
    "parse":     "입력 데이터를 파싱합니다.",
    "decode":    "인코딩된 값을 디코딩합니다.",
    "encode":    "값을 인코딩합니다.",
    "read":      "필요한 데이터를 조회합니다.",
    "map":       "표시/처리용 데이터 형태로 변환합니다.",
    "build":     "요청/표시용 데이터를 생성합니다.",
    "ui":        "화면 상태 또는 팝업 동작을 제어합니다.",
    "event":     "사용자 이벤트를 처리합니다.",
    "state":     "상태값을 갱신하거나 목록을 조정합니다.",
    "condition": "조건 충족 여부를 판별합니다.",
    "validate":  "실행 조건 또는 유효성을 점검합니다.",
    "default":   "해당 화면의 핵심 로직을 수행합니다.",
}
```

**함수명 prefix → 코멘트 접미사 매핑:**
```python
PREFIX_MAP = [
    (r'^parse',                    "parse"),
    (r'^decode',                   "decode"),
    (r'^encode',                   "encode"),
    (r'^(load|fetch|get|select)',  "read"),
    (r'^(map|normalize|format|to)',"map"),
    (r'^(build|create)',           "build"),
    (r'^(open|close|toggle)',      "ui"),
    (r'^(onclick|onsubmit|onchange|onsearch|onprocess|oncreate|on|handle)', "event"),
    (r'^(set|update|apply|move|remove|add)', "state"),
    (r'^(is|has|can|should)',      "condition"),
    (r'^(wait|check|verify|validate)', "validate"),
]
```

**함수 정의 감지 (top-level, brace_depth == 0):**
```python
FUNC_PATTERNS = [
    re.compile(r'^(?:export\s+)?function\s+([A-Za-z_][A-Za-z0-9_]*)\s*\('),
    re.compile(r'^(?:export\s+)?const\s+([A-Za-z_][A-Za-z0-9_]*)\s*=\s*(?:async\s+)?\([^)]*\)\s*=>'),
    re.compile(r'^(?:export\s+)?const\s+([A-Za-z_][A-Za-z0-9_]*)\s*=\s*(?:async\s+)?function\s*\('),
]
```

**기존 자동생성 코멘트 감지 조건:**
- 라인이 `// FuncName: <suffix>` 패턴
- suffix가 PHRASES 중 하나이거나 "React" 포함

**파일 처리 흐름:**
```python
for js_file in find_js_files(target_root):  # node_modules, build, dist, .min.js 제외
    lines = read_file(js_file)
    output = []
    brace_depth = 0
    for line in lines:
        if is_generated_comment(line):
            continue  # 기존 자동생성 코멘트 제거
        func_name = get_top_level_func(line, brace_depth)
        if func_name and not has_comment_before(output):
            output.append(f"// {func_name}: {get_suffix(func_name)}")
        output.append(line)
        brace_depth += line.count('{') - line.count('}')
        brace_depth = max(0, brace_depth)
    if output_differs(lines, output):
        write_utf8_no_bom(js_file, output)
```

**출력:**
```
ANNOTATE_FILES_CHANGED=N
ANNOTATE_COMMENTS_ADDED=N
```

### shell wrapper (annotate-react-functions.sh)
```bash
#!/usr/bin/env bash
set -euo pipefail
PROJECT_ROOT="$(pwd)"
TARGET_ROOT="src/main/frontend/src"
while [[ $# -gt 0 ]]; do
  case "$1" in
    --project-root|-ProjectRoot) PROJECT_ROOT="$2"; shift 2 ;;
    --target-root|-TargetRoot)   TARGET_ROOT="$2";  shift 2 ;;
    *) shift ;;
  esac
done
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
python3 "$SCRIPT_DIR/annotate-react-functions.py" \
  --project-root "$PROJECT_ROOT" --target-root "$TARGET_ROOT"
```

### thin wrapper (annotate-react-functions.ps1 교체)
```powershell
param(
  [string]$ProjectRoot = (Get-Location).Path,
  [string]$TargetRoot = 'src/main/frontend/src'
)
$sh = Join-Path $PSScriptRoot 'annotate-react-functions.sh'
$linuxSh   = (wsl wslpath -u "$sh").Trim()
$linuxRoot = (wsl wslpath -u "$ProjectRoot").Trim()
wsl bash $linuxSh --project-root $linuxRoot --target-root $TargetRoot
exit $LASTEXITCODE
```

---

## 5. run-all.sh (최종 — 다른 스크립트 완료 후 진행)

### 전제 조건
위 1~4번 모두 완료되어야 합니다.

### 핵심 변경 사항

| PS1 패턴 | bash 대체 |
|---------|----------|
| `cmd.exe /c npm install` | `npm install` |
| `cmd.exe /c npm run build` | `npm run build` |
| `cmd.exe /c set VAR=val && npm run dev` | `VAR=val npm run dev` |
| `Get-NetTCPConnection -LocalPort $Port` | `ss -ltn \| grep -q ":$PORT "` 또는 `nc -z localhost $PORT` |
| `$env:LOCALAPPDATA` (Playwright 경로) | `${XDG_CACHE_HOME:-$HOME/.cache}/ms-playwright` |
| `Invoke-WebRequest` | `curl -s -o /dev/null -w "%{http_code}"` |
| `ConvertTo-Json` | `jq -n` 또는 heredoc |
| `& powershell -File script.ps1` | `bash script.sh` |
| `Start-Job`, `$job` | `&` (백그라운드 프로세스), `$!`, `wait` |

### 포트 리스닝 확인 함수 (Wait-PortListening 대체)
```bash
wait_port_listening() {
  local port="$1"
  local timeout="${2:-30}"
  local deadline=$(( $(date +%s) + timeout ))
  while [[ $(date +%s) -lt $deadline ]]; do
    nc -z localhost "$port" 2>/dev/null && return 0
    sleep 1
  done
  return 1
}
```

### Dev Server 백그라운드 시작 (npm run dev)
```bash
# PS1의 Start-Job 대체
BROWSER=none npm run dev > "$LOG_DIR/devserver.log" 2>&1 &
DEV_SERVER_PID=$!
trap 'kill $DEV_SERVER_PID 2>/dev/null || true' EXIT
wait_port_listening 3000 120 || { echo "DEV_SERVER_START_FAIL" >&2; exit 1; }
```

### Playwright 브라우저 캐시 경로
```bash
PLAYWRIGHT_CACHE="${XDG_CACHE_HOME:-$HOME/.cache}/ms-playwright"
if ! find "$PLAYWRIGHT_CACHE" -name "chromium_headless_shell-*" -type d 2>/dev/null | grep -q .; then
  npx playwright install
fi
```

### JSON 로그 작성 (ConvertTo-Json 대체)
```bash
write_run_log() {
  local log_file="$1"
  jq -n \
    --arg run_id "$RUN_ID" \
    --arg status "$RUN_STATUS" \
    --argjson steps "$STEPS_JSON" \
    '{run_id: $run_id, status: $status, steps: $steps}' > "$log_file"
}
```

### 16개 Step 매핑

| Step 이름 | PS1 호출 | bash 대체 |
|-----------|---------|----------|
| UTF-8 Mojibake Check | grep 기반 | `grep -rP '\xef\xbf\xbd' ...` |
| Frontend Bootstrap | `bootstrap-frontend.ps1` | `bash bootstrap-frontend.sh` |
| Tomcat Control | `tomcat-control.ps1` | `bash tomcat-control.sh` |
| Tomcat Ready Check | `Invoke-WebRequest` | `curl` |
| Verify Session Contract | `verify-session-contract.ps1` | `bash verify-session-contract.sh` |
| Install Frontend Deps | `cmd.exe /c npm install` | `npm install` |
| Install Playwright Browsers | `npx playwright install` | `npx playwright install` |
| Frontend Compile Check | `cmd.exe /c npm run build` | `npm run build` |
| Start Capture Dev Server | `cmd.exe ... npm run dev` | `BROWSER=none npm run dev &` |
| Validate Skill Integration | `validate-skill-integration.ps1` | `bash validate-skill-integration.sh` ✅ |
| Check Routing Contract | `check-routing-contract.ps1` | `bash check-routing-contract.sh` ✅ |
| Run Screen Migration | `run-screen-migration.ps1` | `bash run-screen-migration.sh` ✅ |
| Annotate React Functions | `annotate-react-functions.ps1` | `bash annotate-react-functions.sh` |
| Run Capture | `run-capture.ps1` | `bash run-capture.sh` ✅ |
| Build Frontend | `cmd.exe /c npm run build` | `npm run build` |
| Sync Session Log | `run-doc-sync.ps1` | `bash run-doc-sync.sh` ✅ |

### Invoke-TrackedStep 대체
```bash
run_step() {
  local name="$1"
  local fn="$2"
  echo "[STEP] $name"
  local start=$(date +%s)
  if $fn; then
    local elapsed=$(( $(date +%s) - start ))
    STEPS_JSON=$(echo "$STEPS_JSON" | jq \
      --arg n "$name" --arg s "PASS" --argjson e "$elapsed" \
      '. + [{"name": $n, "status": $s, "elapsed_sec": $e}]')
    echo "[PASS] $name (${elapsed}s)"
  else
    local exit_code=$?
    STEPS_JSON=$(echo "$STEPS_JSON" | jq \
      --arg n "$name" --arg s "FAIL" \
      '. + [{"name": $n, "status": $s}]')
    echo "[FAIL] $name (exit=$exit_code)"
    return $exit_code
  fi
}
```

---

## 구현 순서 및 검증 방법

### 단계별 구현 순서
```
1. tomcat-control.sh          → bash automation/tomcat-control.sh --action status
2. verify-session-contract.sh → bash automation/verify-session-contract.sh (Tomcat 실행 중 필요)
3. bootstrap-frontend.sh      → bash automation/bootstrap-frontend.sh (dry-run 먼저)
4. annotate-react-functions.py + .sh → bash automation/annotate-react-functions.sh
5. run-all.sh                 → bash automation/run-all.sh (전체 통합 테스트)
```

### 각 스크립트 검증 기준

| 스크립트 | 검증 방법 |
|---------|---------|
| `tomcat-control.sh` | `--action status` 실행 후 `TOMCAT_STATUS=UP` 또는 `DOWN` 출력 확인 |
| `verify-session-contract.sh` | `[session-contract] PASS` 출력 확인 |
| `bootstrap-frontend.sh` | `--apply` 없이 dry-run 실행, 상태표 출력 확인 |
| `annotate-react-functions.sh` | `ANNOTATE_FILES_CHANGED=N` 출력 확인 |
| `run-all.sh` | 각 Step `[PASS]` 출력 확인, `automation/logs/run-*.json` 생성 확인 |

### 필수 시스템 의존성 (bash 환경)
```
curl, jq, python3, nc (netcat), npm, npx, bash 4.0+
```

---

## 참고: 경로 구조

```
project_root/                         (레거시 프로젝트 루트, CWD의 부모 디렉토리)
└── migration_tool/                   (CWD of Claude Code)
    └── automation/
        ├── run-all.sh                ← 최종 목표
        ├── run-all.ps1               ← thin wrapper (wsl bash run-all.sh)
        ├── tomcat-control.sh
        ├── tomcat-control.ps1        ← thin wrapper
        ├── verify-session-contract.sh
        ├── verify-session-contract.ps1 ← thin wrapper
        ├── bootstrap-frontend.sh
        ├── bootstrap-frontend.ps1    ← thin wrapper
        ├── annotate-react-functions.py
        ├── annotate-react-functions.sh
        ├── annotate-react-functions.ps1 ← thin wrapper
        └── skills/                   ✅ 전환 완료
```
