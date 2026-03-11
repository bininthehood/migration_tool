# WORKFLOW.md

## Next Session Entry

Read in this order:

1. `AGENTS.md`
2. `automation/next-session-manifest.json`
3. `LATEST_STATE.md`
4. `docs/project-docs/MIGRATION_AUTOMATION_FEEDBACK.md`

Preferred command:

```powershell
powershell -ExecutionPolicy Bypass -File automation/run-all.ps1 `
  -ProjectRoot C:\Users\rays\ArcFlow_Webv1.2_test4 `
  -CaptureMode preset `
  -CapturePreset all `
  -CaptureBaseUrl http://localhost:8080 `
  -DisableAutoInstallFrontendDeps
```

Fallback command:

```powershell
powershell -ExecutionPolicy Bypass -File automation/run-all.ps1 `
  -ProjectRoot C:\Users\rays\ArcFlow_Webv1.2_test4 `
  -CaptureMode none `
  -DisableAutoInstallFrontendDeps
```

Operational notes:
- Current phase is `Transition`.
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

1. State the phase as `Transition`.
2. Confirm routing contract files:
   - `src/main/webapp/WEB-INF/web.xml`
   - `src/main/webapp/WEB-INF/config/springmvc/dispatcher-servlet.xml`
   - `src/main/java/com/rays/app/web/SpaForwardController.java`
   - `src/main/java/com/rays/app/view/controller/ViewController.java`
3. Check UTF-8 and mojibake risk first.
4. Use `automation/next-session-manifest.json` as the command source of truth.

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
6. Repackage:
   - `powershell -ExecutionPolicy Bypass -File automation/package-migration-kit.ps1 -ProjectRoot <root>`

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
- Package output: `dist/migration-kit`
