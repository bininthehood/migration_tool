Migration automation 루프를 시작합니다.
서브에이전트 호출(orchestrator → migration-agent)은 이 스킬(메인 Claude)이 직접 순서대로 실행합니다.
문서/git 정리는 세션 종료 후 `/update-docs`로 별도 실행합니다.

## Step 0 — 경로 계산

Bash 도구로 아래 명령을 실행해 project_root와 migration_tool_root를 계산합니다:

```bash
echo "project_root_linux: $(dirname "$(pwd)")"
echo "migration_tool_root_linux: $(pwd)"
```

이후 모든 단계에서 Linux 경로를 사용합니다. 절대 경로를 하드코딩하지 않습니다.

## Step 1 — 컨텍스트 로드

아래 파일을 순서대로 읽어 현재 상태를 파악합니다:

1. `CLAUDE.md` — 절대 원칙 및 프로젝트 제약
2. `automation/next-session-manifest.json` — 직전 실행 상태 및 선호 커맨드
3. `LATEST_STATE.md` — 마이그레이션 현황
4. `TASK_BOARD.md` — 미완료 태스크 목록
5. `docs/project-docs/MIGRATION_AUTOMATION_FEEDBACK.md` — 최근 실행 피드백

읽은 후 아래 변수를 추출해 이후 단계에서 사용합니다 (에이전트에 인라인 전달용):

| 변수 | 추출 위치 |
|------|-----------|
| `{current_phase}` | next-session-manifest.json → `phase` |
| `{run_command}` | next-session-manifest.json → `preferred_flow.command` (<project-root>를 실제 경로로 치환) |
| `{latest_run_status}` | next-session-manifest.json → `latest_run.status` |
| `{latest_run_failed_step}` | next-session-manifest.json → `latest_run.failed_step` |
| `{latest_run_id}` | next-session-manifest.json → `latest_run.run_id` |
| `{capture_user}` | next-session-manifest.json → `environment.capture_user` |
| `{capture_password}` | next-session-manifest.json → `environment.capture_password` |
| `{context_path}` | next-session-manifest.json → `environment.tomcat_context_path` |
| `{pending_tasks}` | TASK_BOARD.md → `[ ]`로 시작하는 줄 전체 목록 |

- Phase A 스킵 가능 여부 (직전 success + 핵심 파일 변경 없음)

## Step 1.5 — bootstrap-frontend 자동 실행 (필요 시)

`next-session-manifest.json`의 `setup_required.frontend_dir_missing == true` 이면:

```bash
bash {migration_tool_root}/automation/bootstrap-frontend.sh \
  --project-root {project_root} \
  --apply \
  --install-deps
```

실행 후 `next-session-manifest.json`의 `setup_required.frontend_dir_missing`을 `false`로 업데이트합니다.

실패 시: 사용자에게 보고하고 중단. (npm 미설치, 권한 문제 등 환경 문제일 가능성 높음)

`frontend_dir_missing == false` 이면: 이 단계를 건너뜁니다.

## Step 1.6 — Dev Server 상태 확인 (수동 실행)

dev 서버는 사용자가 직접 별도 탭에서 실행합니다. 포트 3000 응답 여부만 확인하고 계속 진행합니다.

```bash
# 포트 확인
if nc -z localhost 3000 2>/dev/null || ss -ltn 2>/dev/null | grep -q ':3000 '; then
  echo "Dev server :3000 실행 중"
else
  echo "⚠ Dev server :3000 미응답 — Phase A 검증에는 불필요. 계속 진행."
  echo "  (dev 서버가 필요하면: cd {project_root_linux}/src/main/frontend && npm run dev)"
fi
```

- dev 서버 자동 기동 없음 — 사용자가 별도 터미널에서 수동 실행.
- Phase A (run-all.sh --skip-tomcat-check) 검증은 :3000 불필요.
- Phase B 구현 결과 확인 시 dev 서버가 필요하면 수동으로 먼저 실행할 것.

## Step 2 — 인자 처리

인자: $ARGUMENTS

| 인자 | 동작 |
|------|------|
| `capture=none` | fallback_flow 사용 |
| `capture=preset` | preferred_flow 사용 |
| `fresh` | 인프라 체크 강제 실행 (Phase A 스킵 불가) |
| `infra-only` | Phase A만 실행하고 종료 (Phase B 스킵) |
| `impl-only` | Phase A 스킵, Phase B (migration-agent)만 실행 |
| 인자 없음 | preferred_flow, Phase A 스킵 조건 자동 판단 |

