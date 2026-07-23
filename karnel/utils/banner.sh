#!/usr/bin/env bash
# shellcheck disable=all
[[ -n "$ZSH_VERSION" ]] && emulate -L bash 2>/dev/null || true
# Note: deliberately NOT using set -e here — it leaks errexit to the parent
# shell, causing non-existent commands to exit zsh with code 127.

BANNER_SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"
BANNER_VERSION="$(grep "^KARNEL_VERSION=" "$BANNER_SCRIPT_DIR/env.sh" 2>/dev/null | cut -d'"' -f2)"
[[ -z "$BANNER_VERSION" ]] && BANNER_VERSION="1.0.0"

ESC=$(printf '\033')
BOLD="${ESC}[1m"
DIM="${ESC}[2m"
NC="${ESC}[0m"
# TrueColor helper (original gradient: red → purple → blue → black)
tc() { printf '%s[38;2;%d;%d;%dm' "$ESC" "$1" "$2" "$3"; }

WHITE=$(tc 255 255 255)
GRAY="${ESC}[0;90m"

# TP gradient: cyan → blue → purple → magenta (muted, original style)
TP=()
for i in $(seq 0 15); do
  if   (( i < 4 )); then
    r=$(( 0 + i * 16 )); g=$(( 200 + i * 14 )); b=$(( 255 - i * 10 ))
  elif (( i < 8 )); then
    r=$(( 48 + (i-4) * 8 )); g=$(( 255 - (i-4) * 32 )); b=$(( 215 - (i-4) * 25 ))
  elif (( i < 12 )); then
    r=$(( 80 + (i-8) * 30 )); g=$(( 127 - (i-8) * 25 )); b=$(( 115 - (i-8) * 20 ))
  else
    r=$(( 200 + (i-12) * 14 )); g=$(( 27 + (i-12) * 5 )); b=$(( 35 + (i-12) * 20 ))
  fi
  (( r > 255 )) && r=255; (( g > 255 )) && g=255; (( b > 255 )) && b=255
  (( r < 0 )) && r=0; (( g < 0 )) && g=0; (( b < 0 )) && b=0
  TP+=("$(tc "$r" "$g" "$b")")
done

CYAN="${TP[0]}"
BLUE="${TP[4]}"
PURP="${TP[8]}"
MAG="${TP[12]}"
PINK=$(tc 255 80 140)
RED=$(tc 220 50 50)
RUBY=$(tc 220 50 60)
OBSIDIAN=$(tc 140 90 200)
GREEN1=$(tc 80 220 80)
GREEN2=$(tc 60 200 120)
C07="${TP[7]}"
C01="${TP[1]}"
C03="${TP[3]}"
C05="${TP[5]}"
C09="${TP[9]}"
C11="${TP[11]}"
C13="${TP[13]}"

# RK gradient: red → purple → blue → black (original)
RK=()
for _i in $(seq 0 15); do
  if (( _i < 6 )); then
    _r=$(( 255 - _i * 10 ))
    _g=$(( 40 + _i * 22 ))
    _b=$(( 40 + _i * 28 ))
  elif (( _i < 11 )); then
    _r=$(( 195 - (_i-6) * 30 ))
    _g=$(( 172 - (_i-6) * 28 ))
    _b=$(( 208 - (_i-6) * 15 ))
  else
    _r=$(( 45 - (_i-11) * 8 ))
    _g=$(( 32 - (_i-11) * 6 ))
    _b=$(( 133 - (_i-11) * 26 ))
  fi
  (( _r < 0 )) && _r=0; (( _g < 0 )) && _g=0; (( _b < 0 )) && _b=0
  RK+=("$(tc "$_r" "$_g" "$_b")")
done
unset _i _r _g _b

# Metallic shine (pure gold → bright white gradient)
M_SHINE=$(tc 255 215 0)
M_GOLD=$(tc 255 200 50)
M_SILVER=$(tc 220 220 255)

