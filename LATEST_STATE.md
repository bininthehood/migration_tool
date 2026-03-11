# 현재 프로젝트 상태 (최종 업데이트: 2026-03-10)

## 진행 단계
전환(Transition) - 기능 화면 컷오버 적용 완료

## 마이그레이션 진행률
100% (23개 화면 중 23개 완료)

## 세션 참고 산출물
- SourceAnalyzer 모듈 이식/실행 완료 (2026-03-06)
  - 모듈 경로: `automation/tools/source-analyzer/`
  - 결과 경로: `source-analysis/`
  - 대표 인덱스: `source-analysis/00_Index.md`
  - 서술형 요약: `source-analysis/narrative/ReadMe.md`

## 완료된 화면 목록

| 화면명 | React 라우트 | 완료일 | 캡처 파일명 |
|---|---|---|---|
| Main | `/ui/main` | 2026-03-05 | `react-main-1920x911-9.png` |
| Dashboard Status | `/ui/dashboard/status` | 2026-03-05 | `react-dashboard-status-1920x911-8.png` |
| Dashboard Monitoring | `/ui/dashboard/monitoring` | 2026-03-04 | `react-monitoring-parity-1920x911.png` |
| Logs Account | `/ui/logs/account` | 2026-03-04 | `react-log-account-parity-1920x911.png` |
| Logs Web | `/ui/logs/web` | 2026-03-04 | `react-log-web-parity-1920x911.png` |
| Logs Access | `/ui/logs/access` | 2026-03-04 | `react-log-access-parity-1920x911.png` |
| Logs System | `/ui/logs/system` | 2026-03-04 | `react-log-system-parity-1920x911.png` |
| Listen List | `/ui/listen/listen` | 2026-03-05 | `react-listen-player-react-only-1920x911-1920x911.png` |
| Listen Target | `/ui/listen/listen_target` | 2026-03-04 | `react-listen-target-parity-1920x911-2.png` |
| Listen Interface Info | `/ui/listen/interface_info` | 2026-03-04 | `react-interface-info-parity-1920x911.png` |
| Listen Table Manager | `/ui/listen/table_manager` | 2026-03-05 | `react-table-manager-advanced-flow-1920x911.png` |
| System Config | `/ui/system/config` | 2026-03-04 | `react-system-config-parity-1920x911.png` |
| System Config Setting | `/ui/system/config_setting` | 2026-03-04 | `react-system-config-setting-parity-1920x911.png` |
| System Menu | `/ui/system/menu` | 2026-03-04 | `react-system-menu-parity-1920x911.png` |
| System Code | `/ui/system/code` | 2026-03-04 | `react-system-code-parity-1920x911.png` |
| User Manage | `/ui/manag/user` | 2026-03-05 | `react-manag-user-group-picker-1920x911.png` |
| Group Manage | `/ui/manag/group` | 2026-03-05 | `react-manag-group-tree-parity-1920x911.png` |
| Permission Manage | `/ui/manag/perm` | 2026-03-05 | `react-manag-perm-group-header-1920x911.png` |
| Approve | `/ui/approve/approve` | 2026-03-05 | `react-approve-popup-ux-approve-1920x911.png` |
| Approve Request | `/ui/approve/approve_request` | 2026-03-05 | `react-approve-popup-ux-request-1920x911.png` |
| Login | `/ui/login` | 2026-03-05 | `react-login-parity-1920x911.png` |
| Recorder Sender | `/ui/recorder/sender` | 2026-03-04 | `react-recorder-sender-parity-1920x911-1920x911.png` |
| Recorder Server | `/ui/recorder/server` | 2026-03-04 | `react-recorder-server-parity-1920x911-1920x911.png` |

## 현재 진행중 항목
- JSP 제거 소배치 실행 완료
- Batch-1 완료: `dashboard/monitoring_bak.jsp` 제거
- Batch-2 완료: 기능 화면 JSP 23건 제거 + 레거시 URL React 리다이렉트 적용
- JSP 인벤토리 최종화(2026-03-06): 잔여 16건 분류 완료
  - 유지: `error/*`, `view/download*`, `common/*`, `approve/document/v1/*`, `index.jsp`
  - 제거 대상 기능 JSP는 배치 제거 완료 상태 유지

