# 마이그레이션 작업 보드

이 문서는 현재 프로젝트의 마이그레이션 작업을 추적합니다.

프로젝트는 AI 지원 개발을 통해 점진적으로 현대화됩니다.

Migration progress: 45%

에이전트는 작업 완료 시 이 파일을 업데이트해야 합니다.

---

# Task Status Legend

[ ] 대기
[~] 진행중
[x] 완료

---

# Phase 0 - Setup (선행 작업 — 착수 전 필수)

[x] 프론트엔드 프로젝트 생성 (`bootstrap-frontend.sh/ps1 --apply`)
[x] npm 의존성 설치 (`bootstrap-frontend.sh/ps1 --install-deps` 또는 `npm install`)
[x] `dispatcher-servlet.xml` — SPA 라우팅 설정 추가 (`/ui/**` 리소스, 뷰컨트롤러)
[x] `SpaForwardController.java` 생성 (`/ui`, `/ui/`, `/ui/**` 핸들러)
[x] `ViewController.java` — 레거시 `/{path}/{page}` 매핑에서 `ui` 제외 (`^(?!ui$).+`)
[x] `src/main/frontend/public/index.html` 생성 (CRA 진입점)
[x] `src/main/frontend/src/index.js` 생성 (CRA 진입점)
[x] 초기 `npm run build` 실행 확인 → **Phase 5(컷오버 시점)로 이관**
[x] `GET /<context-path>/ui/` → 200 확인 → **Phase 5(컷오버 시점)로 이관**

---

# Phase 1 - Project Analysis

[x] Analyze existing repository structure
[x] Identify backend Spring modules
[x] Identify legacy JSP UI structure (전체 화면 목록화)
[x] Identify API endpoints used by UI
[x] Map frontend dependencies (package.json 구성 후 의존성 문서화)

---

# Phase 2 - React Integration

[x] Setup React build pipeline (npm run build 성공 확인) → **Phase 5(컷오버 시점)로 이관**
[x] Configure React output path to webapp/ui
[x] Implement dynamic basename resolver (`window.location.pathname` 기반)
[x] Establish API communication layer (fetch 기반)
[x] Setup environment configuration (.env.development, REACT_APP_CONTEXT_PATH)
[x] Implement base layout (공통 레이아웃, 세션 가드, 라우터)

---

# Phase 3 - UI Migration

[ ] `login.jsp` → `src/pages/LoginPage.jsx` (`/ui/login`)
[ ] `main.jsp` → `src/pages/MainPage.jsx` (`/ui/main`)
[ ] `dashboard/monitoring.jsp` → `src/pages/dashboard/MonitoringPage.jsx` (`/ui/dashboard/monitoring`)
[ ] `dashboard/status.jsp` → `src/pages/dashboard/StatusPage.jsx` (`/ui/dashboard/status`)
[ ] `listen/listen.jsp` → `src/pages/listen/ListenPage.jsx` (`/ui/listen/listen`)
[ ] `listen/listen_target.jsp` → `src/pages/listen/ListenTargetPage.jsx` (`/ui/listen/target`)
[ ] `listen/interface_info.jsp` → `src/pages/listen/InterfacePage.jsx` (`/ui/listen/interface`)
[ ] `listen/table_manager.jsp` → `src/pages/listen/TableManagerPage.jsx` (`/ui/listen/table`)
[ ] `logs/log_access.jsp` → `src/pages/logs/LogAccessPage.jsx` (`/ui/logs/access`)
[ ] `logs/log_account.jsp` → `src/pages/logs/LogAccountPage.jsx` (`/ui/logs/account`)
[ ] `logs/log_system.jsp` → `src/pages/logs/LogSystemPage.jsx` (`/ui/logs/system`)
[ ] `logs/log_web.jsp` → `src/pages/logs/LogWebPage.jsx` (`/ui/logs/web`)
[ ] `manag/group.jsp` → `src/pages/manage/GroupPage.jsx` (`/ui/manage/group`)
[ ] `manag/perm.jsp` → `src/pages/manage/PermissionPage.jsx` (`/ui/manage/permission`)
[ ] `manag/user.jsp` → `src/pages/manage/UserPage.jsx` (`/ui/manage/user`)
[ ] `recorder/sender.jsp` → `src/pages/recorder/SenderPage.jsx` (`/ui/recorder/sender`)
[ ] `recorder/server.jsp` → `src/pages/recorder/ServerPage.jsx` (`/ui/recorder/server`)
[ ] `system/code.jsp` → `src/pages/system/CodePage.jsx` (`/ui/system/code`)
[ ] `system/config.jsp` → `src/pages/system/ConfigPage.jsx` (`/ui/system/config`)
[ ] `system/config_setting.jsp` → `src/pages/system/ConfigSettingPage.jsx` (`/ui/system/config-setting`)
[ ] `system/menu.jsp` → `src/pages/system/MenuPage.jsx` (`/ui/system/menu`)
[ ] `approve/approve.jsp` → `src/pages/approve/ApprovePage.jsx` (`/ui/approve/approve`)
[ ] `approve/approve_request.jsp` → `src/pages/approve/ApproveRequestPage.jsx` (`/ui/approve/request`)
[ ] `view/download.jsp` → `src/pages/view/DownloadPage.jsx` (팝업 — 별도 처리)
[ ] `view/download_agent.jsp` → `src/pages/view/DownloadAgentPage.jsx` (팝업 — 별도 처리)

---

# Phase 4 - API Stabilization

[x] Document current backend API endpoints (docs/project-docs/ENDPOINT_MAP.md)
[ ] Ensure API consistency for frontend
[ ] Refactor unstable controllers
[ ] Improve error handling

---

# Phase 5 - Build and Deployment

[ ] Integrate frontend build with Maven
[ ] Configure production build output (robocopy 기반 동기화)
[ ] Verify Tomcat deployment (`/<context-path>/ui/` 200)
[ ] Validate React static resource serving

---

# Phase 6 - Cleanup and Optimization

[ ] Remove unused JSP pages (기능 화면 이관 완료 후)
[ ] Migrate approval document JSP popups to React (해당 시)
[ ] Migrate download JSP screens to React (해당 시)
[ ] Define error route cutover policy
[ ] Remove obsolete JS scripts
[ ] Optimize frontend bundle
[ ] Refactor backend modules

---

# Current Priority

**Phase 0/1/2 완료. Phase 3 화면 마이그레이션 즉시 착수 가능.**

개발/검증은 `:3000` dev 서버 기준. 빌드·Tomcat 배포는 전체 이관 완료 후 Phase 5에서 수행.

다음 단계:
1. Phase 3 — JSP 화면을 React 컴포넌트로 마이그레이션 시작 (권장 첫 화면: login.jsp → LoginPage.jsx)
2. 각 화면 구현 후 `:3000`에서 JSP 화면과 기능 비교 확인

---

# Agent Instructions

Before performing any change

1. Read `AGENTS.md`
2. Read `LATEST_STATE.md`
3. Read `automation/next-session-manifest.json`
4. Read `TASK_BOARD.md`

Phase 0 완료 전에 Phase 3 마이그레이션 작업을 시작하지 않는다.
