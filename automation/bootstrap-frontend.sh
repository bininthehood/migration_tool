#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="$(pwd)"
APPLY=false
INSTALL_DEPS=false
TEMPLATE_FRONTEND_ROOT=""
TEMPLATE_UI_ROOT=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --project-root|-ProjectRoot) PROJECT_ROOT="$2"; shift 2 ;;
    --apply|-Apply) APPLY=true; shift ;;
    --install-deps|-InstallDeps) INSTALL_DEPS=true; shift ;;
    --template-frontend-root|-TemplateFrontendRoot) TEMPLATE_FRONTEND_ROOT="$2"; shift 2 ;;
    --template-ui-root|-TemplateUiRoot) TEMPLATE_UI_ROOT="$2"; shift 2 ;;
    *) shift ;;
  esac
done

FRONTEND_DIR="$PROJECT_ROOT/src/main/frontend"
SCRIPTS_DIR="$FRONTEND_DIR/scripts"
SRC_DIR="$FRONTEND_DIR/src"
PUBLIC_DIR="$FRONTEND_DIR/public"
PKG_PATH="$FRONTEND_DIR/package.json"
CAPTURE_PATH="$SCRIPTS_DIR/capture-react.cjs"
UI_DIR="$PROJECT_ROOT/src/main/webapp/ui"
UI_INDEX="$UI_DIR/index.html"

print_status() {
  printf "%-30s %s\n" "frontend_dir:" "$([[ -d $FRONTEND_DIR ]] && echo OK || echo MISSING)"
  printf "%-30s %s\n" "package_json:" "$([[ -f $PKG_PATH ]] && echo OK || echo MISSING)"
  printf "%-30s %s\n" "capture_script:" "$([[ -f $CAPTURE_PATH ]] && echo OK || echo MISSING)"
  printf "%-30s %s\n" "public_index_html:" "$([[ -f $PUBLIC_DIR/index.html ]] && echo OK || echo MISSING)"
  printf "%-30s %s\n" "src_index_js:" "$([[ -f $SRC_DIR/index.js ]] && echo OK || echo MISSING)"
  printf "%-30s %s\n" "webapp_ui_index:" "$([[ -f $UI_INDEX ]] && echo OK || echo MISSING)"
}

copy_dir_if_missing_or_empty() {
  local src="$1"
  local dst="$2"
  [[ -d "$src" ]] || return 0
  if [[ ! -d "$dst" ]] || [[ -z "$(ls -A "$dst" 2>/dev/null)" ]]; then
    cp -r "$src/." "$dst/"
  fi
}

copy_file_if_missing() {
  local src="$1"
  local dst="$2"
  [[ -f "$src" ]] && [[ ! -f "$dst" ]] && { mkdir -p "$(dirname "$dst")"; cp "$src" "$dst"; }
}

flatten_one_level() {
  local parent="$1"
  local nested_name="$2"
  local nested="$parent/$nested_name"
  [[ -d "$nested" ]] || return 0
  mv "$nested"/* "$parent/" 2>/dev/null || true
  rm -rf "$nested"
}

if ! $APPLY; then
  echo "[bootstrap-frontend] Dry run"
  print_status
  echo "TemplateFrontendRoot: $TEMPLATE_FRONTEND_ROOT"
  echo "TemplateUiRoot: $TEMPLATE_UI_ROOT"
  echo "Run with --apply to scaffold missing frontend files."
  exit 0
fi

mkdir -p "$FRONTEND_DIR" "$SCRIPTS_DIR" "$SRC_DIR" "$PUBLIC_DIR" "$UI_DIR"

if [[ -n "$TEMPLATE_FRONTEND_ROOT" ]]; then
  copy_dir_if_missing_or_empty "$TEMPLATE_FRONTEND_ROOT/public" "$PUBLIC_DIR"
  copy_dir_if_missing_or_empty "$TEMPLATE_FRONTEND_ROOT/src" "$SRC_DIR"
  copy_file_if_missing "$TEMPLATE_FRONTEND_ROOT/package.json" "$PKG_PATH"
  copy_file_if_missing "$TEMPLATE_FRONTEND_ROOT/scripts/capture-react.cjs" "$CAPTURE_PATH"
fi

if [[ -n "$TEMPLATE_UI_ROOT" ]]; then
  copy_dir_if_missing_or_empty "$TEMPLATE_UI_ROOT" "$UI_DIR"
fi

flatten_one_level "$PUBLIC_DIR" "public"
flatten_one_level "$SRC_DIR" "src"
flatten_one_level "$UI_DIR" "ui"

if [[ ! -f "$PKG_PATH" ]]; then
  cat > "$PKG_PATH" <<'PKGJSON'
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
PKGJSON
fi

if [[ ! -f "$CAPTURE_PATH" ]]; then
  cat > "$CAPTURE_PATH" <<'CAPTURE'
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
CAPTURE
fi

if $INSTALL_DEPS; then
  pushd "$FRONTEND_DIR" >/dev/null
  npm install
  popd >/dev/null
fi

echo "[bootstrap-frontend] Applied"
print_status
