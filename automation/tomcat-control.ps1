param(
  [ValidateSet('start', 'stop', 'restart', 'status')][string]$Action = 'status',
  [string]$TomcatHome = 'C:\dev\eclipse\bin\apache-tomcat-9.0.100',
  [string]$TomcatBase = 'C:\dev\eclipse\workspace\.metadata\.plugins\org.eclipse.wst.server.core\tmp0',
  [string]$TomcatJreHome = 'C:\Users\rays\.p2\pool\plugins\org.eclipse.justj.openjdk.hotspot.jre.full.win32.x86_64_21.0.10.v20260205-0638\jre',
  [string]$TomcatBaseUrl = 'http://localhost:8080',
  [string]$TomcatContextPath = '/rays',
  [string]$TomcatHealthPath = '/ui/',
  [int]$TimeoutSec = 120,
  [switch]$NoHealthCheck
)

$ErrorActionPreference = 'Stop'

function Get-HealthUrl {
  return ('{0}{1}{2}' -f $TomcatBaseUrl.TrimEnd('/'), $TomcatContextPath, $TomcatHealthPath)
}

function Test-TomcatReady {
  try {
    $resp = Invoke-WebRequest -Uri (Get-HealthUrl) -Method Get -UseBasicParsing -TimeoutSec 6
    return ($resp.StatusCode -ge 200 -and $resp.StatusCode -lt 400)
  }
  catch {
    return $false
  }
}

function Wait-Until {
  param(
    [scriptblock]$Condition,
    [int]$Timeout = 120,
    [int]$PollSec = 2
  )
  $deadline = (Get-Date).AddSeconds($Timeout)
  while ((Get-Date) -lt $deadline) {
    if (& $Condition) { return $true }
    Start-Sleep -Seconds $PollSec
  }
  return $false
}

function Invoke-CatalinaScript {
  param([string]$ScriptName)
  $scriptPath = Join-Path $TomcatHome "bin\$ScriptName"
  if (-not (Test-Path $scriptPath)) {
    throw "TOMCAT_CONTROL_FAIL: missing script $scriptPath"
  }

  $env:CATALINA_HOME = $TomcatHome
  $env:CATALINA_BASE = $TomcatBase
  $env:JRE_HOME = $TomcatJreHome
  Remove-Item Env:JAVA_HOME -ErrorAction SilentlyContinue

  & $scriptPath
}

if (-not (Test-Path $TomcatHome)) {
  throw "TOMCAT_CONTROL_FAIL: TomcatHome not found: $TomcatHome"
}
if (-not (Test-Path $TomcatBase)) {
  throw "TOMCAT_CONTROL_FAIL: TomcatBase not found: $TomcatBase"
}
if (-not (Test-Path $TomcatJreHome)) {
  throw "TOMCAT_CONTROL_FAIL: TomcatJreHome not found: $TomcatJreHome"
}

switch ($Action) {
  'status' {
    $ready = Test-TomcatReady
    if ($ready) {
      Write-Host "TOMCAT_STATUS=UP URL=$(Get-HealthUrl)"
      exit 0
    }
    Write-Host "TOMCAT_STATUS=DOWN URL=$(Get-HealthUrl)"
    exit 1
  }
  'start' {
    Write-Host 'TOMCAT_ACTION=start'
    Invoke-CatalinaScript -ScriptName 'startup.bat'
    if ($NoHealthCheck) { exit 0 }
    $ok = Wait-Until -Condition { Test-TomcatReady } -Timeout $TimeoutSec
    if (-not $ok) {
      throw "TOMCAT_CONTROL_FAIL: Tomcat did not become ready within ${TimeoutSec}s"
    }
    Write-Host "TOMCAT_READY URL=$(Get-HealthUrl)"
    exit 0
  }
  'stop' {
    Write-Host 'TOMCAT_ACTION=stop'
    Invoke-CatalinaScript -ScriptName 'shutdown.bat'
    if ($NoHealthCheck) { exit 0 }
    $down = Wait-Until -Condition { -not (Test-TomcatReady) } -Timeout $TimeoutSec
    if (-not $down) {
      throw "TOMCAT_CONTROL_FAIL: Tomcat did not stop within ${TimeoutSec}s"
    }
    Write-Host 'TOMCAT_STOPPED'
    exit 0
  }
  'restart' {
    Write-Host 'TOMCAT_ACTION=restart'
    Invoke-CatalinaScript -ScriptName 'shutdown.bat'
    if (-not $NoHealthCheck) {
      [void](Wait-Until -Condition { -not (Test-TomcatReady) } -Timeout ([Math]::Min($TimeoutSec, 60)))
    }
    Invoke-CatalinaScript -ScriptName 'startup.bat'
    if ($NoHealthCheck) { exit 0 }
    $ok = Wait-Until -Condition { Test-TomcatReady } -Timeout $TimeoutSec
    if (-not $ok) {
      throw "TOMCAT_CONTROL_FAIL: Tomcat did not become ready after restart within ${TimeoutSec}s"
    }
    Write-Host "TOMCAT_READY URL=$(Get-HealthUrl)"
    exit 0
  }
}

