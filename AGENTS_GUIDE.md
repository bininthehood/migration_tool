# AGENTS_GUIDE.md — 사람용 참고 문서

> 자동화 에이전트용 규칙은 `AGENTS.md`를 참조하세요.
> 이 문서는 팀원 및 수동 작업 시 참고용입니다.

---

## 초기 설정 절차 (최초 1회 — 새 레거시 프로젝트 적용 시)

> **이 단계는 `src/main/frontend`와 `src/main/webapp/ui`가 없는 순수 레거시 프로젝트에 migration_tool을 처음 적용할 때 반드시 실행한다.**

### Step 1 — 프론트엔드 프로젝트 생성 및 의존성 설치

```bash
# WSL / Linux
bash migration_tool/automation/bootstrap-frontend.sh \
  --project-root <legacy-project-root> \
  --apply \
  --install-deps
```

```powershell
# Windows PowerShell
powershell -ExecutionPolicy Bypass -File migration_tool\automation\bootstrap-frontend.ps1 `
  -ProjectRoot <legacy-project-root> `
  -Apply `
  -InstallDeps
```

결과: `src/main/frontend/` (package.json 포함) + `src/main/webapp/ui/` 폴더 생성, npm install 완료.

> `/run-automation` 실행 시 자동으로 수행됩니다 (`setup_required.frontend_dir_missing: true` 감지 시).

### Step 2 — Spring MVC SPA 라우팅 설정

`src/main/webapp/WEB-INF/config/springmvc/dispatcher-servlet.xml` 에 추가:

```xml
<mvc:resources mapping="/ui/**" location="/ui/"/>
<mvc:default-servlet-handler />
<mvc:view-controller path="/ui" view-name="redirect:/ui/"/>
<mvc:view-controller path="/ui/" view-name="forward:/ui/index.html"/>
<mvc:resources mapping="/static/**" location="/ui/static/"/>
<mvc:resources mapping="/manifest.json" location="/ui/"/>
<mvc:resources mapping="/favicon.ico" location="/ui/"/>
```

`SpaForwardController.java` 생성 (AGENTS.md Java 컨트롤러 필수 조건 참조).
`ViewController.java` 레거시 매핑에서 `ui` 제외 확인 (`^(?!ui$).+`).

### Step 3 — 초기 빌드 및 배포 확인

```bash
cd src/main/frontend
npm run build
# build/ → src/main/webapp/ui/ 복사
# Eclipse WTP → Tomcat Clean + Publish + Restart
# GET http://<host>/<context-path>/ui/ → 200
```

영문 요약: Bootstrap frontend, configure Spring SPA routing, build and deploy once to Tomcat.

---

## 빌드/동기화 절차

1. `cd src/main/frontend`
2. `npm run build`
3. `src/main/frontend/build/*` → `src/main/webapp/ui/` 복사
4. Tomcat(Eclipse WTP)에서 Clean + Publish + Restart

영문 요약: Build CRA, copy to webapp/ui, republish Tomcat.

---

## 팀 공유용 실행 프로세스 (권장)

목적: 팀원은 명령 블록을 직접 공유받기보다, 대상 legacy 프로젝트 루트에 자동화 저장소를 직접 checkout/pull 한 뒤 AI 지시문으로 동일 프로세스를 실행한다.

1. 팀원이 대상 legacy 프로젝트 루트에 이 자동화 저장소 최신본을 checkout 또는 pull 한다.
2. **`src/main/frontend`가 없는 경우** → `/run-automation` 실행 시 자동으로 bootstrap됩니다.
3. 팀원이 프로젝트 루트에서 AI에 아래 지시문 전달

추천 AI 지시문:
- `AGENTS.md를 읽고 /run-automation을 실행해줘.`

운영 규칙:
- 프로젝트별 화면 매핑이 다르면 `automation/migration-screen-map.json`을 먼저 수정한다.
- 기본 배포는 git checkout/pull 이고, zip 패키지는 오프라인 전달이 필요한 경우에만 사용한다.
- 실행 결과는 `automation/logs/run-*.json` 기준으로 성공/실패를 판단한다.
- 자동 생성 함수 주석은 **한글 필수**로 작성한다.

자동화 종료 후 필수 후속 작업(Post-Run):
- `docs/project-docs/MIGRATION_AUTOMATION_FEEDBACK.md`와 최신 `automation/logs/run-*.json`을 확인해 실패 코드/우회 조치를 정리한다.
- 이번 실행 피드백을 `LATEST_STATE.md`, `TASK_BOARD.md`, `docs-migration-backlog.md`에 즉시 반영한다.

---

## 검증 체크리스트

- `GET /<context-path>/ui` → `/<context-path>/ui/`로 redirect 후 200
- `GET /<context-path>/ui/` → 200 (`index.html`)
- `GET /<context-path>/ui/static/js/*.js` → 200
- `GET /<context-path>/ui/static/css/*.css` → 200
- `GET /<context-path>/ui/<deep-route>` → 200 (`index.html`)
- 로그인 세션 기준 API 계약 검증:
  - `POST /<context-path>/user/v1/policyCheck` → `resultCode=0`
  - `POST /<context-path>/user/v1/sessionAlive` → `resultCode=0`
  - `POST /<context-path>/user/v1/sessionInfo` → `resultCode=0`
  - `sessionInfo.sessionData.siteCode/levelCode/userId` 필수값 존재
- Browser Console에 아래 에러가 없어야 함:
  - `<Router basename="/ui"> ... URL "/<context-path>/ui" ... won't render`

영문 요약: Verify redirect, SPA entry, static assets, deep-link fallback, and no basename mismatch error.
