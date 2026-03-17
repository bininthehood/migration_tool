# JSP -> React 마이그레이션 백로그 (2단계)

## 범위
- Workspace pattern guide: `docs/project-docs/docs-main-workspace-migration-guide.md` (reusable pattern from `/main`)
- Main QA report: `docs/project-docs/docs-main-qa-report.md`
- Dashboard 상태 parity note: `docs/project-docs/docs-dashboard-status-parity.md`
- Goal: Move JSP entry screens to React routes under `/ui/...` with feature parity.
- Basis: `docs/project-docs/docs-migration-inventory.md` + controller mapping inspection.
- Note: DB menu URL full list is still required for complete coverage.
- Migration mode: keep legacy JSP URLs alive, build React in `/ui/...`, and cut over in one final transition step.

## 상태 범례
- `할 일`: not started
- `진행중`: currently migrating
- `차단`: waiting for API/spec/DB info
- `완료`: migrated and verified

## 우선 시작 권장 3개 화면
| 우선순위 | 레거시 URL | 현재 JSP 뷰 | 대상 React 라우트 | 주요 백엔드 의존 | 상태 | 사유 |
|---|---|---|---|---|---|---|
| P0 | `/login` | `/login.jsp` | `/ui/login` | `/user/v1/logon`, `/user/v1/policyCheck` | 완료 | 로그인 폼/정책체크/비밀번호 변경 팝업 동작 확인 + 캡처 검증 완료(2026-03-05) |
| P0 | `/main` | `/main.jsp` | `/ui/main` | menu/permission APIs | 완료 | React shell + dialog + tab workspace 적용 후 사용자 수동 QA 완료(2026-03-05) |
| P1 | `/{path}/{page}` -> `/dashboard/status` | `/dashboard/status.jsp` | `/ui/dashboard/status` | `status.selectLastTwoLogStatus`, `status.selectLogStatus` | 완료 | Date filter + `/selectGridData` 서버 페이징/정렬 + 레이아웃 보정 후 사용자 수동 QA 완료(2026-03-05) |

