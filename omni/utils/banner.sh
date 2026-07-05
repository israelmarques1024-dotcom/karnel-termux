#!/usr/bin/env bash
# shellcheck disable=all
[[ -n "$ZSH_VERSION" ]] && emulate -L bash 2>/dev/null || true
set -e 2>/dev/null || true

BANNER_SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"
BANNER_VERSION="$(grep "^OMNI_VERSION=" "$BANNER_SCRIPT_DIR/env.sh" 2>/dev/null | cut -d'"' -f2)"
[[ -z "$BANNER_VERSION" ]] && BANNER_VERSION="4.4.0"

ESC=$(printf '\033')

# TrueColor gradient: ciano -> azul -> roxo -> magenta -> rosa
tc() { printf '%s[38;2;%d;%d;%dm' "$ESC" "$1" "$2" "$3"; }

# 16-step TrueColor palette
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
WHITE="${ESC}[1;37m"
GRAY="${ESC}[0;90m"
DIM="${ESC}[2m"
NC="${ESC}[0m"

# Fixed colors for specific elements
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

_mirror() {
  local s="$1" out="" i c
  for (( i = ${#s} - 1; i >= 0; i-- )); do
    c="${s:$i:1}"
    case "$c" in
      ┌) c=┐ ;; ┐) c=┌ ;;
      └) c=┘ ;; ┘) c=└ ;;
      ├) c=┤ ;; ┤) c=├ ;;
      ┏) c=┓ ;; ┓) c=┏ ;;
      ┗) c=┛ ;; ┛) c=┗ ;;
      ┣) c=┫ ;; ┫) c=┣ ;;
      ╭) c=╮ ;; ╮) c=╭ ;;
      ╰) c=╯ ;; ╯) c=╰ ;;
      ◤) c=◥ ;; ◥) c=◤ ;;
      ◣) c=◢ ;; ◢) c=◣ ;;
    esac
    out+="$c"
  done
  printf '%s' "$out"
}

# ================================================================
# Counters
# ================================================================
_count_ai() { local c=0; for cmd in opencode claude gemini codex qwen vibe mimo hermes kimi ollama freebuff agy mmx pi engram codegraph command-code gentle-ai gga openclaude openclaw mistral-vibe minimax-cli antigravity-cli heygen seedance veo3 odysseus kimchi; do command -v "$cmd" &>/dev/null && ((c++)); done; echo "$c"; }
_count_lang() { local c=0; for cmd in node python python3 rustc go clang php perl; do command -v "$cmd" &>/dev/null && ((c++)); done; echo "$c"; }
_count_db() { local c=0; command -v pg_ctl &>/dev/null && ((c++)); command -v mariadb &>/dev/null && ((c++)); command -v sqlite3 &>/dev/null && ((c++)); command -v mongod &>/dev/null && ((c++)); echo "$c"; }
_uptime() {
  if [[ -f /proc/uptime ]]; then
    local secs; secs=$(awk '{print int($1)}' /proc/uptime 2>/dev/null)
    local d=$((secs/86400)) h=$((secs%86400/3600)) m=$((secs%3600/60))
    if (( d>0 )); then printf "%dd %dh" "$d" "$h"
    elif (( h>0 )); then printf "%dh %dm" "$h" "$m"
    else printf "%dm" "$m"; fi
  else echo "?"; fi
}
_ram_free() {
  if [[ -f /proc/meminfo ]]; then
    local kb; kb=$(grep MemAvailable /proc/meminfo 2>/dev/null | awk '{print $2}')
    [[ -n "$kb" ]] && echo "$((kb/1024))MB" || echo "?"
  else echo "?"; fi
}

# ================================================================
# OMNI letters design (8 wide x 7 tall)
# ================================================================
O=(
"╭────╮"
"│ ╭╮ │"
"│ ││ │"
"│ ││ │"
"│ ││ │"
"│ ╰╯ │"
"╰────╯"
)

M=(
"╭╮  ╭╮"
"││  ││"
"│╲  ╱│"
"│ ╲╱ │"
"│ ╭╮ │"
"│ ││ │"
"╰╯  ╰╯"
)

N=(
"╭────╮"
"││   │"
"││   │"
"│╲   │"
"│ ╲  │"
"│  ╲││"
"╰╯  ╰╯"
)

