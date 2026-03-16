# 현재 프로젝트 상태 (최종 업데이트: 2026-03-16 16:57:24)

## 진행 단계
Phase 2 완료 — Phase 3 (화면 마이그레이션) 준비 완료

## 마이그레이션 진행률
45% (Phase 0/1/2 완료, Phase 3 미착수)

## 최종 검증 결과 (Run 20260316-165724)
- Phase A (자동화 검증): PASS (8/8)
- 총 실행 횟수: 3회
- 최종 결과: 모든 구조 검증 완료

## 선행 작업 상태

| 항목 | 상태 | 비고 |
|---|---|---|
| `src/main/frontend` | **완료** | package.json, node_modules 존재 |
| `dispatcher-servlet.xml` SPA 라우팅 | **완료** | `/ui/**` 리소스, 뷰컨트롤러 설정됨 |
| `SpaForwardController.java` | **완료** | `/ui`, `/ui/**` 핸들러 존재 |
| `ViewController.java` ui 제외 | **완료** | `^(?!ui$).+` 패턴 적용됨 |
| `public/index.html` | **완료** | CRA 진입점 생성됨 |
| `src/index.js` | **완료** | 동적 basename + ReactDOM.createRoot |
| `src/App.js` | **완료** | BrowserRouter + 기본 라우트 |
| `src/api/client.js` | **완료** | apiPost/apiGet, 동적 contextPath |
| `src/auth/sessionGuard.js` | **완료** | /user/v1/sessionInfo + 필수 필드 확인 |
| `src/routing/routeNormalizer.js` | **완료** | getBasename, normalizePath |
| `.env.development` | **완료** | PORT=3000 설정 |
| `react-router-dom` | **완료** | ^6.30.3 설치됨 |
| npm 의존성 | **완료** | node_modules 존재 |
| JSP 화면 인벤토리 | **완료** | 25개 화면 목록화 |
| API 엔드포인트 문서 | **완료** | docs/project-docs/ENDPOINT_MAP.md |

## 대기 중 (human 확인 필요)

- `npm run build` 실행 후 `../webapp/ui`에 빌드 산출물 확인
- Eclipse WTP 재배포 후 `GET /<context-path>/ui/` → 200 확인

## JSP 인벤토리 (이관 대상 — 25개 화면)

### 인증
- `/login.jsp` → `/ui/login`

### 메인
- `/main.jsp` → `/ui/main`

### 대시보드 (2개)
- `/dashboard/monitoring.jsp` → `/ui/dashboard/monitoring`
- `/dashboard/status.jsp` → `/ui/dashboard/status`

### 청취 관리 (4개)
- `/listen/listen.jsp` → `/ui/listen/listen`
- `/listen/listen_target.jsp` → `/ui/listen/target`
- `/listen/interface_info.jsp` → `/ui/listen/interface`
- `/listen/table_manager.jsp` → `/ui/listen/table`

### 로그 (4개)
- `/logs/log_access.jsp` → `/ui/logs/access`
- `/logs/log_account.jsp` → `/ui/logs/account`
- `/logs/log_system.jsp` → `/ui/logs/system`
- `/logs/log_web.jsp` → `/ui/logs/web`

### 관리 (3개)
- `/manag/group.jsp` → `/ui/manage/group`
- `/manag/perm.jsp` → `/ui/manage/permission`
- `/manag/user.jsp` → `/ui/manage/user`

### 레코더 (2개)
- `/recorder/sender.jsp` → `/ui/recorder/sender`
- `/recorder/server.jsp` → `/ui/recorder/server`

### 시스템 (4개)
- `/system/code.jsp` → `/ui/system/code`
- `/system/config.jsp` → `/ui/system/config`
- `/system/config_setting.jsp` → `/ui/system/config-setting`
- `/system/menu.jsp` → `/ui/system/menu`

### 승인 (2개)
- `/approve/approve.jsp` → `/ui/approve/approve`
- `/approve/approve_request.jsp` → `/ui/approve/request`

### 다운로드 팝업 (별도 처리 — 2개)
- `/view/download.jsp`
- `/view/download_agent.jsp`

## 남은 핵심 작업

1. **human 수행**: `cd src/main/frontend && npm run build` → Tomcat 재배포 → `GET /ui/` 200 확인
2. **Phase 3 착수**: login.jsp → Login.jsx 마이그레이션부터 시작
3. **Phase 3 완료 후**: Phase 5 (Maven 빌드 통합), Phase 6 (정리)

## React 프론트엔드 구조

```
src/main/frontend/
  public/
    index.html              # CRA 진입점
  src/
    index.js                # ReactDOM.createRoot + 동적 basename
    App.js                  # BrowserRouter + Routes
    api/
      client.js             # apiPost, apiGet (동적 contextPath)
    auth/
      sessionGuard.js       # checkSession() — /user/v1/sessionInfo 검증
    routing/
      routeNormalizer.js    # getBasename(), normalizePath()
    pages/                  # Phase 3 컴포넌트 위치
  .env.development          # PORT=3000
  package.json              # homepage=".", BUILD_PATH=../webapp/ui
```
