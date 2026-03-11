# 기여 가이드

## 목적
이 저장소는 레거시 프로젝트 마이그레이션 자동화 킷의 실행 피드백을 빠르게 반영하고, 재사용 가능한 업그레이드를 축적하는 것을 목표로 합니다.

## 기본 원칙
- 작은 단위로 변경하고, 실행 가능한 상태를 유지합니다.
- 실행 결과 근거(로그/캡처/재현 절차)를 함께 남깁니다.
- 세션/권한/라우팅 계약은 회귀가 없도록 우선 검증합니다.

## 작업 절차
1. 이슈 생성 또는 기존 이슈 연결
2. 브랜치 생성 (`feat/...`, `fix/...`, `docs/...`)
3. 수정 후 로컬 검증
4. 문서 동기화 (`MIGRATION_AUTOMATION_FEEDBACK.md` 등)
5. PR 생성

## 권장 검증
- `automation/run-all.ps1` 실행 결과 확인
- `automation/logs/run-*.json` 실패 코드 확인
- session 계약: `policyCheck -> sessionAlive -> sessionInfo` + 필수값 검증

## 커밋 메시지 예시
- `fix: enforce sessionInfo guard before login redirect`
- `feat: improve comment annotation rules for migrated React functions`
- `docs: update migration feedback and workflow`