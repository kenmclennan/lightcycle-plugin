#!/usr/bin/env bash

REPO="git+https://github.com/kenmclennan/lightcycle"
STAMP_DIR="${CLAUDE_PLUGIN_DATA:-$HOME/.lightcycle}"
STAMP="$STAMP_DIR/.plugin-bootstrap-checked"

mkdir -p "$STAMP_DIR" 2>/dev/null

nudge() {
  if [ -z "$(lc project list 2>/dev/null)" ]; then
    echo "lightcycle: no projects registered on this machine yet - invoke the 'setup' skill to configure lightcycle and register your repos."
  else
    echo "lightcycle: to drive work - develop a brief, file items to the pipeline, and clear the human review gates in 'lc inbox' - invoke the 'driver' skill."
  fi
}

if [ -n "$(find "$STAMP" -mtime -1 2>/dev/null)" ]; then
  command -v lc >/dev/null 2>&1 && nudge
  exit 0
fi

if ! command -v git >/dev/null 2>&1; then
  echo "lightcycle-plugin: git not found - install it and restart your session; the engine is installed from a git URL." >&2
  exit 1
fi

if ! command -v pipx >/dev/null 2>&1; then
  echo "lightcycle-plugin: pipx not found - install it (https://pipx.pypa.io/) and restart your session to get the lc engine." >&2
  exit 1
fi

if ! command -v lc >/dev/null 2>&1; then
  pipx ensurepath >/dev/null 2>&1
  export PATH="$HOME/.local/bin:$PATH"
fi

if command -v lc >/dev/null 2>&1; then
  if ! lc upgrade; then
    echo "lightcycle-plugin: 'lc upgrade' failed - the engine may be out of date. Re-run by restarting your session." >&2
    exit 1
  fi
else
  if ! pipx install "$REPO"; then
    echo "lightcycle-plugin: 'pipx install $REPO' failed - the lc engine is not available. Fix the error above and restart your session." >&2
    exit 1
  fi
  export PATH="$HOME/.local/bin:$PATH"
fi

if ! command -v lc >/dev/null 2>&1; then
  echo "lightcycle-plugin: lc is installed but not on PATH - add pipx's bin directory (usually ~/.local/bin) to PATH and restart your session." >&2
  exit 1
fi

if ! lc init; then
  echo "lightcycle-plugin: 'lc init' failed - lightcycle is not configured. Fix the error above and restart your session." >&2
  exit 1
fi

touch "$STAMP" 2>/dev/null
nudge
exit 0
