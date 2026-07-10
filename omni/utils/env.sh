#!/usr/bin/env bash

OMNI_VERSION="1.0.0"

# -------------------------
# Directorios del usuario
# -------------------------

# configuración
OMNI_CONFIG="${XDG_CONFIG_HOME:-$HOME/.config}/omni"

# cache
OMNI_CACHE="${XDG_CACHE_HOME:-$HOME/.cache}/omni"

# datos del usuario
OMNI_DATA="${XDG_DATA_HOME:-$HOME/.local/share}/omni-data"

# -------------------------
# Rutas internas del CLI
# -------------------------

OMNI_BIN="$OMNI_PATH/bin"
OMNI_MODULES="$OMNI_PATH/modules"
OMNI_UTILS="$OMNI_PATH/utils"
OMNI_CLI="$OMNI_PATH/cli"

# -------------------------
# Crear directorios
# -------------------------

mkdir -p \
  "$OMNI_CONFIG" \
  "$OMNI_CACHE" \
  "$OMNI_DATA"

# -------------------------
# TUI Colors - Ruby & Obsidian
# -------------------------
[[ -f "$OMNI_UTILS/dialogrc" ]] && export DIALOGRC="$OMNI_UTILS/dialogrc"
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
