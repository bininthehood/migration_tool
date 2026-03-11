param(
  [string]$ProjectRoot = (Get-Location).Path,
  [switch]$Apply,
  [switch]$InstallDeps,
  [string]$TemplateFrontendRoot = 'C:\Users\rays\ArcFlow_Webv1.2\src\main\frontend',
  [string]$TemplateUiRoot = 'C:\Users\rays\ArcFlow_Webv1.2\src\main\webapp\ui'
)

$ErrorActionPreference = 'Stop'

$frontendDir = Join-Path $ProjectRoot 'src/main/frontend'
$scriptsDir = Join-Path $frontendDir 'scripts'
$srcDir = Join-Path $frontendDir 'src'
$publicDir = Join-Path $frontendDir 'public'
$pkgPath = Join-Path $frontendDir 'package.json'
$capturePath = Join-Path $scriptsDir 'capture-react.cjs'
$srcIndexPath = Join-Path $srcDir 'index.js'
$publicIndexPath = Join-Path $publicDir 'index.html'
$uiDir = Join-Path $ProjectRoot 'src/main/webapp/ui'
$uiIndexPath = Join-Path $uiDir 'index.html'

function Ensure-Dir([string]$Path) {
  if (-not (Test-Path $Path)) {
    New-Item -ItemType Directory -Path $Path -Force | Out-Null
  }
}

function Write-Utf8NoBomFile([string]$Path, [string]$Content) {
  Ensure-Dir (Split-Path -Parent $Path)
  $enc = New-Object System.Text.UTF8Encoding($false)
  [System.IO.File]::WriteAllText($Path, $Content, $enc)
}

function Copy-FileIfMissing([string]$TemplatePath, [string]$TargetPath) {
  if (Test-Path $TargetPath) { return $false }
  if (-not (Test-Path $TemplatePath)) { return $false }
  Ensure-Dir (Split-Path -Parent $TargetPath)
  Copy-Item -Path $TemplatePath -Destination $TargetPath -Force
  return $true
}

function Sync-TemplateFileIfMarkerMissing([string]$TemplatePath, [string]$TargetPath, [string]$RequiredMarker) {
  if (-not (Test-Path $TemplatePath)) { return $false }
  if (-not (Test-Path $TargetPath)) {
    Ensure-Dir (Split-Path -Parent $TargetPath)
    Copy-Item -Path $TemplatePath -Destination $TargetPath -Force
    return $true
  }
  $content = Get-Content -Path $TargetPath -Raw -ErrorAction SilentlyContinue
  if ($null -eq $content) { $content = '' }
  if ($content -notmatch [regex]::Escape($RequiredMarker)) {
    Copy-Item -Path $TemplatePath -Destination $TargetPath -Force
    return $true
  }
  return $false
}

function Copy-DirIfMissingOrEmpty([string]$TemplatePath, [string]$TargetPath) {
  if (-not (Test-Path $TemplatePath)) { return $false }
  $needCopy = $false
  if (-not (Test-Path $TargetPath)) {
    $needCopy = $true
  } else {
    $hasChild = Get-ChildItem -Path $TargetPath -Force -ErrorAction SilentlyContinue | Select-Object -First 1
    if (-not $hasChild) { $needCopy = $true }
  }
  if (-not $needCopy) { return $false }
  Ensure-Dir $TargetPath
  Get-ChildItem -Path $TemplatePath -Force | ForEach-Object {
    Copy-Item -Path $_.FullName -Destination $TargetPath -Recurse -Force
  }
  return $true
}

function Flatten-OneLevel([string]$ParentPath, [string]$NestedName) {
  $nestedPath = Join-Path $ParentPath $NestedName
  if (-not (Test-Path $nestedPath)) { return $false }
  Get-ChildItem -Path $nestedPath -Force | ForEach-Object {
    Move-Item -Path $_.FullName -Destination $ParentPath -Force
  }
  Remove-Item -Path $nestedPath -Recurse -Force
  return $true
}

function Write-Status {
  [pscustomobject]@{
    frontend_dir = (Test-Path $frontendDir)
    package_json = (Test-Path $pkgPath)
    capture_script = (Test-Path $capturePath)
    public_index_html = (Test-Path $publicIndexPath)
    src_index_js = (Test-Path $srcIndexPath)
    webapp_ui_index_html = (Test-Path $uiIndexPath)
  } | Format-Table -AutoSize
}

