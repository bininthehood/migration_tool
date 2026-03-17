# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

`migration_tool` is a reusable automation framework for migrating legacy Java Spring MVC + JSP applications to React SPA. It is kept in a clean initial state in git and applied to a target legacy project by checking out into the project root.

- Stack: Legacy Spring MVC 4.x (XML config), WAR packaging, Tomcat 9
- Frontend: CRA React (`src/main/frontend`)
- SPA deploy target: `src/main/webapp/ui`
- DispatcherServlet mapping: `/`
- Local contextPath: `/rays` / Production contextPath: `/`
- Current target project: `/home/rays/projects/ArcFlow_Webv1.2`

**North Star:** Migrate all JSP screens to React SPA under `/ui/...`. Zero JSP ViewResolver dependencies. Backend reduced to API + static resource serving.

## Session Entry Order

Read in this order at session start:

1. `CLAUDE.md` (this file)
2. `automation/next-session-manifest.json` — current phase, preferred run command, last run status
3. `LATEST_STATE.md` — current migration progress
4. `docs/project-docs/MIGRATION_AUTOMATION_FEEDBACK.md` — recent run feedback

If `next-session-manifest.json → setup_required.frontend_dir_missing` is `true`, run bootstrap before anything else.

## Key Commands

```bash
# Phase A: infrastructure pre-flight (preferred daily command)
bash migration_tool/automation/run-all.sh \
  --project-root /home/rays/projects/ArcFlow_Webv1.2 \
  --capture-mode none \
  --skip-tomcat-check \
  --skip-session-contract-check \
  --skip-frontend-compile-check

# Phase A: full milestone check (after Eclipse Publish + Tomcat running)
bash migration_tool/automation/run-all.sh \
  --project-root /home/rays/projects/ArcFlow_Webv1.2 \
  --capture-mode preset \
  --capture-preset all \
  --tomcat-base-url http://<host>:<port>

# First-time setup: scaffold React frontend
bash migration_tool/automation/bootstrap-frontend.sh \
  --project-root /home/rays/projects/ArcFlow_Webv1.2 \
  --apply \
  --install-deps

# Frontend build (manual human gate — required before Phase 3)
cd /home/rays/projects/ArcFlow_Webv1.2/src/main/frontend && npm run build
```

Always use `preferred_flow.command` from `next-session-manifest.json` as the authoritative run command. Do not construct it manually.

## Architecture

### run-all.sh Pipeline (10 steps)

`automation/run-all.sh` is the main orchestrator (851 lines):

1. UTF-8 Mojibake preflight — aborts on corrupted Korean text
2. Frontend bootstrap check — auto-runs bootstrap if `frontend_dir_missing: true`
3. Dependency install — auto-runs `npm install` if needed
4. Skill integration validation — checks all 5 skills present and functional
5. Routing contract check — validates `dispatcher-servlet.xml` + SPA controllers
6. Dev server launch — starts `npm start` on `:3000` if capture needed
7. Playwright capture — QA screenshots (may fail with `spawn EPERM` in sandbox)
8. Session contract verification — `policyCheck → sessionAlive → sessionInfo` chain
9. Frontend compile check — `npm run build`
10. Doc sync — appends to `SESSION_WORKLOG_*.md`

Outputs:
- `automation/logs/run-YYYYMMDD-HHMMSS.json` — structured log with error codes + fix suggestions
- `docs/project-docs/MIGRATION_AUTOMATION_FEEDBACK.md` — human-readable summary
- `automation/next-session-manifest.json` — updated for next session
- `LATEST_STATE.md`, `TASK_BOARD.md`, `docs-migration-backlog.md` — state updates

### 5 Reusable Skills (`automation/skills/`)

| Skill | Purpose |
|---|---|
| `legacy-migration-bootstrap` | Reads `LATEST_STATE.md` to determine current phase; checks required docs present |
| `springmvc-spa-routing-guard` | Validates `dispatcher-servlet.xml` and controllers match the SPA routing contract |
| `react-capture-qa-runner` | Playwright screenshot automation for `/ui/*` routes |
| `jsp-react-screen-migrator` | Generates per-screen JSP→React migration checklist markdown |
| `migration-doc-sync` | Appends changed files/commands/captures to `SESSION_WORKLOG_*.md` |

