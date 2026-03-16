# AGENTS.md

## 프로젝트 개요
- 스택: Legacy Spring MVC 4.x (XML config), WAR packaging, Tomcat 9
- 프론트엔드: CRA React (`src/main/frontend`)
- SPA 배포 대상: `src/main/webapp/ui`
- DispatcherServlet mapping: `/`
- 로컬 contextPath: `/rays`
- 운영 contextPath: `/`

영문 요약: Legacy Spring MVC + CRA SPA under `/ui`, deployed as WAR on Tomcat.

## 최종 목표 (Migration North Star)
- 최종 목표: **기존 모든 JSP 화면을 React SPA(`/ui/...`)로 전환**한다.
- 전환 완료 기준:
  - 신규/기존 화면 진입 URL이 JSP가 아닌 React route로 통합됨
  - JSP ViewResolver 의존 화면이 0개가 됨(관리/로그인/메인 포함)
  - 서버는 API + 정적 리소스 서빙 역할 중심으로 축소됨

영문 요약: Migrate all JSP screens to React routes; backend becomes API/static-serving focused.

## 절대 원칙 (Non-Negotiable)
- Spring Boot로 전환하지 않고, 순수 Spring MVC XML 스타일을 유지한다.
- 기존 JSP 레거시 페이지 동작을 유지한다. (전환 완료 전까지)
- **마이그레이션 완료 전에는 `/login` 포함 기존 JSP 진입 URL/컨트롤러를 직접 전환하지 않는다.**
- 신규 React 화면은 `/ui/...`에 병행 구축하고, 최종 컷오버 시점에 일괄 이관한다.
- React `PUBLIC_URL`을 contextPath별 Maven profile로 분기하지 않는다.
- CRA `homepage`는 `.`(상대 경로)로 유지한다.
- React Router `basename`은 고정값(`"/ui"`)이 아니라 contextPath를 반영한 동적 계산이어야 한다.
- 화면 전환은 **점진적(Incremental)** 으로 수행하며, 매 단계 배포 가능 상태를 유지한다.

영문 요약: Keep XML MVC + JSP coexistence during migration; no context-specific PUBLIC_URL; dynamic basename; incremental rollout.

## 멀티 에이전트 워크플로 (통합)
- 본 프로젝트는 다중 에이전트 역할 분리를 전제로 협업한다.
- 핵심 목표는 **기존 시스템을 유지한 상태에서 점진 이관**하는 것이다.
- 금지 사항: 완료된 모듈 전체 재작성, 대규모 구조 재설계, 기존 라우팅 계약 위반.

### 역할 정의
- 플래너(Planner)
  - 프로젝트 맥락/문서/마이그레이션 이력 파악
  - 남은 작업을 단계별 작업 항목으로 분해
- 아키텍트(Architect)
  - 아키텍처 일관성/호환성 검증
  - 폴더 구조, 모듈 경계, API 계약 안정성 유지
- 마이그레이션(Migration)
  - 레거시를 React로 점진 전환
  - 작은 단위 변경 우선, 완료 영역 재작성 금지
- 백엔드(Backend)
  - Spring MVC + MyBatis + JSP 호환 유지
  - 기존 컨트롤러/서비스 계약 파괴 금지
- 프론트엔드(Frontend)
  - React 화면 구현 및 기존 API 연동
  - 레거시 동작 유지(완전 전환 전까지)
- 테스트(Test)
  - 신규/변경 기능 검증 및 회귀 방지
- 리뷰(Review)
  - 코드 품질, 회귀 리스크, 이관 일관성 점검

### 개발 원칙
1. 기존 작업을 이어서 진행한다.
2. 점진 이관(Incremental Migration)을 우선한다.
3. 큰 재작성보다 작은 변경을 선호한다.
4. 운영 안정성을 최우선으로 유지한다.
5. 하위 호환성을 유지한다.

## 라우팅 계약 (Routing Contract)
- `/ui`는 반드시 `/ui/`로 redirect 한다.
- `/ui/`는 `/ui/index.html`로 forward 한다.
- 확장자 없는 `/ui/**` deep route는 `/ui/index.html`로 forward 한다.
- `/ui/**` 정적 파일은 ResourceHandler가 직접 서빙한다.
- 레거시 JSP 라우트 `/{path}/{page}`는 `path=ui`를 제외해야 한다.

