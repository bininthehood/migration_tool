# ArcFlow_Webv1.2 마이그레이션 작업 보드

This document tracks the current migration tasks for the ArcFlow_Webv1.2 project.

The project is undergoing incremental modernization with AI-assisted development.

Migration progress: 0% (2026-03-13 기준)
완료 화면: 0개 / 전체 23개

Agents must update this file as tasks are completed.

---

# Task Status Legend

[ ] 대기
[~] 진행중
[x] 완료

---

# Phase 0 - Setup (선행 작업 — 착수 전 필수)

[ ] 프론트엔드 프로젝트 생성 (`bootstrap-frontend.sh/ps1 --apply`)
[ ] npm 의존성 설치 (`bootstrap-frontend.sh/ps1 --install-deps` 또는 `npm install`)
[ ] `dispatcher-servlet.xml` — SPA 라우팅 설정 추가 (`/ui/**` 리소스, 뷰컨트롤러)
[ ] `SpaForwardController.java` 생성 (`/ui`, `/ui/`, `/ui/**` 핸들러)
[ ] `ViewController.java` — 레거시 `/{path}/{page}` 매핑에서 `ui` 제외 (`^(?!ui$).+`)
[ ] 초기 `npm run build` 실행 및 `webapp/ui` 배포 확인
[ ] `GET /rays/ui/` → 200 확인 (Tomcat 런타임)

---

# Phase 1 - Project Analysis

[ ] Analyze existing repository structure
[ ] Identify backend Spring modules
[ ] Identify legacy JSP UI structure (23개 화면 목록화 — 초안은 LATEST_STATE.md 참조)
[ ] Identify API endpoints used by UI
[ ] Map frontend dependencies (package.json 구성 후 의존성 문서화)

---

# Phase 2 - React Integration

[ ] Setup React build pipeline (npm run build 성공 확인)
[ ] Configure React output path to webapp/ui
[ ] Implement dynamic basename resolver (`window.location.pathname` 기반)
[ ] Establish API communication layer (fetch 기반)
[ ] Setup environment configuration (.env.development, REACT_APP_CONTEXT_PATH)
[ ] Implement base layout (공통 레이아웃, 세션 가드, 라우터)

---

# Phase 3 - UI Migration

[ ] Login (`/ui/login`) — P0
[ ] Main (`/ui/main`) — P0
[ ] Dashboard Status (`/ui/dashboard/status`) — P1
[ ] Dashboard Monitoring (`/ui/dashboard/monitoring`) — P1
[ ] Logs Account (`/ui/logs/account`) — P1
[ ] Logs Web (`/ui/logs/web`) — P1
[ ] Logs Access (`/ui/logs/access`) — P1
[ ] Logs System (`/ui/logs/system`) — P1
[ ] Listen List (`/ui/listen/listen`) — P1
[ ] Listen Target (`/ui/listen/listen_target`) — P1
[ ] Listen Interface Info (`/ui/listen/interface_info`) — P1
[ ] Listen Table Manager (`/ui/listen/table_manager`) — P1
[ ] System Config (`/ui/system/config`) — P1
[ ] System Config Setting (`/ui/system/config_setting`) — P1
[ ] System Menu (`/ui/system/menu`) — P1
[ ] System Code (`/ui/system/code`) — P1
[ ] User Manage (`/ui/manag/user`) — P2
[ ] Group Manage (`/ui/manag/group`) — P2
[ ] Permission Manage (`/ui/manag/perm`) — P2
[ ] Approve (`/ui/approve/approve`) — P2
[ ] Approve Request (`/ui/approve/approve_request`) — P2
[ ] Recorder Sender (`/ui/recorder/sender`) — P2
[ ] Recorder Server (`/ui/recorder/server`) — P2

---

# Phase 4 - API Stabilization

[ ] Document current backend API endpoints (docs/project-docs/ENDPOINT_MAP.md)
[ ] Ensure API consistency for frontend
[ ] Refactor unstable controllers (미착수)
[ ] Improve error handling (미착수)

---

# Phase 5 - Build and Deployment

[ ] Integrate frontend build with Maven (미착수)
[ ] Configure production build output (robocopy 기반 동기화)
[ ] Verify Tomcat deployment (`/rays/ui/` 200)
[ ] Validate React static resource serving

---

# Phase 6 - Cleanup and Optimization

[ ] Remove unused JSP pages (기능 화면 이관 완료 후)
[ ] Migrate approval document JSP popups to React
[ ] Migrate download JSP screens to React
[ ] Define error route cutover policy
[ ] Remove obsolete JS scripts
[ ] Optimize frontend bundle
[ ] Refactor backend modules

---

# Current Priority

**Phase 0 선행 작업부터 시작.**

1. `bootstrap-frontend.sh/ps1 --apply --install-deps` 실행
2. `dispatcher-servlet.xml` SPA 라우팅 설정
3. `SpaForwardController.java` 생성
4. 초기 빌드 + Tomcat 배포 확인 후 Phase 1 착수

---

# Agent Instructions

Before performing any change

1. Read `AGENTS.md`
2. Read `LATEST_STATE.md` (현재 Phase 0 — 선행 작업 진행 중)
3. Read `automation/next-session-manifest.json`
4. Read `TASK_BOARD.md`

Phase 0 완료 전에 Phase 3 마이그레이션 작업을 시작하지 않는다.
