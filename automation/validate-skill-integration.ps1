param(
  [string]$ProjectRoot = (Get-Location).Path,
  [switch]$LegacyMode
)
# Thin wrapper — delegates to validate-skill-integration.sh
$sh = Join-Path $PSScriptRoot 'validate-skill-integration.sh'
$linuxSh   = (wsl wslpath -u "$sh").Trim()
$linuxRoot = (wsl wslpath -u "$ProjectRoot").Trim()
$args = @("--project-root", $linuxRoot)
if ($LegacyMode) { $args += "--legacy-mode" }
wsl bash $linuxSh @args
exit $LASTEXITCODE
