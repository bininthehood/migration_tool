param(
  [string]$ProjectRoot = (Get-Location).Path,
  [string]$TargetRoot = 'src/main/frontend/src'
)
$sh = Join-Path $PSScriptRoot 'annotate-react-functions.sh'
$linuxSh   = (wsl wslpath -u "$sh").Trim()
$linuxRoot = (wsl wslpath -u "$ProjectRoot").Trim()
wsl bash $linuxSh --project-root $linuxRoot --target-root $TargetRoot
exit $LASTEXITCODE
