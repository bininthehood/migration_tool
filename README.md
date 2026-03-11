# Legacy Migration Kit - Agent Feedback & Upgrade

이 저장소는 `레거시 프로젝트 마이그레이션 킷 - 에이전트가 피드백 및 업그레이드 하는` 자동화 자산을 별도로 버전 관리하기 위한 레포입니다.

## 포함 범위
- `automation/` : 실행/검증/패키징 스크립트
- `AGENTS.md`, `WORKFLOW.md` : 운영 규칙
- `LATEST_STATE.md`, `TASK_BOARD.md`, `docs-migration-backlog.md` : 상태 기준선
- `docs/project-docs/MIGRATION_AUTOMATION_FEEDBACK.md` : 실행 피드백 이력

## 운영 원칙
- 소스(스크립트/문서)만 Git으로 관리
- `dist/migration-kit/*.zip`, `*-staging/` 등 산출물은 커밋하지 않음
- 릴리스 시 태그 예시: `kit-vYYYYMMDD-HHMM`

## 빠른 시작
1. 변경 반영
2. `automation/run-all.ps1` 검증 실행
3. `automation/package-migration-kit.ps1`로 패키지 생성
4. 태그/릴리스 배포