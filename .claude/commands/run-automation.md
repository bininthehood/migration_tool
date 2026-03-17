Migration automation 루프를 시작합니다.
서브에이전트 호출(orchestrator → migration-agent → meta-agent)은 이 스킬(메인 Claude)이 직접 순서대로 실행합니다.

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
4. `docs/project-docs/MIGRATION_AUTOMATION_FEEDBACK.md` — 최근 실행 피드백

읽은 후 아래 변수를 추출해 이후 단계에서 사용합니다 (에이전트에 인라인 전달용):

| 변수 | 추출 위치 |
|------|-----------|
| `{current_phase}` | next-session-manifest.json → `phase` |
| `{run_command}` | next-session-manifest.json → `preferred_flow.command` (<project-root>를 실제 경로로 치환) |
| `{latest_run_status}` | next-session-manifest.json → `latest_run.status` |
| `{latest_run_failed_step}` | next-session-manifest.json → `latest_run.failed_step` |
| `{latest_run_id}` | next-session-manifest.json → `latest_run.run_id` |
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

## Step 1.6 — Dev Server 기동 (필요 시)

포트 3000이 응답하지 않으면 Windows Terminal 새 탭으로 `npm run dev`를 띄우고 로그를 파일로 저장합니다.

```bash
DEV_LOG="{migration_tool_root}/automation/logs/devserver-$(date +%Y%m%d-%H%M%S).log"
mkdir -p "$(dirname "$DEV_LOG")"

# 포트 확인
if ! nc -z localhost 3000 2>/dev/null && ! ss -ltn 2>/dev/null | grep -q ':3000 '; then
  if command -v wt.exe &>/dev/null; then
    # wt.exe로 새 Ubuntu 탭에서 npm run dev 실행 + 로그 동시 저장
    wt.exe new-tab --profile Ubuntu --title "React Dev :3000" -- bash -c \
      "cd {project_root_linux}/src/main/frontend && npm run dev 2>&1 | tee '$DEV_LOG'; exec bash"
    echo "Dev server 기동 중... 로그: $DEV_LOG"
    # 최대 60초 대기
    for i in $(seq 1 30); do
      sleep 2
      if nc -z localhost 3000 2>/dev/null; then
        echo "Dev server :3000 응답 확인"
        break
      fi
      # 로그에서 에러 조기 감지
      if grep -q "Error\|EADDRINUSE\|Failed" "$DEV_LOG" 2>/dev/null; then
        echo "⚠ Dev server 오류 감지. 로그 확인: $DEV_LOG"
        break
      fi
    done
  else
    echo "wt.exe 없음 — dev 서버를 수동으로 실행해 주세요: cd src/main/frontend && npm run dev"
  fi
else
  echo "Dev server :3000 이미 실행 중"
fi
```

- `wt.exe`가 없으면 수동 실행 안내 메시지를 출력하고 계속 진행합니다.
- 새 탭 타이틀: `React Dev :3000`
- 로그 파일: `automation/logs/devserver-YYYYMMDD-HHMMSS.log` (run-all.sh 로그와 같은 위치)
- 60초 후에도 포트가 열리지 않으면 경고만 출력하고 계속 진행합니다 (Phase A 검증은 :3000 불필요).

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

# Dev 서버 로그 (Step 1.6에서 생성된 최신 파일)
DEV_LOG=$(ls -t "$LOG_DIR"/devserver-*.log 2>/dev/null | head -1)

if [ -n "$DEV_LOG" ]; then
  # 오케스트레이터 진행 + dev 서버 로그 동시 감시
  echo "=== 오케스트레이터 진행 감시: $PROGRESS_FILE ==="
  echo "=== Dev 서버 로그 감시: $DEV_LOG ==="
  bash -c "tail -f '$PROGRESS_FILE' '$DEV_LOG'" &
else
  bash -c "tail -f '$PROGRESS_FILE'" &
fi
```

> "진행 상태 감시가 시작됐습니다."

## Step 4 — Phase A: automation-orchestrator (인프라 체크)

`infra-only` 또는 일반 실행 시 수행. `impl-only` 인자면 이 단계를 건너뜁니다.

**Phase A 스킵 조건** (모두 충족 시 건너뜀):
- `latest_run.status == "success"`
- `latest_run.failed_step == ""`
- 아래 핵심 파일이 마지막 run 이후 변경되지 않음:
  - `src/main/webapp/WEB-INF/config/springmvc/dispatcher-servlet.xml`
  - `src/main/frontend/package.json`
  - `migration_tool/automation/run-all.sh`

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

TASK_BOARD.md를 읽어 `[ ]` 미완료 태스크 존재 여부를 확인합니다.

미완료 태스크가 없으면: "모든 구현 작업 완료" 보고 → Step 6으로 이동.

미완료 태스크 존재 시: migration-agent를 호출합니다.

Agent 도구 사용:
```
subagent_type: migration-agent
prompt: |
  project_root: {project_root_linux}
  migration_tool_root: {migration_tool_root_linux}

  [PRE-LOADED CONTEXT — 파일 재읽기 불필요]
  current_phase: {current_phase}

  pending_tasks:
  {pending_tasks}

  key_constraints:
  - Dynamic basename: window.location.pathname 기반, "/ui" 하드코딩 금지
  - JSP/Spring 파일 수정 금지 (dispatcher-servlet.xml, web.xml, controllers)
  - 세션 가드: /user/v1/sessionInfo + sessionData.siteCode/levelCode/userId 확인 필수
  - UTF-8 without BOM
  - npm run build 실행 금지 (dev 서버가 처리)
  - 완료된 코드 재작성 금지 (incremental only)
```

migration-agent 반환 결과(`tasks_implemented`, `tasks_blocked`)를 수집합니다.

migration-agent 완료 후 사용자에게 보고합니다:
```
Phase B 완료. :3000에서 구현 결과를 확인해 주세요.

구현된 tasks: {tasks_implemented 목록}
블록된 tasks: {tasks_blocked 목록} (있는 경우)

다음 단계:
1. 확인 완료 → Phase C 진행
2. 추가 구현 요청 → 피드백 제공
3. 중단
```

사용자 응답을 기다립니다:
- 1 → Step 6
- 2 → migration-agent 재호출 (피드백 포함)
- 3 → Step 6 (meta-agent 스킵)

## Step 6 — Phase C: meta-agent (문서 업데이트)

아래 조건 중 하나라도 해당하면 meta-agent를 **스킵**하고 next-session-manifest.json의 `latest_run`만 직접 업데이트합니다:

- `migration_tasks_implemented` AND `previous_fixes` 모두 비어있음 (Phase A PASS만 있고 변경 없음)
- 사용자가 Step 5에서 "3. 중단"을 선택함

스킵 시 next-session-manifest.json 업데이트:
```json
"latest_run": {
  "run_id": "{YYYYMMDD-HHMMSS}",
  "status": "success",
  "log": "",
  "duration_sec": 0,
  "failed_step": "",
  "failed_code": ""
}
```

그 외 (구현된 태스크 또는 수정된 코드가 있는 경우): meta-agent를 호출합니다.

Agent 도구 사용:
```
subagent_type: meta-agent
prompt: |
  {
    "termination_reason": "completion | user_stopped",
    "project_root": "{project_root_linux}",
    "migration_tool_root": "{migration_tool_root_linux}",
    "run_stats": { ... },
    "previous_fixes": [...],
    "migration_tasks_implemented": [...]
  }
```

meta-agent 완료 후 최종 결과를 사용자에게 보고합니다.
