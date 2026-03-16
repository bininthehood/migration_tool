# WORKFLOW.md

## Git 최신화 규약 (새 레거시 프로젝트 적용 시 필수)

> **migration_tool은 프로젝트 고유 상태(완료된 화면, 캡처, 로그)를 포함하지 않고,**
> **항상 새 레거시 프로젝트에 즉시 적용 가능한 클린 상태로 git에 유지한다.**

### git에 포함하지 않는 파일 (프로젝트별 생성물)
- `src/main/frontend/` — 각 프로젝트에서 bootstrap-frontend로 생성
- `src/main/webapp/ui/` — 각 프로젝트에서 npm run build 후 복사
- `automation/logs/run-*.json` — 실행 로그 (프로젝트별)
- `automation/logs/devserver-*.log` — dev 서버 로그
- `captures/` — 스크린샷 캡처 (프로젝트별)
- `source-analysis/` — SourceAnalyzer 결과 (프로젝트별)

### git에 반드시 포함하는 파일 (공유 자산)
- `AGENTS.md` — 절대 원칙 및 프로젝트 제약
- `WORKFLOW.md` — 이 문서
- `LATEST_STATE.md` — **항상 Phase 0 (Inventory) 초기 상태로 커밋**
- `TASK_BOARD.md` — **항상 0% 미착수 상태로 커밋**
- `automation/next-session-manifest.json` — **항상 phase: Inventory, setup_required: true 로 커밋**
- `automation/migration-screen-map.json` — **모든 status: "pending" 으로 커밋**
- `automation/run-all.ps1`, `run-all.sh` 등 자동화 스크립트 전체
- `automation/bootstrap-frontend.sh`, `bootstrap-frontend.ps1`
- `docs/project-docs/MIGRATION_AUTOMATION_FEEDBACK.md` — **빈 템플릿 상태로 커밋**

### 커밋 전 체크리스트
```
[ ] LATEST_STATE.md → 진행률 0%, Phase: Inventory
[ ] TASK_BOARD.md → 모든 항목 [ ] 대기 상태
[ ] next-session-manifest.json → phase: Inventory, latest_run.status: not_run
[ ] migration-screen-map.json → 모든 status: "pending"
[ ] MIGRATION_AUTOMATION_FEEDBACK.md → 내용 없음 (템플릿만)
[ ] src/main/frontend/ 미포함 확인
[ ] src/main/webapp/ui/ 미포함 확인
[ ] automation/logs/ 미포함 확인
[ ] captures/ 미포함 확인
```

영문 요약: Keep migration_tool repo in clean initial state — no project-specific build artifacts, logs, captures, or progress records. Always committable to a fresh legacy project.

---

## Next Session Entry

Read in this order:

1. `AGENTS.md`
2. `automation/next-session-manifest.json`
3. `LATEST_STATE.md`
4. `docs/project-docs/MIGRATION_AUTOMATION_FEEDBACK.md`

**Check `next-session-manifest.json` → `setup_required` 필드 먼저 확인.**
`setup_required.frontend_dir_missing: true` 이면 bootstrap-frontend 먼저 실행 후 자동화 진행.

Preferred command (Phase 0 완료 후):

```powershell
powershell -ExecutionPolicy Bypass -File automation/run-all.ps1 `
  -ProjectRoot <legacy-project-root> `
  -TomcatControlAction restart `
  -MigrateBatch all `
  -CaptureMode preset `
  -CapturePreset all `
  -CaptureBaseUrl http://localhost:8080 `
  -DisableAutoInstallFrontendDeps `
  -SkipReactFunctionCommenting
```

Fallback command:

```powershell
powershell -ExecutionPolicy Bypass -File automation/run-all.ps1 `
  -ProjectRoot <legacy-project-root> `
  -TomcatControlAction restart `
  -MigrateBatch all `
  -CaptureMode none `
  -DisableAutoInstallFrontendDeps `
  -SkipReactFunctionCommenting
```

Operational notes:
- Default verification path is Tomcat runtime `http://localhost:8080/rays/ui/...`.
- `localhost:3000` is a secondary dev-only route, not the primary automation target.
- Capture-including runs should be treated as elevated-permission runs because Playwright may fail with `spawn EPERM` in sandboxed execution.
- All docs and source files must remain UTF-8 without BOM.

