# ArcFlow Web 1.2 — Backend API Endpoint Map

> 생성일: 2026-03-16
> 분석 기준: src/main/java/com/rays/app

---

## 1. 인증 / 세션

| Method | Endpoint | Controller | 설명 |
|--------|----------|-----------|------|
| POST/GET | `/logon` | LoginController | 로그인 처리 |
| GET/POST | `/logout` | LoginController | 로그아웃 처리 |
| POST/GET | `/sessionChecker` | SessionController | 세션 유효성 단순 확인 |
| POST/GET | `/sessionAlive` | SessionController | 세션 alive 확인 |
| POST/GET | `/sessionDestory` | SessionController | 세션 파기 |
| POST/GET | `/sessionStatusUpdate` | SessionController | 세션 상태 업데이트 |
| GET/POST | `/session` | SessionController | 세션 정보 |
| POST | `/user/v1/sessionInfo` | UserController (v1) | 세션 정보 + siteCode/levelCode/userId 반환 (SPA 세션 가드 필수) |
| POST/GET | `/policyCheck` | UserController | 비밀번호 정책 확인 |
| POST/GET | `/updateFirstPassword` | UserController | 최초 비밀번호 변경 |
| POST/GET | `/updatePassword` | UserController | 비밀번호 변경 |
| POST/GET | `/resetPwd` | UserController | 비밀번호 초기화 |
| POST/GET | `/clearFailCount` | UserController | 로그인 실패 횟수 초기화 |
| POST/GET | `/updateLockYn` | UserController | 계정 잠금 여부 변경 |

---

## 2. 사용자 / 그룹 / 권한

| Method | Endpoint | Controller | 설명 |
|--------|----------|-----------|------|
| POST/GET | `/selectList` | UserController | 사용자 목록 조회 |
| POST/GET | `/selectOne` | UserController | 사용자 단건 조회 |
| POST/GET | `/insertUserInfo` | UserController | 사용자 등록 |
| POST/GET | `/updateUserInfo` | UserController | 사용자 수정 |
| POST/GET | `/deleteUserInfo` | UserController | 사용자 삭제 |
| GET/POST | `/insertGroupInfo` | GroupController | 그룹 등록 |
| GET/POST | `/updateGroupInfo` | GroupController | 그룹 수정 |
| GET/POST | `/updateGroupInfoByDelYn` | GroupController | 그룹 삭제 여부 변경 |
| GET/POST | `/updateGroupInfoByUseYn` | GroupController | 그룹 사용 여부 변경 |
| POST/GET | `/insertLevelInfo` | LevelController | 레벨 등록 |
| POST/GET | `/updateLevelInfo` | LevelController | 레벨 수정 |
| POST/GET | `/updateLevelInfoByDelYn` | LevelController | 레벨 삭제 여부 변경 |
| POST/GET | `/updateLevelInfoByUseYn` | LevelController | 레벨 사용 여부 변경 |
| POST/GET | `/permission` | LevelController | 권한 조회 |
| POST/GET | `/updatePermission` | LevelController | 권한 수정 |
| GET/POST | `/getPageAuth` | CommonController | 페이지 접근 권한 확인 |
| POST | `/manag/v1/` prefix | manageGroupController | 관리 그룹 CRUD |
| POST | `/insertManageGroup` | manageGroupController | 관리 그룹 등록 |
| POST | `/updateManageGroup` | manageGroupController | 관리 그룹 수정 |
| POST | `/deleteManageGroup` | manageGroupController | 관리 그룹 삭제 |
| POST | `/selectGridManageData` | manageGroupController | 관리 그룹 그리드 데이터 |

---

## 3. 공통 / 설정 / 메뉴

