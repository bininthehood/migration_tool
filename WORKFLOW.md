# WORKFLOW.md

## 새 세션 시작 프롬프트

아래 프롬프트를 Claude Code에 붙여 넣어 세션을 시작한다.

```text
너는 C:\Users\rays\ArcFlow_Webv1.2 프로젝트를 이어받아 작업하는 코딩 에이전트다.
이전 세션 맥락 없이도 아래 절차를 처음부터 자동 수행해라.

[목표]
- JSP -> React 이관 화면의 패리티를 legacy/react 캡처 비교로 지속 개선
- 개발 검증은 localhost:3000 자동 캡처 기반으로 빠르게 반복
- 최종 단계에서만 빌드/복사/톰캣 검증 수행
- 결과를 체크리스트 형태로 남기고 docs/project-docs/SESSION_WORKLOG_2026-03-03.md를 갱신

[컨텍스트 복구 순서]
1. LATEST_STATE.md
2. docs/project-docs/SESSION_WORKLOG_2026-03-03.md
3. docs-migration-backlog.md
4. captures/main 최신 legacy/react 캡처
```

## 목적
루트 마크다운 문서를 단일 실행 체계로 묶어, 세션마다 동일한 순서로 작업한다.
병행 운영(Parallel Run) 단계에서 JSP + React 공존 원칙과 라우팅 계약을 우선 보장한다.

## 문서 우선순위 (충돌 시 적용 순서)
1. `AGENTS.md`
2. `LATEST_STATE.md`
3. `docs-migration-backlog.md`
4. `docs/project-docs/docs-main-qa-report.md`
5. `docs/project-docs/SESSION_WORKLOG_2026-03-03.md`
6. `docs/project-docs/README_FRONTEND_BUILD_DEPLOY.md`
7. 기타 참고 문서 (`docs/project-docs/REACT_CAPTURE_AUTOMATION.md`, `docs/project-docs/SYSTEM_ARCHITECTURE.md`)

## 운영 원칙
1. 개발 중에는 `npm run build`를 매번 수행하지 않는다.
2. 화면 검증은 `localhost:3000` + 자동 캡처 스크립트로 진행한다.
3. Tomcat publish/서버 8080 검증은 마일스톤(사용자 요청 시점)에만 수행한다.
4. 완료된 영역 재작업 금지, 최소 단위 수정 우선.
5. 변경 후에는 검증 근거(명령/캡처/로그)를 문서에 기록한다.
6. 현재 세션 기준 프론트 확인은 3000 포트(dev 서버)에서 진행하며, `npm run build`는 이관 작업 마무리 시점에 일괄 1회 수행한다.

## 세션 시작 리스크 체크 (레거시 공통)
1. 인코딩 확인: 신규/수정 파일은 UTF-8(무BOM) 유지
2. 선행 빌드: `npm run build` 1회로 문자열/문법 깨짐 조기 탐지
3. 포트 점검: 3000 포트 기존 점유 프로세스 확인 후 dev 서버 기동
4. 딥링크 점검: `/ui`, `/ui/`, `/ui/<deep-route>` 직접접속 200 확인
5. 팝업 점검: 차단/누락/미지원 케이스 예외 메시지 준비

## 한글 인코딩 운영 규칙
1. 파일 저장은 UTF-8(무BOM) 고정, 에디터 자동 인코딩 추측 기능 비활성화 권장
2. PowerShell 파일 쓰기는 명시적 UTF-8로만 수행
   - `$enc = New-Object System.Text.UTF8Encoding($false)`
   - `[System.IO.File]::WriteAllText($path, $content, $enc)`
3. `Out-File`/기본 `Set-Content`/무분별한 `-replace` 기반 대량 치환 금지
4. 커밋 전 깨짐 점검(`�`, `??`, 비정상 한글 문자열) 수행

## 시작 체크리스트
1. 현재 단계 명시: `병행 운영(Parallel Run)`
2. 라우팅 계약 핵심 파일 확인
   - `src/main/webapp/WEB-INF/web.xml`
   - `src/main/webapp/WEB-INF/config/springmvc/dispatcher-servlet.xml`
   - `src/main/java/com/rays/app/web/SpaForwardController.java`
   - `src/main/java/com/rays/app/view/controller/ViewController.java`
