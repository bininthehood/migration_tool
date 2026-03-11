param(
  [string]$ProjectRoot = (Get-Location).Path,
  [string]$TomcatBaseUrl = 'http://localhost:8080',
  [string]$TomcatContextPath = '/rays',
  [string]$User = 'admin',
  [string]$Password = 'admin'
)

$ErrorActionPreference = 'Stop'

function Read-ResponseText([object]$Response) {
  if ($null -eq $Response) { return '' }
  if ($Response.Content -is [string]) { return $Response.Content }
  if ($Response.Content -is [byte[]]) { return [System.Text.Encoding]::UTF8.GetString($Response.Content) }
  return [string]$Response.Content
}

function Ensure-ResultCode([object]$Payload, [string]$ApiName) {
  if ($null -eq $Payload) {
    throw "$ApiName returned empty payload"
  }
  $resultCode = -9999
  try { $resultCode = [int]$Payload.resultCode } catch { $resultCode = -9999 }
  if ($resultCode -ne 0) {
    throw "$ApiName resultCode=$resultCode"
  }
}

$baseUrl = $TomcatBaseUrl.TrimEnd('/')
$ctx = $TomcatContextPath
if (-not $ctx.StartsWith('/')) { $ctx = "/$ctx" }

$policyCheckUrl = "$baseUrl$ctx/user/v1/policyCheck"
$sessionAliveUrl = "$baseUrl$ctx/user/v1/sessionAlive"
$sessionInfoUrl = "$baseUrl$ctx/user/v1/sessionInfo"

$webSession = New-Object Microsoft.PowerShell.Commands.WebRequestSession

$loginBody = "userId=$([uri]::EscapeDataString($User))&userPwd=$([uri]::EscapeDataString($Password))&userLang=ko"
$loginResponse = Invoke-WebRequest -UseBasicParsing -Uri $policyCheckUrl -Method POST -WebSession $webSession -ContentType 'application/x-www-form-urlencoded; charset=UTF-8' -Body $loginBody
$loginText = Read-ResponseText -Response $loginResponse
$loginJson = $loginText | ConvertFrom-Json
Ensure-ResultCode -Payload $loginJson -ApiName 'policyCheck'

$aliveResponse = Invoke-WebRequest -UseBasicParsing -Uri $sessionAliveUrl -Method POST -WebSession $webSession -ContentType 'application/x-www-form-urlencoded; charset=UTF-8' -Body ''
$aliveText = Read-ResponseText -Response $aliveResponse
$aliveJson = $aliveText | ConvertFrom-Json
Ensure-ResultCode -Payload $aliveJson -ApiName 'sessionAlive'

$sessionResponse = Invoke-WebRequest -UseBasicParsing -Uri $sessionInfoUrl -Method POST -WebSession $webSession -ContentType 'application/x-www-form-urlencoded; charset=UTF-8' -Body ''
$sessionText = Read-ResponseText -Response $sessionResponse
$sessionJson = $sessionText | ConvertFrom-Json
Ensure-ResultCode -Payload $sessionJson -ApiName 'sessionInfo'

$sessionData = $sessionJson.sessionData
if ($null -eq $sessionData) {
  throw 'sessionInfo payload missing sessionData'
}

$requiredKeys = @('siteCode', 'levelCode', 'userId')
foreach ($key in $requiredKeys) {
  $value = [string]$sessionData.$key
  if ([string]::IsNullOrWhiteSpace($value) -or $value -eq 'null') {
    throw "sessionInfo.sessionData.$key is missing"
  }
}

Write-Host "Session contract check passed: userId=$($sessionData.userId), siteCode=$($sessionData.siteCode), levelCode=$($sessionData.levelCode)"