I=(
"╭────╮"
"│ │  │"
"│ │  │"
"│ │  │"
"│ │  │"
"│ │  │"
"╰────╯"
)

OMNI_LETTERS=(O M N I)
OMNI_W=8

# OMNI colors: gradient across letters
OMNI_COLORS=("${TP[1]}" "${TP[5]}" "${TP[9]}" "${TP[13]}")

# ================================================================
# CATALYST letters design (5 wide x 5 tall)
# ================================================================
C_A=(
"╭──╮"
"│╭╮│"
"││││"
"││││"
"╰╯╰╯"
)
C_T=(
"╭──╮"
" ││ "
" ││ "
" ││ "
" ╰╯ "
)
C_L=(
"╭   "
"│   "
"│   "
"│   "
"╰──╮"
)
C_Y=(
"╭──╮"
" ╲╱ "
" ││ "
" ││ "
" ╰╯ "
)
C_S=(
"╭──╮"
"│   "
"╰──╮"
"   │"
"╰──╯"
)

C_C=(
"╭──╮"
"│   "
"│   "
"│   "
"╰──╯"
)

# Map CATALYST letters
CAT_MAP=(C_C C_A C_T C_A C_L C_Y C_S C_T)
CAT_W=5
CAT_H=5
CAT_COLORS=("${TP[0]}" "${TP[2]}" "${TP[4]}" "${TP[6]}" "${TP[8]}" "${TP[10]}" "${TP[12]}" "${TP[14]}")

# ================================================================
# Side circuit decorations
# ================================================================
SIDE_H=7
SIDE_W=4
DECOR_L=(
$'╭──╮'
$'│  ╰'
$'╰╮  '
$' │  '
$' ╰──'
$'╭╮  '
$'╰╯  '
)
DECOR_R=()
for row in "${DECOR_L[@]}"; do
  DECOR_R+=("$(_mirror "$row")")
done

# ================================================================
# CATALYST side circuit decorations
# ================================================================
CAT_DECOR_L=(
"╭─╮ "
"│╰╮ "
"│ │ "
"╰╮│ "
" ╰╯ "
)
CAT_DECOR_R=()
for row in "${CAT_DECOR_L[@]}"; do
  CAT_DECOR_R+=("$(_mirror "$row")")
done

# ================================================================
# Panel
# ================================================================
PANEL_HEADERS=("AI" "Lang" "DB" "Up" "RAM")
PANEL_ICONS=("◆" "</>" "⛁" "↗" "◫")

_panel_value() {
  case $1 in
    0) _count_ai ;;
    1) _count_lang ;;
    2) _count_db ;;
    3) _uptime ;;
    4) _ram_free ;;
  esac
}

