param(
  [string]$ProjectRoot = (Get-Location).Path,
  [switch]$Apply,
  [switch]$InstallDeps,
  [string]$TemplateFrontendRoot = '',
  [string]$TemplateUiRoot = ''
)
$sh = Join-Path $PSScriptRoot 'bootstrap-frontend.sh'
$linuxSh   = (wsl wslpath -u "$sh").Trim()
$linuxRoot = (wsl wslpath -u "$ProjectRoot").Trim()
$args = @("--project-root", $linuxRoot)
if ($Apply)       { $args += "--apply" }
if ($InstallDeps) { $args += "--install-deps" }
if ($TemplateFrontendRoot) { $args += @("--template-frontend-root", (wsl wslpath -u "$TemplateFrontendRoot").Trim()) }
if ($TemplateUiRoot)       { $args += @("--template-ui-root",       (wsl wslpath -u "$TemplateUiRoot").Trim()) }
wsl bash $linuxSh @args
exit $LASTEXITCODE
