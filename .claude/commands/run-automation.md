Migration automation 루프를 시작합니다. 경로를 동적으로 계산한 뒤 automation-orchestrator 서브에이전트를 실행합니다.

## Step 0 — 경로 계산

Bash 도구로 아래 명령을 실행해 project_root와 migration_tool_root를 계산합니다:

```bash
echo "migration_tool_root: $(wslpath -w "$(pwd)")"
echo "project_root: $(wslpath -w "$(dirname "$(pwd)")")"
```

결과 예시:
- `migration_tool_root` = `C:\Projects\SomeApp\migration_tool`
- `project_root` = `C:\Projects\SomeApp`

이후 모든 단계에서 이 두 값을 사용합니다. 절대 경로를 하드코딩하지 않습니다.

## Step 1 — 컨텍스트 로드

아래 파일을 순서대로 읽어 현재 상태를 파악합니다 (CWD = migration_tool_root 기준 상대경로):

1. `AGENTS.md` — 절대 원칙 및 프로젝트 제약
2. `automation/next-session-manifest.json` — 직전 실행 상태 및 선호 커맨드
3. `LATEST_STATE.md` — 마이그레이션 현황
4. `docs/project-docs/MIGRATION_AUTOMATION_FEEDBACK.md` — 최근 실행 피드백

읽은 후 아래를 요약합니다:
- 현재 Phase
- 직전 run_id, status, failed_step (있는 경우)
- 실행에 사용할 명령 (preferred_flow 또는 fallback_flow)

## Step 2 — 인자 처리

인자: $ARGUMENTS

| 인자 | 동작 |
|------|------|
| `capture=none` | CaptureMode를 none으로 강제 (fallback_flow 사용) |
| `capture=preset` | CaptureMode를 preset으로 강제 (preferred_flow 사용) |
| `fresh` | run_count=0으로 시작 |
| `resume` | orchestrator-state.json에서 이전 상태 복원 |
| 인자 없음 | next-session-manifest.json의 preferred_flow 사용 |

직전 실행이 `SESSION_CONTRACT_FAIL` 또는 `EPERM` 관련 실패였고 인자가 없으면,
자동으로 fallback_flow(CaptureMode none)를 먼저 시도합니다.

## Step 3 — 진행 상태 감시 창 자동 실행

automation-orchestrator를 호출하기 전에 Bash 도구로 아래 명령을 실행합니다:

```bash
PROGRESS_FILE="$(pwd)/automation/logs/orchestrator-progress.md"
mkdir -p "$(dirname "$PROGRESS_FILE")"
touch "$PROGRESS_FILE"
bash -c "tail -f '$PROGRESS_FILE'" &
```

실행 후 사용자에게 알립니다:
> "진행 상태 감시가 시작됐습니다. `orchestrator-progress.md`가 각 Step마다 갱신됩니다."

## Step 4 — automation-orchestrator 실행

아래와 같이 automation-orchestrator 서브에이전트를 호출합니다:

```
Agent 도구 사용:
  subagent_type: automation-orchestrator
  prompt: |
    project_root: {Step 0에서 계산한 project_root}
    migration_tool_root: {Step 0에서 계산한 migration_tool_root}

    [컨텍스트 요약]
    - Phase: ...
    - 직전 run_id / status / failed_step: ...
    - 실행 명령: preferred_flow 또는 fallback_flow

    [인자 처리 결과]
    - fresh / resume / capture 여부: ...
```

서브에이전트가 완료되면 결과를 사용자에게 보고합니다.
