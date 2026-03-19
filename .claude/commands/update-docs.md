세션 후 template 파일(문서·설정·git)을 정리하고 커밋합니다.

사용 시점: migration 작업 또는 자동화 루프를 마친 뒤 배운 점이 있을 때 수동 실행.

## Step 0 — 경로 계산

```bash
echo "migration_tool_root: $(pwd)"
echo "project_root: $(dirname "$(pwd)")"
```

## Step 1 — 변경 현황 파악

아래 명령을 실행해 현재 상태를 수집합니다:

```bash
# template 파일 변경 현황
git status
git diff HEAD

# 최신 실행 로그 (있으면)
ls -t automation/logs/run-*.json 2>/dev/null | head -1 | xargs -I{} cat {}
```

수집 후 변경된 파일 목록을 사용자에게 보여주고 계속 진행합니다.

## Step 2 — gitignore 점검

**Untracked 파일 분류:**

```bash
git ls-files --others --exclude-standard
```

출력 파일을 아래 두 기준으로 분류합니다:
- **gitignore 추가 필요**: 세션 생성 산출물, 로그, 다이어그램 등 — `.gitignore`에 패턴 추가
- **커밋 필요**: template 파일 (agent 프롬프트, 스크립트, 패턴 문서 등)

**Tracked 파일 중 gitignore해야 할 항목 확인:**

```bash
# gitignore에 있는데 여전히 tracked된 파일
git ls-files -i --exclude-standard
```

출력이 있으면 `git rm --cached <file>` 처리 후 사용자에게 보고합니다.

## Step 3 — CLAUDE.md 개선 (해당 시)

이번 세션에서 발견한 패턴을 CLAUDE.md에 추가합니다.

**추가 대상:**
- 반복 실패 패턴 → "Non-Negotiable Rules" 또는 관련 섹션
- 새 라우팅/세션/인코딩 이슈 → 관련 섹션
- validate-skill-integration.sh 등 검증 스크립트 변경 이유

**절대 금지 (template 오염 방지):**
- 프로젝트 특정 절대경로 (`/home/...`) 하드코딩
- 날짜 기반 섹션명 ("Known State Drift Pattern 2026-03-19" 등)
- 특정 화면 파일명 (`LoginPage.js`, `MainPage.jsx` 등)
- 복구 지침이 특정 사건에만 유효한 경우

경로가 필요하면 `{project_root}`, `{page_name}` 플레이스홀더 사용.

## Step 4 — .claude/agents/*.md 개선 (해당 시)

명확한 패턴이 있을 때만 업데이트합니다:

- 반복 실패 원인이 agent prompt 누락 → 해당 section에 추가
- 불필요한 파일 읽기 패턴 발견 → skip 힌트 추가
- 잘못된 분기 로직 발견 → 수정

변경 없으면 "No agent prompt updates needed" 보고 후 건너뜁니다.

## Step 5 — .gitignore 업데이트 (해당 시)

Step 2에서 식별한 항목을 반영합니다:
- 새 패턴 추가 시 관련 주석과 함께 적절한 섹션에 삽입
- 기존 패턴 중복 없는지 확인 후 추가

## Step 6 — 커밋

**커밋 대상 (template 파일만):**

```bash
# template 파일 목록 확인
git diff --name-only HEAD
git ls-files --others --exclude-standard
```

커밋에 포함하는 파일:
- `.claude/agents/*.md` — agent 프롬프트
- `.claude/commands/*.md` — slash command 스킬
- `.claude/patterns/*.md` — 패턴 문서
- `automation/*.sh`, `automation/*.yml` — 자동화 스크립트
- `CLAUDE.md`, `WORKFLOW.md`, `.gitignore`
- 새로 추가된 template 문서

**커밋에 포함하지 않는 파일 (project-specific):**
- `LATEST_STATE.md`, `TASK_BOARD.md`
- `automation/next-session-manifest.json`
- `automation/logs/`
- `captures/`, `source-analysis/`
- `src/main/frontend/`, `src/main/webapp/ui/`
- `docs/project-docs/MIGRATION_AUTOMATION_FEEDBACK.md`
- `docs/project-docs/ENDPOINT_MAP.md`

스테이징 후 커밋 메시지를 작성해 사용자에게 확인을 요청합니다.
커밋 메시지 형식: `<type>: <subject>` (예: `docs: add session guard pattern to CLAUDE.md`)

사용자 승인 후 커밋합니다.

## Step 7 — 결과 보고

```
# UPDATE-DOCS 결과

## 변경된 파일
- (파일 목록)

## 내용 요약
- CLAUDE.md: (추가된 항목 또는 "변경 없음")
- .gitignore: (추가된 패턴 또는 "변경 없음")
- Agent prompts: (변경된 파일 또는 "변경 없음")

## 커밋
- (커밋 해시 및 메시지 또는 "커밋 없음")
```
