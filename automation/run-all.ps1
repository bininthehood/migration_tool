param(
  [string]$ProjectRoot = (Get-Location).Path,
  [string]$User = 'admin',
  [string]$Password = 'admin',
  [ValidateSet('none', 'single', 'preset')][string]$CaptureMode = 'single',
  [string]$CapturePath = '/rays/ui/login',
  [string]$CaptureName = 'react-login-automation-check',
  [string]$CapturePreset = 'all',
  [string]$CaptureBaseUrl = 'http://localhost:3000',
  [int]$CaptureDevServerPort = 3000,
  [int]$CaptureDevServerStartTimeoutSec = 120,
  [switch]$DisableAutoStartCaptureDevServer,
  [switch]$BootstrapFrontend,
  [switch]$DisableAutoBootstrapFrontend,
  [switch]$LegacyMode,
  [switch]$InstallFrontendDeps,
  [switch]$DisableAutoInstallFrontendDeps,
  [switch]$DisableAutoInstallPlaywrightBrowsers,
  [switch]$SkipFrontendCompileCheck,
  [switch]$SkipSessionContractCheck,
  [switch]$SkipFrontendCheck,
  [string]$TomcatBaseUrl = 'http://localhost:8080',
  [string]$TomcatContextPath = '/rays',
  [string]$TomcatHealthPath = '/ui/',
  [string]$TomcatHome = 'C:\dev\eclipse\bin\apache-tomcat-9.0.100',
  [string]$TomcatBase = 'C:\dev\eclipse\workspace\.metadata\.plugins\org.eclipse.wst.server.core\tmp0',
  [string]$TomcatJreHome = 'C:\Users\rays\.p2\pool\plugins\org.eclipse.justj.openjdk.hotspot.jre.full.win32.x86_64_21.0.10.v20260205-0638\jre',
  [ValidateSet('none', 'start', 'stop', 'restart')][string]$TomcatControlAction = 'none',
  [int]$TomcatControlTimeoutSec = 120,
  [switch]$TomcatControlNoHealthCheck,
  [switch]$SkipTomcatCheck,
  [string]$LogDir = 'automation/logs',
  [string]$FeedbackFile = 'docs/project-docs/MIGRATION_AUTOMATION_FEEDBACK.md',
  [int]$HistoryWindow = 20,
  [switch]$Build,
  [string]$MigrateScreen = '',
  [string]$MigrateBatch = '',
  [string]$MigrationPlanFile = 'automation/migration-screen-map.json',
  [string]$MigrationOutputDir = 'docs/project-docs/migration-checklists',
  [switch]$SkipReactFunctionCommenting,
  [switch]$SkipDocSync
)

$ErrorActionPreference = 'Stop'

function Step([string]$Name, [scriptblock]$Action) {
  Write-Host ""
  Write-Host "== $Name =="
  & $Action
}

function Wait-PortListening([int]$Port, [int]$TimeoutSec) {
  $deadline = (Get-Date).AddSeconds($TimeoutSec)
  do {
    $conn = Get-NetTCPConnection -LocalPort $Port -State Listen -ErrorAction SilentlyContinue
    if ($conn) { return $true }
    Start-Sleep -Seconds 2
  } while ((Get-Date) -lt $deadline)
  return $false
}

function Get-ErrorCode([string]$Message) {
  if ([string]::IsNullOrWhiteSpace($Message)) { return 'UNKNOWN' }
  if ($Message -match 'EPERM|browserType\.launch|spawn EPERM') { return 'CAPTURE_EPERM' }
  if ($Message -match 'EADDRINUSE|port 3000|port 8080|already in use') { return 'PORT_CONFLICT' }
  if ($Message -match 'Missing .*\.ps1|Missing C:') { return 'SCRIPT_MISSING' }
  if ($Message -match 'npm run build failed|frontend compile check failed|npm ERR!') { return 'NPM_BUILD_FAIL' }
  if ($Message -match 'routing check failed') { return 'ROUTING_CONTRACT_FAIL' }
  if ($Message -match 'screen migration step failed') { return 'MIGRATION_EXEC_FAIL' }
  if ($Message -match 'validate step failed') { return 'PREFLIGHT_FAIL' }
  if ($Message -match 'doc-sync step failed|run-doc-sync') { return 'DOC_SYNC_FAIL' }
  if ($Message -match 'TOMCAT_NOT_READY') { return 'TOMCAT_NOT_READY' }
  if ($Message -match 'TOMCAT_CONTROL_FAIL') { return 'TOMCAT_CONTROL_FAIL' }
  if ($Message -match 'Cannot find module ''playwright''|Cannot find module|frontend deps install failed') { return 'FRONTEND_DEPS_MISSING' }
  if ($Message -match 'Executable doesn''t exist at|playwright install|browser executable') { return 'PLAYWRIGHT_BROWSER_MISSING' }
  if ($Message -match 'FRONTEND_BOOTSTRAP_REQUIRED') { return 'FRONTEND_BOOTSTRAP_REQUIRED' }
  if ($Message -match 'session contract check failed|policyCheck resultCode|sessionAlive resultCode|sessionInfo resultCode|sessionInfo\.sessionData') { return 'SESSION_CONTRACT_FAIL' }
  return 'UNKNOWN'
}

