param(
  [string]$ProjectRoot = (Get-Location).Path,
  [string]$OutputDir = 'dist/migration-kit',
  [string]$PackageName = '',
  [switch]$IncludeSessionLog,
  [switch]$Minimal
)

$ErrorActionPreference = 'Stop'

function Ensure-Dir([string]$Path) {
  if (-not (Test-Path $Path)) {
    New-Item -ItemType Directory -Path $Path -Force | Out-Null
  }
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
  $suffix = if ($Minimal) { 'minimal' } else { 'full' }
  $PackageName = "migration-automation-kit-$suffix-$stamp"
}

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
Add-PathIfExists $items (Join-Path $ProjectRoot 'automation/skills')

# Frontend runtime essentials (must exist in shared kit).
Add-PathIfExists $items (Join-Path $ProjectRoot 'src/main/frontend/package.json')
Add-PathIfExists $items (Join-Path $ProjectRoot 'src/main/frontend/package-lock.json')
Add-PathIfExists $items (Join-Path $ProjectRoot 'src/main/frontend/public')
Add-PathIfExists $items (Join-Path $ProjectRoot 'src/main/frontend/src')
Add-PathIfExists $items (Join-Path $ProjectRoot 'src/main/frontend/scripts')
Add-PathIfExists $items (Join-Path $ProjectRoot 'src/main/webapp/ui')

if (-not $Minimal) {
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
} else {
  # Minimal mode still includes manifest required docs so validate-skill-integration can pass.
  $manifestRequired = Get-ManifestRequiredPaths (Join-Path $ProjectRoot 'automation/project-doc-manifest.yml')
  foreach ($doc in $manifestRequired) {
    Add-PathIfExists $items (Join-Path $ProjectRoot $doc)
  }

  # Plus a small set of execution guidance docs.
  Add-PathIfExists $items (Join-Path $ProjectRoot 'AGENTS.md')
  Add-PathIfExists $items (Join-Path $ProjectRoot 'WORKFLOW.md')
  Add-PathIfExists $items (Join-Path $ProjectRoot 'README.md')
  Add-PathIfExists $items (Join-Path $ProjectRoot 'docs/project-docs/README_FRONTEND_BUILD_DEPLOY.md')
}

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
$manifest += "Minimal: $([bool]$Minimal)"
$manifest += ''
$manifest += 'Included Paths:'
$manifest += (Get-ChildItem -Path $stagingDir -Recurse | ForEach-Object {
  $_.FullName.Substring($stagingDir.Length).TrimStart('\', '/')
} | Sort-Object)
Set-Content -Path $manifestPath -Value $manifest -Encoding UTF8

$zipPath = Join-Path $resolvedOutputDir "$PackageName.zip"
if (Test-Path $zipPath) {
  Remove-Item -Force $zipPath
}
Compress-Archive -Path (Join-Path $stagingDir '*') -DestinationPath $zipPath -Force

Write-Host "PACKAGED"
Write-Host "ZIP: $zipPath"
Write-Host "STAGING: $stagingDir"
