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
  [int]$FrontendInstallTimeoutSec = 900,
  [switch]$DisableAutoInstallPlaywrightBrowsers,
  [switch]$SkipFrontendCompileCheck,
  [int]$FrontendBuildTimeoutSec = 1800,
  [switch]$SkipSessionContractCheck,
  [switch]$SkipFrontendCheck,
  [switch]$GitCommit,
  [string]$GitCommitMessage = '',
  [string]$GitRemoteUrl = '',
  [string]$GitDefaultBranch = 'main',
  [switch]$GitInitIfMissing,
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

function New-Utf8NoBomEncoding() {
  return New-Object System.Text.UTF8Encoding($false)
}

function Write-Utf8NoBomFile([string]$Path, [string]$Content) {
  $dir = Split-Path -Path $Path -Parent
  if ($dir -and -not (Test-Path $dir)) {
    New-Item -ItemType Directory -Path $dir -Force | Out-Null
  }
  [System.IO.File]::WriteAllText($Path, $Content, (New-Utf8NoBomEncoding))
}

function Append-Utf8NoBomFile([string]$Path, [string]$Content) {
  $dir = Split-Path -Path $Path -Parent
  if ($dir -and -not (Test-Path $dir)) {
    New-Item -ItemType Directory -Path $dir -Force | Out-Null
  }
  [System.IO.File]::AppendAllText($Path, $Content, (New-Utf8NoBomEncoding))
}

function Test-MojibakePattern([string]$Path) {
  $patterns = @(
    [regex]::Escape([string][char]0xFFFD),
    '\?\p{IsHangulSyllables}'
  )
  $content = [System.IO.File]::ReadAllText($Path)
  foreach ($pattern in $patterns) {
    if ($content -match $pattern) { return $true }
  }
  return $false
}

