param(
  [string]$ProjectRoot = (Get-Location).Path,
  [switch]$NoFail
)
# Thin wrapper — delegates to check-routing-contract.sh
$sh = Join-Path $PSScriptRoot 'check-routing-contract.sh'
$linuxSh   = (wsl wslpath -u "$sh").Trim()
$linuxRoot = (wsl wslpath -u "$ProjectRoot").Trim()
$args = @("--project-root", $linuxRoot)
if ($NoFail) { $args += "--no-fail" }
wsl bash $linuxSh @args
exit $LASTEXITCODE
