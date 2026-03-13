#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="$(pwd)"
MODE="preset"
CAPTURE_PATH=""
NAME=""
PRESET="all"
BASE_URL=""
USER_ARG=""
PASSWORD_ARG=""
WIDTH=1920
HEIGHT=911
HEADED=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    --project-root|-ProjectRoot) PROJECT_ROOT="$2"; shift 2 ;;
    --mode|-Mode)                MODE="$2";          shift 2 ;;
    --path|-Path)                CAPTURE_PATH="$2";  shift 2 ;;
    --name|-Name)                NAME="$2";          shift 2 ;;
    --preset|-Preset)            PRESET="$2";        shift 2 ;;
    --base-url|-BaseUrl)         BASE_URL="$2";      shift 2 ;;
    --user|-User)                USER_ARG="$2";      shift 2 ;;
    --password|-Password)        PASSWORD_ARG="$2";  shift 2 ;;
    --width|-Width)              WIDTH="$2";         shift 2 ;;
    --height|-Height)            HEIGHT="$2";        shift 2 ;;
    --headed|-Headed)            HEADED=true;         shift ;;
    *) shift ;;
  esac
done

FRONTEND="$PROJECT_ROOT/src/main/frontend"
if [[ ! -d "$FRONTEND" ]]; then
  echo "Error: Frontend path not found: $FRONTEND" >&2
  exit 1
fi

START_TS=$(date +%s)

CAPTURE_ARGS=()
if [[ "$MODE" == "single" ]]; then
  if [[ -z "$CAPTURE_PATH" || -z "$NAME" ]]; then
    echo "Error: single mode requires --path and --name" >&2
    exit 1
  fi
  CAPTURE_ARGS+=(--path "$CAPTURE_PATH" --name "$NAME")
else
  CAPTURE_ARGS+=(--preset "$PRESET")
fi

[[ -n "$BASE_URL" ]]      && CAPTURE_ARGS+=(--baseUrl "$BASE_URL")
[[ -n "$USER_ARG" ]]      && CAPTURE_ARGS+=(--user "$USER_ARG")
[[ -n "$PASSWORD_ARG" ]]  && CAPTURE_ARGS+=(--password "$PASSWORD_ARG")
[[ "$WIDTH" -gt 0 ]]      && CAPTURE_ARGS+=(--width "$WIDTH")
[[ "$HEIGHT" -gt 0 ]]     && CAPTURE_ARGS+=(--height "$HEIGHT")
$HEADED                   && CAPTURE_ARGS+=(--headed)

echo "Running: npm run capture:react -- ${CAPTURE_ARGS[*]}"
pushd "$FRONTEND" > /dev/null
npm run capture:react -- "${CAPTURE_ARGS[@]}"
EXIT_CODE=$?
popd > /dev/null

if [[ $EXIT_CODE -ne 0 ]]; then
  echo "Error: capture command failed with code $EXIT_CODE" >&2
  exit $EXIT_CODE
fi

OUT_DIR="$PROJECT_ROOT/captures/main"
if [[ ! -d "$OUT_DIR" ]]; then
  echo "Error: Capture output directory not found: $OUT_DIR" >&2
  exit 1
fi

FOUND_FILES=()
while IFS= read -r -d '' f; do
  FILE_TS=$(stat -c %Y "$f" 2>/dev/null || stat -f %m "$f")
  if [[ "$FILE_TS" -ge "$START_TS" ]]; then
    if [[ "$MODE" == "single" ]]; then
      [[ "$(basename "$f")" == ${NAME}-*.png ]] && FOUND_FILES+=("$f")
    else
      FOUND_FILES+=("$f")
    fi
  fi
done < <(find "$OUT_DIR" -maxdepth 1 -name '*.png' -print0 2>/dev/null)

if [[ ${#FOUND_FILES[@]} -eq 0 ]]; then
  echo "Error: No new capture files detected for this run." >&2
  exit 1
fi

echo "PASS"
echo "Generated files:"
for f in "${FOUND_FILES[@]}"; do echo "- $f"; done