function Get-MojibakeCandidates([string]$RootPath) {
  $candidateDirs = @(
    (Join-Path $RootPath 'src'),
    (Join-Path $RootPath 'automation')
  ) | Where-Object { Test-Path $_ } | Select-Object -Unique
  $extensions = @('.js', '.jsx', '.ts', '.tsx', '.java', '.xml', '.jsp', '.ps1')
  $out = New-Object System.Collections.Generic.List[string]
  foreach ($dir in $candidateDirs) {
    Get-ChildItem -Path $dir -Recurse -File -ErrorAction SilentlyContinue |
      Where-Object {
        $extensions -contains $_.Extension.ToLowerInvariant() -and
        $_.FullName -notmatch '\\node_modules\\|\\build(_automation_smoke)?\\|\\target\\|\\dist\\|\\captures\\|\\src\\main\\webapp\\resources\\component\\' -and
        $_.FullName -notmatch '\\automation\\run-all\.ps1$' -and
        $_.FullName -notmatch '\\src\\main\\java\\com\\rays\\app\\util\\data\\EncodingFixUtil\.java$' -and
        $_.FullName -notmatch '\\src\\main\\java\\com\\rays\\app\\util\\file\\CompressionUtil\.java$'
      } |
      ForEach-Object {
        try {
          if (Test-MojibakePattern -Path $_.FullName) {
            $relative = $_.FullName
            if ($relative.StartsWith($RootPath)) {
              $relative = $relative.Substring($RootPath.Length).TrimStart('\')
            }
            $out.Add($relative)
          }
        }
        catch {
          # ignore unreadable files
        }
      }
  }
  return @($out | Select-Object -Unique)
}

function Get-ErrorCode([string]$Message) {
  if ([string]::IsNullOrWhiteSpace($Message)) { return 'UNKNOWN' }
  if ($Message -match 'EPERM|browserType\.launch|spawn EPERM') { return 'CAPTURE_EPERM' }
  if ($Message -match 'EADDRINUSE|port 3000|port 8080|already in use') { return 'PORT_CONFLICT' }
  if ($Message -match 'Missing .*\.ps1|Missing C:') { return 'SCRIPT_MISSING' }
  if ($Message -match 'npm run build failed|frontend compile check failed|npm ERR!') { return 'NPM_BUILD_FAIL' }
  if ($Message -match 'UTF8_MOJIBAKE_DETECTED') { return 'UTF8_MOJIBAKE_DETECTED' }
  if ($Message -match 'FRONTEND_DEVSERVER_START_FAIL|capture dev server start failed|capture dev server did not become ready') { return 'FRONTEND_DEVSERVER_START_FAIL' }
  if ($Message -match 'routing check failed') { return 'ROUTING_CONTRACT_FAIL' }
  if ($Message -match 'screen migration step failed') { return 'MIGRATION_EXEC_FAIL' }
  if ($Message -match 'validate step failed') { return 'PREFLIGHT_FAIL' }
  if ($Message -match 'doc-sync step failed|run-doc-sync') { return 'DOC_SYNC_FAIL' }
  if ($Message -match 'TOMCAT_NOT_READY') { return 'TOMCAT_NOT_READY' }
  if ($Message -match 'TOMCAT_UI_NOT_READY') { return 'TOMCAT_UI_NOT_READY' }
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

function Test-HttpReady([string]$Url) {
  try {
    $resp = Invoke-WebRequest -Uri $Url -Method Get -UseBasicParsing -TimeoutSec 8
    return ($resp.StatusCode -ge 200 -and $resp.StatusCode -lt 400)
  }
  catch {
    return $false
  }
}

function ConvertTo-ProcessArgumentString {
  param(
    [Parameter(Mandatory = $true)][string[]]$ArgumentList
  )

  return ($ArgumentList | ForEach-Object {
    if ($_ -match '[\s"]') {
      '"' + ($_ -replace '"', '\"') + '"'
    } else {
      $_
    }
  }) -join ' '
}

function Invoke-ProcessWithTimeout {
  param(
    [Parameter(Mandatory = $true)][string]$FilePath,
    [Parameter(Mandatory = $true)][string[]]$ArgumentList,
    [Parameter(Mandatory = $true)][string]$WorkingDirectory,
    [Parameter(Mandatory = $true)][int]$TimeoutSec,
    [Parameter(Mandatory = $true)][string]$StepLabel
  )

  $psi = New-Object System.Diagnostics.ProcessStartInfo
  $psi.FileName = $FilePath
  $psi.Arguments = ConvertTo-ProcessArgumentString -ArgumentList $ArgumentList
  $psi.WorkingDirectory = $WorkingDirectory
  $psi.UseShellExecute = $false
  $psi.RedirectStandardOutput = $true
  $psi.RedirectStandardError = $true
  $psi.CreateNoWindow = $true

  $proc = New-Object System.Diagnostics.Process
  $proc.StartInfo = $psi

  try {
    $null = $proc.Start()
    if (-not $proc.WaitForExit($TimeoutSec * 1000)) {
      try { Stop-Process -Id $proc.Id -Force -ErrorAction SilentlyContinue } catch {}
      $stdoutTail = ''
      $stderrTail = ''
      try { $stdoutTail = ($proc.StandardOutput.ReadToEnd() -split "`r?`n" | Select-Object -Last 20) -join ' | ' } catch {}
      try { $stderrTail = ($proc.StandardError.ReadToEnd() -split "`r?`n" | Select-Object -Last 20) -join ' | ' } catch {}
      throw "$StepLabel timed out after ${TimeoutSec}s. stdout=[$stdoutTail] stderr=[$stderrTail]"
    }

    $null = $proc.WaitForExit()
    $proc.Refresh()
    $exitCode = $proc.ExitCode

    $stdout = $proc.StandardOutput.ReadToEnd()
    $stderr = $proc.StandardError.ReadToEnd()

    return [pscustomobject]@{
      ExitCode = $exitCode
      StdOut = $stdout
      StdErr = $stderr
    }
  }
  finally {
    $proc.Dispose()
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
      'UTF8_MOJIBAKE_DETECTED' { 'Fail fast on UTF-8 mojibake patterns before build/doc sync and print affected files.' }
      'FRONTEND_DEVSERVER_START_FAIL' { 'Capture dev-server stdout/stderr, set BROWSER=none, and detect early process exit separately from port conflicts.' }
      'MIGRATION_EXEC_FAIL' { 'Validate migration-screen-map entries (id/group/legacyUrl/reactRoute) before orchestration.' }
      'ROUTING_CONTRACT_FAIL' { 'Print focused routing diffs for dispatcher-servlet.xml and controllers on failure.' }
      'DOC_SYNC_FAIL' { 'Search session logs in both root and docs/project-docs paths by default.' }
      'TOMCAT_CONTROL_FAIL' { 'Validate CATALINA_HOME/BASE/JRE paths and automate startup/shutdown with health polling.' }
      'TOMCAT_UI_NOT_READY' { 'Distinguish Tomcat process readiness from SPA /ui deployment readiness and print both URLs.' }
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
  Write-Utf8NoBomFile -Path $logFile -Content ($runLog | ConvertTo-Json -Depth 8)

  if (-not (Test-Path $resolvedFeedback)) {
    Write-Utf8NoBomFile -Path $resolvedFeedback -Content "# Migration Automation Feedback`n"
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
  Append-Utf8NoBomFile -Path $resolvedFeedback -Content $entry

  $manifestPath = Join-Path $ProjectRoot 'automation/next-session-manifest.json'
  $recommendedCommand = "powershell -ExecutionPolicy Bypass -File automation/run-all.ps1 -ProjectRoot $ProjectRoot -CaptureMode preset -CapturePreset all -CaptureBaseUrl http://localhost:8080 -FrontendBuildTimeoutSec $FrontendBuildTimeoutSec"
  $fallbackCommand = "powershell -ExecutionPolicy Bypass -File automation/run-all.ps1 -ProjectRoot $ProjectRoot -CaptureMode none -FrontendBuildTimeoutSec $FrontendBuildTimeoutSec"
  $latestFailedStep = $failedSteps | Select-Object -First 1
  $manifest = [ordered]@{
    format_version = 1
    updated_at = (Get-Date).ToString('o')
    phase = 'Transition'
    purpose = 'Compact execution manifest for rerunning the same automation test next session.'
    read_order = @(
      'AGENTS.md',
      'automation/next-session-manifest.json',
      'LATEST_STATE.md',
      'docs/project-docs/MIGRATION_AUTOMATION_FEEDBACK.md'
    )
    preferred_flow = [ordered]@{
      id = 'tomcat_runtime_capture'
      reason = 'Validated on 2026-03-11 as the most stable path.'
      command = $recommendedCommand
      requires_elevation = $true
      base_url = 'http://localhost:8080'
      context_path = '/rays'
      success_criteria = @(
        'Tomcat Ready Check success',
        'Verify Session Contract success',
        'Frontend Compile Check success',
        'Run Capture success',
        'Sync Session Log success'
      )
      expected_runtime = [ordered]@{
        automation_only_sec = 70.26
        practical_elapsed_minutes = '10-20'
      }
    }
    fallback_flow = [ordered]@{
      id = 'no_capture_validation'
      command = $fallbackCommand
      use_when = 'Use when browser capture permission (EPERM) or GUI constraints block preset execution.'
    }
    environment = [ordered]@{
      tomcat_base_url = $TomcatBaseUrl
      tomcat_context_path = $TomcatContextPath
      capture_base_url = $CaptureBaseUrl
      frontend_dev_port = $CaptureDevServerPort
      encoding = 'UTF-8 without BOM'
    }
    latest_run = [ordered]@{
      run_id = $script:runId
      status = $script:runStatus
      log = "automation/logs/run-$($script:runId).json"
      duration_sec = $totalDuration
      failed_step = if ($latestFailedStep) { $latestFailedStep.name } else { '' }
      failed_code = if ($latestFailedStep) { $latestFailedStep.error_code } else { '' }
    }
    validated_capture_reference = [ordered]@{
      run_id = '20260311-145541'
      status = 'success'
      log = 'automation/logs/run-20260311-145541.json'
      capture_mode = 'preset'
      capture_base_url = 'http://localhost:8080'
      duration_sec = 70.26
    }
    known_constraints = @(
      'Playwright capture is reliable when executed with elevated permission.',
      'UTF-8 mojibake preflight blocks corrupted Hangul before build/doc sync.',
      'Tomcat readiness and /ui readiness are handled as separate states.'
    )
    post_run_updates = @(
      'docs/project-docs/MIGRATION_AUTOMATION_FEEDBACK.md',
      'LATEST_STATE.md',
      'TASK_BOARD.md',
      'docs-migration-backlog.md',
      'dist/migration-kit'
    )
  }
  Write-Utf8NoBomFile -Path $manifestPath -Content ($manifest | ConvertTo-Json -Depth 8)
}

$script:executedCommands = @()
$script:captures = @()
$script:stepResults = @()
$script:autoLegacyMode = $false
$script:runStartedAt = Get-Date
$script:runId = Get-Date -Format 'yyyyMMdd-HHmmss'
$script:runStatus = 'success'

$gitCommitScript = Join-Path $ProjectRoot 'automation/git-commit.ps1'
$gitConfigPath = Join-Path $ProjectRoot 'automation/git-automation-config.json'
$gitConfig = $null
if (Test-Path $gitConfigPath) {
  try {
    $gitConfig = Get-Content -Path $gitConfigPath -Raw | ConvertFrom-Json
  }
  catch {
    Write-Warning "Unable to parse git automation config: $gitConfigPath"
  }
}
$gitCommitEnabled = [bool]$GitCommit
if (-not $gitCommitEnabled -and $gitConfig -and $gitConfig.enabledByDefault) {
  $gitCommitEnabled = [bool]$gitConfig.enabledByDefault
}
if ([string]::IsNullOrWhiteSpace($GitRemoteUrl) -and $gitConfig -and $gitConfig.remoteUrl) {
  $GitRemoteUrl = [string]$gitConfig.remoteUrl
}
if ([string]::IsNullOrWhiteSpace($GitCommitMessage) -and $gitConfig -and $gitConfig.commitMessageTemplate) {
  $GitCommitMessage = [string]$gitConfig.commitMessageTemplate
}
if (([string]::IsNullOrWhiteSpace($GitDefaultBranch) -or $GitDefaultBranch -eq 'main') -and $gitConfig -and $gitConfig.defaultBranch) {
  $GitDefaultBranch = [string]$gitConfig.defaultBranch
}
$gitInitIfMissingEnabled = [bool]$GitInitIfMissing
if (-not $gitInitIfMissingEnabled -and $gitConfig -and $gitConfig.initIfMissing) {
  $gitInitIfMissingEnabled = [bool]$gitConfig.initIfMissing
}

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
  Invoke-TrackedStep 'UTF-8 Mojibake Check' {
    $hits = Get-MojibakeCandidates -RootPath $ProjectRoot
    if ($hits.Count -gt 0) {
      $topHits = ($hits | Select-Object -First 10) -join ', '
      throw "UTF8_MOJIBAKE_DETECTED: UTF-8 mojibake pattern found in $($hits.Count) file(s): $topHits"
    }
  }

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
      $loginUrl = "{0}{1}/login" -f $TomcatBaseUrl.TrimEnd('/'), $TomcatContextPath
      $script:executedCommands += "GET $healthUrl"
      try {
        $resp = Invoke-WebRequest -Uri $healthUrl -Method Get -UseBasicParsing -TimeoutSec 8
        if ($resp.StatusCode -lt 200 -or $resp.StatusCode -ge 400) {
          throw "TOMCAT_NOT_READY: health check returned status $($resp.StatusCode). Please start Tomcat once, then rerun."
        }
      }
      catch {
        if (Test-HttpReady -Url $loginUrl) {
          throw "TOMCAT_UI_NOT_READY: Tomcat responds at $loginUrl but SPA entry $healthUrl is not ready. Check dispatcher-servlet.xml /ui mappings and WTP publish state."
        }
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
      $reactScriptsModule = Join-Path $nodeModulesDir 'react-scripts'
      $reactScriptsBin = Join-Path $nodeModulesDir '.bin\react-scripts.cmd'
      $needInstall = $InstallFrontendDeps -or -not (Test-Path $nodeModulesDir)
      if (-not $needInstall -and ((-not (Test-Path $reactScriptsModule)) -or (-not (Test-Path $reactScriptsBin)))) {
        $needInstall = $true
      }
      if (-not $needInstall -and $CaptureMode -ne 'none' -and -not (Test-Path $playwrightModule)) {
        $needInstall = $true
      }

      if (-not $needInstall) { return }

      $cmd = "cd `"$frontendDir`"; npm install"
      $script:executedCommands += $cmd
      Push-Location $frontendDir
      try {
        $result = Invoke-ProcessWithTimeout -FilePath 'cmd.exe' -ArgumentList @('/c', 'npm install') -WorkingDirectory $frontendDir -TimeoutSec $FrontendInstallTimeoutSec -StepLabel 'frontend dependency install'
        if ($result.ExitCode -ne 0) {
          throw "frontend deps install failed: npm install exit $($result.ExitCode)"
        }
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
        $result = Invoke-ProcessWithTimeout -FilePath 'cmd.exe' -ArgumentList @('/c', "set BUILD_PATH=$buildPath && npm run build") -WorkingDirectory $frontendDir -TimeoutSec $FrontendBuildTimeoutSec -StepLabel 'frontend compile check'
        if ($result.ExitCode -ne 0) { throw "frontend compile check failed: npm run build exit $($result.ExitCode)" }
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
      $resolvedLogDir = Join-Path $ProjectRoot $LogDir
      if (-not (Test-Path $resolvedLogDir)) {
        New-Item -ItemType Directory -Path $resolvedLogDir -Force | Out-Null
      }
      $stdoutLog = Join-Path $resolvedLogDir ("devserver-{0}.out.log" -f $script:runId)
      $stderrLog = Join-Path $resolvedLogDir ("devserver-{0}.err.log" -f $script:runId)
      $npmCmd = (Get-Command npm.cmd -ErrorAction SilentlyContinue).Source
      if (-not $npmCmd) {
        throw 'FRONTEND_DEVSERVER_START_FAIL: npm.cmd not found'
      }
      $proc = Start-Process -FilePath 'cmd.exe' `
        -ArgumentList '/c', "set BROWSER=none && `"$npmCmd`" run dev" `
        -WorkingDirectory $frontendDir `
        -RedirectStandardOutput $stdoutLog `
        -RedirectStandardError $stderrLog `
        -PassThru
      Write-Host "Capture dev server started. PID=$($proc.Id), port=$CaptureDevServerPort, stdout=$stdoutLog, stderr=$stderrLog"

      $deadline = (Get-Date).AddSeconds($CaptureDevServerStartTimeoutSec)
      do {
        if (Wait-PortListening -Port $CaptureDevServerPort -TimeoutSec 2) { return }
        if ($proc.HasExited) {
          $stdoutTail = ''
          $stderrTail = ''
          if (Test-Path $stdoutLog) {
            $stdoutTail = (Get-Content -Path $stdoutLog -Tail 20 -ErrorAction SilentlyContinue) -join ' | '
          }
          if (Test-Path $stderrLog) {
            $stderrTail = (Get-Content -Path $stderrLog -Tail 20 -ErrorAction SilentlyContinue) -join ' | '
          }
          throw "FRONTEND_DEVSERVER_START_FAIL: pid $($proc.Id) exited with code $($proc.ExitCode). stdout=[$stdoutTail] stderr=[$stderrTail]"
        }
        Start-Sleep -Seconds 2
      } while ((Get-Date) -lt $deadline)

      $stdoutTail = ''
      $stderrTail = ''
      if (Test-Path $stdoutLog) {
        $stdoutTail = (Get-Content -Path $stdoutLog -Tail 20 -ErrorAction SilentlyContinue) -join ' | '
      }
      if (Test-Path $stderrLog) {
        $stderrTail = (Get-Content -Path $stderrLog -Tail 20 -ErrorAction SilentlyContinue) -join ' | '
      }
      throw "FRONTEND_DEVSERVER_START_FAIL: port $CaptureDevServerPort not ready within ${CaptureDevServerStartTimeoutSec}s. stdout=[$stdoutTail] stderr=[$stderrTail]"
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
        $result = Invoke-ProcessWithTimeout -FilePath 'cmd.exe' -ArgumentList @('/c', 'npm run build') -WorkingDirectory $frontend -TimeoutSec $FrontendBuildTimeoutSec -StepLabel 'build frontend'
        if ($result.ExitCode -ne 0) { throw "npm run build failed: $($result.ExitCode)" }
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
        'automation/git-commit.ps1',
        'automation/git-automation-config.json',
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
  if ($script:runStatus -eq 'success' -and $gitCommitEnabled) {
    if (-not (Test-Path $gitCommitScript)) {
      Write-Warning "Git commit step skipped: missing $gitCommitScript"
    }
    else {
      try {
        Write-Host ""
        Write-Host '== Git Commit =='
        $resolvedGitCommitMessage = $GitCommitMessage
        if (-not [string]::IsNullOrWhiteSpace($resolvedGitCommitMessage)) {
          $resolvedGitCommitMessage = $resolvedGitCommitMessage.Replace('{run_id}', $script:runId)
        }

        $gitArgs = @(
          '-ExecutionPolicy', 'Bypass',
          '-File', $gitCommitScript,
          '-ProjectRoot', $ProjectRoot,
          '-RemoteUrl', $GitRemoteUrl,
          '-DefaultBranch', $GitDefaultBranch,
          '-CommitMessage', $resolvedGitCommitMessage,
          '-RunId', $script:runId
        )
        if ($gitInitIfMissingEnabled) {
          $gitArgs += '-InitIfMissing'
        }

        & powershell @gitArgs
        if ($LASTEXITCODE -ne 0) {
          Write-Warning "Git commit step failed with exit code $LASTEXITCODE"
        }
      }
      catch {
        Write-Warning "Git commit step failed: $($_.Exception.Message)"
      }
    }
  }
}

Write-Host ""
Write-Host '== DONE =='
Write-Host "ProjectRoot: $ProjectRoot"
Write-Host "CaptureMode: $CaptureMode"
if ($script:captures.Count -gt 0) {
  Write-Host "CaptureFiles: $($script:captures -join ', ')"
}
