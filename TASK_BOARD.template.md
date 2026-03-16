# 마이그레이션 작업 보드

이 문서는 현재 프로젝트의 마이그레이션 작업을 추적합니다.

프로젝트는 AI 지원 개발을 통해 점진적으로 현대화됩니다.

Migration progress: 0%

에이전트는 작업 완료 시 이 파일을 업데이트해야 합니다.

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
[ ] `src/main/frontend/public/index.html` 생성 (CRA 진입점)
[ ] `src/main/frontend/src/index.js` 생성 (CRA 진입점)

---

# Phase 1 - Project Analysis

[ ] Analyze existing repository structure
[ ] Identify backend Spring modules
[ ] Identify legacy JSP UI structure (전체 화면 목록화)
[ ] Identify API endpoints used by UI
[ ] Map frontend dependencies (package.json 구성 후 의존성 문서화)

---

# Phase 2 - React Integration

[ ] Configure React output path to webapp/ui
[ ] Implement dynamic basename resolver (`window.location.pathname` 기반)
[ ] Establish API communication layer (fetch 기반)
[ ] Setup environment configuration (.env.development, REACT_APP_CONTEXT_PATH)
[ ] Implement base layout (공통 레이아웃, 세션 가드, 라우터)

---

# Phase 3 - UI Migration

Phase 1 완료 후 화면별 마이그레이션 태스크가 자동 생성됩니다.
(migration-agent가 실제 JSP 파일을 스캔하여 [ ] 항목으로 추가)

---

# Phase 4 - API Stabilization

[ ] Document current backend API endpoints (docs/project-docs/ENDPOINT_MAP.md)
[ ] Ensure API consistency for frontend

---

# Phase 5 - Build and Deployment

[ ] 초기 `npm run build` 실행 확인 (전체 이관 완료 후)
[ ] Integrate frontend build with Maven
[ ] Configure production build output (robocopy 기반 동기화)
[ ] Verify Tomcat deployment (`/<context-path>/ui/` 200)
[ ] Validate React static resource serving

---

# Phase 6 - Cleanup and Optimization

[ ] Remove unused JSP pages (기능 화면 이관 완료 후)
[ ] Define error route cutover policy
[ ] Remove obsolete JS scripts
[ ] Optimize frontend bundle

---

# Current Priority

**Phase 0 착수 필요.**

1. `bootstrap-frontend.sh --apply --install-deps` 실행
2. SPA 라우팅 설정 (`dispatcher-servlet.xml`, `SpaForwardController.java`, `ViewController.java`)

---

# Agent Instructions

Before performing any change

1. Read `AGENTS.md`
2. Read `LATEST_STATE.md`
3. Read `automation/next-session-manifest.json`
4. Read `TASK_BOARD.md`

Phase 0 완료 전에 Phase 3 마이그레이션 작업을 시작하지 않는다.
