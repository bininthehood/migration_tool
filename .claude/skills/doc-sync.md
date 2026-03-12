세션 작업 내역을 SESSION_WORKLOG에 추가합니다.

## 사용법

```
/doc-sync
```

변경 파일, 실행 커맨드, 캡처 목록을 입력받아 가장 최근 SESSION_WORKLOG_*.md에 추가합니다.

## 실행 절차

인자: $ARGUMENTS

1. 인자가 없으면 사용자에게 아래 항목을 질문합니다:
   - 변경된 파일 목록 (콤마 구분)
   - 실행한 커맨드 목록 (콤마 구분)
   - 캡처 파일 목록 (없으면 생략)

2. migration_tool_root를 동적으로 계산합니다:
   ```bash
   MIGRATION_TOOL_ROOT=$(wslpath -w "$(pwd)")
   ```

3. Bash 도구로 아래 명령을 실행합니다 (수집한 값을 채워 넣음):
   ```bash
   pwsh -ExecutionPolicy Bypass -File "$(pwd)/automation/skills/migration-doc-sync/scripts/sync-doc-stub.ps1" \
     -ProjectRoot "$(wslpath -w "$(pwd)")" \
     -ChangedFiles "<file1>","<file2>" \
     -Commands "<cmd1>","<cmd2>" \
     -Captures "<cap1>" \
     -Apply
   ```

4. 결과를 사용자에게 보고합니다.