## Step 3 — 진행 상태 감시 시작

```bash
LOG_DIR="$(pwd)/automation/logs"
mkdir -p "$LOG_DIR"

# 오케스트레이터 진행 상태 파일
PROGRESS_FILE="$LOG_DIR/orchestrator-progress.md"
touch "$PROGRESS_FILE"

tail -f "$PROGRESS_FILE" &
TAIL_PID=$!
echo "진행 상태 감시 PID: $TAIL_PID"
```

> "진행 상태 감시가 시작됐습니다."
>
> `TAIL_PID`는 Step 6에서 종료합니다.

## Step 4 — Phase A: automation-orchestrator (인프라 체크)

`infra-only` 또는 일반 실행 시 수행. `impl-only` 인자면 이 단계를 건너뜁니다.

**Phase A 스킵 조건** (모두 충족 시 건너뜀):
- `latest_run.status == "success"`
- `latest_run.failed_step == ""`
- 아래 핵심 파일이 manifest 마지막 업데이트 이후 변경되지 않음 — Bash로 확인:

```bash
# migration_tool은 별도 git repo — migration_tool_root 기준으로 확인
git -C {migration_tool_root_linux} diff --name-only HEAD -- \
  automation/run-all.sh

# project_root 핵심 파일 변경 확인 — log 파일 대신 manifest 자체를 기준으로 사용
# (log 파일은 존재하지 않을 수 있지만 manifest는 항상 존재)
find {project_root_linux}/src/main/webapp/WEB-INF/config/springmvc/dispatcher-servlet.xml \
     {project_root_linux}/src/main/frontend/package.json \
     -newer {migration_tool_root_linux}/automation/next-session-manifest.json \
     2>/dev/null
```

두 명령 모두 출력이 비어있으면 스킵 가능. 하나라도 출력되면 Phase A 실행.
(log 파일이 없어도 manifest가 항상 기준점이 됨 — 로그 파일 의존성 제거)

출력이 비어있으면 스킵 가능. 파일명이 하나라도 출력되면 Phase A를 실행합니다.

스킵 조건 미충족 또는 `fresh` 인자 시: automation-orchestrator를 호출합니다.

Agent 도구 사용:
```
subagent_type: automation-orchestrator
prompt: |
  project_root: {project_root_linux}
  migration_tool_root: {migration_tool_root_linux}

  역할: Phase A (인프라 pre-flight check)만 수행하고 결과를 반환하세요.
  run-all.sh를 실행하고, FAIL 시 dev-agent로 수정 후 재시도(최대 3회).
  PASS 또는 한도 초과 시 아래 JSON을 반환하고 즉시 종료하세요.
  migration-agent, meta-agent는 호출하지 마세요.

  반환 형식:
  {
    "phase_a_result": "pass | fail | limit",
    "run_count": N,
    "pass_history": [...],
    "previous_fixes": [...],
    "final_pass": N,
    "final_total": N,
    "failed_step": "",
    "failed_code": ""
  }

  [PRE-LOADED CONTEXT — 파일 재읽기 불필요]
  phase: {current_phase}
  latest_run.status: {latest_run_status}
  latest_run.failed_step: {latest_run_failed_step}
  latest_run.run_id: {latest_run_id}
  run_command: {run_command}
```

orchestrator 반환 결과를 확인합니다:
- `phase_a_result == "fail"` 또는 `"limit"`: 사용자에게 보고하고 중단
- `phase_a_result == "pass"`: Step 5로 진행

## Step 5 — Phase B: migration-agent (구현)

`infra-only` 인자면 이 단계를 건너뜁니다.

TASK_BOARD.md를 읽어 `[ ]` 미완료 태스크를 확인합니다.
미완료 태스크가 없으면: "모든 구현 작업 완료" 보고 → Step 6으로 이동.

### Step 5a — 태스크 분류

미완료 태스크를 아래 두 계층으로 분류합니다:

**직렬 태스크** (Phase 1/2 — 기반 작업, 병렬화 불가):
- Phase 1: 인벤토리 (JSP/컨트롤러/API 카탈로그)
- Phase 2: React 기반 설정 (setupProxy, client.js, sessionGuard, App.js 초기화)

**병렬 태스크** (Phase 3 — 화면 마이그레이션, 그룹별 독립):
- `auth` 그룹: 로그인/로그아웃/세션 관련 화면
- `list` 그룹: 조회 전용 화면 (목록/상세)
- `write` 그룹: 등록/수정/삭제 화면 (폼)
- `admin` 그룹: 관리자 화면

