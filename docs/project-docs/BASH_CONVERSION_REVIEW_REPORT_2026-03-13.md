# Bash Conversion Review Report

## 메타
- 작성일: 2026-03-13
- 현재 단계: `Transition`
- 기준 문서: `migration_tool/docs/project-docs/BASH_CONVERSION_GUIDE.md`
- 목적: 다른 에이전트가 이번 bash 전환 작업을 빠르게 점검하고 후속 조치를 이어갈 수 있도록 변경 범위와 검증 상태를 정리한다.

## 작업 범위
- 가이드에 명시된 남은 변환 대상 5건을 기준으로 작업했다.
- 실제 반영 범위:
  - `automation/tomcat-control.sh` 신규 추가
  - `automation/verify-session-contract.sh` 신규 추가
  - `automation/bootstrap-frontend.sh` 신규 추가
  - `automation/annotate-react-functions.py` 신규 추가
  - `automation/annotate-react-functions.sh` 신규 추가
  - `automation/run-all.sh` 신규 추가
  - 위 대상과 대응되는 `.ps1`는 thin wrapper 형태로 교체

## 변경 파일
- 신규 bash/Python 파일
  - `migration_tool/automation/tomcat-control.sh`
  - `migration_tool/automation/verify-session-contract.sh`
  - `migration_tool/automation/bootstrap-frontend.sh`
  - `migration_tool/automation/annotate-react-functions.py`
  - `migration_tool/automation/annotate-react-functions.sh`
  - `migration_tool/automation/run-all.sh`
- thin wrapper로 교체한 PowerShell 파일
  - `migration_tool/automation/tomcat-control.ps1`
  - `migration_tool/automation/verify-session-contract.ps1`
  - `migration_tool/automation/bootstrap-frontend.ps1`
  - `migration_tool/automation/annotate-react-functions.ps1`
  - `migration_tool/automation/run-all.ps1`

## 구현 요약
- `tomcat-control.sh`
  - `status/start/stop/restart` 지원
  - `curl` 기반 health check 및 polling 구현
  - `CATALINA_HOME`, `CATALINA_BASE`, `JRE_HOME` 환경 변수를 설정한 뒤 `startup.sh`, `shutdown.sh` 실행
- `verify-session-contract.sh`
  - `curl + jq + python3(url encode)` 조합으로 `policyCheck -> sessionAlive -> sessionInfo` 순서 검증
  - `sessionData.siteCode/levelCode/userId` 필수값 확인
- `bootstrap-frontend.sh`
  - dry-run 상태표 출력 지원
  - 필요한 디렉토리/파일 스캐폴딩
  - 템플릿 경로가 있으면 복사, 없으면 fallback `package.json` 및 `capture-react.cjs` 생성
- `annotate-react-functions.py`
  - top-level 함수 정의를 감지해서 자동 주석을 UTF-8 무BOM으로 정리
  - 기존 자동 생성 주석 제거 후 재생성
- `run-all.sh`
  - 가이드의 오케스트레이션 방향대로 하위 bash 스크립트를 연결
  - step 추적, 에러 코드 분류, `automation/logs/run-*.json` 작성
  - `docs/project-docs/MIGRATION_AUTOMATION_FEEDBACK.md`, `automation/next-session-manifest.json` 갱신
  - `run-doc-sync.sh` 연동 포함

## 점검 포인트
- `run-all.sh`는 기존 PowerShell 오케스트레이션을 1:1 완전 이식하기보다, 이미 bash 전환된 하위 스크립트를 중심으로 재구성했다.
- `run-all.sh`는 `Git Commit` 옵션을 파싱하지만 실제 git commit 단계는 아직 미구현 상태로 남겨 두었다.
- `run-all.ps1` wrapper는 주요 인자를 `run-all.sh`로 전달하도록 교체했다.
- Windows 경로 인자는 `.ps1` wrapper에서 `wslpath`로 변환하도록 맞췄다.

