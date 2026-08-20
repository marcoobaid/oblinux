#!/usr/bin/env bash
# Verify the OBLinux GNOME Shell theme (THEMING.md item 5) is correctly
# wired up: the User Themes extension is enabled and active, pointed at
# the right theme name, and the compiled CSS actually exists on disk.
#
# Run this ON the built/installed/booted system (liveuser session or a
# real install) -- not on the build machine, gsettings/gnome-extensions
# need a running GNOME session to query.
#
# This only covers the mechanism (docs' checklist item 1). It can't
# confirm the CSS actually LOADED without error, or that it looks right
# -- see docs/THEMING.md item 5 / the checklist in chat history for the
# journalctl error check and the visual walkthrough.

set -uo pipefail

UUID="user-theme@gnome-shell-extensions.gcampax.github.com"
THEME_NAME="OBLinux"
CSS_PATH="/usr/share/themes/OBLinux/gnome-shell/gnome-shell.css"

pass=0
fail=0

check() {
  local desc="$1" ok="$2"
  if [ "$ok" -eq 0 ]; then
    echo "  PASS  $desc"
    pass=$((pass + 1))
  else
    echo "  FAIL  $desc"
    fail=$((fail + 1))
  fi
}

echo "== OBLinux GNOME Shell theme verification =="
echo

echo "-- enabled-extensions --"
enabled="$(gsettings get org.gnome.shell enabled-extensions 2>&1)"
echo "  $enabled"
case "$enabled" in
  *"$UUID"*) check "User Themes extension listed in enabled-extensions" 0 ;;
  *)         check "User Themes extension listed in enabled-extensions" 1 ;;
esac
echo

echo "-- extension state --"
if command -v gnome-extensions >/dev/null 2>&1; then
  info="$(gnome-extensions info "$UUID" 2>&1)"
  echo "$info" | sed 's/^/  /'
  if echo "$info" | grep -qi "State: ENABLED"; then
    check "Extension state is ENABLED" 0
  else
    check "Extension state is ENABLED" 1
  fi
else
  echo "  gnome-extensions command not found"
  check "Extension state is ENABLED" 1
fi
echo

echo "-- user-theme name --"
name="$(gsettings get org.gnome.shell.extensions.user-theme name 2>&1)"
echo "  $name"
if [ "$name" = "'$THEME_NAME'" ]; then
  check "user-theme name is '$THEME_NAME'" 0
else
  check "user-theme name is '$THEME_NAME'" 1
fi
echo

echo "-- CSS file on disk --"
if [ -f "$CSS_PATH" ]; then
  echo "  found: $CSS_PATH ($(wc -c < "$CSS_PATH") bytes)"
  check "$CSS_PATH exists" 0
else
  echo "  missing: $CSS_PATH"
  check "$CSS_PATH exists" 1
fi
echo

echo "== Result: $pass passed, $fail failed =="
if [ "$fail" -eq 0 ]; then
  echo "Mechanism looks correct. Still do the visual walkthrough and the"
  echo "journalctl error check -- a passing mechanism doesn't guarantee"
  echo "the CSS loaded without error or looks right."
  exit 0
else
  echo "Something above needs attention before checking further."
  exit 1
fi
