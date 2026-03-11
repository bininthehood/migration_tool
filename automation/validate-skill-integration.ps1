param(
  [string]$ProjectRoot = (Get-Location).Path,
  [switch]$LegacyMode
)

$ErrorActionPreference = 'Stop'

function Resolve-ProjectPath([string]$RelativePath) {
  return Join-Path $ProjectRoot $RelativePath
}

function Add-Result([ref]$Rows, [string]$Name, [bool]$Pass, [string]$Detail, [bool]$Critical = $true) {
  $Rows.Value += [pscustomobject]@{
    Check = $Name
    Pass = $Pass
    Critical = $Critical
    Detail = $Detail
  }
}

$results = @()

# 1) Manifest required docs check
$manifestPath = Resolve-ProjectPath 'automation/project-doc-manifest.yml'
if (-not (Test-Path $manifestPath)) {
  Add-Result ([ref]$results) 'manifest exists' $false "Missing $manifestPath"
} else {
  Add-Result ([ref]$results) 'manifest exists' $true $manifestPath
  $manifestText = Get-Content -Path $manifestPath -Raw
  $required = @()
  $inRequired = $false
  foreach ($line in ($manifestText -split "`r?`n")) {
    if ($line -match '^\s*required:\s*$') { $inRequired = $true; continue }
    if ($inRequired -and $line -match '^\s*optional:\s*$') { $inRequired = $false; continue }
    if ($inRequired -and $line -match '^\s*-\s+(.+?)\s*$') {
      $required += $matches[1].Trim()
    }
  }
  $missing = @()
  foreach ($doc in $required) {
    $docPath = Resolve-ProjectPath $doc
    if (-not (Test-Path $docPath)) { $missing += $doc }
  }
  $requiredDetail = ''
  if ($missing.Count -eq 0) {
    $requiredDetail = "count=$($required.Count)"
  } else {
    $requiredDetail = "missing: $($missing -join ', ')"
  }
  Add-Result ([ref]$results) 'required docs present' ($missing.Count -eq 0) $requiredDetail
}

# 2) legacy-migration-bootstrap
$bootstrapScript = Join-Path $ProjectRoot 'automation/skills/legacy-migration-bootstrap/scripts/bootstrap.ps1'
if (-not (Test-Path $bootstrapScript)) {
  Add-Result ([ref]$results) 'bootstrap skill script exists' $false $bootstrapScript
} else {
  Add-Result ([ref]$results) 'bootstrap skill script exists' $true $bootstrapScript
  $bootstrapJson = & powershell -ExecutionPolicy Bypass -File $bootstrapScript -ProjectRoot $ProjectRoot -AsJson
  if ($LASTEXITCODE -ne 0 -or -not $bootstrapJson) {
    Add-Result ([ref]$results) 'bootstrap run' $false 'bootstrap command failed'
  } else {
    $obj = $bootstrapJson | ConvertFrom-Json
    $phaseOk = -not [string]::IsNullOrWhiteSpace($obj.Phase) -and $obj.Phase -ne 'Unknown'
    Add-Result ([ref]$results) 'bootstrap run' $phaseOk "phase=$($obj.Phase)"
    $missingDocs = @($obj.Documents | Where-Object { -not $_.Exists })
    $bootstrapDocDetail = ''
    if ($missingDocs.Count -eq 0) {
      $bootstrapDocDetail = 'all docs OK'
    } else {
      $bootstrapDocDetail = "missing: $($missingDocs.File -join ', ')"
    }
    Add-Result ([ref]$results) 'bootstrap docs status' ($missingDocs.Count -eq 0) $bootstrapDocDetail
  }
}

# 3) springmvc-spa-routing-guard
$routingScript = Join-Path $ProjectRoot 'automation/skills/springmvc-spa-routing-guard/scripts/check-routing-contract.ps1'
if (-not (Test-Path $routingScript)) {
  Add-Result ([ref]$results) 'routing-guard skill script exists' $false $routingScript
} else {
  $routingOut = & powershell -ExecutionPolicy Bypass -File $routingScript -ProjectRoot $ProjectRoot -NoFail 2>&1 | Out-String
  $routingPass = ($routingOut -notmatch 'FAILED CHECKS')
  $routingDetail = ''
  if ($routingPass) {
    $routingDetail = 'all routing checks passed'
  } else {
    $routingDetail = 'contains FAILED CHECKS'
  }
  Add-Result ([ref]$results) 'routing-guard run' $routingPass $routingDetail (-not $LegacyMode)
}

