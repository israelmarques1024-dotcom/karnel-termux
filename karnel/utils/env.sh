#!/usr/bin/env bash

KARNEL_VERSION="4.9.5"

# -------------------------
# Directorios del usuario
# -------------------------

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

mkdir -p \
  "$KARNEL_CONFIG" \
  "$KARNEL_CACHE" \
  "$KARNEL_DATA" \
  "$KARNEL_TOOLS" \
  "$KARNEL_RUN" \
  "$KARNEL_LOGS"

chmod 700 \
  "$KARNEL_CONFIG" \
  "$KARNEL_CACHE" \
  "$KARNEL_DATA" \
  "$KARNEL_TOOLS" \
  "$KARNEL_RUN" \
  "$KARNEL_LOGS" 2>/dev/null || true

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
