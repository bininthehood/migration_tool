# ArcFlow_Webv1.2 마이그레이션 작업 보드

This document tracks the current migration tasks for the ArcFlow_Webv1.2 project.

The project is undergoing incremental modernization with AI-assisted development.

Migration progress: 100% (2026-03-09 기준)
완료 화면: 23개 / 전체 23개

Agents must update this file as tasks are completed.

---

# Task Status Legend

[ ] 대기  
[~] 진행중  
[x] 완료  

---

# Phase 1 - Project Analysis

[x] Analyze existing repository structure
[x] Identify backend Spring modules
[x] Identify legacy JSP UI structure
[x] Identify API endpoints used by UI
[~] Map frontend dependencies (CRA package.json 구성됨, 전체 의존성 문서화 부분 완료)

---

# Phase 2 - React Integration

[x] Setup React build pipeline (npm run build 성공 확인)
[x] Configure React output path to webappstatic (src/main/webapp/ui 설정 완료)
[x] Establish API communication layer (fetch 기반 API 연동 완성)
[x] Setup environment configuration (.env.development, REACT_APP_CONTEXT_PATH 설정 완료)
[x] Implement base layout (MainPage 탭 워크스페이스 + 레거시 레이아웃 완성)

---

# Phase 3 - UI Migration

[x] Identify candidate JSP pages for migration (21개 화면 목록화 완료)
[x] Convert first JSP page to React (LoginPage, MainPage, DashboardStatusPanel 등 완료)
[x] Connect React component to existing API (전체 패널 API 연동 완성)
[x] Validate backward compatibility (레거시 JSP URL 유지 확인, /ui/** deep-link 200 확인)
[x] Deploy hybrid UI (JSP + React) (Tomcat `/rays/ui` 라우팅/정적자산 계약 검증 완료, 2026-03-05)

---

# Phase 4 - API Stabilization

[~] Document current backend API endpoints (docs/project-docs/ENDPOINT_MAP.md 작성 중)
[x] Ensure API consistency for frontend (기존 API 계약 유지, 변경 없음)
[ ] Refactor unstable controllers (미착수)
[ ] Improve error handling (미착수)

---

# Phase 5 - Build and Deployment

[ ] Integrate frontend build with Maven (미착수)
[~] Configure production build output (robocopy 기반 수동 동기화 운영 중)
[x] Verify Tomcat deployment (2026-03-09 `/rays/ui` 302, 주요 `/rays/ui/*` 200, `/rays/user/v1/sessionChecker` 200 확인)
[x] Validate React static resource serving (2026-03-09 `main.5ae8cf5c.js`, `main.f5ccebab.css` 200 확인)
[x] Harden migration automation capture target (2026-03-11 보완 + 검증 완료: `TOMCAT_UI_NOT_READY` 분기 추가, `npm.cmd` + `BROWSER=none` 기반 dev server 기동 로그 분리, Tomcat `:8080`/DEV `:3000` 대상 구분, `CaptureMode preset` Tomcat 런타임 PASS)
[x] Add preflight checks for automation capture (2026-03-11 보완 완료: UTF-8/mojibake 검사 추가, Playwright `spawn EPERM` 명시 분리 기반 정리, 다음 세션용 `automation/next-session-manifest.json` compact 실행 포맷 추가)

---

# Phase 6 - Cleanup and Optimization

[x] Remove unused JSP pages (Batch-1 `dashboard/monitoring_bak.jsp` + Batch-2 기능 JSP 23건 제거 완료, 2026-03-09 운영 로그 회귀 확인(5xx=0) 완료)
[~] Migrate approval document JSP popups (`approve/document/v1/format_00`, `format_01`) to React (2차: `docType 01/02/03/04/05` 네이티브 적용 + AP_USR_* 옵션 기반 대상자 필터 반영 + 브리지/목록 패널 한국어 문구 정리 + 취소 요청 `docType 06` 접근 로직 보정 완료, 최종 런타임 QA 잔여)
[ ] Migrate download JSP screens (`view/download`, `view/download_agent`) to React
[ ] Define error route cutover policy (`error/*` JSP -> `/ui/error/*`)
[ ] Remove obsolete JS scripts
[ ] Optimize frontend bundle
[ ] Refactor backend modules

---

# Current Priority

The agent should determine the next task based on

1. Migration history (MIGRATION_HISTORY.md)
2. Current repository structure
3. This task board

Agents should always work on the highest 우선순위 pending task.

---

# Agent Instructions

Before performing any change

1. Read docs/project-docs/PROJECT_CONTEXT.md
2. Read docs/project-docs/REPOSITORY_MAP.md
3. Read MIGRATION_HISTORY.md
4. Read TASK_BOARD.md

Then select the next pending task and implement it incrementally.
