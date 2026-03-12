프로젝트 문서 상태를 확인하고 현재 Phase와 다음 작업을 파악합니다.

## 사용법

```
/bootstrap
```

## 실행 절차

1. migration_tool_root를 동적으로 계산합니다:
   ```bash
   MIGRATION_TOOL_ROOT=$(wslpath -w "$(pwd)")
   ```
2. Bash 도구로 아래 명령을 실행합니다:
   ```bash
   pwsh -ExecutionPolicy Bypass -File "$(pwd)/automation/skills/legacy-migration-bootstrap/scripts/bootstrap.ps1" \
     -ProjectRoot "$(wslpath -w "$(pwd)")"
   ```
3. 출력 결과를 사용자에게 표시합니다:
   - ProjectRoot
   - Phase (LATEST_STATE.md에서 추출)
   - SelectedTask (다음 작업)
   - Documents 상태 (존재 여부)