## 마이그레이션 큐 템플릿
| 우선순위 | 레거시 URL | 현재 JSP 뷰 | 대상 React 라우트 | API list | auth/session parity | deep-link refresh | qa 상태 | 상태 |
|---|---|---|---|---|---|---|---|---|
| P1 | `/dashboard/monitoring` | `/dashboard/monitoring.jsp` | `/ui/dashboard/monitoring` | `arcFlow.selectArcFlowDeviceList`, `/helthCheckOtherService`, `arcFlow.selectArcflowHistory` (`/selectGridData`), `arcFlow.selectArcflowError` (`/selectGridData`) | session cookie applied | 검증 완료(2026-03-04) | 캡처 검증 완료(2026-03-04) | 완료 |
| P1 | `/logs/log_account` | `/logs/log_account.jsp` | `/ui/logs/account` | `logAccount.selectLog` (`/selectGridData`) | session/siteCode applied | 검증 완료(2026-03-04) | 캡처 검증 완료(2026-03-04) | 완료 |
| P1 | `/logs/log_web` | `/logs/log_web.jsp` | `/ui/logs/web` | `logWeb.selectLog` (`/selectGridData`) | session/siteCode applied | 검증 완료(2026-03-04) | 캡처 검증 완료(2026-03-04) | 완료 |
| P1 | `/logs/log_access` | `/logs/log_access.jsp` | `/ui/logs/access` | `logAccess.selectLog` (`/selectGridData`) | session/siteCode applied | 검증 완료(2026-03-04) | 캡처 검증 완료(2026-03-04) | 완료 |
| P1 | `/logs/log_system` | `/logs/log_system.jsp` | `/ui/logs/system` | `logSystem.selectLog` (`/selectGridData`) | session/siteCode applied | 검증 완료(2026-03-04) | 캡처 검증 완료(2026-03-04) | 완료 |
| P1 | `/listen/listen` | `/listen/listen.jsp` | `/ui/listen/listen` | `listen_01.selectListenList` (`/selectGridData`), `/recorder/v1/listen/A0/seq/{REC_SEQ}`, `/recorder/v1/listen/A1/seq/{REC_SEQ}` | session/groupCode applied | 청취/다운 엔드포인트 연계 + 검증 완료(2026-03-04) | 캡처 검증 완료(2026-03-04) | 완료 |
| P1 | `/listen/listen_target` | `/listen/listen_target.jsp` | `/ui/listen/listen_target` | `arcFlow.selectArcflowJob` (`/selectGridData`) | session cookie applied | 문구/기본일자/정렬표시 보정 + 검증 완료(2026-03-04) | 캡처 검증 완료(2026-03-04) | 완료 |
| P1 | `/listen/interface_info` | `/listen/interface_info.jsp` | `/ui/listen/interface_info` | `interface.selectInterfaceInfo`, `interface.upsertInterfaceInfo`, `interface.deleteInterfaceInfo`, `/arcflow/checkDbConnection`, `/arcflow/insertArcflowJob` | session/userId applied | 문구/DB연결 상태제어/SQL영역 활성화 보정 + 검증 완료(2026-03-04) | 캡처 검증 완료(2026-03-04) | 완료 |
| P1 | `/listen/table_manager` | `/listen/table_manager.jsp` | `/ui/listen/table_manager` | `tableManage.selectTableList` (`/selectGridData`), `tableManage.selectTableColumn` (`/selectGridData`), `tableManage.deleteTableColumn` (`/delete`) | session cookie applied | 고급 편집 플로우(UI/검증/삭제확인) 보강 완료(2026-03-05) | 캡처 검증 완료(2026-03-05) | 완료 |
| P1 | `/system/config` | `/system/config.jsp` | `/ui/system/config` | `config.selectConfigList`, `config.updateConfigInfo`, `iptable.selectAccessList`, `iptable.insertAccessIp`, `iptable.deleteAccessIp` | session/userId applied | 문구 보정 + 검증 완료(2026-03-04) | 캡처 검증 완료(2026-03-04) | 완료 |
| P1 | `/system/config_setting` | `/system/config_setting.jsp` | `/ui/system/config_setting` | `config.selectConfigGroupList`, `config.selectConfigList`, `config.insertConfigGroupInfo`, `config.updateConfigGroupInfo`, `config.deleteConfigGroupInfo`, `config.deleteConfigGroupByConfigInfo`, `config.insertConfigInfoSetting`, `config.updateConfigInfoSetting`, `config.deleteConfigInfoSetting` | session cookie applied | 문구 보정 + 검증 완료(2026-03-04) | 캡처 검증 완료(2026-03-04) | 완료 |
| P1 | `/system/menu` | `/system/menu.jsp` | `/ui/system/menu` | `menu.selectMainMenuList`, `menu.selectSubMenuList`, `menu.insertMainMenuInfo`, `menu.updateMainMenuInfo`, `menu.updateSubMenuInfo`, `menu.updateMenuUseYn`, `menu.updateSubMenuInfoByAuthUseYn`, `menu.deleteMenuInfo`, `menu.deleteMenuInfoByParent`, `menu.deleteMenuPerm`, `/insertSubMenuInfo` | session cookie applied | 문구 보정 + 검증 완료(2026-03-04) | 캡처 검증 완료(2026-03-04) | 완료 |
| P1 | `/system/code` | `/system/code.jsp` | `/ui/system/code` | `code.selectCommonCodeParentList`, `code.selectCommonCodeByParent`, `code.insertCommonCodeParentInfo`, `code.insertCommonCodeChildInfo`, `code.updateCommonCodeParentInfo`, `code.updateCommonCodeChildInfo`, `code.updateCommonCodeUseYn`, `code.updateCommonCodeDelYn`, `code.updateCommonCodeChildDelYn` | session/siteCode/userId applied | 문구 보정 + 검증 완료(2026-03-04) | 캡처 검증 완료(2026-03-04) | 완료 |
| P2 | `/manag/user` | `/manag/user.jsp` | `/ui/manag/user` | `user.selectUserList` (`/selectGridData`), `level.selectLevelList`, `/user/v1/insertUserInfo`, `/user/v1/updateUserInfo`, `/user/v1/deleteUserInfo`, `/user/v1/updateLockYn`, `/user/v1/clearFailCount`, `/user/v1/resetPwd` | session/siteCode/userId applied | 문구 보정 완료(2026-03-04) | 캡처 검증 완료(2026-03-04) | 완료 |
| P2 | `/manag/group` | `/manag/group.jsp` | `/ui/manag/group` | `group.selectGroupList` (`/selectGridData`), `/user/v1/insertGroupInfo`, `/user/v1/updateGroupInfo`, `/user/v1/updateGroupInfoByUseYn`, `/user/v1/updateGroupInfoByDelYn` | session/siteCode applied | 문구 보정 완료(2026-03-04) | 캡처 검증 완료(2026-03-04) | 완료 |
| P2 | `/manag/perm` | `/manag/perm.jsp` | `/ui/manag/perm` | `level.selectLevelList`, `level.selectMenuPermList`, `/user/v1/insertLevelInfo`, `/user/v1/updateLevelInfo`, `/user/v1/updateLevelInfoByUseYn`, `/user/v1/updateLevelInfoByDelYn`, `/user/v1/updatePermission`, `/user/v1/getListenPermInfo`, `/user/v1/updateListenPermInfo` | session/siteCode/levelCode applied | 문구 보정 완료(2026-03-04) | 캡처 검증 완료(2026-03-04) | 완료 |
| P2 | `/approve/approve` | `/approve/approve.jsp` | `/ui/approve/approve` | `approve_02.selectApproveInfo02List` (`/selectGridData`), `approveEvent.selectMyApproveCount` (`/selectOne`) | session cookie applied | 문구/상태매핑 + 결재 팝업 + 팝업 차단/예외 UX 보강 완료(2026-03-05) | 캡처 검증 완료(2026-03-05) | 완료 |
| P2 | `/approve/approve_request` | `/approve/approve_request.jsp` | `/ui/approve/approve_request` | `approve.selectMyRequestCount` (`/selectOne`), `approve.selectApproveListMine` (`/selectGridData`) | session/userId applied | 문구 + 결재 팝업 + 팝업 차단/예외 UX 보강 완료(2026-03-05) | 캡처 검증 완료(2026-03-05) | 완료 |
| P2 | `/recorder/sender` | `/recorder/sender.jsp` | `/ui/recorder/sender` | `sender.selectServerList` (`/selectGridData`), `/insertSenderServerInfo`, `/updateSenderServerInfo`, `/deleteSenderServerInfo` | session cookie applied | 문구/입력검증 보정 + 검증 완료(2026-03-04) | 캡처 검증 완료(2026-03-04) | 완료 |
| P2 | `/recorder/server` | `/recorder/server.jsp` | `/ui/recorder/server` | `server.selectServerList` (`/selectGridData`), `/insertServerInfo`, `/updateServerInfo`, `/deleteServerInfo` | session cookie applied | 문구/입력검증 보정 + 검증 완료(2026-03-04) | 캡처 검증 완료(2026-03-04) | 완료 |

