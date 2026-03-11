param(
  [string]$ProjectRoot = (Get-Location).Path,
  [string[]]$ChangedFiles,
  [string[]]$Commands,
  [string[]]$Captures,
  [string]$SessionLog,
  [switch]$Apply
)

if (-not $SessionLog) {
  $logs = Get-ChildItem -Path $ProjectRoot -File -Filter 'SESSION_WORKLOG_*.md' | Sort-Object LastWriteTime -Descending
  if ($logs.Count -gt 0) { $SessionLog = $logs[0].FullName }
}

$ts = Get-Date -Format 'yyyy-MM-dd HH:mm:ss K'
$entry = @"

## $ts
- Changed files:
$(($ChangedFiles | ForEach-Object { "  - $_" }) -join "`n")
- Commands:
$(($Commands | ForEach-Object { "  - $_" }) -join "`n")
- Captures:
$(($Captures | ForEach-Object { "  - $_" }) -join "`n")
- Docs to sync:
  - LATEST_STATE.md
  - TASK_BOARD.md
  - docs-migration-backlog.md
  - docs-main-qa-report.md (if impacted)
"@

if ($Apply -and $SessionLog) {
  Add-Content -Path $SessionLog -Value $entry -Encoding UTF8
  "Appended session log entry: $SessionLog"
} else {
  $entry
}
