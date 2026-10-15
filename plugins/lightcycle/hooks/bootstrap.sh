#!/usr/bin/env bash

REPO="git+https://github.com/kenmclennan/lightcycle"
STAMP_DIR="${CLAUDE_PLUGIN_DATA:-$HOME/.lightcycle}"
STAMP="$STAMP_DIR/.plugin-bootstrap-checked"
VERSION_FILE="$STAMP_DIR/.plugin-engine-version"

mkdir -p "$STAMP_DIR" 2>/dev/null

upgrade_hint() {
  seen="$(lc --version 2>/dev/null | head -1)"
  [ -z "$seen" ] && return
  last="$(cat "$VERSION_FILE" 2>/dev/null)"
  if [ "$seen" != "$last" ]; then
    echo "lightcycle: the engine is now $seen (was: ${last:-not recorded}) - invoke the 'upgrade' skill to bring this machine up to date."
    printf '%s\n' "$seen" > "$VERSION_FILE" 2>/dev/null
  fi
}

nudge() {
  if [ -z "$(lc project list 2>/dev/null | cut -f1 | grep -v -x -e specs -e guidance)" ]; then
    echo "lightcycle: no projects registered on this machine yet - invoke the 'setup' skill to configure lightcycle and register your repos."
  elif lc doctor 2>/dev/null | grep -q "trusted-authors.*blank"; then
    upgrade_hint
    echo "lightcycle: trusted-authors is blank, so the pool acts on no PR comments - invoke the 'setup' skill to set it."
  else
    upgrade_hint
    raw="$(sed -n '/<!-- driver-contract:start -->/,/<!-- driver-contract:end -->/p' \
      "${CLAUDE_PLUGIN_ROOT}/skills/driver/SKILL.md")"
    if [ -z "$raw" ] || [ "$(printf '%s\n' "$raw" | tail -1)" != "<!-- driver-contract:end -->" ]; then
      echo "lightcycle: driving contract markers not found in driver/SKILL.md - invoke the 'driver' skill directly."
      exit 0
    fi
    printf '%s\n' "$raw" | sed '1d;$d'
  fi
}

if [ -n "$(find "$STAMP" -mtime -1 2>/dev/null)" ]; then
  command -v lc >/dev/null 2>&1 && nudge
  exit 0
fi

if ! command -v git >/dev/null 2>&1; then
  echo "lightcycle-plugin: git not found - install it and restart your session; the engine is installed from a git URL."
  exit 0
fi

if ! command -v pipx >/dev/null 2>&1; then
  if command -v brew >/dev/null 2>&1; then
    brew install pipx >/dev/null 2>&1
  elif command -v python3 >/dev/null 2>&1 && python3 -c 'import sys; sys.exit(0 if sys.version_info >= (3, 11) else 1)' 2>/dev/null; then
    python3 -m pip install --user pipx >/dev/null 2>&1
    export PATH="$HOME/.local/bin:$PATH"
  fi
  if ! command -v pipx >/dev/null 2>&1; then
    echo "lightcycle-plugin: pipx not found and could not be installed automatically - install it (https://pipx.pypa.io/) and restart your session to get the lc engine."
    exit 0
  fi
fi

if ! command -v lc >/dev/null 2>&1; then
  pipx ensurepath >/dev/null 2>&1
  export PATH="$HOME/.local/bin:$PATH"
fi

if command -v lc >/dev/null 2>&1; then
  if ! lc upgrade; then
    upgrade_failed=1
    echo "lightcycle-plugin: 'lc upgrade' did not complete - see its output above; if it names workflow origins whose required engine version excludes the new engine, run 'lc workflow upgrade' for those origins, or 'lc upgrade --force' if no compatible bundle exists. The 'upgrade' skill can walk you through it."
  fi
else
  if ! pipx install "$REPO"; then
    echo "lightcycle-plugin: 'pipx install $REPO' failed - the lc engine is not available. Fix the error above and restart your session."
    exit 0
  fi
  export PATH="$HOME/.local/bin:$PATH"
fi

if ! command -v lc >/dev/null 2>&1; then
  echo "lightcycle-plugin: lc is installed but not on PATH - add pipx's bin directory (usually ~/.local/bin) to PATH and restart your session."
  exit 0
fi

if ! lc init; then
  echo "lightcycle-plugin: 'lc init' failed - lightcycle is not configured. Fix the error above and restart your session."
  exit 0
fi

[ -z "$upgrade_failed" ] && touch "$STAMP" 2>/dev/null
nudge
exit 0
