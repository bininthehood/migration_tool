JSP 화면을 React로 마이그레이션할 때 체크리스트를 생성합니다.

## 사용법

```
/migrate-screen <LegacyUrl> <ReactRoute>
```

예시:
```
/migrate-screen /rays/user/list.do /ui/user/list
```

## 실행 절차

인자: $ARGUMENTS

1. 인자에서 LegacyUrl(첫 번째)과 ReactRoute(두 번째)를 파싱합니다.
2. migration_tool_root를 동적으로 계산합니다:
   ```bash
   MIGRATION_TOOL_ROOT=$(wslpath -w "$(pwd)")
   ```
3. Bash 도구로 아래 명령을 실행합니다:
   ```bash
   pwsh -ExecutionPolicy Bypass -File "$(pwd)/automation/skills/jsp-react-screen-migrator/scripts/migrate-screen-checklist.ps1" \
     -ProjectRoot "$(wslpath -w "$(pwd)")" \
     -LegacyUrl "<LegacyUrl>" \
     -ReactRoute "<ReactRoute>"
   ```
4. 출력된 체크리스트 내용을 사용자에게 표시합니다.
5. 파일로 저장하려면 `-OutputPath` 경로를 지정해 재실행합니다.
