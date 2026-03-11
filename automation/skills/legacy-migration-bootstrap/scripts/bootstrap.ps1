param(
  [string]$ProjectRoot = (Get-Location).Path,
  [switch]$AsJson
)

$docs = @('AGENTS.md','WORKFLOW.md','LATEST_STATE.md','TASK_BOARD.md','docs-migration-backlog.md')
$docStatus = foreach ($d in $docs) {
  $p = Join-Path $ProjectRoot $d
  [pscustomobject]@{ File = $d; Exists = (Test-Path $p); Path = $p }
}

$phase = 'Unknown'
$latestState = Join-Path $ProjectRoot 'LATEST_STATE.md'
if (Test-Path $latestState) {
  $lines = Get-Content $latestState
  $idx = [Array]::IndexOf($lines, ($lines | Where-Object { $_ -match '^##\s+진행 단계' } | Select-Object -First 1))
  if ($idx -ge 0 -and $idx + 1 -lt $lines.Count) {
    $phase = $lines[$idx + 1].Trim()
  }
}

$selectedTask = $null
$backlog = Join-Path $ProjectRoot 'docs-migration-backlog.md'
if (Test-Path $backlog) {
  $selectedTask = Get-Content $backlog | Where-Object { $_ -match '\|\s*진행중\s*\|' } | Select-Object -First 1
}
if (-not $selectedTask) {
  $taskBoard = Join-Path $ProjectRoot 'TASK_BOARD.md'
  if (Test-Path $taskBoard) {
    $selectedTask = Get-Content $taskBoard | Where-Object { $_ -match '^\[\s\]\s+' } | Select-Object -First 1
  }
}
if (-not $selectedTask) { $selectedTask = 'No pending task line found in docs.' }

$result = [pscustomobject]@{
  ProjectRoot = $ProjectRoot
  Phase = $phase
  SelectedTask = $selectedTask.Trim()
  Documents = $docStatus
}

if ($AsJson) {
  $result | ConvertTo-Json -Depth 4
} else {
  "[BOOTSTRAP]"
  "ProjectRoot: $($result.ProjectRoot)"
  "Phase: $($result.Phase)"
  "SelectedTask: $($result.SelectedTask)"
  "Documents:"
  $result.Documents | ForEach-Object { "- $($_.File): $([string]::Join('',$(if($_.Exists){'OK'}else{'MISSING'})))" }
}