### State Documents

| File | Role |
|---|---|
| `CLAUDE.md` | Absolute rules, routing contract, SPA constraints, full architecture (this file) |
| `WORKFLOW.md` | Git state rules, session entry order, verification checklist |
| `LATEST_STATE.md` | Current phase and progress percentage |
| `TASK_BOARD.md` | Phase-based task checklist (`[ ]` / `[~]` / `[x]`) |
| `docs-migration-backlog.md` | Full JSP→React screen queue (22+ screens with API deps, QA status) |
| `automation/next-session-manifest.json` | Compact execution manifest: preferred command, last run status, known constraints |
| `automation/migration-screen-map.json` | Screen-level JSP→React mapping used by `run-screen-migration.sh` |

### Phase Model

- **Phase 0 (Setup)**: Bootstrap frontend, configure SPA routing in Spring MVC
- **Phase 1 (Inventory)**: Catalog all JSP screens, controllers, API endpoints, common components
- **Phase 2 (React Integration)**: CRA setup, API layer, layout, basename resolver
- **Phase 3 (Screen Migration)**: Per-screen JSP→React conversion — read-only → write → admin → login/main
- **Phase 4 (API Stabilization)**: Document and stabilize backend APIs
- **Phase 5/6 (Build/Cleanup)**: Production build, remove unused JSPs/controllers, cutover

## Non-Negotiable Rules

- Do not convert to Spring Boot. Keep XML-config Spring MVC throughout.
- Do not directly convert `/login` or any existing JSP entry URLs/controllers until full migration is complete.
- Build new React screens in parallel at `/ui/...`; cut over all at once at the final milestone.
- Do not branch `PUBLIC_URL` by Maven profile per contextPath. Keep CRA `homepage` as `.` (relative).
- React Router `basename` must be computed dynamically from `window.location.pathname` at runtime — **never hardcode `"/ui"`**.
- Keep every step deployable (incremental migration).
- Never fully rewrite completed modules, do large-scale structural redesigns, or break the routing contract.

## SPA Routing Contract

Enforced by `springmvc-spa-routing-guard` at every run:

- `GET /ui` → 302 redirect to `/ui/`
- `GET /ui/` → 200 (serves `index.html`)
- `GET /ui/<deep-route>` (no file extension) → 200 (forward to `index.html`)
- Static files under `/ui/**` served directly by `<mvc:resources>`
- Legacy route `/{path}/{page}` excludes `ui`: `^(?!ui$).+`

### Required `dispatcher-servlet.xml` entries

```xml
<mvc:resources mapping="/ui/**" location="/ui/"/>
<mvc:default-servlet-handler />
<mvc:view-controller path="/ui"  view-name="redirect:/ui/"/>
<mvc:view-controller path="/ui/" view-name="forward:/ui/index.html"/>
<!-- Compatibility mappings: prevent 404 for root-relative asset requests -->
<mvc:resources mapping="/static/**"           location="/ui/static/"/>
<mvc:resources mapping="/manifest.json"       location="/ui/"/>
<mvc:resources mapping="/favicon.ico"         location="/ui/"/>
<mvc:resources mapping="/logo192.png"         location="/ui/"/>
<mvc:resources mapping="/logo512.png"         location="/ui/"/>
<mvc:resources mapping="/robots.txt"          location="/ui/"/>
<mvc:resources mapping="/asset-manifest.json" location="/ui/"/>
```

### Required Java controllers

- `SpaForwardController.java`: handles `/ui` redirect, `/ui/` index forward, `/ui/**` (no extension) forward to `index.html`
- `ViewController.java`: legacy mapping must use `@RequestMapping(value="/{path:^(?!ui$).+}/{page}")`

### Session guard rules (all screens)

