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

```bash
bash migration_tool/automation/run-all.sh \
  --project-root <legacy-project-root> \
  --capture-mode none \
  --skip-tomcat-check \
  --skip-session-contract-check \
  --skip-frontend-compile-check
```

Milestone command (Eclipse Publish 후 전체 검증):

```bash
bash migration_tool/automation/run-all.sh \
  --project-root <legacy-project-root> \
  --capture-mode preset \
  --capture-preset all \
  --tomcat-base-url http://<tomcat-host>:<port> \
  --frontend-build-timeout-sec 1800
```

Operational notes:
- Preferred command: dev 서버 `:3000` 대상, Tomcat 없이 검증 가능한 단계만 실행.
- Milestone command: Eclipse WTP Publish 후 Tomcat 런타임 전체 검증.
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
   - `src/main/java/<package>/SpaForwardController.java`
   - `src/main/java/<package>/ViewController.java`
3. Check UTF-8 and mojibake risk first.
4. Use `automation/next-session-manifest.json` as the command source of truth.
5. Treat git checkout/pull in the target project root as the default delivery path.

## Main Pipeline

1. Restore context from `automation/next-session-manifest.json` and `LATEST_STATE.md`.
2. Run `automation/run-all.sh` with preferred_flow command from `next-session-manifest.json`.
3. If capture permission is blocked, rerun with `--capture-mode none` and keep the failure classified.
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
   - Only when offline delivery is required, run `bash automation/package-migration-kit.sh --project-root <root>`

## Verification Rules

- `GET /<context-path>/ui` redirects to `/<context-path>/ui/`
- `GET /<context-path>/ui/` returns `200`
- `GET /<context-path>/ui/<deep-route>` returns `200`
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

<!-- meta-agent added: 2026-03-16 -->
## Human Gate: npm build + Tomcat Verification

Phase A PASS 후, Phase 3 화면 마이그레이션 착수 전에:

1. Human manual action: `cd src/main/frontend && npm run build`
   - 빌드 산출물이 `../webapp/ui/` 디렉토리에 생성되는지 확인
   - 빌드 오류 없이 완료되어야 다음 단계 진행 가능
2. Human manual action: Eclipse WTP 재배포 (또는 수동 Tomcat restart)
3. Verification: `GET http://localhost:<port>/<context-path>/ui/` → 200 응답 확인
   - 200 응답이 아닌 경우 dispatcher-servlet.xml 또는 빌드 산출물 상태 재점검
4. TASK_BOARD.md 최하단 항목 완료 표시: `[x] GET /<context-path>/ui/ → 200 확인`

이 단계가 완료되어야만 migration-agent가 Phase 3 화면 마이그레이션을 안전하게 시작할 수 있다.

영문 요약: After Phase A PASS, manually build frontend, redeploy Tomcat, verify /ui/ → 200, then mark TASK_BOARD complete before starting Phase 3 migration-agent.