**직렬 태스크** (Phase 3.5 — jQuery → React 라이브러리 교체):
- TASK_BOARD에 "DataGrid 컴포넌트 적용" / "jQuery → React" 유형 태스크가 있으면 Phase 3 병렬 실행 전에 처리
- migration-agent가 `{migration_tool_root}/.claude/patterns/jquery-to-react.md` 를 읽어 절차 수행
- 트리거: JSP JS에 `.DataTable(` / `openModal(` / `gfn_setDatePicker` 패턴 발견 시 자동 적용

**직렬 태스크** (Phase 4/5/6 — API 안정화 · 빌드/배포 · 정리):
- Phase 3 화면 마이그레이션 완료 후 순서대로 처리 (병렬화 불가)
- Phase 4: API 엔드포인트 문서화 (`docs/project-docs/ENDPOINT_MAP.md` 작성)
- Phase 5: 빌드/배포 — `npm run build` 는 Human Gate (자동 실행 불가, 사용자에게 안내)
- Phase 6: JSP/JS 정리 — 전체 이관 확인 후 진행
- migration-agent 단일 호출로 처리 (Step 5b와 동일 방식)

### Step 5b — 직렬 태스크 처리 (Phase 1/2 미완료 시)

Phase 1/2 미완료 태스크가 있으면 단일 migration-agent를 먼저 실행합니다 (worktree 없음):

```
subagent_type: migration-agent
prompt: |
  project_root: {project_root_linux}
  migration_tool_root: {migration_tool_root_linux}

  [PRE-LOADED CONTEXT]
  current_phase: {current_phase}

  pending_tasks (Phase 1/2만):
  {phase_1_2_tasks}

  key_constraints: migration-agent.md의 key_constraints 섹션 참조 (중복 나열 생략)
```

완료 후 Phase 3 태스크 존재 여부 확인 → 있으면 Step 5c 진행.

### Step 5c — 병렬 태스크 처리 (Phase 3 화면 마이그레이션)

Phase 3 태스크를 그룹별로 분류한 뒤 **동시 실행**합니다.

> **worktree 미사용 이유:** migration_tool은 별도 git 레포이므로 worktree가 `src/main/frontend/`를 포함하지 않습니다. 대신 각 그룹은 서로 다른 화면 파일을 생성하므로 파일 충돌이 없습니다. App.js의 충돌만 `routes_added` 반환 방식으로 방지합니다 (Step 5d에서 메인 Claude가 병합).

아래 에이전트들을 **단일 메시지에서 동시에 호출**합니다 (그룹에 태스크가 있는 경우만):

```
# auth 그룹
subagent_type: migration-agent
prompt: |
  project_root: {project_root_linux}
  migration_tool_root: {migration_tool_root_linux}
  group: auth

  [PRE-LOADED CONTEXT]
  pending_tasks (auth 그룹만):
  {auth_tasks}

  반환 형식:
  {
    "tasks_implemented": [...],
    "tasks_blocked": [...],
    "routes_added": ["<Route path='/login' element={<LoginPage />} />", ...]
  }

  제약: App.js는 직접 수정하지 말고 import 라인과 <Route> 라인만 반환할 것.
  나머지 제약은 migration-agent.md의 key_constraints 참조.

# list 그룹 (동시 실행)
subagent_type: migration-agent
prompt: |
  project_root: {project_root_linux}
  migration_tool_root: {migration_tool_root_linux}
  group: list
  pending_tasks (list 그룹만): {list_tasks}
  반환 형식: 위 auth와 동일
  제약: 위 auth와 동일

# write 그룹 (동시 실행)
subagent_type: migration-agent
prompt: |
  project_root: {project_root_linux}
  migration_tool_root: {migration_tool_root_linux}
  group: write
  pending_tasks (write 그룹만): {write_tasks}
  반환 형식: 위 auth와 동일
  제약: 위 auth와 동일

# admin 그룹 (동시 실행)
subagent_type: migration-agent
prompt: |
  project_root: {project_root_linux}
  migration_tool_root: {migration_tool_root_linux}
  group: admin
  pending_tasks (admin 그룹만): {admin_tasks}
  반환 형식: 위 auth와 동일
  제약: 위 auth와 동일
```

### Step 5d — App.js 병합

모든 병렬 에이전트 완료 후:

