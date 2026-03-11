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

function Append-Utf8NoBomFile([string]$Path, [string]$Content) {
  $enc = New-Object System.Text.UTF8Encoding($false)
  [System.IO.File]::AppendAllText($Path, $Content, $enc)
}

if ($Apply -and $SessionLog) {
  Append-Utf8NoBomFile -Path $SessionLog -Content $entry
  "Appended session log entry: $SessionLog"
} else {
  $entry
}
