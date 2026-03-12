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

$frontend = Join-Path $ProjectRoot 'src/main/frontend'
if (-not (Test-Path $frontend)) { throw "Frontend path not found: $frontend" }

$start = Get-Date
Push-Location $frontend
try {
  $captureArgs = @()
  if ($Mode -eq 'single') {
    if (-not $Path -or -not $Name) { throw 'single mode requires -Path and -Name' }
    $captureArgs += @('--path',$Path,'--name',$Name)
  } else {
    $captureArgs += @('--preset',$Preset)
  }
  if (-not [string]::IsNullOrWhiteSpace($BaseUrl)) { $captureArgs += @('--baseUrl',$BaseUrl) }
  if ($User) { $captureArgs += @('--user',$User) }
  if ($Password) { $captureArgs += @('--password',$Password) }
  if ($Width -gt 0) { $captureArgs += @('--width',$Width) }
  if ($Height -gt 0) { $captureArgs += @('--height',$Height) }
  if ($Headed) { $captureArgs += '--headed' }

  $npmArgs = @('run','capture:react','--') + $captureArgs
  Write-Host "Running: npm $($npmArgs -join ' ')"
  $captureOutput = & npm @npmArgs 2>&1 | ForEach-Object { "$_" }
  if ($captureOutput) {
    $captureOutput | ForEach-Object { Write-Host $_ }
  }
  if ($LASTEXITCODE -ne 0) {
    $detail = ($captureOutput -join [Environment]::NewLine).Trim()
    if ([string]::IsNullOrWhiteSpace($detail)) {
      throw "capture command failed with code $LASTEXITCODE"
    }
    throw "capture command failed with code $LASTEXITCODE`n$detail"
  }
}
finally {
  Pop-Location
}

$outDir = Join-Path $ProjectRoot 'captures/main'
if (-not (Test-Path $outDir)) { throw "Capture output directory not found: $outDir" }

$files = Get-ChildItem $outDir -File -Filter '*.png' | Where-Object { $_.LastWriteTime -ge $start }
if ($Mode -eq 'single') {
  $files = $files | Where-Object { $_.Name -like "$Name-*.png" }
}

if (-not $files -or $files.Count -eq 0) {
  throw 'No new capture files detected for this run.'
}

"PASS"
"Generated files:"
$files | Sort-Object LastWriteTime | ForEach-Object { "- $($_.FullName)" }