## 수행 검증
- 문법 검증
  - `bash -n migration_tool/automation/tomcat-control.sh`
  - `bash -n migration_tool/automation/verify-session-contract.sh`
  - `bash -n migration_tool/automation/bootstrap-frontend.sh`
  - `bash -n migration_tool/automation/annotate-react-functions.sh`
  - `bash -n migration_tool/automation/run-all.sh`
  - `python3 -m py_compile migration_tool/automation/annotate-react-functions.py`
- 실행 검증
  - `bash migration_tool/automation/bootstrap-frontend.sh --project-root /mnt/c/users/rays/ArcFlow_Webv1.2`
    - 결과: dry-run 정상 출력
  - `bash migration_tool/automation/annotate-react-functions.sh --project-root /mnt/c/users/rays/ArcFlow_Webv1.2 --target-root migration_tool/automation`
    - 결과: `ANNOTATE_FILES_CHANGED=0`, `ANNOTATE_COMMENTS_ADDED=0`
  - `bash migration_tool/automation/tomcat-control.sh --action restart ... --no-health-check`
    - 결과: 임시 mock 디렉토리 기준 실행 확인

## 미완료 또는 환경 제약
- 현재 WSL 실행 환경에는 `jq`가 없다.
  - 영향:
    - `verify-session-contract.sh` 실검증 중단
    - `run-all.sh` 최소 실행 검증 중단
  - 실제 관측 메시지:
    - `Error: jq required`
- 따라서 이번 세션에서는 "문법 및 부분 실행 확인"까지 완료했고, "전체 오케스트레이션 런타임 확인"은 보류 상태다.

## 다른 에이전트용 즉시 점검 절차
1. `jq` 설치 여부부터 확인한다.
2. 아래 명령으로 bash 문법 검증을 다시 확인한다.
```bash
bash -n migration_tool/automation/tomcat-control.sh
bash -n migration_tool/automation/verify-session-contract.sh
bash -n migration_tool/automation/bootstrap-frontend.sh
bash -n migration_tool/automation/annotate-react-functions.sh
bash -n migration_tool/automation/run-all.sh
python3 -m py_compile migration_tool/automation/annotate-react-functions.py
```
3. 아래 명령으로 최소 실행을 확인한다.
```bash
bash migration_tool/automation/bootstrap-frontend.sh --project-root /mnt/c/users/rays/ArcFlow_Webv1.2
bash migration_tool/automation/annotate-react-functions.sh --project-root /mnt/c/users/rays/ArcFlow_Webv1.2 --target-root migration_tool/automation
bash migration_tool/automation/run-all.sh \
  --project-root /mnt/c/users/rays/ArcFlow_Webv1.2/migration_tool \
  --capture-mode none \
  --skip-session-contract-check \
  --skip-tomcat-check \
  --skip-doc-sync \
  --skip-frontend-compile-check \
  --disable-auto-install-frontend-deps
```
4. `jq` 설치 후에는 아래 순서로 실제 기능 검증을 이어간다.
```bash
bash migration_tool/automation/verify-session-contract.sh \
  --project-root /mnt/c/users/rays/ArcFlow_Webv1.2 \
  --base-url http://localhost:8080 \
  --context-path /rays \
  --user admin \
  --password admin

bash migration_tool/automation/run-all.sh \
  --project-root /mnt/c/users/rays/ArcFlow_Webv1.2/migration_tool \
  --capture-mode none
```

## 주요 파일 위치
- 가이드 원문: `migration_tool/docs/project-docs/BASH_CONVERSION_GUIDE.md`
- 오케스트레이션 구현: `migration_tool/automation/run-all.sh`
- 세션 계약 검증: `migration_tool/automation/verify-session-contract.sh`
- Tomcat 제어: `migration_tool/automation/tomcat-control.sh`
- 주석 자동화: `migration_tool/automation/annotate-react-functions.py`

## 결론
- 가이드에 적힌 bash 전환 대상은 파일 기준으로 모두 생성 또는 wrapper 교체를 마쳤다.
- 현재 남은 핵심 리스크는 코드 문법이 아니라 실행 환경 의존성 `jq`와 실제 런타임 통합 검증이다.
- 다음 에이전트는 `jq` 준비 후 `run-all.sh` 실제 실행 결과와 PowerShell wrapper 인자 전달 일치 여부를 우선 점검하면 된다.
