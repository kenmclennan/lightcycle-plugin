#!/usr/bin/env bash

REPO="git+https://github.com/kenmclennan/lightcycle"
STAMP_DIR="${CLAUDE_PLUGIN_DATA:-$HOME/.lightcycle}"
STAMP="$STAMP_DIR/.plugin-bootstrap-checked"

mkdir -p "$STAMP_DIR" 2>/dev/null

if command -v lc >/dev/null 2>&1; then
  echo "lightcycle: to drive work - develop a brief, file items to the pipeline, and clear the human review gates in 'lc inbox' - invoke the 'driver' skill."
fi

if [ -n "$(find "$STAMP" -mtime -1 2>/dev/null)" ]; then
  exit 0
fi

if ! command -v pipx >/dev/null 2>&1; then
  echo "lightcycle-plugin: pipx not found - install it (https://pipx.pypa.io/) and restart your session to get the lc engine." >&2
  exit 0
fi

if command -v lc >/dev/null 2>&1; then
  lc upgrade
else
  pipx install "$REPO"
fi

if command -v lc >/dev/null 2>&1; then
  lc init
fi

touch "$STAMP" 2>/dev/null
exit 0