1. 현재 `src/main/frontend/src/App.js`를 읽습니다.
2. 각 에이전트의 `routes_added`를 수집합니다.
3. 중복 제거 후 **라우트 유형에 따라 삽입 위치를 구분**합니다:
   - **일반 콘텐츠 화면** → `<Route path="/main">` 블록 **내부** 자식으로 추가 (`path="category/name"`, 앞에 `/` 없음)
   - **팝업/독립 화면** (`monitoring_bak`, `format_*`, `download*`) → `/main` **밖** 최상위 Route로 추가
4. 각 에이전트의 component import도 파일 상단에 추가합니다.

병합 시 충돌(동일 path 중복 등)이 있으면 사용자에게 보고합니다.

### Step 5e — 결과 보고

사용자에게 결과를 보고합니다:

```
Phase B 완료. :3000에서 구현 결과를 확인해 주세요.

[직렬] Phase 1/2 구현: {phase_1_2_implemented}
[병렬] auth 그룹:  {auth_implemented} / 블록: {auth_blocked}
[병렬] list 그룹:  {list_implemented} / 블록: {list_blocked}
[병렬] write 그룹: {write_implemented} / 블록: {write_blocked}
[병렬] admin 그룹: {admin_implemented} / 블록: {admin_blocked}

다음 단계:
1. 확인 완료 → 비교 캡처
2. 추가 구현 요청 → 피드백 제공
3. 중단
```

- **1 선택**: Step 5.5로 진행
- **2 선택**: 해당 그룹 migration-agent 재호출 → 완료 후 Step 5.5
- **3 선택**: Step 6으로 이동 (중단)

## Step 5.5 — 비교 캡처 (JSP vs React)

Phase B에서 구현된 태스크가 있고 사용자가 "1. 확인 완료"를 선택한 경우에 실행합니다.

먼저 두 서버 상태를 확인합니다:

```bash
# :3000 React dev 서버
if nc -z localhost 3000 2>/dev/null || ss -ltn 2>/dev/null | grep -q ':3000 '; then
  REACT_UP=true
else
  REACT_UP=false
fi

# :8080 Tomcat (레거시 JSP)
if nc -z localhost 8080 2>/dev/null || ss -ltn 2>/dev/null | grep -q ':8080 '; then
  TOMCAT_UP=true
else
  TOMCAT_UP=false
fi

echo "React :3000 = $REACT_UP / Tomcat :8080 = $TOMCAT_UP"
```

**두 서버 모두 응답하는 경우:** 사용자에게 비교 캡처 실행 여부를 묻습니다:

```
JSP(:8080)과 React(:3000) 비교 캡처를 실행할 수 있습니다.
captures/report/index.html 에 나란히 비교 리포트가 생성됩니다.

실행할까요?
1. 예 — 비교 캡처 실행
2. 아니오 — 건너뜀
```

**"1. 예" 선택 시:** Bash 도구로 직접 실행합니다 (사용자가 직접 실행하는 것과 동일):

```bash
cd {project_root_linux}/src/main/frontend
node scripts/capture-react.cjs \
  --mode compare \
  --preset all \
  --baseUrl http://localhost:3000 \
  --legacyUrl http://localhost:8080 \
  --contextPath {context_path} \
  --user {capture_user} \
  --password {capture_password}
```

실행 후 리포트 경로를 보고합니다:
```
비교 캡처 완료: captures/report/index.html
브라우저에서 열어 JSP ↔ React 차이를 확인하세요.

다음 단계:
1. 차이 없음 / 수정 불필요 → Phase C 진행
2. 수정 필요 화면 있음 → 화면 ID 목록 알려주세요 (재구현)
```

사용자 응답:
- 1 → Step 6
- 2 → 해당 화면 ID를 받아 migration-agent 재호출 후 다시 캡처

**한 서버라도 미응답인 경우:** 건너뛰고 Step 6으로 이동합니다.
- `:3000` 미응답: "dev 서버를 먼저 실행해 주세요 (npm start)"
- `:8080` 미응답: "Tomcat이 기동되지 않아 JSP 캡처를 스킵합니다"

## Step 6 — 세션 마무리

### 6-1. tail 프로세스 종료

```bash
kill $TAIL_PID 2>/dev/null || true
```

### 6-2. next-session-manifest.json 업데이트

```json
{
  "latest_run": {
    "run_id": "{YYYYMMDD-HHMMSS}",
    "status": "success",
    "log": "",
    "duration_sec": 0,
    "failed_step": "",
    "failed_code": ""
  }
}
```

완료 후 최종 결과를 사용자에게 보고합니다.

> 문서/설정/git 정리가 필요하면 `/update-docs`를 실행하세요.
