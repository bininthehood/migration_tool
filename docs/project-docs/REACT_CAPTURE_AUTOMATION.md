# React Capture Automation

## Overview
This document describes the Playwright-based screen capture automation for the React frontend.

## Capture Script
Located at `src/main/frontend/scripts/capture-react.cjs`.

## Running Captures

```bash
# From migration_tool/automation directory
bash run-all.sh --project-root <project-root> --capture-mode single --capture-path /rays/ui/login
```

## Preset Captures
Use `--capture-mode preset --capture-preset all` to capture all configured routes.

## Output
Screenshots are saved to `captures/main/`.

## Requirements
- Tomcat running at `http://localhost:8080`
- `npm run build` completed and deployed to `webapp/ui/`
- Playwright browsers installed (`npx playwright install`)

## Status
- Phase 0 — initial stub. Capture not yet executable (frontend not built).
