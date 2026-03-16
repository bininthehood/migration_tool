# 현재 프로젝트 상태 (최종 업데이트: YYYY-MM-DD)

## 진행 단계
인벤토리(Inventory) — Phase 0 미착수

## 마이그레이션 진행률
0% (0개 / ? 개 화면 완료)

## 선행 작업 상태

| 항목 | 상태 | 비고 |
|---|---|---|
| `src/main/frontend` | **미생성** | bootstrap-frontend 실행 필요 |
| `dispatcher-servlet.xml` SPA 라우팅 | **미설정** | Phase 0 완료 후 설정 |
| `SpaForwardController.java` | **미생성** | Phase 0 완료 후 생성 |
| JSP 화면 (기능) | **인벤토리 미완료** | Phase 1에서 목록화 |
| npm 의존성 | **미설치** | bootstrap-frontend --install-deps 필요 |

## JSP 인벤토리 (이관 대상)

Phase 1 완료 후 여기에 화면 목록이 추가됩니다.

## 남은 핵심 작업

1. **bootstrap-frontend 실행**: `bash migration_tool/automation/bootstrap-frontend.sh --apply --install-deps`
2. **Phase 0 완료**: SPA 라우팅 설정, 초기 빌드 확인
3. **Phase 1 (인벤토리)**: JSP/API/컨트롤러 매핑 전체 목록 작성
4. **Phase 2 (병행 운영)**: CRA 기반 React 앱 구조 설계
5. **Phase 3 (전환)**: 화면 단위 JSP → React 이관
