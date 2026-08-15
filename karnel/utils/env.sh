#!/usr/bin/env bash

KARNEL_VERSION=""
if [[ -n "$KARNEL_PATH" ]] && [[ -f "$KARNEL_PATH/../package.json" ]]; then
  KARNEL_VERSION=$(grep '"version"' "$KARNEL_PATH/../package.json" | head -1 | sed -E 's/.*"version": "([^"]+)".*/\1/')
fi
: "${KARNEL_VERSION:=unknown}"

# -------------------------
# Directorios del usuario
# -------------------------

: "${HOME:?HOME is unset — cannot determine config paths}"

# configuración
KARNEL_CONFIG="${XDG_CONFIG_HOME:-$HOME/.config}/karnel"

# cache
KARNEL_CACHE="${XDG_CACHE_HOME:-$HOME/.cache}/karnel"

# datos del usuario
KARNEL_DATA="${XDG_DATA_HOME:-$HOME/.local/share}/karnel-data"

# -------------------------
# Rutas internas del CLI
# -------------------------

KARNEL_BIN="$KARNEL_PATH/bin"
KARNEL_MODULES="$KARNEL_PATH/modules"
KARNEL_UTILS="$KARNEL_PATH/utils"
KARNEL_CLI="$KARNEL_PATH/cli"
KARNEL_TOOLS="$KARNEL_DATA/tools"
KARNEL_RUN="$KARNEL_CACHE/run"
KARNEL_LOGS="$KARNEL_CACHE/logs"
KARNEL_PLUGINS="$KARNEL_DATA/plugins"

# -------------------------
# Crear directorios
# -------------------------

_karnel_secure_directory() {
  local directory="$1"

  if [[ -L "$directory" ]]; then
    printf 'karnel: refusing symlink directory: %s\n' "$directory" >&2
    return 1
  fi
  mkdir -p -m 700 "$directory" || return 1
  if [[ -L "$directory" ]]; then
    printf 'karnel: refusing symlink directory: %s\n' "$directory" >&2
    return 1
  fi
  chmod 700 "$directory"
}

if [[ "${KARNEL_READ_ONLY:-0}" != "1" ]]; then
  for _karnel_directory in \
    "$KARNEL_CONFIG" \
    "$KARNEL_CACHE" \
    "$KARNEL_DATA" \
    "$KARNEL_TOOLS" \
    "$KARNEL_RUN" \
    "$KARNEL_LOGS"; do
    _karnel_secure_directory "$_karnel_directory" || return 1
  done
  unset _karnel_directory
fi

# -------------------------
# TUI Colors - Ruby & Obsidian
# -------------------------
[[ -f "$KARNEL_UTILS/dialogrc" ]] && export DIALOGRC="$KARNEL_UTILS/dialogrc"
export NEWT_COLORS='
root=,black
window=,black
border=magenta,black
textbox=white,black
button=white,red
actbutton=white,magenta
checkbox=magenta,black
actcheckbox=white,red
label=white,black
listbox=white,black
actlistbox=white,magenta
title=red,black
'
