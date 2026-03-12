param(
  [string]$ProjectRoot = (Get-Location).Path,
  [string[]]$ChangedFiles,
  [string[]]$Commands,
  [string[]]$Captures,
  [switch]$Apply
)

$ErrorActionPreference = 'Stop'

function Write-Utf8NoBomFile([string]$Path, [string]$Content) {
  $dir = Split-Path -Path $Path -Parent
  if ($dir -and -not (Test-Path $dir)) {
    New-Item -Path $dir -ItemType Directory -Force | Out-Null
  }
  $enc = New-Object System.Text.UTF8Encoding($false)
  [System.IO.File]::WriteAllText($Path, $Content, $enc)
}

$syncScript = Join-Path $ProjectRoot 'automation/skills/migration-doc-sync/scripts/sync-doc-stub.ps1'
if (-not (Test-Path $syncScript)) {
  throw "Skill script not found: $syncScript"
}

$sessionCandidates = @()
$movedLogDir = Join-Path $ProjectRoot 'docs/project-docs'
if (Test-Path $movedLogDir) {
  $sessionCandidates += Get-ChildItem -Path $movedLogDir -File -Filter 'SESSION_WORKLOG_*.md' -ErrorAction SilentlyContinue
}
$sessionCandidates += Get-ChildItem -Path $ProjectRoot -File -Filter 'SESSION_WORKLOG_*.md' -ErrorAction SilentlyContinue
$sessionLog = ($sessionCandidates | Sort-Object LastWriteTime -Descending | Select-Object -First 1).FullName

if (-not $sessionLog) {
  if (-not (Test-Path $movedLogDir)) {
    New-Item -Path $movedLogDir -ItemType Directory -Force | Out-Null
  }
  $newSessionLog = Join-Path $movedLogDir ("SESSION_WORKLOG_{0}.md" -f (Get-Date -Format 'yyyy-MM-dd'))
  if (-not (Test-Path $newSessionLog)) {
    $header = "# Session Worklog`n`nAuto-created by automation/run-doc-sync.ps1 on $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss K').`n"
    Write-Utf8NoBomFile -Path $newSessionLog -Content $header
  }
  $sessionLog = $newSessionLog
}

$args = @(
  '-ExecutionPolicy', 'Bypass',
  '-File', $syncScript,
  '-ProjectRoot', $ProjectRoot,
  '-SessionLog', $sessionLog
)
if ($ChangedFiles) { $args += @('-ChangedFiles') + $ChangedFiles }
if ($Commands) { $args += @('-Commands') + $Commands }
if ($Captures) { $args += @('-Captures') + $Captures }
if ($Apply) { $args += '-Apply' }

Write-Host "Running doc-sync with SessionLog: $sessionLog"
& powershell @args
if ($LASTEXITCODE -ne 0) {
  throw "Doc-sync failed with exit code $LASTEXITCODE"
}
