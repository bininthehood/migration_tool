# 현재 프로젝트 상태 (최종 업데이트: 2026-03-13)

## 진행 단계
인벤토리(Inventory) - 마이그레이션 시작 전 (Phase 1)

## 마이그레이션 진행률
0% (0개 / 23개 화면 완료)

## 실제 프로젝트 상태 확인 (2026-03-13 기준)

| 항목 | 상태 | 비고 |
|---|---|---|
| `src/main/frontend` | **없음** | CRA 프로젝트 생성 필요 |
| `src/main/webapp/ui` | **없음** | 빌드 후 복사 필요 |
| `dispatcher-servlet.xml` SPA 라우팅 | **없음** | `/ui/**` 리소스/뷰컨트롤러 추가 필요 |
| `SpaForwardController.java` | **없음** | 생성 필요 |
| JSP 화면 (기능) | **23개 전체 존재** | 이관 전 상태 |
| npm 의존성 | **미설치** | bootstrap-frontend 후 npm install 필요 |

## 선행 작업 (마이그레이션 착수 전 필수)

### Step 1 — 프론트엔드 프로젝트 생성 및 의존성 설치

```bash
# WSL / Linux 기준
bash migration_tool/automation/bootstrap-frontend.sh \
  --project-root /home/rays/projects/ArcFlow_Webv1.2 \
  --apply \
  --install-deps
```

```powershell
# Windows PowerShell 기준
powershell -ExecutionPolicy Bypass -File migration_tool/automation/bootstrap-frontend.ps1 `
  -ProjectRoot C:\...\ArcFlow_Webv1.2 `
  -Apply `
  -InstallDeps
```

결과:
- `src/main/frontend/` 폴더 생성 (package.json, src/, public/, scripts/ 포함)
- `src/main/webapp/ui/` 폴더 생성
- `npm install` 완료

### Step 2 — Spring MVC SPA 라우팅 설정

대상 파일: `src/main/webapp/WEB-INF/config/springmvc/dispatcher-servlet.xml`

추가 필요 항목:
```xml
<!-- SPA 정적 리소스 서빙 -->
<mvc:resources mapping="/ui/**" location="/ui/"/>
<mvc:default-servlet-handler />

<!-- SPA 진입점 뷰 컨트롤러 -->
<mvc:view-controller path="/ui" view-name="redirect:/ui/"/>
<mvc:view-controller path="/ui/" view-name="forward:/ui/index.html"/>

<!-- 브라우저 호환 리소스 매핑 -->
<mvc:resources mapping="/static/**" location="/ui/static/"/>
<mvc:resources mapping="/manifest.json" location="/ui/"/>
<mvc:resources mapping="/favicon.ico" location="/ui/"/>
```

대상 파일: `src/main/java/com/rays/app/web/SpaForwardController.java` (신규 생성)
- `/ui` redirect 핸들러
- `/ui/` index forward 핸들러
- 확장자 없는 `/ui/**` forward 핸들러

### Step 3 — 초기 빌드 및 배포 확인

```powershell
cd src/main/frontend
npm run build
robocopy build ..\..\..\webapp\ui /MIR
# Eclipse WTP → Tomcat Clean + Publish + Restart
# GET http://localhost:8080/rays/ui/ → 200 확인
```

## JSP 인벤토리 (이관 대상)

| # | JSP 경로 | 레거시 URL | React 대상 라우트 | 상태 |
|---|---|---|---|---|
| 1 | `login.jsp` | `/login` | `/ui/login` | 대기 |
| 2 | `main.jsp` | `/main` | `/ui/main` | 대기 |
| 3 | `dashboard/status.jsp` | `/dashboard/status` | `/ui/dashboard/status` | 대기 |
| 4 | `dashboard/monitoring.jsp` | `/dashboard/monitoring` | `/ui/dashboard/monitoring` | 대기 |
| 5 | `logs/log_account.jsp` | `/logs/log_account` | `/ui/logs/account` | 대기 |
| 6 | `logs/log_web.jsp` | `/logs/log_web` | `/ui/logs/web` | 대기 |
| 7 | `logs/log_access.jsp` | `/logs/log_access` | `/ui/logs/access` | 대기 |
| 8 | `logs/log_system.jsp` | `/logs/log_system` | `/ui/logs/system` | 대기 |
| 9 | `listen/listen.jsp` | `/listen/listen` | `/ui/listen/listen` | 대기 |
| 10 | `listen/listen_target.jsp` | `/listen/listen_target` | `/ui/listen/listen_target` | 대기 |
| 11 | `listen/interface_info.jsp` | `/listen/interface_info` | `/ui/listen/interface_info` | 대기 |
| 12 | `listen/table_manager.jsp` | `/listen/table_manager` | `/ui/listen/table_manager` | 대기 |
| 13 | `system/config.jsp` | `/system/config` | `/ui/system/config` | 대기 |
| 14 | `system/config_setting.jsp` | `/system/config_setting` | `/ui/system/config_setting` | 대기 |
| 15 | `system/menu.jsp` | `/system/menu` | `/ui/system/menu` | 대기 |
| 16 | `system/code.jsp` | `/system/code` | `/ui/system/code` | 대기 |
| 17 | `manag/user.jsp` | `/manag/user` | `/ui/manag/user` | 대기 |
| 18 | `manag/group.jsp` | `/manag/group` | `/ui/manag/group` | 대기 |
| 19 | `manag/perm.jsp` | `/manag/perm` | `/ui/manag/perm` | 대기 |
| 20 | `approve/approve.jsp` | `/approve/approve` | `/ui/approve/approve` | 대기 |
| 21 | `approve/approve_request.jsp` | `/approve/approve_request` | `/ui/approve/approve_request` | 대기 |
| 22 | `recorder/sender.jsp` | `/recorder/sender` | `/ui/recorder/sender` | 대기 |
| 23 | `recorder/server.jsp` | `/recorder/server` | `/ui/recorder/server` | 대기 |

## 유지 JSP (이관 대상 아님)

| JSP 경로 | 유지 사유 |
|---|---|
| `common/inc_*.jsp`, `header.jsp` | 공통 include — JSP 완전 제거 시까지 유지 |
| `index.jsp` | 기본 진입 — 유지 |
| `error/page.jsp` | 에러 페이지 — 추후 React 에러 라우트로 전환 검토 |
| `view/download.jsp`, `view/download_agent.jsp` | 파일/에이전트 다운로드 — 추후 전환 검토 |
| `approve/document/v1/format_00.jsp`, `format_01.jsp` | 결재 문서 팝업 — 추후 전환 검토 |

## 남은 핵심 작업

1. **선행 작업 완료**: bootstrap-frontend → dispatcher-servlet.xml 설정 → 초기 빌드
2. **Phase 1 (인벤토리)**: JSP/API/컨트롤러 매핑 전체 목록 작성
3. **Phase 2 (병행 운영)**: CRA 기반 React 앱 구조 설계, 공통 레이아웃/세션/라우팅 구현
4. **Phase 3 (전환)**: 화면 단위 JSP → React 이관 (P0 로그인/메인 → P1 기능화면 순)

## 빠른 실행 명령

```powershell
# 프론트엔드 부트스트랩 (최초 1회)
powershell -ExecutionPolicy Bypass -File automation\bootstrap-frontend.ps1 `
  -ProjectRoot <project-root> -Apply -InstallDeps

# 자동화 실행 (부트스트랩 완료 후)
powershell -ExecutionPolicy Bypass -File automation\run-all.ps1 `
  -ProjectRoot <project-root> -CaptureMode none -FrontendBuildTimeoutSec 1800
```