# 4) react-capture-qa-runner prerequisites
$captureScript = Join-Path $ProjectRoot 'automation/skills/react-capture-qa-runner/scripts/run-capture.ps1'
$frontendPkg = Resolve-ProjectPath 'src/main/frontend/package.json'
if (-not (Test-Path $captureScript)) {
  Add-Result ([ref]$results) 'capture skill script exists' $false $captureScript
} elseif (-not (Test-Path $frontendPkg)) {
  Add-Result ([ref]$results) 'frontend package exists' $false $frontendPkg
} else {
  $pkgJson = Get-Content -Path $frontendPkg -Raw | ConvertFrom-Json
  $hasCaptureScript = $null -ne $pkgJson.scripts.'capture:react'
  $captureScriptDetail = ''
  if ($hasCaptureScript) {
    $captureScriptDetail = 'present'
  } else {
    $captureScriptDetail = 'missing in package.json'
  }
  Add-Result ([ref]$results) 'capture:react npm script' $hasCaptureScript $captureScriptDetail
  $captureDir = Resolve-ProjectPath 'captures/main'
  Add-Result ([ref]$results) 'capture output directory exists' (Test-Path $captureDir) $captureDir $false
}

# 5) migration-doc-sync compatibility against moved docs
$syncScript = Join-Path $ProjectRoot 'automation/skills/migration-doc-sync/scripts/sync-doc-stub.ps1'
$rootLogs = Get-ChildItem -Path $ProjectRoot -File -Filter 'SESSION_WORKLOG_*.md' -ErrorAction SilentlyContinue
$movedLogs = Get-ChildItem -Path (Resolve-ProjectPath 'docs/project-docs') -File -Filter 'SESSION_WORKLOG_*.md' -ErrorAction SilentlyContinue
if (-not (Test-Path $syncScript)) {
  Add-Result ([ref]$results) 'doc-sync skill script exists' $false $syncScript
} else {
  $rootLogDetail = ''
  if ($rootLogs.Count -gt 0) {
    $rootLogDetail = "root logs=$($rootLogs.Count)"
  } elseif ($movedLogs.Count -gt 0) {
    $rootLogDetail = "root log omitted; docs/project-docs logs=$($movedLogs.Count)"
  } else {
    $rootLogDetail = 'no root session log; wrapper should pass -SessionLog'
  }
  Add-Result ([ref]$results) 'doc-sync sessionlog autodetect (root)' (($rootLogs.Count -gt 0) -or ($movedLogs.Count -gt 0)) $rootLogDetail $false

  $movedLogDetail = ''
  if ($movedLogs.Count -gt 0) {
    $movedLogDetail = "docs/project-docs logs=$($movedLogs.Count)"
  } else {
    $movedLogDetail = 'missing docs/project-docs/SESSION_WORKLOG_*.md'
  }
  Add-Result ([ref]$results) 'doc-sync moved session log exists' ($movedLogs.Count -gt 0) $movedLogDetail $false
}

# 6) frontend session/login/logout guard policy
$loginPagePath = Resolve-ProjectPath 'src/main/frontend/src/pages/login/LoginPage.js'
$mainPagePath = Resolve-ProjectPath 'src/main/frontend/src/pages/main/MainPage.js'
if (-not (Test-Path $loginPagePath)) {
  Add-Result ([ref]$results) 'login page exists for session guard' $false $loginPagePath
} else {
  $loginText = Get-Content -Path $loginPagePath -Raw
  $hasSessionChecker = $loginText -match '/user/v1/sessionChecker'
  $hasSessionInfo = $loginText -match '/user/v1/sessionInfo'
  $hasRequiredCheck = $loginText -match 'hasRequired'
  Add-Result ([ref]$results) 'login session guard uses sessionChecker' $hasSessionChecker 'sessionChecker call present'
  Add-Result ([ref]$results) 'login session guard validates sessionInfo' ($hasSessionInfo -and $hasRequiredCheck) 'sessionInfo + required fields check present'
}

if (-not (Test-Path $mainPagePath)) {
  Add-Result ([ref]$results) 'main page exists for logout guard' $false $mainPagePath
} else {
  $mainText = Get-Content -Path $mainPagePath -Raw
  $hasLogoutApiCall = $mainText -match '/user/v1/logout'
  $hasLoginRedirect = $mainText -match "toAppUrl\(contextPath,\s*'/login'\)"
  $hasDirectLogoutHref = $mainText -match "window\.location\.(href|assign)\s*=\s*toAppUrl\(contextPath,\s*'/user/v1/logout'\)"
  Add-Result ([ref]$results) 'main logout calls backend api' $hasLogoutApiCall 'logout API call present'
  Add-Result ([ref]$results) 'main logout redirects to login page' $hasLoginRedirect 'login redirect present after logout'
  Add-Result ([ref]$results) 'main logout avoids direct logout href navigation' (-not $hasDirectLogoutHref) 'no direct browser navigation to /user/v1/logout'
}

$results | Format-Table -AutoSize

$criticalFailed = @($results | Where-Object { $_.Critical -and -not $_.Pass }).Count
if ($criticalFailed -gt 0) {
  Write-Host "SUMMARY: FAIL (critical=$criticalFailed)"
  exit 1
}

$warnFailed = @($results | Where-Object { -not $_.Critical -and -not $_.Pass }).Count
if ($warnFailed -gt 0) {
  Write-Host "SUMMARY: PASS_WITH_WARNINGS (warnings=$warnFailed)"
} else {
  Write-Host 'SUMMARY: PASS'
}