## 남은 핵심 작업
1. 컷오버 이후 운영 모니터링(로그/권한/팝업 예외) 단기 추적
2. 잔여 JSP 전환 후보 착수: 결재 문서 팝업(`approve/document/v1/format_00,01`) -> React 전환 설계/구현
3. 수렴 단계 문서 정리 및 잔여 레거시(`error/*`, `download*`, `common/*`) 유지/전환 정책 확정
4. 자동화 안정화: `run-all.ps1` 캡처 단계의 대상 URL 선택(DEV `:3000` vs Tomcat `:8080`) 및 사전점검 규칙 명시

## 최신 검증 로그
- 2026-03-10: 결재 문서 팝업 P0 전환 1차(브리지) 적용
  - React 라우트 추가: `/ui/approval/document/:docId`
  - 팝업 호출 변경: React 화면에서 직접 JSP POST 호출 대신 브리지 라우트 경유
  - 브리지 동작: 토큰(sessionStorage)로 payload 전달 후 기존 `/approval/v1/document/{docId}` POST self-submit
  - 결과: 레거시 팝업 동작 호환 유지 + React 진입점 확보(2차 본문 React 이관 준비)
- 2026-03-10: 결재 문서 팝업 P0 전환 2차(부분 네이티브) 적용
  - 대상: `docType 03/04/05` (조회/결재/승인)
  - 구현: 브리지 페이지에서 `requestApprovalInfo` 조회 + `approvalComplete`/`approvalCancel` 처리
  - fallback: `docType 01/02` 또는 오류 시 기존 JSP 폼 POST 경로로 자동 전환
- 2026-03-10: 결재 문서 팝업 `docType 01/02` 보강
  - 구현: `requestApproval` 생성 플로우에 `AP_USR_*` 옵션(`AP_USR_T_CD`, `AP_USR_T_EXP_CD`, `AP_USR_C_CD`, `AP_USR_C_GRP_CD`) 기반 대상자 필터 반영
  - 구현: 확인자 그룹(`AP_USR_C_GRP_CD`) 및 본인 그룹 기준 부모/자기 그룹 범위 조회 반영(`group.selectParentGroup` 연계)
- 2026-03-10: 프론트 빌드 검증
  - `npm run build` 성공 (warning only: react-datepicker critical dependency)
- 2026-03-09: 팀 공유 자동화 리허설 피드백 반영(검증 프로젝트: `ArcFlow_Webv1.2_test2`)
  - `run-20260309-160559`: 실패 (`FRONTEND_DEPS_MISSING`) - `npm install` 단계에서 `EACCES`/registry fetch 오류
  - `run-20260309-162333`: 실패 (`Run Capture`, `UNKNOWN`) - 실원인 분리 확인:
    - 샌드박스 실행 시 `browserType.launch: spawn EPERM`
    - 권한 상승 후 `page.goto ... ERR_CONNECTION_REFUSED` (`http://localhost:3000` 미기동)
  - 우회/완료 검증:
    - `npm run capture:react -- --preset all --baseUrl http://localhost:8080 --user admin --password admin` 성공
    - `run-20260309-163621`: `CaptureMode none`으로 전체 오케스트레이션 성공 (Tomcat restart + batch migration + doc sync)
- 2026-03-09: Tomcat Clean + Publish + Restart 이후 최종 반영 확인
  - `/rays/ui/` index 참조 자산: `main.5ae8cf5c.js`, `main.f5ccebab.css`
  - `GET /rays/user/v1/sessionChecker` -> `200`
  - 접근로그 최근 구간 집계: `/rays/user/v1/sessionCheck` 404 = `0`, `/rays/user/v1/sessionChecker` 호출 = `2`
- 2026-03-09: 라우팅 컷오버 실행 검증 완료
  - 레거시 URL 22개 전수 확인: `/rays/{legacy-route}` -> `302` (`/rays/ui/login;jsessionid=...`)
  - 근거 로그: `localhost_access_log.2026-03-09.txt` (14:14:56 KST 일괄 요청)
