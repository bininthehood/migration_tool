# Migration Automation Repository

이 저장소는 레거시 프로젝트 루트에서 직접 checkout 받아 실행하는 마이그레이션 자동화 운영 저장소다.

## 기본 운영 방식
- 대상 legacy 프로젝트 루트에 이 저장소를 checkout 또는 pull 해서 최신 자동화 스크립트를 반영한다.
- 기본 실행 위치는 legacy 프로젝트 루트다.
- 자동화 결과는 legacy 프로젝트의 문서와 로그에 반영한다.

## 포함 범위
- `automation/` : 실행, 검증, 문서 동기화 스크립트
- `AGENTS.md`, `WORKFLOW.md` : 운영 규칙
- `LATEST_STATE.md`, `TASK_BOARD.md`, `docs-migration-backlog.md` : 상태 기준선
- `docs/project-docs/MIGRATION_AUTOMATION_FEEDBACK.md` : 자동화 실행 피드백

## 권장 실행 흐름
1. 대상 프로젝트 루트에서 이 저장소 내용을 최신으로 맞춘다.
2. `AGENTS.md`와 `WORKFLOW.md`를 읽는다.
3. `automation/run-all.ps1`를 실행한다.
4. 결과 로그와 피드백 문서를 검토한다.

## Quick Start
기본 실행:

```powershell
powershell -ExecutionPolicy Bypass -File automation/run-all.ps1 `
  -ProjectRoot <legacy-project-root> `
  -TomcatControlAction restart `
  -MigrateBatch all `
  -CaptureMode preset `
  -CapturePreset all `
  -CaptureBaseUrl http://localhost:8080 `
  -FrontendBuildTimeoutSec 1800 `
  -SkipReactFunctionCommenting
```

캡처가 막히는 경우:

```powershell
powershell -ExecutionPolicy Bypass -File automation/run-all.ps1 `
  -ProjectRoot <legacy-project-root> `
  -TomcatControlAction restart `
  -MigrateBatch all `
  -CaptureMode none `
  -FrontendBuildTimeoutSec 1800 `
  -SkipReactFunctionCommenting
```

실행 후 확인:
- `automation/logs/run-*.json`
- `docs/project-docs/MIGRATION_AUTOMATION_FEEDBACK.md`
- `automation/next-session-manifest.json`

운영 메모:
- `react-scripts` 같은 프론트 의존성이 없으면 자동 의존성 단계에서 복구한다.
- `dist/migration-kit`은 오프라인 전달이 필요할 때만 예외적으로 사용한다.

## 패키징 정책
- 기본 배포 방식은 git checkout/pull 이다.
- `dist/migration-kit` 패키징은 오프라인 전달이나 외부 반출이 필요한 경우에만 예외적으로 사용한다.
- `dist/migration-kit/*.zip`, `*-staging/` 등 산출물은 커밋하지 않는다.