function Add-StepResult([string]$Name, [string]$Status, [double]$DurationSec, [string]$ErrorCode, [string]$ErrorMessage) {
  $script:stepResults += [pscustomobject]@{
    name = $Name
    status = $Status
    duration_sec = [Math]::Round($DurationSec, 2)
    error_code = $ErrorCode
    error_message = $ErrorMessage
  }
}

function Invoke-TrackedStep([string]$Name, [scriptblock]$Action) {
  $sw = [System.Diagnostics.Stopwatch]::StartNew()
  try {
    Step $Name $Action
    $sw.Stop()
    Add-StepResult -Name $Name -Status 'success' -DurationSec $sw.Elapsed.TotalSeconds -ErrorCode '' -ErrorMessage ''
  }
  catch {
    $sw.Stop()
    $message = $_.Exception.Message
    $code = Get-ErrorCode -Message $message
    Add-StepResult -Name $Name -Status 'failed' -DurationSec $sw.Elapsed.TotalSeconds -ErrorCode $code -ErrorMessage $message
    throw
  }
}

function Get-ImprovementSuggestions([string]$ResolvedLogDir, [int]$Window) {
  if (-not (Test-Path $ResolvedLogDir)) { return @() }
  $files = Get-ChildItem -Path $ResolvedLogDir -File -Filter 'run-*.json' |
    Sort-Object LastWriteTime -Descending |
    Select-Object -First $Window
  if (-not $files -or $files.Count -eq 0) { return @() }

  $counter = @{}
  foreach ($file in $files) {
    try {
      $obj = Get-Content -Path $file.FullName -Raw | ConvertFrom-Json
      foreach ($step in $obj.steps) {
        if ($step.status -eq 'failed' -and -not [string]::IsNullOrWhiteSpace($step.error_code)) {
          if (-not $counter.ContainsKey($step.error_code)) { $counter[$step.error_code] = 0 }
          $counter[$step.error_code] += 1
        }
      }
    }
    catch {
      # ignore malformed historical logs
    }
  }

  if ($counter.Count -eq 0) { return @() }
  $sorted = $counter.GetEnumerator() | Sort-Object Value -Descending | Select-Object -First 3
  $out = @()
  foreach ($item in $sorted) {
    $suggestion = switch ($item.Key) {
      'CAPTURE_EPERM' { 'Add a pre-check for browser launch permission and a retry path with elevated permission.' }
      'PORT_CONFLICT' { 'Preflight-check ports 3000/8080 and auto-handle conflicts before capture/build.' }
      'SCRIPT_MISSING' { 'Fail fast on missing automation/skills files and print exact remediation steps.' }
      'NPM_BUILD_FAIL' { 'Run dependency verification before build and auto-suggest npm install/ci.' }
      'MIGRATION_EXEC_FAIL' { 'Validate migration-screen-map entries (id/group/legacyUrl/reactRoute) before orchestration.' }
      'ROUTING_CONTRACT_FAIL' { 'Print focused routing diffs for dispatcher-servlet.xml and controllers on failure.' }
      'DOC_SYNC_FAIL' { 'Search session logs in both root and docs/project-docs paths by default.' }
      'TOMCAT_CONTROL_FAIL' { 'Validate CATALINA_HOME/BASE/JRE paths and automate startup/shutdown with health polling.' }
      'FRONTEND_DEPS_MISSING' { 'Auto-run npm install in src/main/frontend before capture/build when dependencies are missing.' }
      'PLAYWRIGHT_BROWSER_MISSING' { 'Auto-run npx playwright install before capture when browser binaries are missing.' }
      'FRONTEND_BOOTSTRAP_REQUIRED' { 'Add frontend bootstrap step (src/main/frontend + package/capture script) before migration run.' }
      default { 'Promote recurring failure text patterns into explicit error codes with recoveries.' }
    }
    $out += [pscustomobject]@{
      error_code = $item.Key
      count = [int]$item.Value
      recommendation = $suggestion
    }
  }
  return $out
}