# ================================================================
# Render
# ================================================================
_render() {
  local cols="${COLUMNS:-$(tput cols 2>/dev/null || echo 80)}"
  local W=$(( cols > 72 ? 68 : cols - 6 ))
  (( W < 40 )) && W=40
  local GAP_L=$(( (cols - W - 2) / 2 ))
  (( GAP_L < 0 )) && GAP_L=0
  local GAP_R=$(( cols - W - 2 - GAP_L ))
  (( GAP_R < 0 )) && GAP_R=0

  local pad_l; pad_l=$(printf '%*s' "$GAP_L" '')
  local pad_r; pad_r=$(printf '%*s' "$GAP_R" '')
  local sp_line; sp_line=$(printf '%*s' "$W" '')

  # ---- Gradient frame line with tech connectors ----
  local p1=$(( W / 4 )) p2=$(( W / 2 )) p3=$(( 3 * W / 4 ))
  local top_frame="" bot_frame="" i
  for (( i = 0; i < W; i++ )); do
    local c_idx=$(( i * 16 / W ))
    (( c_idx > 15 )) && c_idx=15
    if (( i == 1 || i == W-2 )); then
      top_frame+="${TP[$c_idx]}╌${NC}"
      bot_frame+="${TP[$c_idx]}╌${NC}"
    elif (( i == p1 || i == p2 || i == p3 )); then
      top_frame+="${TP[$c_idx]}┬${NC}"
      bot_frame+="${TP[$c_idx]}┴${NC}"
    else
      top_frame+="${TP[$c_idx]}─${NC}"
      bot_frame+="${TP[$c_idx]}─${NC}"
    fi
  done

  # ---- Top frame ----
  echo "${pad_l}${TP[0]}╭${NC}${top_frame}${TP[15]}╮${NC}${pad_r}"

  # ---- Header row ----
  local hdr="${DIM}┄${NC}${DIM}┄${NC} ${TP[2]}◈${NC} ${WHITE}OMNI${NC} ${GRAY}${DIM}✦${NC} ${WHITE}SYSTEMS${NC} ${TP[2]}◈${NC} ${DIM}┄${NC}${DIM}┄${NC}"
  echo "${pad_l}${TP[0]}│${NC}$(_center "$hdr" "$W")${TP[15]}│${NC}${pad_r}"

  # ---- Empty row ----
  echo "${pad_l}${TP[0]}│${NC}${sp_line}${TP[15]}│${NC}${pad_r}"

  # ---- OMNI letters (7 rows) ----
  local total_omni_w=$(( OMNI_W * 4 + 3 ))
  for (( row_art = 0; row_art < 7; row_art++ )); do
    local content=""
    content+="${DIM}${DECOR_L[$row_art]}${NC} "
    local l
    for (( l = 0; l < 4; l++ )); do
      local _arr="${OMNI_LETTERS[$l]}" _val
      eval "_val=\"\${${_arr}[$row_art]}\""
      content+="${OMNI_COLORS[$l]}${_val}${NC}"
      (( l < 3 )) && content+=" "
    done
    content+=" ${DIM}${DECOR_R[$row_art]}${NC}"
    echo "${pad_l}${TP[0]}│${NC}$(_center "$content" "$W")${TP[15]}│${NC}${pad_r}"
  done

  # ---- CATALYST (5 rows) ----
  local total_cat_w=$(( CAT_W * 8 + 7 ))
  for (( cat_row = 0; cat_row < CAT_H; cat_row++ )); do
    local cat_line=""
    cat_line+="${DIM}${CAT_DECOR_L[$cat_row]}${NC} "
    for (( li = 0; li < 8; li++ )); do
      local _carr="${CAT_MAP[$li]}" _cval
      eval "_cval=\"\${${_carr}[$cat_row]}\""
      cat_line+="${CAT_COLORS[$li]}${_cval}${NC}"
      (( li < 7 )) && cat_line+=" "
    done
    cat_line+=" ${DIM}${CAT_DECOR_R[$cat_row]}${NC}"
    echo "${pad_l}${TP[0]}│${NC}$(_center "$cat_line" "$W")${TP[15]}│${NC}${pad_r}"
  done

  # ---- Tech bus divider ----
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
  echo "${pad_l}${TP[0]}│${NC}$(_center "$div_line" "$W")${TP[15]}│${NC}${pad_r}"

  # ---- RUBY & OBSIDIAN ----
  local gem_line="${TP[2]}◈${NC} ${RUBY}RUBY${NC} ${WHITE}&${NC} ${OBSIDIAN}OBSIDIAN${NC} ${TP[2]}◈${NC}"
  echo "${pad_l}${TP[0]}│${NC}$(_center "$gem_line" "$W")${TP[15]}│${NC}${pad_r}"

  # ---- Version ----
  echo "${pad_l}${TP[0]}│${NC}$(_center "${GREEN2}Omni${NC} ${GREEN1}v${BANNER_VERSION}${NC}" "$W")${TP[15]}│${NC}${pad_r}"

  # ---- Author ----
  echo "${pad_l}${TP[0]}│${NC}$(_center "${GRAY}by${NC} ${WHITE}israel${NC} ${GRAY}marques${NC}" "$W")${TP[15]}│${NC}${pad_r}"

  # ---- Empty row ----
  echo "${pad_l}${TP[0]}│${NC}${sp_line}${TP[15]}│${NC}${pad_r}"

  # ---- Info panel ----
  local PW=$(( W - 4 ))
  (( PW < 20 )) && PW=20
  local phline; phline=$(_repeat '─' "$PW")

  # Panel top
  echo "${pad_l}${TP[0]}│${NC} ${TP[3]}╭${NC}${phline}${TP[11]}╮${NC} ${TP[15]}│${NC}${pad_r}"

  # Panel header
  local ph=" ${TP[3]}◈${NC} ${WHITE}STATUS${NC} ${TP[3]}◈${NC} "
  echo "${pad_l}${TP[0]}│${NC} ${TP[3]}│${NC}$(_center "$ph" "$PW")${TP[11]}│${NC} ${TP[15]}│${NC}${pad_r}"

  # Panel separator
  local psep="" j
  for (( j = 0; j < PW; j++ )); do
    local m=$(( j % 4 ))
    if (( m == 0 )); then psep+="─"
    elif (( m == 1 )); then psep+="┄"
    elif (( m == 2 )); then psep+="·"
    else psep+="─"; fi
  done
  echo "${pad_l}${TP[0]}│${NC} ${TP[3]}│${NC}${DIM}${psep}${NC}${TP[11]}│${NC} ${TP[15]}│${NC}${pad_r}"

  # Panel data row
  local col_w=$(( (PW - 4) / 5 ))
  local col_line=""
  for (( i = 0; i < 5; i++ )); do
    local val; val=$(_panel_value $i)
    local entry="${TP[$(( i * 3 + 1 ))]}${PANEL_ICONS[$i]}${NC} ${WHITE}${PANEL_HEADERS[$i]}${NC} ${GREEN1}${val}${NC}"
    local ev; ev=$(_ansi_len "$entry")
    local epad=$(( (col_w - ev) / 2 ))
    local epad2=$(( col_w - ev - epad ))
    (( epad < 0 )) && epad=0
    (( epad2 < 0 )) && epad2=0
    col_line+="$(printf '%*s' "$epad" '')${entry}$(printf '%*s' "$epad2" '')"
    (( i < 4 )) && col_line+="${GRAY}│${NC}"
  done
  echo "${pad_l}${TP[0]}│${NC} ${TP[3]}│${NC}${col_line}${TP[11]}│${NC} ${TP[15]}│${NC}${pad_r}"

  # Panel bottom
  echo "${pad_l}${TP[0]}│${NC} ${TP[3]}╰${NC}${phline}${TP[11]}╯${NC} ${TP[15]}│${NC}${pad_r}"

  # ---- Empty row ----
  echo "${pad_l}${TP[0]}│${NC}${sp_line}${TP[15]}│${NC}${pad_r}"

  # ---- Decorative dot line ----
  local dot_line="" j
  for (( j = 0; j < W; j++ )); do
    if (( j == W/2 )); then
      dot_line+="${TP[3]}◈${NC}"
    elif (( j % 5 == 0 )); then
      dot_line+="${DIM}·${NC}"
    elif (( j % 3 == 1 )); then
      dot_line+="${GRAY}${DIM}┄${NC}"
    else
      dot_line+="${DIM}─${NC}"
    fi
  done
  echo "${pad_l}${TP[0]}│${NC}${dot_line}${TP[15]}│${NC}${pad_r}"

  # ---- Bottom card frame ----
  echo "${pad_l}${TP[0]}│${NC}${DIM}╭${NC}$(printf '%*s' $((W-2)) '')${DIM}╮${NC}${TP[15]}│${NC}${pad_r}"

  # ---- Run omni line ----
  local run_content="${CYAN}>${NC} ${GREEN1}Run${NC} ${WHITE}omni${NC} ${GREEN1}to get started${NC} ${CYAN}_${NC}"
  echo "${pad_l}${TP[0]}│${NC}${DIM}╰${NC}$(_center "$run_content" $((W-2)))${DIM}╯${NC}${TP[15]}│${NC}${pad_r}"

  # ---- Bottom frame ----
  echo "${pad_l}${TP[0]}╰${NC}${bot_frame}${TP[15]}╯${NC}${pad_r}"
}

