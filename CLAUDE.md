# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

`migration_tool` is a reusable automation framework for migrating legacy Java Spring MVC + JSP applications to React SPA.

- Stack: Legacy Spring MVC 4.x (XML config), WAR packaging, Tomcat 9
- Frontend: CRA React (`src/main/frontend`)
- SPA deploy target: `src/main/webapp/ui`
- DispatcherServlet mapping: `/`
- Local contextPath: `/rays` / Production contextPath: `/`
- Current target project: `/home/rays/projects/ArcFlow_Webv1.2`

**North Star:** Migrate all JSP screens to React SPA under `/ui/...`. Zero JSP ViewResolver dependencies.

## Session Entry Order

1. `CLAUDE.md` (this file)
2. `automation/next-session-manifest.json` — current phase, preferred run command, last run status
3. `LATEST_STATE.md` — current migration progress
4. `docs/project-docs/MIGRATION_AUTOMATION_FEEDBACK.md` — recent run feedback

If `next-session-manifest.json → setup_required.frontend_dir_missing == true`, run bootstrap first.

## Key Commands

```bash
# Phase A: infrastructure pre-flight (preferred daily command)
bash migration_tool/automation/run-all.sh \
  --project-root /home/rays/projects/ArcFlow_Webv1.2 \
  --capture-mode none \
  --skip-tomcat-check \
  --skip-session-contract-check \
  --skip-frontend-compile-check

# First-time setup
bash migration_tool/automation/bootstrap-frontend.sh \
  --project-root /home/rays/projects/ArcFlow_Webv1.2 \
  --apply --install-deps

# Frontend build (manual human gate)
cd /home/rays/projects/ArcFlow_Webv1.2/src/main/frontend && npm run build
```

Always use `preferred_flow.command` from `next-session-manifest.json`. Do not construct manually.

## Architecture

### Phase Model

- **Phase 0**: Bootstrap frontend, configure SPA routing in Spring MVC
- **Phase 1**: Catalog all JSP screens, controllers, API endpoints
- **Phase 2**: CRA setup, API layer, layout, basename resolver
- **Phase 3**: Per-screen JSP→React conversion
- **Phase 4**: Document and stabilize backend APIs
- **Phase 5/6**: Production build, remove unused JSPs/controllers, cutover

### State Documents

| File | Role |
|---|---|
| `LATEST_STATE.md` | Current phase and progress |
| `TASK_BOARD.md` | Phase-based task checklist (`[ ]` / `[~]` / `[x]`) |
| `automation/next-session-manifest.json` | Preferred command, last run status |
| `automation/migration-screen-map.json` | Screen-level JSP→React mapping |

### run-all.sh Pipeline (10 steps)

UTF-8 check → bootstrap → npm install → skill validation → routing contract → dev server → Playwright capture → session contract → frontend compile → doc sync

Outputs: `automation/logs/run-YYYYMMDD-HHMMSS.json`, `MIGRATION_AUTOMATION_FEEDBACK.md`, updated manifests

## Non-Negotiable Rules

- Do not convert to Spring Boot. Keep XML-config Spring MVC.
- Do not convert `/login` or existing JSP entry URLs/controllers until full migration complete.
- Build React screens in parallel at `/ui/...`; cut over all at once at final milestone.
- React Router `basename` must be computed dynamically — **never hardcode `"/ui"`**.
- Keep every step deployable (incremental migration).
- Never rewrite completed modules or break the routing contract.

## SPA Routing Contract

- `GET /ui` → 302 redirect to `/ui/`
- `GET /ui/` → 200 (index.html)
- `GET /ui/<deep-route>` (no extension) → 200 (forward to index.html)
- Legacy `/{path}/{page}` excludes `ui`: `^(?!ui$).+`

상세 XML + Java 컨트롤러 명세: @.claude/patterns/routing-contract.md

## Session Rules

- Always verify actual endpoints from Spring controllers before writing `sessionGuard.js`
- This project: `sessionChecker` = session validation, `sessionInfo` does not exist
- Store `siteCode`/`levelCode` in sessionStorage at login — required for permission APIs

Session guard + siteCode/levelCode 패턴 상세: @.claude/patterns/session-data.md

## React Frontend Patterns

API 호출 규칙, Dev Proxy, CSS/Static Assets: @.claude/patterns/api-conventions.md

Shell 레이아웃 (GNB + 탭 + Outlet) 구현 패턴: @.claude/patterns/shell-layout.md

## Agent Change Policy

- Prefer minimum edits to existing files.
- Before any routing change, inspect: `web.xml`, `dispatcher-servlet.xml`, `SpaForwardController.java`, legacy `/{path}/{page}` controller.
- State the current migration phase at the start of each turn.

## Definition of Done (per screen)

- React route implemented with full feature parity (use Step 0 checklist from JSP chain analysis)
- Auth, session, and error handling parity confirmed
- Direct URL access and deep-link refresh returns 200

## Phase A vs Phase B

- `run-all.sh` N/N PASS = validation checks passed, NOT migration work completed.
- After Phase A PASS, verify Phase B (migration-agent) was invoked — check `TASK_BOARD.md`.

## Human Gate (required before Phase 3)

1. `cd src/main/frontend && npm run build`
2. Eclipse WTP republish (or Tomcat restart)
3. Verify `GET http://localhost:<port>/<context-path>/ui/` → 200
4. Mark TASK_BOARD.md final item `[x]`

## Git State Rules

Never commit: `src/main/frontend/`, `src/main/webapp/ui/`, `automation/logs/run-*.json`, `captures/`

Always commit in clean initial state: `LATEST_STATE.md` (Phase 0), `TASK_BOARD.md` (all `[ ]`), `next-session-manifest.json` (`setup_required: true`), `MIGRATION_AUTOMATION_FEEDBACK.md` (blank)

## Environment Notes (WSL + Windows Tomcat)

- Use `--skip-tomcat-check` when Tomcat unreachable from WSL.
- Use `--skip-frontend-compile-check` when CRA entry points missing.
- Playwright fails with `spawn EPERM` → rerun with `--capture-mode none`.
- Port check: `ss -ltn | grep ':3000'`

## Encoding Rules

- All files must use **UTF-8 without BOM**.
- Never use PowerShell default encoding to write files.
- On mojibake: stop, compare with `git show HEAD:<file>`.