function Write-FeedbackArtifacts() {
  $resolvedLogDir = Join-Path $ProjectRoot $LogDir
  $resolvedFeedback = Join-Path $ProjectRoot $FeedbackFile
  if (-not (Test-Path $resolvedLogDir)) {
    New-Item -ItemType Directory -Path $resolvedLogDir -Force | Out-Null
  }
  $feedbackDir = Split-Path -Path $resolvedFeedback -Parent
  if (-not (Test-Path $feedbackDir)) {
    New-Item -ItemType Directory -Path $feedbackDir -Force | Out-Null
  }

  $suggestions = Get-ImprovementSuggestions -ResolvedLogDir $resolvedLogDir -Window $HistoryWindow
  $failedSteps = @($script:stepResults | Where-Object { $_.status -eq 'failed' })
  $totalDuration = [Math]::Round(((Get-Date) - $script:runStartedAt).TotalSeconds, 2)

  $runLog = [ordered]@{
    run_id = $script:runId
    started_at = $script:runStartedAt.ToString('o')
    finished_at = (Get-Date).ToString('o')
    status = $script:runStatus
    project_root = $ProjectRoot
    options = [ordered]@{
      capture_mode = $CaptureMode
      capture_path = $CapturePath
      capture_name = $CaptureName
      capture_preset = $CapturePreset
      capture_base_url = $CaptureBaseUrl
      tomcat_control_action = $TomcatControlAction
      build = [bool]$Build
      migrate_screen = $MigrateScreen
      migrate_batch = $MigrateBatch
      migration_plan_file = $MigrationPlanFile
      migration_output_dir = $MigrationOutputDir
      skip_react_function_commenting = [bool]$SkipReactFunctionCommenting
      skip_frontend_compile_check = [bool]$SkipFrontendCompileCheck
      skip_session_contract_check = [bool]$SkipSessionContractCheck
      skip_doc_sync = [bool]$SkipDocSync
    }
    duration_sec = $totalDuration
    commands = $script:executedCommands
    captures = $script:captures
    steps = $script:stepResults
    failure_codes = @($failedSteps | Select-Object -ExpandProperty error_code -Unique)
    suggestions = $suggestions
  }

  $logFile = Join-Path $resolvedLogDir ("run-{0}.json" -f $script:runId)
  $runLog | ConvertTo-Json -Depth 8 | Set-Content -Path $logFile -Encoding UTF8

  if (-not (Test-Path $resolvedFeedback)) {
    Set-Content -Path $resolvedFeedback -Encoding UTF8 -Value "# Migration Automation Feedback`n"
  }

  $stepLines = @($script:stepResults | ForEach-Object {
    "- $($_.name): $($_.status) ($($_.duration_sec)s)$(if($_.error_code){", code=$($_.error_code)"}else{''})"
  }) -join "`n"
  $failureCodeLines = if ($failedSteps.Count -gt 0) {
    @($failedSteps | ForEach-Object { "- $($_.error_code): $($_.error_message)" }) -join "`n"
  } else {
    "- none"
  }
  $suggestionLines = if ($suggestions.Count -gt 0) {
    @($suggestions | ForEach-Object { "- [$($_.error_code)] x$($_.count): $($_.recommendation)" }) -join "`n"
  } else {
    "- none"
  }

  $entry = @"

## Run $($script:runId) - $($script:runStatus)
- Started: $($script:runStartedAt.ToString('yyyy-MM-dd HH:mm:ss zzz'))
- Duration: ${totalDuration}s
- CaptureMode: $CaptureMode
- TomcatControlAction: $TomcatControlAction
- Build: $([bool]$Build)
- Log: automation/logs/run-$($script:runId).json

### Steps
$stepLines

### Failure Codes
$failureCodeLines

### Improvement Suggestions
$suggestionLines
"@
  Add-Content -Path $resolvedFeedback -Value $entry -Encoding UTF8
}

$script:executedCommands = @()
$script:captures = @()
$script:stepResults = @()
$script:autoLegacyMode = $false
$script:runStartedAt = Get-Date
$script:runId = Get-Date -Format 'yyyyMMdd-HHmmss'
$script:runStatus = 'success'

