param(
  [Parameter(Mandatory = $true)][string]$LegacyUrl,
  [Parameter(Mandatory = $true)][string]$ReactRoute,
  [string]$ProjectRoot = (Get-Location).Path,
  [string]$OutputPath
)
# Thin wrapper — delegates to migrate-screen-checklist.sh
$sh = Join-Path $PSScriptRoot 'migrate-screen-checklist.sh'
$linuxSh   = (wsl wslpath -u "$sh").Trim()
$linuxRoot = (wsl wslpath -u "$ProjectRoot").Trim()
$args = @("--project-root", $linuxRoot, "--legacy-url", $LegacyUrl, "--react-route", $ReactRoute)
if ($OutputPath) {
  $linuxOut = (wsl wslpath -u "$OutputPath").Trim()
  $args += @("--output-path", $linuxOut)
}
wsl bash $linuxSh @args
exit $LASTEXITCODE
