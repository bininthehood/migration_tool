param(
  [ValidateSet('start','stop','restart','status')][string]$Action = 'status',
  [string]$TomcatHome,
  [string]$TomcatBase,
  [string]$TomcatJreHome,
  [string]$TomcatBaseUrl = 'http://localhost:8080',
  [string]$TomcatContextPath = '/rays',
  [string]$TomcatHealthPath = '/ui/',
  [int]$TimeoutSec = 120,
  [switch]$NoHealthCheck
)
$sh = Join-Path $PSScriptRoot 'tomcat-control.sh'
$linuxSh = (wsl wslpath -u "$sh").Trim()
$args = @("--action", $Action, "--base-url", $TomcatBaseUrl,
          "--context-path", $TomcatContextPath, "--health-path", $TomcatHealthPath,
          "--timeout", $TimeoutSec)
if ($TomcatHome)    { $args += @("--tomcat-home",    (wsl wslpath -u "$TomcatHome").Trim()) }
if ($TomcatBase)    { $args += @("--tomcat-base",    (wsl wslpath -u "$TomcatBase").Trim()) }
if ($TomcatJreHome) { $args += @("--tomcat-jre-home",(wsl wslpath -u "$TomcatJreHome").Trim()) }
if ($NoHealthCheck) { $args += "--no-health-check" }
wsl bash $linuxSh @args
exit $LASTEXITCODE

