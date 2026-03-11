param(
  [string]$ProjectRoot = (Get-Location).Path,
  [string]$TomcatBaseUrl = 'http://localhost:8080',
  [string]$TomcatContextPath = '/rays',
  [string]$User = 'admin',
  [string]$Password = 'admin'
)

$ErrorActionPreference = 'Stop'

function Invoke-JsonRequest {
  param(
    [Parameter(Mandatory = $true)][string]$Method,
    [Parameter(Mandatory = $true)][string]$Url,
    [Microsoft.PowerShell.Commands.WebRequestSession]$Session,
    [hashtable]$Headers,
    [string]$Body = ''
  )

  $invokeParams = @{
    Uri         = $Url
    Method      = $Method
    WebSession  = $Session
    UseBasicParsing = $true
    TimeoutSec  = 15
  }
  if ($Headers) { $invokeParams.Headers = $Headers }
  if ($Method -ne 'GET') { $invokeParams.Body = $Body }

  $response = Invoke-WebRequest @invokeParams
  $content = $response.Content
  if ($content -is [byte[]]) {
    $content = [System.Text.Encoding]::UTF8.GetString($content)
  }
  return ($content | ConvertFrom-Json)
}

function Assert-ResultCodeZero {
  param(
    [Parameter(Mandatory = $true)][string]$StepName,
    [Parameter(Mandatory = $true)]$Payload
  )

  $resultCode = [int]($Payload.resultCode)
  if ($resultCode -ne 0) {
    $resultMessage = [string]$Payload.resultMessage
    throw "$StepName resultCode=$resultCode resultMessage=$resultMessage"
  }
}

$baseUrl = $TomcatBaseUrl.TrimEnd('/')
$contextPath = $TomcatContextPath.TrimEnd('/')
$rootUrl = "$baseUrl$contextPath"

Write-Host "[session-contract] base=$rootUrl"

$session = New-Object Microsoft.PowerShell.Commands.WebRequestSession

# Prime the session cookies from the login page before API calls.
$null = Invoke-WebRequest -Uri "$rootUrl/login" -Method Get -WebSession $session -UseBasicParsing -TimeoutSec 15

$formHeaders = @{
  'Content-Type' = 'application/x-www-form-urlencoded; charset=UTF-8'
}

$policyBody = "userId=$([uri]::EscapeDataString($User))&userPwd=$([uri]::EscapeDataString($Password))&userLang=ko"
$policy = Invoke-JsonRequest -Method 'POST' -Url "$rootUrl/user/v1/policyCheck" -Session $session -Headers $formHeaders -Body $policyBody
Assert-ResultCodeZero -StepName 'policyCheck' -Payload $policy

$alive = Invoke-JsonRequest -Method 'POST' -Url "$rootUrl/user/v1/sessionAlive" -Session $session -Headers $formHeaders -Body ''
Assert-ResultCodeZero -StepName 'sessionAlive' -Payload $alive

$info = Invoke-JsonRequest -Method 'POST' -Url "$rootUrl/user/v1/sessionInfo" -Session $session -Headers $formHeaders -Body ''
Assert-ResultCodeZero -StepName 'sessionInfo' -Payload $info

$sessionData = $info.sessionData
if (-not $sessionData) {
  throw 'sessionInfo.sessionData missing'
}

$requiredFields = @('siteCode', 'levelCode', 'userId')
foreach ($field in $requiredFields) {
  $value = [string]$sessionData.$field
  if ([string]::IsNullOrWhiteSpace($value) -or $value -eq 'null') {
    throw "sessionInfo.sessionData.$field missing"
  }
}

Write-Host "[session-contract] PASS"
