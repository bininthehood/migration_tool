# 현재 프로젝트 상태 (최종 업데이트: 2026-03-16)

## 진행 단계
인벤토리(Inventory) - Phase 1 착수 가능 상태 (Phase 0 완료)

## 마이그레이션 진행률
0% (0개 / 23개 화면 완료)

## 실제 프로젝트 상태 확인 (2026-03-13 기준)

| 항목 | 상태 | 비고 |
|---|---|---|
| `src/main/frontend` | **생성됨** | bootstrap-frontend 완료, npm install 완료 |
| `src/main/frontend/public/index.html` | **생성됨** | CRA 진입점 확인 — npm run build PASS |
| `src/main/frontend/src/index.js` | **생성됨** | CRA 진입점 확인 — npm run build PASS |
| `src/main/frontend/src/pages/login/LoginPage.js` | **stub 생성됨** | Phase 0 stub — 세션 가드 패턴 포함 |
| `src/main/frontend/src/pages/main/MainPage.js` | **stub 생성됨** | Phase 0 stub — 로그아웃 패턴 포함 |
| `src/main/webapp/ui` | **빌드 산출물 존재** | npm run build PASS (60.67 kB gzip) |
| `dispatcher-servlet.xml` SPA 라우팅 | **설정 완료** | `/ui/**` 리소스, 뷰컨트롤러 추가됨 |
| `SpaForwardController.java` | **생성됨** | `/ui`, `/ui/`, `/ui/**` 핸들러 완료 |
| `ViewController.java` ui 경로 제외 | **완료** | `^(?!ui$).+` 패턴 적용됨 |
| JSP 화면 (기능) | **23개 전체 존재** | 이관 전 상태 |
| npm 의존성 | **설치됨** | node_modules 존재 |
| docs/project-docs/ (project root) | **생성됨** | validate 스크립트 find 오류 방지 |

## 자동화 마지막 실행 결과 (2026-03-16 — Phase A 재검증 실행)

| 단계 | 결과 |
|---|---|
| UTF-8 Mojibake Check | PASS |
| Frontend Bootstrap Check | PASS |
| Ensure Frontend Dependencies | PASS |
| Validate Skill Integration | PASS (PASS_WITH_WARNINGS — captures/main 미생성, CaptureMode=none 정상) |
| Check Routing Contract | PASS (8/8) |
| Sync Session Log | PASS |

실행 명령:
```bash
bash migration_tool/automation/run-all.sh \
  --project-root /home/rays/projects/ArcFlow_Webv1.2 \
  --capture-mode none \
  --skip-tomcat-check \
  --skip-session-contract-check \
  --skip-frontend-compile-check
```

스킵된 단계 (이유):
- Tomcat Ready Check: WSL 환경에서 Windows측 Tomcat 접근 불가 (`--skip-tomcat-check`)
- Verify Session Contract: Tomcat 미실행 (`--skip-session-contract-check`)
- Frontend Compile Check: `--skip-frontend-compile-check` 적용 (이전 세션 7/7 → 이번 6/6 — 단계 수 변화, regression 아님)

비고 (2026-03-16): 오케스트레이터가 Phase A 6/6 PASS를 전체 세션 완료로 잘못 처리하여 Phase B (migration-agent) 미실행됨. Phase 1 (인벤토리) 착수가 여전히 남아있음.

## 선행 작업 (마이그레이션 착수 전 필수)

### Step 1 — 프론트엔드 프로젝트 생성 및 의존성 설치 [완료]

bootstrap-frontend.sh --apply --install-deps 실행됨. node_modules 설치 완료.

### Step 2 — Spring MVC SPA 라우팅 설정 [완료]

`dispatcher-servlet.xml` 에 추가됨:
```xml
<mvc:resources mapping="/ui/**" location="/ui/"/>
<mvc:default-servlet-handler/>
<mvc:view-controller path="/ui" view-name="redirect:/ui/"/>
<mvc:view-controller path="/ui/" view-name="forward:/ui/index.html"/>
<mvc:resources mapping="/static/**" location="/ui/static/"/>
<mvc:resources mapping="/manifest.json" location="/ui/"/>
<mvc:resources mapping="/favicon.ico" location="/ui/"/>
```

`SpaForwardController.java` 생성됨.
`ViewController.java` — `/{path:^(?!ui$).+}/{page}` 패턴 적용됨.

### Step 3 — 초기 빌드 및 배포 확인 [빌드 완료 / Tomcat 런타임 미확인]

```bash
# 빌드는 자동화 실행에서 PASS 확인됨 (npm run build, 60.67 kB gzip)
# Tomcat 배포는 Eclipse WTP 측에서 별도 수행 필요
# GET http://localhost:8080/rays/ui/ → 200 확인 (Tomcat 런타임 후)
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

1. **Tomcat 배포 확인**: Eclipse WTP에서 Clean + Publish + Restart 후 `GET /rays/ui/` → 200 확인
2. **Phase 1 (인벤토리)**: JSP/API/컨트롤러 매핑 전체 목록 작성 (TASK_BOARD.md Phase 1 항목)
3. **Phase 2 (병행 운영)**: CRA 기반 React 앱 구조 설계, 공통 레이아웃/세션/라우팅 구현
4. **Phase 3 (전환)**: 화면 단위 JSP → React 이관 (P0 로그인/메인 → P1 기능화면 순)

## 빠른 실행 명령 (현재 상태 기준)

```bash
# WSL 환경 — Tomcat 없이 검증 가능한 단계만 실행 (Phase 0 완료 확인 명령)
bash migration_tool/automation/run-all.sh \
  --project-root /home/rays/projects/ArcFlow_Webv1.2 \
  --capture-mode none \
  --skip-tomcat-check \
  --skip-session-contract-check \
  --frontend-build-timeout-sec 1800

# Tomcat 실행 후 전체 실행 (--skip-frontend-compile-check 불필요 — CRA 진입점 존재)
bash migration_tool/automation/run-all.sh \
  --project-root /home/rays/projects/ArcFlow_Webv1.2 \
  --capture-mode none \
  --frontend-build-timeout-sec 1800
```
