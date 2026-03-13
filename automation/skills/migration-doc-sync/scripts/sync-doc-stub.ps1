param(
  [string]$ProjectRoot = (Get-Location).Path,
  [string[]]$ChangedFiles,
  [string[]]$Commands,
  [string[]]$Captures,
  [string]$SessionLog,
  [switch]$Apply
)
# Thin wrapper — delegates to sync-doc-stub.sh
$sh = Join-Path $PSScriptRoot 'sync-doc-stub.sh'
$linuxSh   = (wsl wslpath -u "$sh").Trim()
$linuxRoot = (wsl wslpath -u "$ProjectRoot").Trim()
$args = @("--project-root", $linuxRoot)
if ($SessionLog) { $args += @("--session-log", (wsl wslpath -u "$SessionLog").Trim()) }
foreach ($f in $ChangedFiles) { $args += @("--changed-file", $f) }
foreach ($c in $Commands)     { $args += @("--command", $c) }
foreach ($p in $Captures)     { $args += @("--capture", $p) }
if ($Apply) { $args += "--apply" }
wsl bash $linuxSh @args
exit $LASTEXITCODE