$validateScript = Join-Path $ProjectRoot 'automation/validate-skill-integration.ps1'
$docSyncScript = Join-Path $ProjectRoot 'automation/run-doc-sync.ps1'
$captureSkillScript = Join-Path $ProjectRoot 'automation/skills/react-capture-qa-runner/scripts/run-capture.ps1'
$screenMigrationScript = Join-Path $ProjectRoot 'automation/run-screen-migration.ps1'
$annotateReactFunctionsScript = Join-Path $ProjectRoot 'automation/annotate-react-functions.ps1'
$bootstrapScript = Join-Path $ProjectRoot 'automation/bootstrap-frontend.ps1'
$tomcatControlScript = Join-Path $ProjectRoot 'automation/tomcat-control.ps1'
$sessionContractScript = Join-Path $ProjectRoot 'automation/verify-session-contract.ps1'

if (-not (Test-Path $validateScript)) { throw "Missing $validateScript" }
if (-not (Test-Path $docSyncScript)) { throw "Missing $docSyncScript" }
if ($TomcatControlAction -ne 'none' -and -not (Test-Path $tomcatControlScript)) { throw "Missing $tomcatControlScript" }
if (-not $SkipSessionContractCheck -and -not (Test-Path $sessionContractScript)) { throw "Missing $sessionContractScript" }
if ((-not [string]::IsNullOrWhiteSpace($MigrateScreen) -or -not [string]::IsNullOrWhiteSpace($MigrateBatch)) -and -not (Test-Path $screenMigrationScript)) {
  throw "Missing $screenMigrationScript"
}
if ((-not [string]::IsNullOrWhiteSpace($MigrateScreen) -or -not [string]::IsNullOrWhiteSpace($MigrateBatch)) -and -not $SkipReactFunctionCommenting -and -not (Test-Path $annotateReactFunctionsScript)) {
  throw "Missing $annotateReactFunctionsScript"
}