3. `docs-migration-backlog.md`의 진행중 항목에서 작업 대상 1개 선택

## 핵심 파이프라인
1. 컨텍스트 복구
   - `LATEST_STATE.md`와 `docs/project-docs/SESSION_WORKLOG_2026-03-03.md` 최신 항목부터 확인
   - `docs-migration-backlog.md`에서 누락/우선순위 점검
2. 자동 캡처 실행
   - 단건: `npm run capture:react -- --path /rays/ui/<route> --name <name> --user <id> --password <pw>`
   - 회귀: `npm run capture:react -- --preset all --user <id> --password <pw>`
   - 자동화(`automation/run-all.ps1`) 실행 시 로그인 세션 API 계약을 선검증한다.
     - `policyCheck` -> `sessionAlive` -> `sessionInfo` 순서로 `resultCode=0`
     - `sessionInfo.sessionData.siteCode/levelCode/userId` 필수값 확인
   - 프론트 세션 가드 규칙(전 패키지 공통):
     - `/login`에서 `sessionChecker`만으로 `/main` 리다이렉트 금지
     - `sessionInfo` 필수값(`siteCode/levelCode/userId`) 검증 후에만 `/main` 이동
     - 필수값 누락 시 `/main` 에러 문구 고정 노출 대신 `/login`으로 복귀
3. 패리티 분석/수정
   - `captures/main`의 `legacy-*` vs `react-*` 비교
   - 레이아웃/기본조회조건/문구/핵심 플로우 우선 보정
   - 화면 이관 자동화 실행 시(`run-all.ps1` + `-MigrateScreen`/`-MigrateBatch`) React 함수 주석 단계가 기본 포함된다.
   - 자동 주석 언어는 한글을 필수 적용한다.
   - 자동 주석 파일 저장 인코딩은 UTF-8(무BOM)으로 강제한다.
4. 재캡처 검증
   - 수정 화면 단건 재캡처
   - 필요 시 `preset all` 재실행
5. 문서 갱신
   - `docs/project-docs/docs-main-qa-report.md`
   - `docs/project-docs/SESSION_WORKLOG_2026-03-03.md`
   - `docs-migration-backlog.md`
   - `LATEST_STATE.md`

## 라우팅 계약
- `/rays/ui/{group}/{page}` 직접 접근 시 200 응답이어야 한다.
- 관련 구현 위치
  - `src/main/frontend/src/app/AppRoutes.js`
  - `src/main/frontend/src/pages/main/MainPage.js`

## 마일스톤 검증 (요청 시만)
1. `docs/project-docs/README_FRONTEND_BUILD_DEPLOY.md` 절차로 build -> copy -> publish 수행
2. `/rays/ui`, `/rays/ui/`, `/rays/ui/<deep-route>` 응답 및 라우팅 계약 확인
3. 콘솔 basename 오류/404 여부 확인

## Post-Run (자동화 종료 직후)
1. 실행 결과 확인
   - 최신 로그: `automation/logs/run-*.json`
   - 자동 피드백: `docs/project-docs/MIGRATION_AUTOMATION_FEEDBACK.md`
2. 문서 동기화
   - `LATEST_STATE.md`, `TASK_BOARD.md`, `docs-migration-backlog.md`에 실패 코드/우회/최종 성공 경로 반영
3. migration-kit 최신화
   - `powershell -ExecutionPolicy Bypass -File automation/package-migration-kit.ps1 -ProjectRoot <root>`
   - `powershell -ExecutionPolicy Bypass -File automation/package-migration-kit.ps1 -ProjectRoot <root> -Minimal`
4. 패키지 정리
   - `dist/migration-kit`에는 최신 타임스탬프 full/minimal zip + staging 1세트만 유지
   - 구버전 zip/staging 및 더미 산출물 삭제

## 결과 보고 형식
- 변경 파일 목록
- 반영한 패리티 항목
- 검증 캡처 파일명
- 남은 갭과 다음 액션 (1~3개)
