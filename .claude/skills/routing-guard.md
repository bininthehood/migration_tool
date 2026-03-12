Spring MVC + React SPA 라우팅 계약이 올바르게 구성되어 있는지 검증합니다.

## 사용법

```
/routing-guard
```

## 검증 항목

| 항목 | 파일 |
|------|------|
| `/ui/**` resources 설정 | dispatcher-servlet.xml |
| default-servlet-handler 설정 | dispatcher-servlet.xml |
| `/ui` → redirect `/ui/` | dispatcher-servlet.xml |
| `/ui/` → forward `/ui/index.html` | dispatcher-servlet.xml |
| SPA redirect `/ui/` | SpaForwardController.java |
| SPA index forward | SpaForwardController.java |
| deep route `/ui/**` 매핑 | SpaForwardController.java |
| legacy controller에서 ui 경로 제외 | ViewController.java |

## 실행 절차

1. project_root를 동적으로 계산합니다 (migration_tool의 부모):
   ```bash
   PROJECT_ROOT=$(wslpath -w "$(dirname "$(pwd)")")
   ```
2. Bash 도구로 아래 명령을 실행합니다:
   ```bash
   pwsh -ExecutionPolicy Bypass -File "$(pwd)/automation/skills/springmvc-spa-routing-guard/scripts/check-routing-contract.ps1" \
     -ProjectRoot "$(wslpath -w "$(dirname "$(pwd)")")" \
     -NoFail
   ```
3. 결과 테이블을 표시하고 실패 항목이 있으면 수정 방향을 안내합니다.
