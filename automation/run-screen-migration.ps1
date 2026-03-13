param(
  [string]$ProjectRoot = (Get-Location).Path,
  [string]$MigrateScreen = '',
  [string]$MigrateBatch = '',
  [string]$MigrationPlanFile = 'automation/migration-screen-map.json',
  [string]$OutputDir = 'docs/project-docs/migration-checklists'
)
# Thin wrapper — delegates to run-screen-migration.sh
$sh = Join-Path $PSScriptRoot 'run-screen-migration.sh'
$linuxSh   = (wsl wslpath -u "$sh").Trim()
$linuxRoot = (wsl wslpath -u "$ProjectRoot").Trim()
$args = @("--project-root", $linuxRoot,
          "--migration-plan-file", $MigrationPlanFile,
          "--output-dir", $OutputDir)
if ($MigrateScreen) { $args += @("--migrate-screen", $MigrateScreen) }
if ($MigrateBatch)  { $args += @("--migrate-batch",  $MigrateBatch) }
wsl bash $linuxSh @args
exit $LASTEXITCODE
