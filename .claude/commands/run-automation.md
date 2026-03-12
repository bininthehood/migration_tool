Migration automation 루프를 시작합니다. 컨텍스트를 로드한 뒤 automation-orchestrator 서브에이전트를 실행합니다.

## Step 1 — 컨텍스트 로드

아래 파일을 순서대로 읽어 현재 상태를 파악합니다:

1. `migration_tool/AGENTS.md` — 절대 원칙 및 프로젝트 제약
2. `migration_tool/automation/next-session-manifest.json` — 직전 실행 상태 및 선호 커맨드
3. `migration_tool/LATEST_STATE.md` — 마이그레이션 현황
4. `migration_tool/docs/project-docs/MIGRATION_AUTOMATION_FEEDBACK.md` — 최근 실행 피드백

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
| `fresh` | orchestrator-state.json 무시, run_count=0으로 시작 |
| `resume` | automation/logs/orchestrator-state.json에서 이전 상태 복원 |
| 인자 없음 | next-session-manifest.json의 preferred_flow 사용 |

직전 실행이 `SESSION_CONTRACT_FAIL` 또는 `EPERM` 관련 실패였고 인자가 없으면,
자동으로 fallback_flow(CaptureMode none)를 먼저 시도합니다.

## Step 3 — 진행 상태 감시 창 자동 실행

automation-orchestrator를 호출하기 전에 Bash 도구로 아래 명령을 실행합니다:

```bash
powershell.exe -Command "Start-Process powershell -ArgumentList '-NoExit', '-Command', \"Get-Content \'C:\\Users\\rays\\ArcFlow_Webv1.2\\migration_tool\\automation\\logs\\orchestrator-progress.md\' -Wait\""
```

실행 후 사용자에게 알립니다:
> "진행 상태 감시 창이 열렸습니다. `orchestrator-progress.md`가 각 Step마다 갱신됩니다."

## Step 4 — automation-orchestrator 실행

아래와 같이 automation-orchestrator 서브에이전트를 호출합니다:

```
Agent 도구 사용:
  subagent_type: automation-orchestrator
  prompt: 로드한 컨텍스트 요약 + 실행할 명령 + 인자 처리 결과
```

서브에이전트가 완료되면 결과를 사용자에게 보고합니다.
