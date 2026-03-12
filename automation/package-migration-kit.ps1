param(
  [string]$ProjectRoot = (Get-Location).Path,
  [string]$OutputDir = 'dist/migration-kit',
  [string]$PackageName = '',
  [switch]$IncludeSessionLog
)

$ErrorActionPreference = 'Stop'

function Ensure-Dir([string]$Path) {
  if (-not (Test-Path $Path)) {
    New-Item -ItemType Directory -Path $Path -Force | Out-Null
  }
}

function Write-Utf8NoBomFile([string]$Path, [string[]]$Content) {
  Ensure-Dir (Split-Path -Parent $Path)
  $enc = New-Object System.Text.UTF8Encoding($false)
  [System.IO.File]::WriteAllText($Path, ($Content -join [Environment]::NewLine), $enc)
}

function Add-PathIfExists([System.Collections.Generic.List[string]]$List, [string]$AbsPath) {
  if (Test-Path $AbsPath) {
    $List.Add($AbsPath)
  } else {
    Write-Host "[warn] missing: $AbsPath"
  }
}

function Get-ManifestRequiredPaths([string]$ManifestPath) {
  if (-not (Test-Path $ManifestPath)) { return @() }
  $required = @()
  $inRequired = $false
  foreach ($line in (Get-Content -Path $ManifestPath)) {
    if ($line -match '^\s*required:\s*$') { $inRequired = $true; continue }
    if ($inRequired -and $line -match '^\s*optional:\s*$') { $inRequired = $false; continue }
    if ($inRequired -and $line -match '^\s*-\s+(.+?)\s*$') {
      $required += $matches[1].Trim()
    }
  }
  return $required
}

$resolvedOutputDir = Join-Path $ProjectRoot $OutputDir
Ensure-Dir $resolvedOutputDir

$stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
if ([string]::IsNullOrWhiteSpace($PackageName)) {
  $PackageName = "migration-automation-kit-$stamp"
}

# Keep only the latest generated kit set in dist/migration-kit.
Get-ChildItem -Path $resolvedOutputDir -Force -ErrorAction SilentlyContinue |
  Where-Object { $_.Name -like 'migration-automation-kit-*' } |
  Remove-Item -Recurse -Force -ErrorAction SilentlyContinue

$stagingDir = Join-Path $resolvedOutputDir "$PackageName-staging"
if (Test-Path $stagingDir) {
  Remove-Item -Recurse -Force $stagingDir
}
Ensure-Dir $stagingDir

$items = New-Object 'System.Collections.Generic.List[string]'

# Core automation
Add-PathIfExists $items (Join-Path $ProjectRoot 'automation/project-doc-manifest.yml')
Add-PathIfExists $items (Join-Path $ProjectRoot 'automation/run-all.ps1')
Add-PathIfExists $items (Join-Path $ProjectRoot 'automation/run-screen-migration.ps1')
Add-PathIfExists $items (Join-Path $ProjectRoot 'automation/migration-screen-map.json')
Add-PathIfExists $items (Join-Path $ProjectRoot 'automation/tomcat-control.ps1')
Add-PathIfExists $items (Join-Path $ProjectRoot 'automation/run-doc-sync.ps1')
Add-PathIfExists $items (Join-Path $ProjectRoot 'automation/validate-skill-integration.ps1')
Add-PathIfExists $items (Join-Path $ProjectRoot 'automation/bootstrap-frontend.ps1')
Add-PathIfExists $items (Join-Path $ProjectRoot 'automation/install-migration-kit.ps1')
Add-PathIfExists $items (Join-Path $ProjectRoot 'automation/package-migration-kit.ps1')
Add-PathIfExists $items (Join-Path $ProjectRoot 'automation/git-commit.ps1')
Add-PathIfExists $items (Join-Path $ProjectRoot 'automation/git-automation-config.json')
Add-PathIfExists $items (Join-Path $ProjectRoot 'automation/skills')

# Frontend runtime essentials (must exist in shared kit).
Add-PathIfExists $items (Join-Path $ProjectRoot 'src/main/frontend/package.json')
Add-PathIfExists $items (Join-Path $ProjectRoot 'src/main/frontend/package-lock.json')
Add-PathIfExists $items (Join-Path $ProjectRoot 'src/main/frontend/public')
Add-PathIfExists $items (Join-Path $ProjectRoot 'src/main/frontend/src')
Add-PathIfExists $items (Join-Path $ProjectRoot 'src/main/frontend/scripts')
Add-PathIfExists $items (Join-Path $ProjectRoot 'src/main/webapp/ui')

# Root docs
Add-PathIfExists $items (Join-Path $ProjectRoot 'AGENTS.md')
Add-PathIfExists $items (Join-Path $ProjectRoot 'WORKFLOW.md')
Add-PathIfExists $items (Join-Path $ProjectRoot 'LATEST_STATE.md')
Add-PathIfExists $items (Join-Path $ProjectRoot 'TASK_BOARD.md')
Add-PathIfExists $items (Join-Path $ProjectRoot 'docs-migration-backlog.md')
Add-PathIfExists $items (Join-Path $ProjectRoot '.gitignore')

# Docs folders
Add-PathIfExists $items (Join-Path $ProjectRoot 'docs/automation/MD_CLASSIFICATION.md')
Add-PathIfExists $items (Join-Path $ProjectRoot 'docs/project-docs')

if (-not $IncludeSessionLog) {
  # Exclude session worklogs by deleting them in staging later.
}

foreach ($src in $items) {
  $relative = $src.Substring($ProjectRoot.Length).TrimStart('\', '/')
  $dst = Join-Path $stagingDir $relative
  $parent = Split-Path -Parent $dst
  Ensure-Dir $parent
  if ((Get-Item $src).PSIsContainer) {
    Copy-Item -Path $src -Destination $dst -Recurse -Force
  } else {
    Copy-Item -Path $src -Destination $dst -Force
  }
}

# Always remove runtime outputs from package.
$runtimeLogs = Join-Path $stagingDir 'automation/logs'
if (Test-Path $runtimeLogs) {
  Remove-Item -Recurse -Force $runtimeLogs
}

if (-not $IncludeSessionLog) {
  Get-ChildItem -Path (Join-Path $stagingDir 'docs/project-docs') -File -Filter 'SESSION_WORKLOG_*.md' -ErrorAction SilentlyContinue |
    Remove-Item -Force
}

$manifestPath = Join-Path $stagingDir 'MIGRATION_KIT_CONTENTS.txt'
$manifest = @()
$manifest += "Package: $PackageName"
$manifest += "CreatedAt: $((Get-Date).ToString('yyyy-MM-dd HH:mm:ss zzz'))"
$manifest += "ProjectRoot: $ProjectRoot"
$manifest += "IncludeSessionLog: $([bool]$IncludeSessionLog)"
$manifest += ''
$manifest += 'Included Paths:'
$manifest += (Get-ChildItem -Path $stagingDir -Recurse | ForEach-Object {
  $_.FullName.Substring($stagingDir.Length).TrimStart('\', '/')
} | Sort-Object)
Write-Utf8NoBomFile -Path $manifestPath -Content $manifest

$zipPath = Join-Path $resolvedOutputDir "$PackageName.zip"
if (Test-Path $zipPath) {
  Remove-Item -Force $zipPath
}
Compress-Archive -Path (Join-Path $stagingDir '*') -DestinationPath $zipPath -Force

Write-Host "PACKAGED"
Write-Host "ZIP: $zipPath"
Write-Host "STAGING: $stagingDir"
