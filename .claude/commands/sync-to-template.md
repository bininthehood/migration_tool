공유 템플릿 파일의 변경사항을 리뷰하고 migration_tool 리포에 commit/push합니다.

## Step 1 — 변경 파일 확인

```bash
git -C {migration_tool_root} diff --stat HEAD -- \
  CLAUDE.md \
  CLAUDE_GUIDE.md \
  WORKFLOW.md \
  automation/next-session-manifest.template.json \
  LATEST_STATE.template.md \
  TASK_BOARD.template.md \
  docs-migration-backlog.md \
  .claude/agents/migration-agent.md \
  .claude/agents/meta-agent.md \
  .claude/commands/run-automation.md \
  .claude/commands/sync-to-template.md \
  .claude/settings.json
```

변경된 파일이 없으면: "템플릿과 차이 없음. sync 불필요." 보고 후 종료.

변경된 파일이 있으면: Step 2로 진행.

## Step 2 — 변경 내용 요약 출력

변경된 각 파일에 대해 `git diff HEAD -- <file>` 을 실행하고, 사용자에게 아래 형식으로 요약합니다:

```
변경된 파일 목록:
  - CLAUDE.md : (추가/수정/삭제된 섹션 한 줄 요약)
  - WORKFLOW.md : (추가/수정/삭제된 내용 한 줄 요약)
  - ...

다음 단계:
  1. 전체 commit & push
  2. 파일별 선택 후 commit & push
  3. 취소
```

사용자 응답을 기다립니다.

## Step 3 — Commit & Push

### 응답 1 (전체):
```bash
git -C {migration_tool_root} add \
  CLAUDE.md CLAUDE_GUIDE.md WORKFLOW.md \
  automation/next-session-manifest.template.json \
  LATEST_STATE.template.md TASK_BOARD.template.md \
  docs-migration-backlog.md \
  .claude/agents/migration-agent.md \
  .claude/agents/meta-agent.md \
  .claude/commands/run-automation.md \
  .claude/commands/sync-to-template.md \
  .claude/settings.json
```

### 응답 2 (파일별 선택):
사용자가 선택한 파일만 `git add`.

### 공통 — commit & push:
```bash
git -C {migration_tool_root} commit -m "sync: update shared templates from project run ($(date +%Y-%m-%d))"
git -C {migration_tool_root} push origin main
```

push 성공 시: "sync 완료. migration_tool 리포에 반영됐습니다." 보고.
push 실패 시: 에러 내용과 함께 "수동으로 push해 주세요." 안내.