- Never use `sessionChecker` result alone to redirect to `/login`.
- Always call `/user/v1/sessionInfo` and verify `sessionData.siteCode`, `levelCode`, `userId` are non-null and non-`"null"` before navigating to `/main`.
- If any required field is missing, stay on `/login` (or immediately redirect back to `/login` from `/main`).
- Centralize redirect/URL normalization through `src/main/frontend/src/routing/routeNormalizer.js`.

### Session contract API chain

```
POST /user/v1/policyCheck  → resultCode=0
POST /user/v1/sessionAlive → resultCode=0
POST /user/v1/sessionInfo  → resultCode=0 + sessionData.{siteCode, levelCode, userId}
```

## Agent Change Policy

- Prefer minimum edits to existing files.
- Before any routing change, always inspect: `web.xml`, `dispatcher-servlet.xml`, `SpaForwardController.java`, legacy `/{path}/{page}` controller.
- After every change, include a per-file diff/snippet and the verification URLs.
- State the current migration phase at the start of each turn.

## Definition of Done (per screen)

- React route implemented
- Feature and data parity with the original JSP confirmed
- Auth, session, and error handling parity confirmed
- Direct URL access and deep-link refresh returns 200
- No abnormal entries in runtime logs

## Phase A vs Phase B

- `run-all.sh` N/N PASS means **validation checks passed**, NOT migration work completed.
- After Phase A PASS, always verify Phase B (migration-agent) was actually invoked by checking `LATEST_STATE.md` and `TASK_BOARD.md`.
- If all Phase 1+ tasks in `TASK_BOARD.md` are still `[ ]`, migration-agent was never run — invoke it explicitly.

## Human Gate (required before Phase 3)

After Phase A PASS, before starting Phase 3 screen migration:

1. Run `cd src/main/frontend && npm run build` — confirm build artifacts appear in `../webapp/ui/`
2. Eclipse WTP republish (or manual Tomcat restart)
3. Verify `GET http://localhost:<port>/<context-path>/ui/` → 200
4. Mark `TASK_BOARD.md` final item complete: `[x] GET /<context-path>/ui/ → 200`

These steps cannot be performed by WSL automation (Windows Tomcat access restriction) and require manual confirmation.

## Git State Rules

Never commit (project-specific artifacts):
- `src/main/frontend/`, `src/main/webapp/ui/`
- `automation/logs/run-*.json`, `automation/logs/devserver-*.log`
- `captures/`, `source-analysis/`

Always commit in clean initial state (template values):
- `LATEST_STATE.md` — Phase 0 / 0% progress
- `TASK_BOARD.md` — all items `[ ]`
- `automation/next-session-manifest.json` — `phase: Inventory, setup_required: true`
- `automation/migration-screen-map.json` — all `status: "pending"`
- `docs/project-docs/MIGRATION_AUTOMATION_FEEDBACK.md` — blank template

## Environment Notes (WSL + Windows Tomcat)

- Automation runs in WSL; Tomcat runs on Windows. Use `--skip-tomcat-check` when Tomcat is unreachable.
- Use `--skip-frontend-compile-check` when CRA entry points are missing.
- If Playwright capture fails with `spawn EPERM`, rerun with `--capture-mode none`.
- Port 3000 check: `ss -ltn | grep ':3000'` or `nc -z localhost 3000`
- `bootstrap.sh` searches for state documents in both the project root and `migration_tool/`. Files missing from the project root but present under `migration_tool/` are treated as valid.
- Pre-create `$PROJECT_ROOT/docs/project-docs/` before running `validate-skill-integration.sh` (`mkdir -p $PROJECT_ROOT/docs/project-docs`).

## Encoding Rules

- All files (`*.md`, `*.js`, `*.jsx`, `*.java`, `*.xml`, `*.jsp`) must use **UTF-8 without BOM**.
- Never use PowerShell default encoding (`Out-File`, `Set-Content`) to write files.
- On mojibake detection, immediately stop work on the file and compare with `git show HEAD:<file>` before restoring.