| Method | Endpoint | Controller | 설명 |
|--------|----------|-----------|------|
| GET/POST | `/getOption` | CommonController | 공통 옵션 조회 |
| POST/GET | `/selectGridData` | CommonController / ConfigController | 그리드 데이터 조회 |
| POST/GET | `/selectBackupGridData` | CommonController | 백업 그리드 데이터 조회 |
| POST/GET | `/insert` | CommonController | 공통 등록 |
| POST/GET | `/update` | CommonController | 공통 수정 |
| POST/GET | `/delete` | CommonController | 공통 삭제 |
| POST/GET | `/switchGridOrder` | CommonController | 그리드 순서 변경 |
| POST/GET | `/uploadLogoFile` | ConfigController | 로고 파일 업로드 |
| POST/GET | `/removeLogoFile` | ConfigController | 로고 파일 삭제 |

---

## 4. 파일 관리

| Method | Endpoint | Controller | 설명 |
|--------|----------|-----------|------|
| POST | `/file/v1` prefix | FileController | 파일 관련 v1 API |
| POST | `/getFileList` | FileController | 파일 목록 조회 |
| POST/GET | `/downloadFile` | FileController | 파일 다운로드 |
| POST | `/removeFile` | FileController | 파일 삭제 |

---

## 5. 청취 / 서버 / 레코더

| Method | Endpoint | Controller | 설명 |
|--------|----------|-----------|------|
| POST/GET | `/selectListenConfig` | ListenController | 청취 설정 조회 |
| POST | `/saveListenConfig` | ListenController | 청취 설정 저장 |
| POST/GET | `/getListenPermInfo` | ListenController | 청취 권한 정보 조회 |
| POST/GET | `/updateListenPermInfo` | ListenController | 청취 권한 정보 수정 |
| POST/GET | `/getServerInfo` | ServerController | 서버 정보 조회 |
| POST/GET | `/insertServerInfo` | ServerController | 서버 등록 |
| POST/GET | `/updateServerInfo` | ServerController | 서버 수정 |
| POST/GET | `/deleteServerInfo` | ServerController | 서버 삭제 |
| POST/GET | `/helthCheckOtherService` | HealthCheckController | 타 서비스 헬스체크 |
| GET | `/listen/{type}/{key}/{value}` | ListenController | 청취 액션 |
| GET | `/recorder/v1` prefix | SenderServerController | 레코더 v1 API |
| GET | `/receiver` | SenderServerController | 수신기 정보 |
| GET | `/sender` | SenderServerController | 송신기 정보 |
| GET/POST | `/insertSenderServerInfo` | SenderServerController | 송신 서버 등록 |
| GET/POST | `/updateSenderServerInfo` | SenderServerController | 송신 서버 수정 |
| GET/POST | `/deleteSenderServerInfo` | SenderServerController | 송신 서버 삭제 |

---

## 6. 승인

| Method | Endpoint | Controller | 설명 |
|--------|----------|-----------|------|
| GET | `/approval/v1` prefix | ApproveController | 승인 v1 API |
| GET | `/document/{docId}` | ApproveController | 승인 문서 조회 |
| GET/POST | `/requestApproval` | ApproveController | 승인 요청 |
| GET/POST | `/requestApprovalInfo` | ApproveController | 승인 요청 정보 조회 |
| GET/POST | `/approvalComplete` | ApproveEventController | 승인 완료 처리 |
| GET/POST | `/approvalCancel` | ApproveEventController | 승인 취소 처리 |

---

## 7. ArcFlow / 스토리지

| Method | Endpoint | Controller | 설명 |
|--------|----------|-----------|------|
| POST | `/arcflow/checkDbConnection` | ArcflowController | DB 연결 확인 |
| POST | `/arcflow/insertArcflowJob` | ArcflowController | ArcFlow 작업 등록 |
| GET | `/arcflow/client/setDatas` | ArcflowController | ArcFlow 클라이언트 데이터 설정 |
| GET | `/healthChecker` | HealthCheckController | 헬스체크 |
| GET/POST | `/list` | StorageCommonController | 스토리지 목록 |
| GET | `/check` | StorageCommonController | 스토리지 확인 |