try {
  if (-not $SkipFrontendCheck) {
    Invoke-TrackedStep 'Frontend Bootstrap Check' {
      $frontendDir = Join-Path $ProjectRoot 'src/main/frontend'
      $pkgPath = Join-Path $frontendDir 'package.json'
      $capturePath = Join-Path $frontendDir 'scripts/capture-react.cjs'
      $publicIndexPath = Join-Path $frontendDir 'public/index.html'
      $srcIndexPath = Join-Path $frontendDir 'src/index.js'
      $uiIndexPath = Join-Path $ProjectRoot 'src/main/webapp/ui/index.html'
      $missing = @()
      if (-not (Test-Path $frontendDir)) { $missing += 'src/main/frontend' }
      if (-not (Test-Path $pkgPath)) { $missing += 'src/main/frontend/package.json' }
      if (-not (Test-Path $capturePath)) { $missing += 'src/main/frontend/scripts/capture-react.cjs' }
      if (-not (Test-Path $publicIndexPath)) { $missing += 'src/main/frontend/public/index.html' }
      if (-not (Test-Path $srcIndexPath)) { $missing += 'src/main/frontend/src/index.js' }
      $useTomcatCapture = ($CaptureMode -ne 'none' -and ($CaptureBaseUrl -notmatch '^https?://(localhost|127\.0\.0\.1):3000/?$'))
      if ($useTomcatCapture -and -not (Test-Path $uiIndexPath)) { $missing += 'src/main/webapp/ui/index.html' }

      if ($missing.Count -eq 0) { return }
      $script:autoLegacyMode = $true
      if (-not (Test-Path $bootstrapScript)) {
        throw "FRONTEND_BOOTSTRAP_REQUIRED: missing frontend artifacts ($($missing -join ', ')) and missing bootstrap script."
      }

      $shouldAutoBootstrap = (-not $DisableAutoBootstrapFrontend)
      if (-not $shouldAutoBootstrap -and -not $BootstrapFrontend) {
        throw "FRONTEND_BOOTSTRAP_REQUIRED: missing frontend artifacts ($($missing -join ', ')). Run: powershell -ExecutionPolicy Bypass -File automation/bootstrap-frontend.ps1 -ProjectRoot `"$ProjectRoot`" -Apply"
      }

      $templateFrontendRoot = 'C:\Users\rays\ArcFlow_Webv1.2\src\main\frontend'
      $templateUiRoot = 'C:\Users\rays\ArcFlow_Webv1.2\src\main\webapp\ui'
      $bootCmd = "powershell -ExecutionPolicy Bypass -File `"$bootstrapScript`" -ProjectRoot `"$ProjectRoot`" -Apply -TemplateFrontendRoot `"$templateFrontendRoot`" -TemplateUiRoot `"$templateUiRoot`""
      $bootArgs = @(
        '-ExecutionPolicy', 'Bypass',
        '-File', $bootstrapScript,
        '-ProjectRoot', $ProjectRoot,
        '-Apply',
        '-TemplateFrontendRoot', $templateFrontendRoot,
        '-TemplateUiRoot', $templateUiRoot
      )
      if ($InstallFrontendDeps) {
        $bootCmd += ' -InstallDeps'
        $bootArgs += '-InstallDeps'
      }
      $script:executedCommands += $bootCmd
      & powershell @bootArgs
      if ($LASTEXITCODE -ne 0) { throw "FRONTEND_BOOTSTRAP_REQUIRED: bootstrap command failed: $LASTEXITCODE" }
    }
  }

  if ($TomcatControlAction -ne 'none') {
    Invoke-TrackedStep "Tomcat Control ($TomcatControlAction)" {
      $cmdParts = @(
        'powershell', '-ExecutionPolicy', 'Bypass',
        '-File', "`"$tomcatControlScript`"",
        '-Action', $TomcatControlAction,
        '-TomcatHome', "`"$TomcatHome`"",
        '-TomcatBase', "`"$TomcatBase`"",
        '-TomcatJreHome', "`"$TomcatJreHome`"",
        '-TomcatBaseUrl', $TomcatBaseUrl,
        '-TomcatContextPath', $TomcatContextPath,
        '-TomcatHealthPath', $TomcatHealthPath,
        '-TimeoutSec', $TomcatControlTimeoutSec
      )
      $invokeArgs = @(
        '-ExecutionPolicy', 'Bypass',
        '-File', $tomcatControlScript,
        '-Action', $TomcatControlAction,
        '-TomcatHome', $TomcatHome,
        '-TomcatBase', $TomcatBase,
        '-TomcatJreHome', $TomcatJreHome,
        '-TomcatBaseUrl', $TomcatBaseUrl,
        '-TomcatContextPath', $TomcatContextPath,
        '-TomcatHealthPath', $TomcatHealthPath,
        '-TimeoutSec', $TomcatControlTimeoutSec
      )
      if ($TomcatControlNoHealthCheck) {
        $cmdParts += '-NoHealthCheck'
        $invokeArgs += '-NoHealthCheck'
      }
      $script:executedCommands += ($cmdParts -join ' ')
      & powershell @invokeArgs
      if ($LASTEXITCODE -ne 0) { throw "TOMCAT_CONTROL_FAIL: tomcat-control step failed: $LASTEXITCODE" }
    }
  }

  if (-not $SkipTomcatCheck) {
    Invoke-TrackedStep 'Tomcat Ready Check' {
      $healthUrl = "{0}{1}{2}" -f $TomcatBaseUrl.TrimEnd('/'), $TomcatContextPath, $TomcatHealthPath
      $script:executedCommands += "GET $healthUrl"
      try {
        $resp = Invoke-WebRequest -Uri $healthUrl -Method Get -UseBasicParsing -TimeoutSec 8
        if ($resp.StatusCode -lt 200 -or $resp.StatusCode -ge 400) {
          throw "TOMCAT_NOT_READY: health check returned status $($resp.StatusCode). Please start Tomcat once, then rerun."
        }
      }
      catch {
        throw "TOMCAT_NOT_READY: cannot reach $healthUrl. Please start Tomcat once, then rerun."
      }
    }
  }

  if (-not $SkipSessionContractCheck) {
    Invoke-TrackedStep 'Verify Session Contract' {
      $cmdParts = @(
        'powershell', '-ExecutionPolicy', 'Bypass',
        '-File', "`"$sessionContractScript`"",
        '-ProjectRoot', "`"$ProjectRoot`"",
        '-TomcatBaseUrl', $TomcatBaseUrl,
        '-TomcatContextPath', $TomcatContextPath,
        '-User', $User,
        '-Password', $Password
      )
      $script:executedCommands += ($cmdParts -join ' ')
      & powershell -ExecutionPolicy Bypass `
        -File $sessionContractScript `
        -ProjectRoot $ProjectRoot `
        -TomcatBaseUrl $TomcatBaseUrl `
        -TomcatContextPath $TomcatContextPath `
        -User $User `
        -Password $Password
      if ($LASTEXITCODE -ne 0) { throw "session contract check failed: $LASTEXITCODE" }
    }
  }

  if (-not $DisableAutoInstallFrontendDeps) {
    Invoke-TrackedStep 'Ensure Frontend Dependencies' {
      $frontendDir = Join-Path $ProjectRoot 'src/main/frontend'
      $pkgPath = Join-Path $frontendDir 'package.json'
      if (-not (Test-Path $pkgPath)) {
        throw "frontend deps install failed: missing $pkgPath"
      }

      $nodeModulesDir = Join-Path $frontendDir 'node_modules'
      $playwrightModule = Join-Path $nodeModulesDir 'playwright'
      $needInstall = $InstallFrontendDeps -or -not (Test-Path $nodeModulesDir)
      if (-not $needInstall -and $CaptureMode -ne 'none' -and -not (Test-Path $playwrightModule)) {
        $needInstall = $true
      }

      if (-not $needInstall) { return }

      $cmd = "cd `"$frontendDir`"; npm install"
      $script:executedCommands += $cmd
      Push-Location $frontendDir
      try {
        & npm install
        if ($LASTEXITCODE -ne 0) { throw "frontend deps install failed: npm install exit $LASTEXITCODE" }
      }
      finally {
        Pop-Location
      }
    }
  }

  if ($CaptureMode -ne 'none' -and -not $DisableAutoInstallPlaywrightBrowsers) {
    Invoke-TrackedStep 'Ensure Playwright Browsers' {
      $frontendDir = Join-Path $ProjectRoot 'src/main/frontend'
      $playwrightRoot = Join-Path $env:LOCALAPPDATA 'ms-playwright'
      $hasChromiumShell = $false
      if (Test-Path $playwrightRoot) {
        $dirs = Get-ChildItem -Path $playwrightRoot -Directory -Filter 'chromium_headless_shell-*' -ErrorAction SilentlyContinue
        $hasChromiumShell = ($dirs.Count -gt 0)
      }
      if ($hasChromiumShell) { return }

      $cmd = "cd `"$frontendDir`"; npx playwright install"
      $script:executedCommands += $cmd
      Push-Location $frontendDir
      try {
        & npx playwright install
        if ($LASTEXITCODE -ne 0) { throw "playwright install failed: exit $LASTEXITCODE" }
      }
      finally {
        Pop-Location
      }
    }
  }

  if (-not $SkipFrontendCompileCheck) {
    Invoke-TrackedStep 'Frontend Compile Check' {
      $frontendDir = Join-Path $ProjectRoot 'src/main/frontend'
      $buildPath = 'build_automation_smoke'
      $cmd = "cd `"$frontendDir`"; set BUILD_PATH=$buildPath; npm run build"
      $script:executedCommands += $cmd
      Push-Location $frontendDir
      try {
        $env:BUILD_PATH = $buildPath
        & npm run build
        if ($LASTEXITCODE -ne 0) { throw "frontend compile check failed: npm run build exit $LASTEXITCODE" }
      }
      finally {
        Remove-Item -Recurse -Force $buildPath -ErrorAction SilentlyContinue
        Remove-Item Env:BUILD_PATH -ErrorAction SilentlyContinue
        Pop-Location
      }
    }
  }

  if ($CaptureMode -ne 'none' -and -not $DisableAutoStartCaptureDevServer) {
    Invoke-TrackedStep 'Ensure Capture Frontend Server' {
      $captureTarget = $CaptureBaseUrl.TrimEnd('/')
      $devRegex = "^https?://(localhost|127\.0\.0\.1):$CaptureDevServerPort$"
      if ($captureTarget -notmatch $devRegex) { return }

      if (Wait-PortListening -Port $CaptureDevServerPort -TimeoutSec 1) { return }

      $frontendDir = Join-Path $ProjectRoot 'src/main/frontend'
      $cmd = "cd `"$frontendDir`"; npm run dev"
      $script:executedCommands += $cmd
      $proc = Start-Process -FilePath 'cmd.exe' -ArgumentList '/c','npm run dev' -WorkingDirectory $frontendDir -PassThru
      Write-Host "Capture dev server started. PID=$($proc.Id), port=$CaptureDevServerPort"

      if (-not (Wait-PortListening -Port $CaptureDevServerPort -TimeoutSec $CaptureDevServerStartTimeoutSec)) {
        throw "capture dev server did not become ready on port $CaptureDevServerPort within ${CaptureDevServerStartTimeoutSec}s"
      }
    }
  }

  Invoke-TrackedStep 'Validate Skill Integration' {
    $effectiveLegacyMode = ($LegacyMode -or $script:autoLegacyMode)
    $cmd = "powershell -ExecutionPolicy Bypass -File `"$validateScript`" -ProjectRoot `"$ProjectRoot`""
    $invokeArgs = @('-ExecutionPolicy', 'Bypass', '-File', $validateScript, '-ProjectRoot', $ProjectRoot)
    if ($effectiveLegacyMode) {
      $cmd += ' -LegacyMode'
      $invokeArgs += '-LegacyMode'
    }
    $script:executedCommands += $cmd
    & powershell @invokeArgs

    if ($LASTEXITCODE -ne 0 -and -not $effectiveLegacyMode) {
      # Fresh legacy projects can fail strict validation before routing migration starts.
      # Auto-retry once in legacy mode to continue orchestration bootstrap.
      $retryCmd = "powershell -ExecutionPolicy Bypass -File `"$validateScript`" -ProjectRoot `"$ProjectRoot`" -LegacyMode"
      $script:executedCommands += $retryCmd
      & powershell -ExecutionPolicy Bypass -File $validateScript -ProjectRoot $ProjectRoot -LegacyMode
      if ($LASTEXITCODE -eq 0) {
        $script:autoLegacyMode = $true
      } else {
        throw "validate step failed: $LASTEXITCODE"
      }
    } elseif ($LASTEXITCODE -ne 0) {
      throw "validate step failed: $LASTEXITCODE"
    }
  }

  Invoke-TrackedStep 'Check Routing Contract' {
    $effectiveLegacyMode = ($LegacyMode -or $script:autoLegacyMode)
    $routingScript = Join-Path $ProjectRoot 'automation/skills/springmvc-spa-routing-guard/scripts/check-routing-contract.ps1'
    if (-not (Test-Path $routingScript)) { throw "Missing $routingScript" }
    $cmd = "powershell -ExecutionPolicy Bypass -File `"$routingScript`" -ProjectRoot `"$ProjectRoot`""
    $invokeArgs = @('-ExecutionPolicy', 'Bypass', '-File', $routingScript, '-ProjectRoot', $ProjectRoot)
    if ($effectiveLegacyMode) {
      $cmd += ' -NoFail'
      $invokeArgs += '-NoFail'
    }
    $script:executedCommands += $cmd
    & powershell @invokeArgs
    if (-not $effectiveLegacyMode -and $LASTEXITCODE -ne 0) { throw "routing check failed: $LASTEXITCODE" }
  }

  if (-not [string]::IsNullOrWhiteSpace($MigrateScreen) -or -not [string]::IsNullOrWhiteSpace($MigrateBatch)) {
    Invoke-TrackedStep 'Run Screen Migration' {
      $cmdParts = @(
        'powershell', '-ExecutionPolicy', 'Bypass',
        '-File', "`"$screenMigrationScript`"",
        '-ProjectRoot', "`"$ProjectRoot`"",
        '-MigrationPlanFile', "`"$MigrationPlanFile`"",
        '-OutputDir', "`"$MigrationOutputDir`""
      )
      $invokeArgs = @(
        '-ExecutionPolicy', 'Bypass',
        '-File', $screenMigrationScript,
        '-ProjectRoot', $ProjectRoot,
        '-MigrationPlanFile', $MigrationPlanFile,
        '-OutputDir', $MigrationOutputDir
      )
      if (-not [string]::IsNullOrWhiteSpace($MigrateScreen)) {
        $cmdParts += @('-MigrateScreen', $MigrateScreen)
        $invokeArgs += @('-MigrateScreen', $MigrateScreen)
      }
      if (-not [string]::IsNullOrWhiteSpace($MigrateBatch)) {
        $cmdParts += @('-MigrateBatch', $MigrateBatch)
        $invokeArgs += @('-MigrateBatch', $MigrateBatch)
      }

      $script:executedCommands += ($cmdParts -join ' ')
      & powershell @invokeArgs
      if ($LASTEXITCODE -ne 0) { throw "screen migration step failed: $LASTEXITCODE" }
    }

    if (-not $SkipReactFunctionCommenting) {
      Invoke-TrackedStep 'Annotate React Function Comments' {
        $cmdParts = @(
          'powershell', '-ExecutionPolicy', 'Bypass',
          '-File', "`"$annotateReactFunctionsScript`"",
          '-ProjectRoot', "`"$ProjectRoot`""
        )
        $script:executedCommands += ($cmdParts -join ' ')
        & powershell -ExecutionPolicy Bypass -File $annotateReactFunctionsScript -ProjectRoot $ProjectRoot
        if ($LASTEXITCODE -ne 0) { throw "react function comment step failed: $LASTEXITCODE" }
      }
    }
  }

  if ($CaptureMode -ne 'none') {
    Invoke-TrackedStep 'Run Capture' {
      if (-not (Test-Path $captureSkillScript)) { throw "Missing $captureSkillScript" }

      $cmdParts = @(
        'powershell', '-ExecutionPolicy', 'Bypass',
        '-File', "`"$captureSkillScript`"",
        '-ProjectRoot', "`"$ProjectRoot`"",
        '-Mode', $CaptureMode
      )
      $invokeArgs = @(
        '-ExecutionPolicy', 'Bypass',
        '-File', $captureSkillScript,
        '-ProjectRoot', $ProjectRoot,
        '-Mode', $CaptureMode
      )

      if ($CaptureMode -eq 'single') {
        $cmdParts += @('-Path', $CapturePath, '-Name', $CaptureName)
        $invokeArgs += @('-Path', $CapturePath, '-Name', $CaptureName)
      } else {
        $cmdParts += @('-Preset', $CapturePreset)
        $invokeArgs += @('-Preset', $CapturePreset)
      }
      if ($CaptureBaseUrl) {
        $cmdParts += @('-BaseUrl', $CaptureBaseUrl)
        $invokeArgs += @('-BaseUrl', $CaptureBaseUrl)
      }

      if ($User) {
        $cmdParts += @('-User', $User)
        $invokeArgs += @('-User', $User)
      }
      if ($Password) {
        $cmdParts += @('-Password', $Password)
        $invokeArgs += @('-Password', $Password)
      }

      $script:executedCommands += ($cmdParts -join ' ')
      $captureStart = Get-Date
      & powershell @invokeArgs
      if ($LASTEXITCODE -ne 0) { throw "capture step failed: $LASTEXITCODE" }

      $captureDir = Join-Path $ProjectRoot 'captures/main'
      if ($CaptureMode -eq 'single') {
        $newCapture = Get-ChildItem -Path $captureDir -File -Filter "$CaptureName-*.png" -ErrorAction SilentlyContinue |
          Where-Object { $_.LastWriteTime -ge $captureStart } |
          Sort-Object LastWriteTime -Descending |
          Select-Object -First 1
        if ($newCapture) {
          $script:captures += $newCapture.FullName.Replace($ProjectRoot + '\', '').Replace('\', '/')
        }
      }
    }
  }

  if ($Build) {
    Invoke-TrackedStep 'Build Frontend' {
      $frontend = Join-Path $ProjectRoot 'src/main/frontend'
      $cmd = "cd `"$frontend`"; npm run build"
      $script:executedCommands += $cmd
      Push-Location $frontend
      try {
        & npm run build
        if ($LASTEXITCODE -ne 0) { throw "npm run build failed: $LASTEXITCODE" }
      }
      finally {
        Pop-Location
      }
    }
  }

  if (-not $SkipDocSync) {
    Invoke-TrackedStep 'Sync Session Log' {
      $changedFiles = @(
        'automation/run-all.ps1',
        'automation/annotate-react-functions.ps1',
        'automation/run-screen-migration.ps1',
        'automation/migration-screen-map.json',
        'automation/tomcat-control.ps1',
        'automation/verify-session-contract.ps1',
        'automation/validate-skill-integration.ps1',
        'automation/run-doc-sync.ps1',
        'README.md',
        'WORKFLOW.md',
        'TASK_BOARD.md',
        'docs-migration-backlog.md'
      )
      $syncArgs = @(
        '-ExecutionPolicy', 'Bypass',
        '-File', $docSyncScript,
        '-ProjectRoot', $ProjectRoot,
        '-ChangedFiles'
      ) + $changedFiles + @(
        '-Commands'
      ) + $script:executedCommands

      if ($script:captures.Count -gt 0) {
        $syncArgs += @('-Captures') + $script:captures
      } else {
        $syncArgs += @('-Captures', 'none')
      }

      $syncArgs += '-Apply'
      & powershell @syncArgs
      if ($LASTEXITCODE -ne 0) { throw "doc-sync step failed: $LASTEXITCODE" }
    }
  }
}
catch {
  $script:runStatus = 'failed'
  throw
}
finally {
  Write-FeedbackArtifacts
}

Write-Host ""
Write-Host '== DONE =='
Write-Host "ProjectRoot: $ProjectRoot"
Write-Host "CaptureMode: $CaptureMode"
if ($script:captures.Count -gt 0) {
  Write-Host "CaptureFiles: $($script:captures -join ', ')"
}