영문 요약: `/ui` redirect, `/ui/` + deep routes forward to SPA index, static served directly, legacy route excludes `ui`.

## Spring MVC XML 필수 조건
대상 파일: `src/main/webapp/WEB-INF/config/springmvc/dispatcher-servlet.xml`
- 필수 포함:
  - `<mvc:resources mapping="/ui/**" location="/ui/"/>`
  - `<mvc:default-servlet-handler />`
  - View controller:
    - `/ui` -> `redirect:/ui/`
    - `/ui/` -> `forward:/ui/index.html`
- 호환성 매핑(브라우저가 `/ui` 기준으로 root 자산을 잘못 요청할 때 404 방지):
  - `/static/**` -> `/ui/static/`
  - `/manifest.json`, `/favicon.ico`, `/logo192.png`, `/logo512.png`, `/robots.txt`, `/asset-manifest.json` -> `/ui/`

영문 요약: Ensure `/ui` resource and view-controller mappings, plus compatibility resource mappings.

## Java 컨트롤러 필수 조건
대상 파일: `src/main/java/com/rays/app/web/SpaForwardController.java`
- `/ui` redirect 핸들러
- `/ui/` index forward 핸들러
- 확장자 없는 `/ui/**` forward 핸들러

대상 파일: `src/main/java/com/rays/app/view/controller/ViewController.java`
- 레거시 매핑 유지:
  - `@RequestMapping(value="/{path:^(?!ui$).+}/{page}")`

영문 요약: Keep dedicated SPA forward controller and preserve legacy exclusion regex.

## 프론트엔드 필수 조건
대상 파일: `src/main/frontend/src/index.js`
- `window.location.pathname` 기반 dynamic basename resolver 사용
- 아래 두 케이스 모두 지원:
  - `/rays/ui` (local)
  - `/ui` (prod)
- 리다이렉트/이동 URL 정규화는 `src/main/frontend/src/routing/routeNormalizer.js`를 통해 일원화한다.

공통 세션 가드 규칙(모든 패키지 공통 적용):
- `/login` 자동 리다이렉트 판단 시 `sessionChecker` 단독 결과만 사용하지 않는다.
- 반드시 `/user/v1/sessionInfo`를 추가 조회하고 `sessionData.siteCode/levelCode/userId` 필수값 존재를 확인한 뒤에만 `/main`으로 이동한다.
- 필수값이 비어있거나 `null` 문자열이면 로그인 상태가 아니므로 `/login` 유지(또는 `/main`에서 즉시 `/login`으로 리다이렉트)한다.

영문 요약: Basename must be computed from runtime path to support both local/prod context paths.

## 단계별 전환 계획 (Step-by-Step)
1. 인벤토리 단계
- JSP URL/파일/컨트롤러 매핑 전체 목록 작성
- 화면별 API 의존성과 공통 컴포넌트(권한, 세션, 파일업로드) 분류

2. 병행 운영 단계
- 기존 JSP URL은 유지하되, 동일 기능 React route를 `/ui/...`에 신설
- 화면 단위로 전환 완료 후 URL 리다이렉트 정책 결정

3. 전환 단계
- 우선순위: 조회 화면 -> 등록/수정 화면 -> 관리자/설정 화면 -> 로그인/메인
- 각 화면 전환 시 JSP 템플릿/스크립트 의존 제거

4. 수렴 단계
- 미사용 JSP, ViewResolver 참조, 관련 컨트롤러 매핑 정리
- 에러 페이지/권한 흐름을 React 기준으로 통일

5. 완료 단계
- JSP 화면 0개 확인
- 운영 경로 `/ui/...` 단일화
- 회귀 테스트 통과 후 레거시 제거 확정

영문 요약: Inventory -> Parallel run -> Screen migration -> Cleanup -> Full cutover.

## 초기 설정 / 빌드 / 검증 체크리스트

> 사람용 참고 문서 → `AGENTS_GUIDE.md`