---

## 8. 스케줄러 (관리자 전용)

| Method | Endpoint | 설명 |
|--------|----------|------|
| GET | `/admin/scheduler/dummySessionDelete` | 더미 세션 삭제 |
| GET | `/admin/scheduler/levelPolicyExpirationCheck` | 레벨 정책 만료 확인 |
| GET | `/admin/scheduler/removeBackupExpire` | 백업 만료 삭제 |
| GET | `/admin/scheduler/tempFileDelete` | 임시 파일 삭제 |
| GET | `/admin/scheduler/tempListenFileDelete` | 임시 청취 파일 삭제 |
| GET | `/admin/scheduler/ttsRealtimeFileDelete` | TTS 실시간 파일 삭제 |
| GET | `/admin/scheduler/updateApproveExpire` | 승인 만료 업데이트 |
| GET | `/admin/scheduler/updatePolicyUserLockRotate` | 정책 사용자 잠금 교체 |

---

## 9. 뷰 컨트롤러 (JSP 렌더링)

| Endpoint | 설명 |
|----------|------|
| `/login` | 로그인 JSP 뷰 |
| `/main` | 메인 JSP 뷰 (세션 필수) |
| `/{path}/{page}` | 일반 JSP 뷰 (`ui` 경로 제외, 세션 필수) |

---

## 10. SPA 라우팅 (React)

| Endpoint | 설명 |
|----------|------|
| `/ui` | `/ui/`로 리다이렉트 |
| `/ui/**` | React SPA index.html로 포워드 |

---

## JSP 화면 목록 (마이그레이션 대상)

| JSP 경로 | React 예상 경로 | 카테고리 |
|----------|----------------|---------|
| `/login.jsp` | `/login` | 인증 |
| `/main.jsp` | `/main` | 메인 |
| `/dashboard/monitoring.jsp` | `/dashboard/monitoring` | 대시보드 |
| `/dashboard/status.jsp` | `/dashboard/status` | 대시보드 |
| `/listen/listen.jsp` | `/listen/listen` | 청취 |
| `/listen/listen_target.jsp` | `/listen/target` | 청취 |
| `/listen/interface_info.jsp` | `/listen/interface` | 청취 |
| `/listen/table_manager.jsp` | `/listen/table` | 청취 |
| `/logs/log_access.jsp` | `/logs/access` | 로그 |
| `/logs/log_account.jsp` | `/logs/account` | 로그 |
| `/logs/log_system.jsp` | `/logs/system` | 로그 |
| `/logs/log_web.jsp` | `/logs/web` | 로그 |
| `/manag/group.jsp` | `/manage/group` | 관리 |
| `/manag/perm.jsp` | `/manage/permission` | 관리 |
| `/manag/user.jsp` | `/manage/user` | 관리 |
| `/recorder/sender.jsp` | `/recorder/sender` | 레코더 |
| `/recorder/server.jsp` | `/recorder/server` | 레코더 |
| `/system/code.jsp` | `/system/code` | 시스템 |
| `/system/config.jsp` | `/system/config` | 시스템 |
| `/system/config_setting.jsp` | `/system/config-setting` | 시스템 |
| `/system/menu.jsp` | `/system/menu` | 시스템 |
| `/approve/approve.jsp` | `/approve/approve` | 승인 |
| `/approve/approve_request.jsp` | `/approve/request` | 승인 |
| `/view/download.jsp` | (팝업 — 별도 처리) | 다운로드 |
| `/view/download_agent.jsp` | (팝업 — 별도 처리) | 다운로드 |

---

## 세션 가드 필수 사항

React SPA에서 모든 인증 필요 화면은 `/user/v1/sessionInfo` 호출 후
`sessionData.siteCode`, `sessionData.levelCode`, `sessionData.userId` 세 필드를 반드시 확인해야 합니다.
단순 HTTP 200만으로는 세션 유효성을 보장할 수 없습니다.
