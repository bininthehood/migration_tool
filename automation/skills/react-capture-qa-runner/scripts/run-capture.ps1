param(
  [string]$ProjectRoot = (Get-Location).Path,
  [ValidateSet('single','preset')][string]$Mode = 'preset',
  [string]$Path,
  [string]$Name,
  [string]$Preset = 'all',
  [string]$BaseUrl = '',
  [string]$User,
  [string]$Password,
  [int]$Width = 1920,
  [int]$Height = 911,
  [switch]$Headed
)
# Thin wrapper — delegates to run-capture.sh
$sh = Join-Path $PSScriptRoot 'run-capture.sh'
$linuxSh   = (wsl wslpath -u "$sh").Trim()
$linuxRoot = (wsl wslpath -u "$ProjectRoot").Trim()
$args = @("--project-root", $linuxRoot, "--mode", $Mode, "--preset", $Preset,
          "--width", $Width, "--height", $Height)
if ($Path)     { $args += @("--path", $Path) }
if ($Name)     { $args += @("--name", $Name) }
if ($BaseUrl)  { $args += @("--base-url", $BaseUrl) }
if ($User)     { $args += @("--user", $User) }
if ($Password) { $args += @("--password", $Password) }
if ($Headed)   { $args += "--headed" }
wsl bash $linuxSh @args
exit $LASTEXITCODE
