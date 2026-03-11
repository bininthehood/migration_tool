param(
  [string]$ProjectRoot = (Get-Location).Path,
  [string]$MigrateScreen = '',
  [string]$MigrateBatch = '',
  [string]$MigrationPlanFile = 'automation/migration-screen-map.json',
  [string]$OutputDir = 'docs/project-docs/migration-checklists'
)

$ErrorActionPreference = 'Stop'

if ([string]::IsNullOrWhiteSpace($MigrateScreen) -and [string]::IsNullOrWhiteSpace($MigrateBatch)) {
  throw 'Either -MigrateScreen or -MigrateBatch is required.'
}

$planPath = Join-Path $ProjectRoot $MigrationPlanFile
if (-not (Test-Path $planPath)) {
  throw "Migration plan file not found: $planPath"
}

$checklistScript = Join-Path $ProjectRoot 'automation/skills/jsp-react-screen-migrator/scripts/migrate-screen-checklist.ps1'
if (-not (Test-Path $checklistScript)) {
  throw "Checklist generator not found: $checklistScript"
}

$raw = Get-Content -Path $planPath -Raw
if ([string]::IsNullOrWhiteSpace($raw)) {
  throw "Migration plan is empty: $planPath"
}
$plan = $raw | ConvertFrom-Json

$screens = @()
if ($plan.screens) {
  $screens = @($plan.screens)
}
if ($screens.Count -eq 0) {
  throw "No screens found in migration plan: $planPath"
}

$targets = @()
if (-not [string]::IsNullOrWhiteSpace($MigrateScreen)) {
  $targets += @($screens | Where-Object { $_.id -eq $MigrateScreen })
}
if (-not [string]::IsNullOrWhiteSpace($MigrateBatch)) {
  if ($MigrateBatch -eq 'all') {
    $targets += $screens
  } else {
    $targets += @($screens | Where-Object { $_.group -eq $MigrateBatch })
  }
}

$targets = @($targets | Group-Object id | ForEach-Object { $_.Group[0] })
if ($targets.Count -eq 0) {
  throw "No migration targets selected (screen='$MigrateScreen', batch='$MigrateBatch')."
}

$resolvedOutDir = Join-Path $ProjectRoot $OutputDir
if (-not (Test-Path $resolvedOutDir)) {
  New-Item -Path $resolvedOutDir -ItemType Directory -Force | Out-Null
}

foreach ($screen in $targets) {
  if ([string]::IsNullOrWhiteSpace($screen.id) -or [string]::IsNullOrWhiteSpace($screen.legacyUrl) -or [string]::IsNullOrWhiteSpace($screen.reactRoute)) {
    throw "Invalid plan entry. Required: id, legacyUrl, reactRoute. Entry: $($screen | ConvertTo-Json -Compress)"
  }
  $outPath = Join-Path $resolvedOutDir ("{0}-checklist.md" -f $screen.id)
  & powershell -ExecutionPolicy Bypass -File $checklistScript `
    -ProjectRoot $ProjectRoot `
    -LegacyUrl $screen.legacyUrl `
    -ReactRoute $screen.reactRoute `
    -OutputPath $outPath
  if ($LASTEXITCODE -ne 0) {
    throw "Checklist generation failed for id=$($screen.id) (exit $LASTEXITCODE)"
  }
}

Write-Host "MIGRATION_TARGETS=$($targets.Count)"
Write-Host "OUTPUT_DIR=$resolvedOutDir"