영문 요약: See AGENTS_GUIDE.md for bootstrap procedure, build steps, team workflow, and verification checklist.

## 신규 레거시 프로젝트 시작 시 주의사항 (실전 이슈 기반)
- 텍스트 인코딩은 UTF-8(무BOM)으로 고정한다. (한글 깨짐 + ESLint BOM 경고 예방)
- 화면 1개 착수 전 `npm run build` 1회로 문법/인코딩 기본 오류를 먼저 제거한다.
- `npm run dev` 전에 3000 포트 점유 여부를 확인한다. (기존 node 프로세스 충돌 예방)
- 브라우저 팝업 차단을 기본 리스크로 간주하고, 팝업 실패 시 대체 메시지/재시도 버튼을 제공한다.
- `/ui`, `/ui/`, `/ui/<deep-route>` 직접 접속/새로고침을 초기부터 함께 검증한다.
- 세션 시작 즉시 문서 기준선(`LATEST_STATE`, `TASK_BOARD`, `docs-migration-backlog`)을 동기화한 뒤 작업한다.

영문 요약: Enforce UTF-8 without BOM, run an early build, check dev port occupancy, design popup fallback UX, validate deep-links early, and sync baseline docs first.

## 한글 인코딩 가이드라인 (필수)
- 문서/소스 파일(`*.md`, `*.js`, `*.jsx`, `*.ts`, `*.tsx`, `*.java`, `*.xml`, `*.jsp`)은 UTF-8(무BOM)만 사용한다.
- PowerShell로 파일 저장 시 기본 인코딩(`Out-File`, `Set-Content` 기본값) 사용을 금지한다.
- PowerShell 저장 예시(무BOM):
  - `$enc = New-Object System.Text.UTF8Encoding($false)`
  - `[System.IO.File]::WriteAllText($path, $content, $enc)`
- 쉘 치환(`-replace`)로 대량 문자열을 직접 주입하지 않는다. 긴 문서 변경은 `apply_patch` 또는 명시적 UTF-8 저장으로 처리한다.
- 커밋 전 한글 깨짐 패턴을 점검한다. (예: `�`, `??`, 비정상 mojibake 문자열)
- 한글 깨짐이 발견되면 즉시 해당 파일 작업을 중단하고, 기준본(`git show HEAD:<file>`)으로 비교 후 복구한다.

영문 요약: Use UTF-8 without BOM, avoid shell-default encodings, write files with explicit UTF-8, avoid risky bulk replace, and run mojibake checks before commit.

## 화면 전환 완료 정의 (Definition of Done per Screen)
- React route 구현 완료
- 기존 JSP와 기능/검증 데이터 동등성 확인
- 권한/세션/에러 처리 동등성 확인
- 새로고침(deep-link) 및 직접접속 200 확인
- 운영 로그/에러 모니터링 이상 없음

영문 요약: Each screen must meet feature parity, routing stability, and operational checks.

## 에이전트 작업 정책 (Change Policy)
- 기존 파일을 최소 수정하는 방향을 우선한다.
- 라우팅 변경 전 반드시 아래 파일을 확인한다:
  - `web.xml`
  - `dispatcher-servlet.xml`
  - `SpaForwardController.java`
  - 레거시 `/{path}/{page}` 컨트롤러
- 변경 후 반드시 파일 단위 diff/스니펫과 검증 URL을 함께 남긴다.
- 매 턴 시작 시 현재 단계(인벤토리/병행운영/전환/수렴/완료)를 명시한다.
- 세부 실행 순서와 문서 우선순위는 루트 `WORKFLOW.md`를 따른다.

영문 요약: Make minimal edits, inspect key routing files first, report diffs + verification URLs, and always state current migration phase.

<!-- meta-agent added: 2026-03-13 -->
## 자동화 실행 환경 주의사항 (WSL + Windows Tomcat)

