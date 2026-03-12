React 화면 캡처(QA 스크린샷)를 실행합니다.

## 사용법

```
/capture-qa
/capture-qa single /ui/login login-page
/capture-qa preset all
```

## 인자

| 인자 | 설명 |
|------|------|
| `single <path> <name>` | 단일 경로 캡처 |
| `preset <name>` | 프리셋 캡처 (기본값: all) |
| 인자 없음 | preset all 실행 |

## 실행 절차

인자: $ARGUMENTS

1. 인자를 파싱해 Mode(single/preset), Path, Name, Preset을 결정합니다.
2. migration_tool_root를 동적으로 계산합니다:
   ```bash
   MIGRATION_TOOL_ROOT=$(wslpath -w "$(pwd)")
   ```
3. Bash 도구로 아래 명령을 실행합니다:
   ```bash
   # preset 모드 예시
   pwsh -ExecutionPolicy Bypass -File "$(pwd)/automation/skills/react-capture-qa-runner/scripts/run-capture.ps1" \
     -ProjectRoot "$(wslpath -w "$(pwd)")" \
     -Mode preset \
     -Preset all

   # single 모드 예시
   pwsh -ExecutionPolicy Bypass -File "$(pwd)/automation/skills/react-capture-qa-runner/scripts/run-capture.ps1" \
     -ProjectRoot "$(wslpath -w "$(pwd)")" \
     -Mode single \
     -Path "/ui/login" \
     -Name "login-page"
   ```
4. 생성된 캡처 파일 목록을 사용자에게 표시합니다.
