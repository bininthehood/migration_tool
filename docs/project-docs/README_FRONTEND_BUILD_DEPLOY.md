# Frontend Build and Deploy Guide

## Overview
This document describes the process for building the React frontend and deploying it to the Tomcat webapp directory.

## Prerequisites
- Node.js and npm installed
- `src/main/frontend` bootstrapped (run `bootstrap-frontend.sh --apply --install-deps`)

## Build

```bash
cd src/main/frontend
npm run build
```

Output is placed in `src/main/frontend/build/`.

## Deploy to Tomcat

Copy the build output to `src/main/webapp/ui/`:

```bash
# Linux/WSL
cp -r src/main/frontend/build/. src/main/webapp/ui/

# Windows (PowerShell)
robocopy src\main\frontend\build src\main\webapp\ui /MIR
```

Then publish to Tomcat via Eclipse WTP or restart Tomcat.

## Verify

After deployment, `GET http://localhost:8080/rays/ui/` should return HTTP 200.

## Status
- Phase 0 — initial stub. Update as build pipeline matures.