## Purpose

Keep session startup deterministic and low-overhead for AI execution while preserving the Spring MVC + React coexistence contract.

## Priority Order

1. `AGENTS.md`
2. `automation/next-session-manifest.json`
3. `LATEST_STATE.md`
4. `docs-migration-backlog.md`
5. `docs/project-docs/MIGRATION_AUTOMATION_FEEDBACK.md`
6. `docs/project-docs/SESSION_WORKLOG_*.md`
7. `docs/project-docs/README_FRONTEND_BUILD_DEPLOY.md`

## Startup Checklist

1. `next-session-manifest.json`의 `setup_required` 필드 확인 — `frontend_dir_missing: true`이면 bootstrap-frontend 먼저.
2. 현재 Phase 확인 (`LATEST_STATE.md`).
3. Confirm routing contract files:
   - `src/main/webapp/WEB-INF/web.xml`
   - `src/main/webapp/WEB-INF/config/springmvc/dispatcher-servlet.xml`
   - `src/main/java/com/rays/app/web/SpaForwardController.java`
   - `src/main/java/com/rays/app/view/controller/ViewController.java`
3. Check UTF-8 and mojibake risk first.
4. Use `automation/next-session-manifest.json` as the command source of truth.
5. Treat git checkout/pull in the target project root as the default delivery path.

## Main Pipeline

1. Restore context from `automation/next-session-manifest.json` and `LATEST_STATE.md`.
2. Run `automation/run-all.ps1` with Tomcat runtime capture by default.
3. If capture permission is blocked, rerun with `-CaptureMode none` and keep the failure classified.
4. Review:
   - `automation/logs/run-*.json`
   - `docs/project-docs/MIGRATION_AUTOMATION_FEEDBACK.md`
5. Sync:
   - `LATEST_STATE.md`
   - `TASK_BOARD.md`
   - `docs-migration-backlog.md`
   - `docs/project-docs/SESSION_WORKLOG_*.md`
   - `automation/next-session-manifest.json`
6. Optional package:
   - Only when offline delivery is required, run `powershell -ExecutionPolicy Bypass -File automation/package-migration-kit.ps1 -ProjectRoot <root>`

## Verification Rules

- `GET /rays/ui` redirects to `/rays/ui/`
- `GET /rays/ui/` returns `200`
- `GET /rays/ui/<deep-route>` returns `200`
- Session contract order:
  - `policyCheck`
  - `sessionAlive`
  - `sessionInfo`
- Required session fields:
  - `siteCode`
  - `levelCode`
  - `userId`

## Post-Run Outputs

- Latest runtime log: `automation/logs/run-*.json`
- Automation feedback: `docs/project-docs/MIGRATION_AUTOMATION_FEEDBACK.md`
- Next session compact manifest: `automation/next-session-manifest.json`
- Package output: `dist/migration-kit` only for offline handoff

<!-- meta-agent added: 2026-03-16 -->
## Phase A / Phase B 구분 체크 (Post-Run 필수)

> `run-all.sh` N/N PASS는 Phase A(검증 단계) 통과를 의미한다. Phase B(migration-agent 실제 이관 작업) 실행 여부는 별도로 확인해야 한다.

자동화 루프 종료 후 아래 항목을 순서대로 확인한다:

1. `COMPLETION_REPORT.md` → "Phase State at Completion" 섹션 확인
   - `Phase 2/3: 미착수` → Phase B migration-agent 미실행
   - Phase 1 이후 항목이 완료 상태여야 실제 이관 작업이 진행된 것
2. `LATEST_STATE.md` → 진행 단계가 "Inventory" 초기 상태이면 Phase B 미착수
3. `TASK_BOARD.md` → Phase 1 이후 항목 체크 여부 확인

오케스트레이터가 Phase A PASS를 세션 완료로 잘못 처리한 경우(6/6 PASS 후 즉시 COMPLETION 처리):
- TASK_BOARD.md Phase 1 항목이 여전히 모두 `[ ]` 대기 상태
- migration-agent를 명시적으로 호출하여 Phase 1 (인벤토리) 작업 재착수

영문 요약: After run-all.sh PASS, always check COMPLETION_REPORT Phase State. If Phase 2/3 show as not started, Phase B migration-agent was never invoked — restart it explicitly next session.