## 잔여 레거시 전환 후보 (기능 화면 23개 완료 이후)
| 우선순위 | 레거시 URL/JSP | React 전환 후보 | 선행 조건 | 상태 |
|---|---|---|---|---|
| P0 | `/approval/v1/document/{docId}` -> `/approve/document/v1/format_00.jsp`, `/approve/document/v1/format_01.jsp` | 결재 문서 팝업 React 모달/라우트 전환 | 1차: React 브리지 라우트 적용 완료. 2차: `docType 01/02/03/04/05` 네이티브 처리 + `AP_USR_T_CD/AP_USR_T_EXP_CD/AP_USR_C_CD/AP_USR_C_GRP_CD` 옵션 기반 결재/확인 대상자 필터 반영. 예외 시 legacy fallback 유지 | 진행중 |
| P1 | `/view/download`, `/view/download_agent` | 다운로드 화면/에이전트 배포 화면 React 전환 | 파일 다운로드/에이전트 배포 UX 요구사항 확정, 보안/권한 정책 점검 | 할 일 |
| P2 | `/error/*` JSP (`session`, `page`, `permission`, `program`, `error`) | React 공통 에러 라우트(`/ui/error/*`) | 서버 에러 포워딩 정책(`ErrorController`)과 SPA 라우팅 계약 통합 설계 | 할 일 |
| 유지 | `/common/inc_*.jsp`, `header.jsp`, `index.jsp` | 공통 include/jsp bootstrap | JSP 완전 제거 시점까지 유지(마이그레이션 대상 아님) | 유지 |

## 화면별 완료 기준(DoD)
1. Feature parity with legacy JSP (input/query/auth/error)
2. Direct URL + refresh returns `200` (`/rays/ui/...`)
3. No console errors (including basename mismatch)
4. Redirect policy decision for legacy URL (immediate/deferred)
5. No abnormal production log/error trend

## 필수 DB 추출 쿼리 (DB에서 실행)
```sql
SELECT
  SITE_CD,
  MENU_CD,
  MENU_P_CD,
  MENU_NM,
  MENU_URL,
  USE_YN
FROM TB_MENU_LIST
WHERE MENU_P_CD <> 'TOP'
  AND USE_YN = 'Y'
  AND MENU_URL IS NOT NULL
  AND MENU_URL <> ''
ORDER BY MENU_P_CD, MENU_ORDER, MENU_CD;
```

## 다음 액션
1. 가이드 선행 확인 (`CLAUDE.md`)
- 현재 단계: 병행 운영(Parallel Run) 명시 후 시작
- 라우팅 변경 전 필수 파일 확인:
  - `web.xml`
  - `dispatcher-servlet.xml`
  - `SpaForwardController.java`
  - `ViewController.java` (`/{path}/{page}`에서 `ui` 제외)

