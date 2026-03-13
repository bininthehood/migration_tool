param(
  [string]$ProjectRoot = (Get-Location).Path,
  [switch]$AsJson
)
# Thin wrapper — delegates to bootstrap.sh
$sh = Join-Path $PSScriptRoot 'bootstrap.sh'
$linuxSh   = (wsl wslpath -u "$sh").Trim()
$linuxRoot = (wsl wslpath -u "$ProjectRoot").Trim()
$args = @("--project-root", $linuxRoot)
if ($AsJson) { $args += "--as-json" }
wsl bash $linuxSh @args
exit $LASTEXITCODE
