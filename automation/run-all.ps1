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
$sh = Join-Path $PSScriptRoot 'run-all.sh'
$linuxSh = (wsl wslpath -u "$sh").Trim()
$linuxRoot = (wsl wslpath -u "$ProjectRoot").Trim()
$args = @("--project-root", $linuxRoot, "--user", $User, "--password", $Password,
          "--capture-mode", $CaptureMode, "--capture-path", $CapturePath, "--capture-name", $CaptureName,
          "--capture-preset", $CapturePreset, "--capture-base-url", $CaptureBaseUrl,
          "--capture-dev-server-port", $CaptureDevServerPort, "--capture-dev-server-start-timeout-sec", $CaptureDevServerStartTimeoutSec,
          "--frontend-install-timeout-sec", $FrontendInstallTimeoutSec, "--frontend-build-timeout-sec", $FrontendBuildTimeoutSec,
          "--tomcat-base-url", $TomcatBaseUrl, "--tomcat-context-path", $TomcatContextPath,
          "--tomcat-health-path", $TomcatHealthPath, "--tomcat-home", (wsl wslpath -u "$TomcatHome").Trim(),
          "--tomcat-base", (wsl wslpath -u "$TomcatBase").Trim(), "--tomcat-jre-home", (wsl wslpath -u "$TomcatJreHome").Trim(),
          "--tomcat-control-action", $TomcatControlAction, "--tomcat-control-timeout-sec", $TomcatControlTimeoutSec,
          "--log-dir", $LogDir, "--feedback-file", $FeedbackFile, "--history-window", $HistoryWindow,
          "--migration-plan-file", $MigrationPlanFile, "--migration-output-dir", $MigrationOutputDir)
if ($DisableAutoStartCaptureDevServer) { $args += "--disable-auto-start-capture-dev-server" }
if ($BootstrapFrontend) { $args += "--bootstrap-frontend" }
if ($DisableAutoBootstrapFrontend) { $args += "--disable-auto-bootstrap-frontend" }
if ($LegacyMode) { $args += "--legacy-mode" }
if ($InstallFrontendDeps) { $args += "--install-frontend-deps" }
if ($DisableAutoInstallFrontendDeps) { $args += "--disable-auto-install-frontend-deps" }
if ($DisableAutoInstallPlaywrightBrowsers) { $args += "--disable-auto-install-playwright-browsers" }
if ($SkipFrontendCompileCheck) { $args += "--skip-frontend-compile-check" }
if ($SkipSessionContractCheck) { $args += "--skip-session-contract-check" }
if ($SkipFrontendCheck) { $args += "--skip-frontend-check" }
if ($GitCommit) { $args += "--git-commit" }
if ($GitCommitMessage) { $args += @("--git-commit-message", $GitCommitMessage) }
if ($GitRemoteUrl) { $args += @("--git-remote-url", $GitRemoteUrl) }
if ($GitDefaultBranch) { $args += @("--git-default-branch", $GitDefaultBranch) }
if ($GitInitIfMissing) { $args += "--git-init-if-missing" }
if ($TomcatControlNoHealthCheck) { $args += "--tomcat-control-no-health-check" }
if ($SkipTomcatCheck) { $args += "--skip-tomcat-check" }
if ($Build) { $args += "--build" }
if ($MigrateScreen) { $args += @("--migrate-screen", $MigrateScreen) }
if ($MigrateBatch) { $args += @("--migrate-batch", $MigrateBatch) }
if ($SkipReactFunctionCommenting) { $args += "--skip-react-function-commenting" }
if ($SkipDocSync) { $args += "--skip-doc-sync" }
wsl bash $linuxSh @args
exit $LASTEXITCODE