2. 컷오버 전 최종 QA 마감
- 우선순위:
  - `capture:react --preset all` 회귀 캡처 재실행
  - 브라우저 수동 QA(팝업 차단/예외, 상세 편집, 권한별 접근)
- 최근 실행:
  - 2026-03-09 `npm run capture:react -- --preset all --user admin --password admin` PASS (22개 라우트 캡처 갱신)
  - 2026-03-09 팀 공유 자동화 리허설(`ArcFlow_Webv1.2_test2`) 피드백:
    - `run-all` + `CaptureMode preset` 실패 패턴 확인 (`FRONTEND_DEPS_MISSING`, `Run Capture: UNKNOWN`)
    - 실원인: Playwright `spawn EPERM` + DEV 서버 미기동 시 `localhost:3000` 연결 거부
    - 우회 검증: `--baseUrl http://localhost:8080` 직접 지정 캡처 성공, 오케스트레이션은 `CaptureMode none`으로 성공
- 공통 점검 항목: 레거시 팝업 연동, 실패/예외 메시지, 권한 제어, 문구/레이아웃 미세 패리티
- 2026-03-11 자동화 보완:
  - `run-all.ps1` 가 `TOMCAT_NOT_READY` 와 `TOMCAT_UI_NOT_READY` 를 분리해 `/rays/login` 생존과 `/rays/ui/` 미배포를 구분함
  - `UTF-8 Mojibake Check` preflight 추가: `�|\?앹|\?몄|\?붿|\?덉|\?먮|\?대` 패턴 발견 시 즉시 실패
  - React dev server 자동 기동 시 `npm.cmd` + `BROWSER=none` + stdout/stderr 로그(`automation/logs/devserver-*.log`)를 사용
  - 자동 문서/로그 생성은 UTF-8(무BOM)으로 저장하도록 보완
  - Tomcat 기준 전체 오케스트레이션 PASS:
    - `run-all.ps1 -CaptureMode preset -CaptureBaseUrl http://localhost:8080`
    - `Tomcat Ready Check` + `Verify Session Contract` + `Frontend Compile Check` + `Run Capture` + `Sync Session Log` 성공
    - 단, Playwright 캡처는 샌드박스 내부 실행 시 `spawn EPERM` 이 날 수 있어 권한 상승 실행 기준으로 운용
- 2026-03-11 결재 문서 팝업 보완:
  - `ApprovalDocumentBridgePage.js` 상단 깨진 주석 제거
  - React 브리지/네이티브 팝업의 사용자 노출 문구를 한국어 기준으로 정리
  - `npm run build` 성공으로 문법/인코딩 확인 완료
  - `approvalPopup.js` 에서 취소 요청(`REQ_STATUS = X`)을 막지 않고 `docType 06` 읽기 전용 팝업으로 연결하도록 보정
  - `ApprovePanel.js`, `ApproveRequestPanel.js` 의 목록/필터/상세 모달 한글 깨짐 정리

3. 검증 루프 고정
- 화면 단건:
  - `npm run capture:react -- --path /rays/ui/<route> --name <name> --user <id> --password <pw>`
- 회귀:
  - `npm run capture:react -- --preset all --user <id> --password <pw>`
  - (Tomcat 기준 런타임 검증) `npm run capture:react -- --preset all --baseUrl http://localhost:8080 --user <id> --password <pw>`
- 빌드:
  - `BUILD_PATH=<temp> npm run build`

4. 문서 동기화 의무
- `docs/project-docs/docs-main-qa-report.md`: 화면별 보정/검증 결과
- `docs/project-docs/SESSION_WORKLOG_*.md`: 변경 파일/명령/캡처
- `docs-migration-backlog.md`: deep-link refresh / qa 상태 갱신
- `automation/next-session-manifest.json`: 다음 세션 재실행용 compact 실행 요약

5. 마일스톤 시점 배포 검증
- `docs/project-docs/README_FRONTEND_BUILD_DEPLOY.md` 절차로 build -> copy -> publish
- `localhost:8080/rays/ui/...` 상태 코드/라우팅 계약 최종 점검
- 최근 실행:
  - 2026-03-09 Tomcat 재시작 이후 런타임 접근 로그 회귀 확인 완료
  - `localhost_access_log.2026-03-09.txt` 기준 `5XX=0` (`4XX=7`: `/` 3건, `/rays/user/v1/sessionCheck` 4건)

6. 컷오버 준비 문서 확정
- `docs/project-docs/docs-cutover-checklist.md` 기준으로 Go/No-Go, 롤백 조건, 실행 담당자/시간 확정
