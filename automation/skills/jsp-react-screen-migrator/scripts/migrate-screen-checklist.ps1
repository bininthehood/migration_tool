param(
  [Parameter(Mandatory = $true)][string]$LegacyUrl,
  [Parameter(Mandatory = $true)][string]$ReactRoute,
  [string]$ProjectRoot = (Get-Location).Path,
  [string]$OutputPath
)

$backlog = Join-Path $ProjectRoot 'docs-migration-backlog.md'
$endpointMap = Join-Path $ProjectRoot 'ENDPOINT_MAP.md'

$backlogHint = ''
if (Test-Path $backlog) {
  $escaped = [regex]::Escape($LegacyUrl)
  $backlogHint = (Get-Content $backlog | Where-Object { $_ -match $escaped } | Select-Object -First 1)
}

$endpointHint = ''
if (Test-Path $endpointMap) {
  $routeKey = ($ReactRoute -replace '^/ui/', '' -replace '/', ' ')
  $endpointHint = (Get-Content $endpointMap | Where-Object { $_ -match [regex]::Escape($routeKey.Split(' ')[0]) } | Select-Object -First 1)
}

$md = @"
# Migration Checklist

- Legacy URL: `$LegacyUrl`
- React Route: `$ReactRoute`
- Date: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss K')

## Pre-check
- [ ] Confirm routing contract files
- [ ] Confirm API dependencies
- [ ] Confirm auth/session behavior

## Implementation
- [ ] Add/adjust React route and page component
- [ ] Keep JSP entry URL unchanged
- [ ] Keep backend API contract unchanged

## Validation
- [ ] Direct access `$ReactRoute` returns 200
- [ ] Refresh on `$ReactRoute` returns 200
- [ ] No basename mismatch or console errors
- [ ] Capture evidence collected

## Evidence Hints
- Backlog line: $backlogHint
- Endpoint hint: $endpointHint
"@

if ($OutputPath) {
  $parent = Split-Path $OutputPath -Parent
  if ($parent -and -not (Test-Path $parent)) { New-Item -ItemType Directory -Path $parent -Force | Out-Null }
  Set-Content -Path $OutputPath -Value $md -Encoding UTF8
  Write-Host "Wrote checklist: $OutputPath"
} else {
  $md
}