if (-not $Apply) {
  Write-Host '[bootstrap-frontend] Dry run'
  Write-Status
  Write-Host "TemplateFrontendRoot: $TemplateFrontendRoot"
  Write-Host "TemplateUiRoot: $TemplateUiRoot"
  Write-Host 'Run with -Apply to scaffold missing frontend files.'
  exit 0
}

Ensure-Dir $frontendDir
Ensure-Dir $scriptsDir
Ensure-Dir $srcDir
Ensure-Dir $publicDir
Ensure-Dir $uiDir

# Restore from the reference project first.
[void](Copy-DirIfMissingOrEmpty (Join-Path $TemplateFrontendRoot 'public') $publicDir)
[void](Copy-DirIfMissingOrEmpty (Join-Path $TemplateFrontendRoot 'src') $srcDir)
[void](Copy-DirIfMissingOrEmpty $TemplateUiRoot $uiDir)
$templatePkgPath = Join-Path $TemplateFrontendRoot 'package.json'
$templateCapturePath = Join-Path $TemplateFrontendRoot 'scripts/capture-react.cjs'
[void](Copy-FileIfMissing $templatePkgPath $pkgPath)
[void](Copy-FileIfMissing $templateCapturePath $capturePath)

# For migration-kit bootstrap, always prefer the reference template package/capture scripts when available.
if (Test-Path $templatePkgPath) {
  Copy-Item -Path $templatePkgPath -Destination $pkgPath -Force
}
if (Test-Path $templateCapturePath) {
  Copy-Item -Path $templateCapturePath -Destination $capturePath -Force
}

# Normalize accidental nested directories from prior bootstrap runs.
[void](Flatten-OneLevel $publicDir 'public')
[void](Flatten-OneLevel $srcDir 'src')
[void](Flatten-OneLevel $uiDir 'ui')

# Fallback package scaffold if template file is not available.
if (-not (Test-Path $pkgPath)) {
  $pkg = @'
{
  "name": "frontend",
  "version": "0.1.0",
  "private": true,
  "scripts": {
    "dev": "react-scripts start",
    "start": "react-scripts start",
    "build": "react-scripts build",
    "capture:react": "node scripts/capture-react.cjs",
    "test": "react-scripts test"
  },
  "dependencies": {
    "react": "^19.2.4",
    "react-dom": "^19.2.4",
    "react-scripts": "5.0.1"
  },
  "devDependencies": {
    "playwright": "^1.58.2"
  }
}
'@
  Write-Utf8NoBomFile -Path $pkgPath -Content $pkg
}

# Fallback capture script if template file is not available.
if (-not (Test-Path $capturePath)) {
  $capture = @'
const fs = require("fs");
const path = require("path");
const { chromium } = require("playwright");

function arg(name, fallback = "") {
  const idx = process.argv.indexOf(`--${name}`);
  return idx >= 0 && process.argv[idx + 1] ? process.argv[idx + 1] : fallback;
}

async function main() {
  const routePath = arg("path", "/rays/ui/login");
  const name = arg("name", "react-capture");
  const baseUrl = arg("baseUrl", "http://localhost:3000");
  const width = Number(arg("width", "1920"));
  const height = Number(arg("height", "911"));

  const outDir = path.resolve(process.cwd(), "..", "..", "..", "captures", "main");
  fs.mkdirSync(outDir, { recursive: true });
  const out = path.join(outDir, `${name}-${width}x${height}.png`);

  const browser = await chromium.launch({ headless: true });
  const page = await browser.newPage({ viewport: { width, height } });
  const url = `${baseUrl}${routePath}`;
  await page.goto(url, { waitUntil: "domcontentloaded", timeout: 30000 });
  await page.screenshot({ path: out, fullPage: true });
  await browser.close();
  console.log(`[capture] saved: ${out}`);
}

main().catch((err) => {
  console.error("[capture] failed:", err.message || err);
  process.exit(1);
});
'@
  Write-Utf8NoBomFile -Path $capturePath -Content $capture
}

if ($InstallDeps) {
  Push-Location $frontendDir
  try {
    & npm install
    if ($LASTEXITCODE -ne 0) { throw "npm install failed: $LASTEXITCODE" }
  }
  finally {
    Pop-Location
  }
}

Write-Host '[bootstrap-frontend] Applied'
Write-Status
