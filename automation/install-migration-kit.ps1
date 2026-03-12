param(
  [Parameter(Mandatory = $true)][string]$PackageZip,
  [Parameter(Mandatory = $true)][string]$TargetProjectRoot,
  [switch]$Force
)

$ErrorActionPreference = 'Stop'

function Ensure-Dir([string]$Path) {
  if (-not (Test-Path $Path)) {
    New-Item -ItemType Directory -Path $Path -Force | Out-Null
  }
}

if (-not (Test-Path $PackageZip)) {
  throw "Package zip not found: $PackageZip"
}
if (-not (Test-Path $TargetProjectRoot)) {
  throw "Target project root not found: $TargetProjectRoot"
}

$tempRoot = Join-Path $env:TEMP ("migration-kit-install-" + [guid]::NewGuid().ToString('N'))
Ensure-Dir $tempRoot

try {
  Expand-Archive -Path $PackageZip -DestinationPath $tempRoot -Force

  $entries = Get-ChildItem -Path $tempRoot
  if ($entries.Count -eq 0) {
    throw "Package is empty: $PackageZip"
  }

  # Copy every top-level packaged path into the target project root.
  foreach ($entry in $entries) {
    $destination = Join-Path $TargetProjectRoot $entry.Name

    if ((Test-Path $destination) -and (-not $Force)) {
      # Merge on existing paths by copying children to preserve target-specific files.
      if ($entry.PSIsContainer) {
        Ensure-Dir $destination
        Copy-Item -Path (Join-Path $entry.FullName '*') -Destination $destination -Recurse -Force
      } else {
        Copy-Item -Path $entry.FullName -Destination $destination -Force
      }
    } else {
      Copy-Item -Path $entry.FullName -Destination $destination -Recurse -Force
    }
  }

  Write-Host "INSTALLED"
  Write-Host "PACKAGE: $PackageZip"
  Write-Host "TARGET: $TargetProjectRoot"
  Write-Host ""
  Write-Host "Next:"
  Write-Host "1) cd $TargetProjectRoot"
  Write-Host "2) powershell -ExecutionPolicy Bypass -File automation/run-all.ps1 -ProjectRoot `"$TargetProjectRoot`" -TomcatControlAction restart -CaptureMode none -SkipDocSync"
}
finally {
  if (Test-Path $tempRoot) {
    Remove-Item -Recurse -Force $tempRoot
  }
}

