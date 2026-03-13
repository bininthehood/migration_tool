param(
  [string]$ProjectRoot = (Get-Location).Path,
  [string[]]$ChangedFiles,
  [string[]]$Commands,
  [string[]]$Captures,
  [switch]$Apply
)
# Thin wrapper — delegates to run-doc-sync.sh
$sh = Join-Path $PSScriptRoot 'run-doc-sync.sh'
$linuxSh   = (wsl wslpath -u "$sh").Trim()
$linuxRoot = (wsl wslpath -u "$ProjectRoot").Trim()
$args = @("--project-root", $linuxRoot)
foreach ($f in $ChangedFiles) { $args += @("--changed-file", $f) }
foreach ($c in $Commands)     { $args += @("--command", $c) }
foreach ($p in $Captures)     { $args += @("--capture", $p) }
if ($Apply) { $args += "--apply" }
wsl bash $linuxSh @args
exit $LASTEXITCODE