- 2026-03-09: 로그인 세션체크 경로 정리
  - 프론트 수정: `/user/v1/sessionCheck` -> `/user/v1/sessionChecker`
  - 서버 엔드포인트 확인: `GET /rays/user/v1/sessionChecker` -> `200`
- 2026-03-09: 빌드/산출물 동기화 재실행
  - `npm run build` 완료 (build hash: `main.5ae8cf5c.js`, `main.f5ccebab.css`)
  - `robocopy .../src/main/frontend/build -> .../src/main/webapp/ui /MIR` 완료
  - Tomcat 재시작 후 런타임 반영 완료 (`main.5ae8cf5c.js`)
- 2026-03-09: Tomcat 런타임 접근 로그 회귀 확인 완료
  - 로그 경로: `C:\dev\eclipse\workspace\.metadata\.plugins\org.eclipse.wst.server.core\tmp0\logs\localhost_access_log.2026-03-09.txt`
  - Tomcat 시작시각: `2026-03-09 13:52:17` (PID 94712)
  - 집계: `TOTAL=455`, `4XX=7`, `5XX=0`
  - 4xx 상위: `404 /`(3건), `404 /rays/user/v1/sessionCheck`(4건)
- 2026-03-09: Tomcat 재시작 이후 런타임 해시 동기화 확인 완료
  - `/rays/ui/` index 참조 자산: `main.b4a5106c.js`, `main.f5ccebab.css`
  - `GET /rays/ui/static/js/main.b4a5106c.js` -> `200`
  - `GET /rays/ui/static/css/main.f5ccebab.css` -> `200`
- 2026-03-09: `npm run capture:react -- --preset all --user admin --password admin` 재실행 PASS
  - 생성 캡처: 22개 라우트 갱신 (`captures/main/react-*-1920x911-*.png`)
- 2026-03-09: 라우팅/리다이렉트 회귀 점검
  - `GET /rays/login` -> `302` (`/rays/ui/login`)
  - `GET /rays/main` -> `302` (`/rays/ui/login;jsessionid=...`)
  - `GET /rays/ui` -> `302` (`/rays/ui/`)
  - `GET /rays/ui/`, `/rays/ui/main`, `/rays/ui/dashboard/status` -> `200`
- 2026-03-06: `npm run capture:react -- --preset all --user admin --password admin` 재실행 완료
- 생성 캡처: `/main`, `/dashboard/status` 포함 22개 라우트 갱신 (`captures/main/react-*-1920x911-*.png`)
- 2026-03-06: Tomcat `/rays/ui` 라우팅/정적자산 계약 확인 완료
  - `GET /rays/ui` -> `302` (`Location: /rays/ui/`)
  - `GET /rays/ui/`, `/rays/ui/main`, `/rays/ui/dashboard/status`, `/rays/ui/login` -> `200`
  - `GET /rays/ui/static/js/main.7c7373b6.js` -> `200`
  - `GET /rays/ui/static/css/main.ebd0d6d1.css` -> `200`
- 2026-03-06: `/main`, `/dashboard/status` 사용자 수동 QA 완료(문제 없음)
- 2026-03-06: Batch-2 실행 후 라우팅 점검
  - `GET /rays/ui` -> `302`
  - `GET /rays/ui/`, `/rays/ui/main` -> `200`
  - `GET /rays/main` -> `302` (비로그인 시 로그인 경유 유지)
  - `GET /rays/login` -> `302` (`/rays/ui/login` 리다이렉트)
- 2026-03-06: 컷오버 사전 동기화 수행
  - `npm run build` 완료 (build hash: `main.4b89f21c.js`, `main.0a23746a.css`)
  - `robocopy .../src/main/frontend/build -> .../src/main/webapp/ui /MIR` 완료
  - 런타임 Tomcat은 아직 이전 해시 서빙 중 (`main.7c7373b6.js`, `main.01bdf935.css`) -> Publish 필요

## 빠른 실행 명령
```powershell
# 개발 서버
cd C:\Users\rays\ArcFlow_Webv1.2\src\main\frontend
npm run dev

# 캡처 검증
npm run capture:react -- --preset all --user admin --password admin

# 빌드
$env:BUILD_PATH='build_tmpX'; npm run build
```

