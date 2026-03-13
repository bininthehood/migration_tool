param(
  [string]$ProjectRoot = (Get-Location).Path,
  [string]$TomcatBaseUrl = 'http://localhost:8080',
  [string]$TomcatContextPath = '/rays',
  [string]$User = 'admin',
  [string]$Password = 'admin'
)
$sh = Join-Path $PSScriptRoot 'verify-session-contract.sh'
$linuxSh   = (wsl wslpath -u "$sh").Trim()
$linuxRoot = (wsl wslpath -u "$ProjectRoot").Trim()
wsl bash $linuxSh --project-root $linuxRoot --base-url $TomcatBaseUrl `
  --context-path $TomcatContextPath --user $User --password $Password
exit $LASTEXITCODE
