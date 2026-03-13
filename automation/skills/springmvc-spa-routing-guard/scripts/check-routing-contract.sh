#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="$(pwd)"
NO_FAIL=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    --project-root|-ProjectRoot) PROJECT_ROOT="$2"; shift 2 ;;
    --no-fail|-NoFail)           NO_FAIL=true;       shift ;;
    *) shift ;;
  esac
done

DISPATCHER="$PROJECT_ROOT/src/main/webapp/WEB-INF/config/springmvc/dispatcher-servlet.xml"
SPA_CONTROLLER="$PROJECT_ROOT/src/main/java/com/rays/app/web/SpaForwardController.java"
VIEW_CONTROLLER="$PROJECT_ROOT/src/main/java/com/rays/app/view/controller/ViewController.java"

FAILED=0

check() {
  local name="$1"
  local file="$2"
  local pattern="$3"
  local result

  if [[ ! -f "$file" ]]; then
    result="MISSING"
    ((FAILED++)) || true
  elif grep -qP "$pattern" "$file" 2>/dev/null; then
    result="PASS"
  else
    result="FAIL"
    ((FAILED++)) || true
  fi
  printf "%-52s %-8s %s\n" "$name" "$result" "$(basename "$file")"
}

echo ""
printf "%-52s %-8s %s\n" "Check" "Result" "File"
printf "%-52s %-8s %s\n" "-----" "------" "----"

check "dispatcher has /ui resources"              "$DISPATCHER"      '<mvc:resources\s+mapping="/ui/\*\*"'
check "dispatcher has default servlet handler"    "$DISPATCHER"      '<mvc:default-servlet-handler\s*/?>'
check "dispatcher /ui redirect view"              "$DISPATCHER"      'path="/ui"\s+view-name="redirect:/ui/"'
check "dispatcher /ui/ forward view"              "$DISPATCHER"      'path="/ui/"\s+view-name="forward:/ui/index\.html"'
check "spa controller includes /ui redirect"      "$SPA_CONTROLLER"  'redirect:/ui/'
check "spa controller includes /ui index forward" "$SPA_CONTROLLER"  'forward:/ui/index\.html'
check "spa deep route mapping exists"             "$SPA_CONTROLLER"  '/ui/\*\*'
check "legacy controller excludes ui path"        "$VIEW_CONTROLLER" '\{path:\^\(\?!ui\$\)\.\+\}'

echo ""
if [[ $FAILED -gt 0 ]]; then
  echo "FAILED CHECKS: $FAILED"
  $NO_FAIL || exit 1
fi