_ansi_len() {
  printf '%s' "$1" | sed 's/\x1b\[[0-9;]*m//g' | wc -m | tr -d ' '
}

_center() {
  local text="$1" width="$2"
  local vis; vis=$(_ansi_len "$text")
  local total=$(( width - vis ))
  local left=$(( total / 2 ))
  local right=$(( total - left ))
  printf '%*s' "$left" ''
  printf '%s' "$text"
  printf '%*s' "$right" ''
}

_repeat() {
  local ch="$1" n="$2" out="" _z
  for ((_z=0; _z<n; _z++)); do out+="$ch"; done
  printf '%s' "$out"
}

# ================================================================
# Counters
# ================================================================
_count_ai() {
  local reg="$KARNEL_PATH/tools/ai/all.sh"
  local c=0
  if [[ -f "$reg" ]]; then
    while IFS= read -r line; do
      [[ "$line" =~ ^[[:space:]]*\"([^\"]+)\" ]] || continue
      local entry="${BASH_REMATCH[1]}"
      local bin="${entry##*:}"
      command -v "$bin" &>/dev/null && ((c++))
    done < <(grep -E '^\s+"' "$reg" 2>/dev/null || true)
  fi
  echo "$c"
}
_count_lang() { local c=0; for cmd in node python rustc go clang php perl bun; do command -v "$cmd" &>/dev/null && ((c++)); done; echo "$c"; }
_count_db() { local c=0; command -v pg_ctl &>/dev/null && ((c++)); command -v mariadb &>/dev/null && ((c++)); command -v sqlite3 &>/dev/null && ((c++)); command -v mongod &>/dev/null && ((c++)); command -v redis-cli &>/dev/null && ((c++)); echo "$c"; }
_count_doctor() {
  local doc_sh="$KARNEL_PATH/cli/commands/doctor/code_langs.sh"
  if [[ -f "$doc_sh" ]]; then
    local count; count=$(grep -c 'LANG_TOOLS\[' "$doc_sh" 2>/dev/null || echo 0)
    echo "$count"
  else echo "0"; fi
}
_pg_status() {
  if command -v pg_ctl &>/dev/null; then
    local data="$KARNEL_DATA/pg/data"
    if [[ -d "$data" ]] && pg_ctl status -D "$data" &>/dev/null 2>&1; then
      echo "ON"
    else
      echo "OFF"
    fi
  else echo "—"; fi
}

# ================================================================
# Figlet-generated text with red-black gradient
# ================================================================
FIGLET_TEXT=""
TERMUX_FIGLET_TEXT=""
FIGLET_LINES=()
TERMUX_FIGLET_LINES=()
if command -v figlet &>/dev/null; then
  FIGLET_TEXT=$(figlet -f big "KARNEL" 2>/dev/null || true)
  TERMUX_FIGLET_TEXT=$(figlet -f big "TERMUX" 2>/dev/null || true)
fi
if [[ -n "$FIGLET_TEXT" ]]; then
  while IFS= read -r _fl; do FIGLET_LINES+=("$_fl"); done <<< "$FIGLET_TEXT"
fi
if [[ -n "$TERMUX_FIGLET_TEXT" ]]; then
  while IFS= read -r _tl; do TERMUX_FIGLET_LINES+=("$_tl"); done <<< "$TERMUX_FIGLET_TEXT"
fi

# ================================================================
# Metallic shine — passes over the big figlet letters only
# ================================================================
_metallic_apply() {
  local _text="$1" _base_color="$2" _scan="${3:-}"
  local _trimmed="${_text#"${_text%%[! ]*}"}"
  _trimmed="${_trimmed%"${_trimmed##*[! ]}"}"
  local _text_len=${#_trimmed}

  if (( _text_len < 4 )); then
    echo "${_base_color}${_text}${NC}"
    return
  fi

  local _lead="${_text%%[! ]*}"
  local _lead_len=${#_lead}
  local _center
  if [[ -n "$_scan" ]]; then
    _center=$(( _lead_len + _scan ))
  else
    _center=$(( _lead_len + _text_len / 2 ))
  fi

  local _core_r=$(( _text_len / 12 + 1 ))
  local _halo_r=$(( _text_len / 7 + 2 ))
  local _glow_r=$(( _text_len / 3 + 3 ))

  local _out="" _i _char
  for (( _i = 0; _i < ${#_text}; _i++ )); do
    _char="${_text:_i:1}"
    if [[ "$_char" == " " ]]; then
      _out+=" "
    else
      local _dist=$(( _i > _center ? _i - _center : _center - _i ))
      if (( _dist < _core_r )); then
        _out+="${BOLD}${WHITE}${_char}"
      elif (( _dist < _halo_r )); then
        _out+="${BOLD}${M_GOLD}${_char}"
      elif (( _dist < _glow_r )); then
        _out+="${M_SHINE}${_char}"
      else
        _out+="${_base_color}${_char}"
      fi
    fi
  done
  _out+="${NC}"
  echo "$_out"
}



# ================================================================
# Frame line (top / bottom) — pure TP gradient, no shine
# ================================================================
_render_frame_line() {
  local _which="$1"
  local cols="${COLUMNS:-$(tput cols 2>/dev/null || echo 80)}"
  local W=$(( cols > 72 ? 68 : cols - 6 ))
  (( W < 40 )) && W=40
  local GAP_L=$(( (cols - W - 2) / 2 ))
  (( GAP_L < 0 )) && GAP_L=0
  local GAP_R=$(( cols - W - 2 - GAP_L ))
  (( GAP_R < 0 )) && GAP_R=0
  local pad_l; pad_l=$(printf '%*s' "$GAP_L" '')
  local pad_r; pad_r=$(printf '%*s' "$GAP_R" '')

  local p1 p2 p3
  p1=$(( W / 4 )); p2=$(( W / 2 )); p3=$(( 3 * W / 4 ))
  local frame="" i m_color
  for (( i = 0; i < W; i++ )); do
    local c_idx=$(( i * 16 / W ))
    (( c_idx > 15 )) && c_idx=15
    m_color="${TP[$c_idx]}"
    if (( i == 1 || i == W-2 )); then
      frame+="${m_color}╌${NC}"
    elif (( i == p1 || i == p2 || i == p3 )); then
      if [[ "$_which" == "top" ]]; then
        frame+="${m_color}┬${NC}"
      else
        frame+="${m_color}┴${NC}"
      fi
    else
      frame+="${m_color}─${NC}"
    fi
  done

  if [[ "$_which" == "top" ]]; then
    echo "${pad_l}${WHITE}╭${NC}${frame}${WHITE}╮${NC}${pad_r}"
  else
    echo "${pad_l}${WHITE}╰${NC}${frame}${WHITE}╯${NC}${pad_r}"
  fi
}

# ================================================================
# Panel
# ================================================================
PANEL_HEADERS=("AI" "Lang" "DB" "Doctor" "PG")
PANEL_ICONS=("◆" "</>" "⛁" "◈" "🐘")

_panel_value() {
  case $1 in
    0) echo "${KAI_VAL:-$(_count_ai)}" ;;
    1) echo "${KLANG_VAL:-$(_count_lang)}" ;;
    2) echo "${KDB_VAL:-$(_count_db)}" ;;
    3) echo "${KDOCTOR_VAL:-$(_count_doctor)}" ;;
    4) echo "${KPG_VAL:-$(_pg_status)}" ;;
  esac
}

# ================================================================
# Render
# ================================================================
_render_top() {
  local cols="${COLUMNS:-$(tput cols 2>/dev/null || echo 80)}"
  local W=$(( cols > 72 ? 68 : cols - 6 ))
  (( W < 40 )) && W=40
  local GAP_L=$(( (cols - W - 2) / 2 ))
  (( GAP_L < 0 )) && GAP_L=0
  local GAP_R=$(( cols - W - 2 - GAP_L ))
  (( GAP_R < 0 )) && GAP_R=0
  local pad_l; pad_l=$(printf '%*s' "$GAP_L" '')
  local pad_r; pad_r=$(printf '%*s' "$GAP_R" '')
  local l_border="${TP[0]}" r_border="${TP[15]}"
  local sp_line; sp_line=$(printf '%*s' "$W" '')

  _render_frame_line "top"
  local hdr="${TP[1]}┄${NC}${TP[1]}┄${NC} ${M_SHINE}◈${NC} ${BOLD}${WHITE}KARNEL${NC} ${WHITE}✦${NC} ${BOLD}${WHITE}SYSTEMS${NC} ${M_SHINE}◈${NC} ${TP[1]}┄${NC}${TP[1]}┄${NC}"
  echo "${pad_l}${l_border}│${NC}$(_center "$hdr" "$W")${r_border}│${NC}${pad_r}"
  echo "${pad_l}${l_border}│${NC}${sp_line}${r_border}│${NC}${pad_r}"
}

_render_figlet() {
  local _anim_off="${1:-0}" _slow="${2:-}"
  local cols="${COLUMNS:-$(tput cols 2>/dev/null || echo 80)}"
  local W=$(( cols > 72 ? 68 : cols - 6 ))
  (( W < 40 )) && W=40
  local GAP_L=$(( (cols - W - 2) / 2 ))
  (( GAP_L < 0 )) && GAP_L=0
  local GAP_R=$(( cols - W - 2 - GAP_L ))
  (( GAP_R < 0 )) && GAP_R=0
  local pad_l; pad_l=$(printf '%*s' "$GAP_L" '')
  local pad_r; pad_r=$(printf '%*s' "$GAP_R" '')
  local l_border="${TP[0]}" r_border="${TP[15]}"

  local num_fl=${#FIGLET_LINES[@]} num_tl=${#TERMUX_FIGLET_LINES[@]}
  local _fi _ti _line _ci _colored _scan2 _fig_w=0 _fl2 _total_fig_lines=$(( num_fl + num_tl ))
  for _fl2 in "${FIGLET_LINES[@]}"; do local _tl2=${#_fl2}; (( _tl2 > _fig_w )) && _fig_w=$_tl2; done
  local _step=$(( (_fig_w + 16) * 1 / (_total_fig_lines > 1 ? _total_fig_lines - 1 : 1) ))
  (( _step < 1 )) && _step=1
  for (( _fi = 0; _fi < num_fl; _fi++ )); do
    _line="${FIGLET_LINES[$_fi]}"
    _ci=$(( _fi * 16 / (num_fl > 1 ? num_fl : 1) ))
    (( _ci > 15 )) && _ci=15
    _scan2=$(( -8 + _anim_off + _fi * _step ))
    _colored=$(_metallic_apply "$_line" "${RK[$_ci]}" "$_scan2")
    echo "${pad_l}${l_border}│${NC}$( _center "$_colored" "$W" )${r_border}│${NC}${pad_r}"
    [[ -n "$_slow" ]] && sleep 0.2
  done
  for (( _ti = 0; _ti < num_tl; _ti++ )); do
    _line="${TERMUX_FIGLET_LINES[$_ti]}"
    _ci=$(( _ti * 16 / (num_tl > 1 ? num_tl : 1) ))
    (( _ci > 15 )) && _ci=15
    _scan2=$(( -8 + _anim_off + (_fi + _ti) * _step ))
    _colored=$(_metallic_apply "$_line" "${RK[$_ci]}" "$_scan2")
    echo "${pad_l}${l_border}│${NC}$( _center "$_colored" "$W" )${r_border}│${NC}${pad_r}"
    [[ -n "$_slow" ]] && sleep 0.2
  done
}

_render_bottom() {
  local cols="${COLUMNS:-$(tput cols 2>/dev/null || echo 80)}"
  local W=$(( cols > 72 ? 68 : cols - 6 ))
  (( W < 40 )) && W=40
  local GAP_L=$(( (cols - W - 2) / 2 ))
  (( GAP_L < 0 )) && GAP_L=0
  local GAP_R=$(( cols - W - 2 - GAP_L ))
  (( GAP_R < 0 )) && GAP_R=0
  local pad_l; pad_l=$(printf '%*s' "$GAP_L" '')
  local pad_r; pad_r=$(printf '%*s' "$GAP_R" '')
  local l_border="${TP[0]}" r_border="${TP[15]}"
  local sp_line; sp_line=$(printf '%*s' "$W" '')

  local div_total=$(( W - 2 ))
  local div_l=$(( (div_total - 3) / 2 ))
  local div_r=$(( div_total - 3 - div_l ))
  local dash_l="" dash_r="" j
  for (( j = 0; j < div_l; j++ )); do
    local m=$(( j % 4 ))
    if (( m == 0 )); then dash_l+="─"
    elif (( m == 1 )); then dash_l+="┄"
    elif (( m == 2 )); then dash_l+="·"
    else dash_l+="─"; fi
  done
  for (( j = 0; j < div_r; j++ )); do
    local m=$(( j % 4 ))
    if (( m == 0 )); then dash_r+="─"
    elif (( m == 1 )); then dash_r+="┄"
    elif (( m == 2 )); then dash_r+="·"
    else dash_r+="─"; fi
  done
  local div_line="${DIM}${dash_l}${NC}${TP[3]}◈${NC}${DIM}${dash_r}${NC}"
  echo "${pad_l}${l_border}│${NC}$(_center "$div_line" "$W")${r_border}│${NC}${pad_r}"

  local gem_line="${M_SHINE}◈${NC} ${BOLD}${RUBY}Dev${NC} ${WHITE}${BOLD}&${NC} ${BOLD}${OBSIDIAN}mobile${NC} ${M_SHINE}◈${NC}"
  echo "${pad_l}${l_border}│${NC}$(_center "$gem_line" "$W")${r_border}│${NC}${pad_r}"
  echo "${pad_l}${l_border}│${NC}$(_center "${GREEN2}${BOLD}Karnel${NC} ${GREEN1}v${BANNER_VERSION}${NC}" "$W")${r_border}│${NC}${pad_r}"
  echo "${pad_l}${l_border}│${NC}$(_center "${DIM}by${NC} ${BOLD}${WHITE}israel${NC} ${WHITE}marques${NC}" "$W")${r_border}│${NC}${pad_r}"
  echo "${pad_l}${l_border}│${NC}${sp_line}${r_border}│${NC}${pad_r}"

  local PW=$(( W - 4 ))
  (( PW < 20 )) && PW=20
  local phline; phline=$(_repeat '─' "$PW")

  echo "${pad_l}${l_border}│${NC} ${M_SHINE}╭${NC}${phline}${M_SHINE}╮${NC} ${r_border}│${NC}${pad_r}"
  local ph=" ${M_SHINE}◈${NC} ${BOLD}${WHITE}STATUS${NC} ${M_SHINE}◈${NC} "
  echo "${pad_l}${l_border}│${NC} ${M_SHINE}│${NC}$(_center "$ph" "$PW")${M_SHINE}│${NC} ${r_border}│${NC}${pad_r}"

  local psep="" pj
  for (( pj = 0; pj < PW; pj++ )); do
    local m=$(( pj % 4 ))
    if (( m == 0 )); then psep+="─"
    elif (( m == 1 )); then psep+="┄"
    elif (( m == 2 )); then psep+="·"
    else psep+="─"; fi
  done
  echo "${pad_l}${l_border}│${NC} ${TP[3]}│${NC}${DIM}${psep}${NC}${TP[11]}│${NC} ${r_border}│${NC}${pad_r}"

  local col_w=$(( (PW - 4) / 5 ))
  local col_line=""
  for (( i = 0; i < 5; i++ )); do
    local val; val=$(_panel_value $i)
    local entry="${TP[$(( i * 3 + 1 ))]}${PANEL_ICONS[$i]}${NC} ${BOLD}${WHITE}${PANEL_HEADERS[$i]}${NC} ${GREEN1}${val}${NC}"
    local ev; ev=$(_ansi_len "$entry")
    local epad=$(( (col_w - ev) / 2 ))
    local epad2=$(( col_w - ev - epad ))
    (( epad < 0 )) && epad=0
    (( epad2 < 0 )) && epad2=0
    col_line+="$(printf '%*s' "$epad" '')${entry}$(printf '%*s' "$epad2" '')"
    (( i < 4 )) && col_line+="${GRAY}│${NC}"
  done
  echo "${pad_l}${l_border}│${NC} ${TP[3]}│${NC}${col_line}${TP[11]}│${NC} ${r_border}│${NC}${pad_r}"
  echo "${pad_l}${l_border}│${NC} ${M_SHINE}╰${NC}${phline}${M_SHINE}╯${NC} ${r_border}│${NC}${pad_r}"
  echo "${pad_l}${l_border}│${NC}${sp_line}${r_border}│${NC}${pad_r}"

  local dot_line="" dj
  for (( dj = 0; dj < W; dj++ )); do
    if (( dj == W/2 )); then
      dot_line+="${M_SHINE}◈${NC}"
    elif (( dj % 4 == 0 )); then
      dot_line+="${DIM}·${NC}"
    elif (( dj % 3 == 1 )); then
      dot_line+="${TP[$(( dj * 4 / W > 15 ? 15 : dj * 4 / W ))]}┄${NC}"
    else
      dot_line+="${DIM}─${NC}"
    fi
  done
  echo "${pad_l}${l_border}│${NC}${dot_line}${r_border}│${NC}${pad_r}"
  _render_frame_line "bot"
}

_render() {
  _render_top
  _render_figlet "" "${1:-}"
  _render_bottom
}

_show_tip() {
  local _tip_index_file="${XDG_CACHE_HOME:-$HOME/.cache}/karnel/.last_tip_index"
  if [[ ${#KARNEL_TIPS[@]} -gt 0 ]]; then
    local last_index=-1 new_index _tip
    [[ -f "$_tip_index_file" ]] && last_index=$(cat "$_tip_index_file" 2>/dev/null || echo "-1")
    new_index=$last_index
    while [[ "$new_index" == "$last_index" ]]; do new_index=$(( RANDOM % ${#KARNEL_TIPS[@]} )); done
    echo "$new_index" >"$_tip_index_file"
    _tip="${KARNEL_TIPS[$new_index]:-}"
    [[ -n "$_tip" ]] && { echo; log_tip "$_tip"; }
  fi
}

_render_animated() {
  _render_top
  _render_figlet
  _render_bottom
  _show_tip
}

# Cache panel values so animation frames don't re-run system commands
KAI_VAL=$(_count_ai)
KLANG_VAL=$(_count_lang)
KDB_VAL=$(_count_db)
KDOCTOR_VAL=$(_count_doctor)
KPG_VAL=$(_pg_status)

# Cache banner for clear() override (capture only, no terminal output)
_banner_output=$(_render 2>/dev/null) || true
_karnel_banner_cache="${XDG_CACHE_HOME:-$HOME/.cache}/karnel/banner_cache"
mkdir -p "$(dirname "$_karnel_banner_cache")" 2>/dev/null
[[ -t 1 ]] && echo "$_banner_output" > "$_karnel_banner_cache" 2>/dev/null

banner_tip() { echo " ${TP[3]}●${NC} ${GRAY}Tip${NC} $*"; }

KARNEL_TIPS=(
  "Keep Karnel updated: ${TP[3]}karnel update karnel${NC}"
  "Check your version: ${TP[3]}karnel --version${NC}"
  "Enable debug logs: ${TP[3]}export KARNEL_DEBUG=1${NC}"
  "Open framework docs: ${TP[3]}karnel open karnel${NC}"
  "Install everything: ${TP[3]}karnel install lang db dev npm${NC}"
  "Install specific AI tools: ${TP[3]}karnel install ai --opencode --ollama${NC}"
  "See what's installed: ${TP[3]}karnel list ai${NC}"
  "Read tool docs: ${TP[3]}karnel show ai --opencode${NC}"
  "Update a specific tool: ${TP[3]}karnel update ai --opencode${NC}"
  "Update all AI tools: ${TP[3]}karnel update ai${NC}"
  "Update all databases: ${TP[3]}karnel update db${NC}"
  "Update ZSH plugins: ${TP[3]}karnel update shell${NC}"
  "Remove a module: ${TP[3]}karnel uninstall npm${NC}"
  "Install all languages: ${TP[3]}karnel install lang${NC}"
  "Install Python: ${TP[3]}karnel install lang --python${NC}"
  "Install Rust: ${TP[3]}karnel install lang --rust${NC}"
  "Install Go: ${TP[3]}karnel install lang --golang${NC}"
  "Start PostgreSQL: ${TP[3]}karnel pg init${NC} then ${TP[3]}karnel pg start${NC}"
  "Open psql shell: ${TP[3]}karnel pg shell${NC}"
  "Install all AI agents: ${TP[3]}karnel install ai${NC}"
  "Install OpenCode: ${TP[3]}karnel install ai --opencode${NC}"
  "Install Claude Code: ${TP[3]}karnel install ai --claude-code${NC}"
  "Install Codex CLI: ${TP[3]}karnel install ai --codex${NC}"
  "Install Gemini CLI: ${TP[3]}karnel install ai --gemini-cli${NC}"
  "Install MiMo Code: ${TP[3]}karnel install ai --mimocode${NC}"
  "Install code-server: ${TP[3]}karnel install editor${NC}"
  "Fuzzy search: ${TP[3]}karnel install dev --fzf${NC}"
  "Modern ls: ${TP[3]}karnel install dev --lsd${NC}"
  "Syntax cat: ${TP[3]}karnel install dev --bat${NC}"
  "GitHub CLI: ${TP[3]}karnel install dev --gh${NC}"
  "Format shell scripts: ${TP[3]}karnel install dev --shfmt${NC}"
  "Process JSON: ${TP[3]}karnel install dev --jq${NC}"
  "Deploy to Vercel: ${TP[3]}karnel install npm --vercel${NC}"
  "TypeScript: ${TP[3]}karnel install npm --typescript${NC}"
  "Install ZSH + plugins: ${TP[3]}karnel install shell${NC}"
  "Customize Termux UI: ${TP[3]}karnel install ui${NC}"
  "Install banner: ${TP[3]}karnel install ui --banner${NC}"
  "Set API keys: ${TP[3]}karnel env set${NC}"
  "Second brain: ${TP[3]}karnel brain init${NC}"
  "Save memories: ${TP[3]}karnel brain save${NC}"
  "Voice-to-AI: ${TP[3]}karnel voice opencode${NC}"
  "Init Next.js: ${TP[3]}cd my-app && karnel init next${NC}"
  "Init Express: ${TP[3]}cd api && karnel init express${NC}"
)

_block_input() {
  _OLD_STTY=$(stty -g 2>/dev/null || true)
  stty -echo -icanon min 0 time 0 2>/dev/null || true
}

_unblock_input() {
  stty "${_OLD_STTY:-sane}" 2>/dev/null || true
}

# Exportado para ser chamado pelo karnel.sh quando necessário
render_banner() {
  _block_input
  _render_animated
  _unblock_input
  echo
}