# Block user input while banner renders
_omni_banner_block_input() {
  if [[ -t 0 ]] && [[ -t 1 ]]; then
    _OMNI_SAVED_STTY=$(stty -g 2>/dev/null)
    stty -echo -icanon min 0 time 0 2>/dev/null
    # Drain any buffered input
    while IFS= read -rsn1 -t 0.01 _drain 2>/dev/null; do :; done
  fi
}

_omni_banner_unblock_input() {
  if [[ -n "${_OMNI_SAVED_STTY:-}" ]]; then
    stty "$_OMNI_SAVED_STTY" 2>/dev/null
    unset _OMNI_SAVED_STTY
  fi
}

_omni_banner_block_input
echo
_render
_omni_banner_unblock_input

# Cache banner for clear() override
_omni_banner_cache="${XDG_CACHE_HOME:-$HOME/.cache}/omni/banner_cache"
mkdir -p "$(dirname "$_omni_banner_cache")" 2>/dev/null
[[ -t 1 ]] && _render > "$_omni_banner_cache" 2>/dev/null

log_tip() { echo " ${TP[3]}●${NC} ${GRAY}Tip${NC} $*"; }

OMNI_TIPS=(
  "Keep Omni updated: ${TP[3]}omni update omni${NC}"
  "Check your version: ${TP[3]}omni --version${NC}"
  "Enable debug logs: ${TP[3]}export OMNI_DEBUG=1${NC}"
  "Open framework docs: ${TP[3]}omni open omni${NC}"
  "Install everything: ${TP[3]}omni install lang db dev npm${NC}"
  "Install specific AI tools: ${TP[3]}omni install ai --opencode --ollama${NC}"
  "See what's installed: ${TP[3]}omni list ai${NC}"
  "Read tool docs: ${TP[3]}omni show ai --opencode${NC}"
  "Update a specific tool: ${TP[3]}omni update ai --opencode${NC}"
  "Update all AI tools: ${TP[3]}omni update ai${NC}"
  "Update all databases: ${TP[3]}omni update db${NC}"
  "Update ZSH plugins: ${TP[3]}omni update shell${NC}"
  "Remove a module: ${TP[3]}omni uninstall npm${NC}"
  "Install all languages: ${TP[3]}omni install lang${NC}"
  "Install Python: ${TP[3]}omni install lang --python${NC}"
  "Install Rust: ${TP[3]}omni install lang --rust${NC}"
  "Install Go: ${TP[3]}omni install lang --golang${NC}"
  "Start PostgreSQL: ${TP[3]}omni pg init${NC} then ${TP[3]}omni pg start${NC}"
  "Open psql shell: ${TP[3]}omni pg shell${NC}"
  "Install all AI agents: ${TP[3]}omni install ai${NC}"
  "Install OpenCode: ${TP[3]}omni install ai --opencode${NC}"
  "Install Claude Code: ${TP[3]}omni install ai --claude-code${NC}"
  "Install Codex CLI: ${TP[3]}omni install ai --codex${NC}"
  "Install Gemini CLI: ${TP[3]}omni install ai --gemini-cli${NC}"
  "Install MiMo Code: ${TP[3]}omni install ai --mimocode${NC}"
  "Install Neovim + NvChad: ${TP[3]}omni install editor${NC}"
  "Fuzzy search: ${TP[3]}omni install dev --fzf${NC}"
  "Modern ls: ${TP[3]}omni install dev --lsd${NC}"
  "Syntax cat: ${TP[3]}omni install dev --bat${NC}"
  "GitHub CLI: ${TP[3]}omni install dev --gh${NC}"
  "Format shell scripts: ${TP[3]}omni install dev --shfmt${NC}"
  "Process JSON: ${TP[3]}omni install dev --jq${NC}"
  "Deploy to Vercel: ${TP[3]}omni install npm --vercel${NC}"
  "TypeScript: ${TP[3]}omni install npm --typescript${NC}"
  "Install ZSH + plugins: ${TP[3]}omni install shell${NC}"
  "Customize Termux UI: ${TP[3]}omni install ui${NC}"
  "Install banner: ${TP[3]}omni install ui --banner${NC}"
  "Set API keys: ${TP[3]}omni env set${NC}"
  "Second brain: ${TP[3]}omni brain init${NC}"
  "Save memories: ${TP[3]}omni brain save${NC}"
  "Voice-to-AI: ${TP[3]}omni voice opencode${NC}"
  "Init Next.js: ${TP[3]}cd my-app && omni init next${NC}"
  "Init Express: ${TP[3]}cd api && omni init express${NC}"
)

_tip_index_file="${XDG_CACHE_HOME:-$HOME/.cache}/omni/.last_tip_index"
if [[ ${#OMNI_TIPS[@]} -gt 0 ]]; then
  last_index=-1
  [[ -f "$_tip_index_file" ]] && last_index=$(cat "$_tip_index_file" 2>/dev/null || echo "-1")
  new_index=$last_index
  while [[ "$new_index" == "$last_index" ]]; do new_index=$(( RANDOM % ${#OMNI_TIPS[@]} )); done
  echo "$new_index" >"$_tip_index_file"
  _tip="${OMNI_TIPS[$new_index]:-}"
  [[ -n "$_tip" ]] && { echo; log_tip "$_tip"; }
fi
echo