- 자동화 스크립트(`run-all.sh`)는 WSL 환경에서 실행되며, Tomcat은 Windows 측에서 동작한다.
- WSL 자동화에서 Tomcat이 접근 불가능한 경우 `--skip-tomcat-check --skip-session-contract-check` 플래그로 해당 단계를 우회할 수 있다.
- CRA 표준 진입점(`public/index.html`, `src/index.js`)이 없으면 `npm run build`가 실패하므로 `--skip-frontend-compile-check` 플래그로 우회한다.
- 위 3개 플래그를 모두 사용한 실행이 "Phase 0 검증 통과 기준"이 될 수 있다 (Tomcat/빌드 없이 라우팅·문서·세션 가드 패턴만 검증).

## bootstrap.sh 경로 규약

- `automation/skills/legacy-migration-bootstrap/scripts/bootstrap.sh`는 `$PROJECT_ROOT/` 및 `$PROJECT_ROOT/migration_tool/` 양쪽에서 상태 문서를 탐색한다.
- 프로젝트 루트와 migration_tool 루트가 분리된 구조(legacy project root / migration_tool 하위)에서 AGENTS.md, WORKFLOW.md, LATEST_STATE.md, TASK_BOARD.md, docs-migration-backlog.md 는 모두 `migration_tool/` 하위에 위치한다.
- 위 파일들이 프로젝트 루트에 없어도 `migration_tool/` 하위에 있으면 정상으로 판단한다.

## validate-skill-integration.sh 실행 환경 주의사항

- `validate-skill-integration.sh` 는 `$PROJECT_ROOT/docs/project-docs/` 디렉토리에 `find` 명령을 실행한다.
- 해당 디렉토리가 없으면 `set -o pipefail`로 인해 스크립트 전체가 중단된다.
- 레거시 프로젝트 루트에 `docs/project-docs/` 디렉토리가 없는 경우 사전에 생성해야 한다: `mkdir -p $PROJECT_ROOT/docs/project-docs`

영문 요약: WSL automation can skip Tomcat/compile checks; bootstrap.sh searches both project root and migration_tool/; always pre-create docs/project-docs/ at project root.

<!-- meta-agent added: 2026-03-16 -->
## 오케스트레이터 Phase 완료 구분 주의사항

- `run-all.sh` 6/6 PASS(또는 N/N PASS)는 **검증 단계 통과**를 의미하며, **마이그레이션 작업 완료**를 의미하지 않는다.
- 오케스트레이터의 Step 2 SUCCESS 조건이 "Phase A 검증 PASS"와 "전체 세션(Phase B migration-agent 포함) 완료"를 혼동할 수 있다.
- Phase A(자동화 검증: Mojibake, Bootstrap, Dependencies, Routing, Session 등) PASS 후에는 **반드시 Phase B(migration-agent) 실행 여부를 별도로 확인**해야 한다.
- 자동화 루프가 Phase A PASS에서 종료될 경우, Phase B는 **미실행** 상태이므로 다음 세션에서 명시적으로 착수해야 한다.
- `COMPLETION_REPORT.md`의 "Phase State at Completion" 항목에서 Phase 1/2/3 착수 여부를 반드시 확인한다. "Phase 2/3: 미착수" 상태이면 migration-agent는 실행되지 않은 것이다.

영문 요약: N/N PASS in run-all.sh means validation checks passed, NOT migration work completed. Always verify Phase B (migration-agent) execution separately after Phase A validator success.

<!-- meta-agent added: 2026-03-16 -->
## 검증 통과 후 수동 단계 (Human Gate)

- Phase A 검증(8/8 PASS) 통과 후 Phase 3 화면 마이그레이션을 시작하기 전에 반드시 다음 2가지 수동 단계를 완료해야 한다:
  1. `cd src/main/frontend && npm run build` 실행 → `../webapp/ui/` 빌드 산출물 생성
  2. Eclipse WTP 재배포 후 `GET /<context-path>/ui/` → 200 응답 확인
- 이 2단계는 WSL 자동화 환경에서 수행 불가능하며(Windows Tomcat 접근 제약), 인프라 일관성 보증을 위해 수동 확인이 필수이다.
- TASK_BOARD.md의 Phase 0 마지막 항목 `[ ] GET /<context-path>/ui/ → 200 확인` 완료까지 기다린 후 Phase 3 착수.

영문 요약: After Phase A PASS, perform npm build and Tomcat verification manually before starting Phase 3 migration.
