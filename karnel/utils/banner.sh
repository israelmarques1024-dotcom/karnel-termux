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
_count_ai() { local c=0; for cmd in opencode claude gemini codex qwen vibe mimo hermes kimi ollama freebuff agy mmx pi engram codegraph command-code gentle-ai gga openclaude openclaw kiro crush odysseus kilocode kimchi cline omni-route ctx7 openspec; do command -v "$cmd" &>/dev/null && ((c++)); done; echo "$c"; }
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
  local _shine_r=$(( _text_len / 5 + 1 ))
  local _trans_r=$(( _text_len / 3 + 1 ))

  local _out="" _i _char
  for (( _i = 0; _i < ${#_text}; _i++ )); do
    _char="${_text:_i:1}"
    if [[ "$_char" == " " ]]; then
      _out+=" "
    else
      local _dist=$(( _i > _center ? _i - _center : _center - _i ))
      if (( _dist < _shine_r )); then
        _out+="${WHITE}${_char}"
      elif (( _dist < _trans_r )); then
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
# Fast single-pass metallic scan (foreground, ~50ms)
# ================================================================
_animate_figlet_fast() {
  local cols="${COLUMNS:-$(tput cols 2>/dev/null || echo 80)}"
  local W=$(( cols > 72 ? 68 : cols - 6 ))
  (( W < 40 )) && W=40
  local GAP_L=$(( (cols - W - 2) / 2 ))
  (( GAP_L < 0 )) && GAP_L=0
  local GAP_R=$(( cols - W - 2 - GAP_L ))
  (( GAP_R < 0 )) && GAP_R=0
  local pad_l=$(printf '%*s' "$GAP_L" '')
  local pad_r=$(printf '%*s' "$GAP_R" '')
  local l_border="${TP[0]}" r_border="${TP[15]}"

  local num_fl=${#FIGLET_LINES[@]}
  local num_tl=${#TERMUX_FIGLET_LINES[@]}
  (( num_fl + num_tl == 0 )) && return

  local fig_w=0 _fl
  for _fl in "${FIGLET_LINES[@]}"; do
    local tl=${#_fl}
    (( tl > fig_w )) && fig_w=$tl
  done

  local bnr_h=$(( 18 + num_fl + num_tl ))
  local up=$(( bnr_h - 3 ))
  local _step _fi _ti _line _ci _colored
  for (( _step = -8; _step <= fig_w + 16; _step += 16 )); do
    printf '\033[s\033[%dA' "$up"
    for (( _fi = 0; _fi < num_fl; _fi++ )); do
      _line="${FIGLET_LINES[$_fi]}"
      _ci=$(( _fi * 16 / (num_fl > 1 ? num_fl : 1) ))
      (( _ci > 15 )) && _ci=15
      _colored=$(_metallic_apply "$_line" "${RK[$_ci]}" "$_step")
      echo "${pad_l}${l_border}│${NC}$( _center "$_colored" "$W" )${r_border}│${NC}${pad_r}"
    done
    for (( _ti = 0; _ti < num_tl; _ti++ )); do
      _line="${TERMUX_FIGLET_LINES[$_ti]}"
      _ci=$(( _ti * 16 / (num_tl > 1 ? num_tl : 1) ))
      (( _ci > 15 )) && _ci=15
      _colored=$(_metallic_apply "$_line" "${RK[$_ci]}" "$_step")
      echo "${pad_l}${l_border}│${NC}$( _center "$_colored" "$W" )${r_border}│${NC}${pad_r}"
    done
    printf '\033[u'
  done
}

# ================================================================
# Isolated infinite daemon — uses scroll region + absolute CUP
# ================================================================
_karnel_banner_launch_daemon() {
  local num_fl=${#FIGLET_LINES[@]}
  local num_tl=${#TERMUX_FIGLET_LINES[@]}
  (( num_fl + num_tl == 0 )) && return

  local fig_w=0 _fl
  for _fl in "${FIGLET_LINES[@]}"; do
    local tl=${#_fl}
    (( tl > fig_w )) && fig_w=$tl
  done
  local bnr_h=$(( 18 + num_fl + num_tl ))
  local frow=$(( 3 + 1 )) # first figlet row (1-based)

  local df="${XDG_CACHE_HOME:-$HOME/.cache}/karnel/banner-daemon.sh"
  local pf="${XDG_CACHE_HOME:-$HOME/.cache}/karnel/banner-daemon.pid"
  mkdir -p "$(dirname "$df")" 2>/dev/null

  # Kill old
  [[ -f "$pf" ]] && kill "$(cat "$pf")" 2>/dev/null || true

  # Serialize figlet lines with printf %q
  local fl_lines tl_lines
  fl_lines=$(printf '%q\n' "${FIGLET_LINES[@]}")
  tl_lines=$(printf '%q\n' "${TERMUX_FIGLET_LINES[@]}")

  # Serialize color arrays
  local rk_ser tp_ser
  rk_ser=$(for c in "${RK[@]}"; do printf '%q ' "$c"; done)
  tp_ser=$(for c in "${TP[@]}"; do printf '%q ' "$c"; done)

  {
    printf '#!/usr/bin/env bash\n'
    printf 'ESCAPE='\''\\033'\''\n'
    # Only colors we actually need in the daemon
    printf 'NC="${ESCAPE}[0m"\n'
    printf 'WHITE="${ESCAPE}[38;2;255;255;255m"\n'
    printf 'M_SHINE="${ESCAPE}[38;2;255;215;0m"\n'
    # Compute everything else from scratch
    printf "NF=%d NT=%d FW=%d BH=%d FROW=%d\n" "$num_fl" "$num_tl" "$fig_w" "$bnr_h" "$frow"
    # Embed arrays
    printf 'RK=('; printf '%s ' $rk_ser; printf ')\n'
    printf 'TP=('; printf '%s ' $tp_ser; printf ')\n'
    # Embed figlet
    printf 'FL=('
    while IFS= read -r line; do printf '%s ' "$line"; done <<< "$fl_lines"
    printf ')\n'
    printf 'TL=('
    while IFS= read -r line; do printf '%s ' "$line"; done <<< "$tl_lines"
    printf ')\n'
    # Compact metallic function
    printf '%s' '
tc() { printf "${ESCAPE}[38;2;%d;%d;%dm" "$1" "$2" "$3"; }
_ansi_len() { printf "%s" "$1" | sed "s/\x1b\[[0-9;]*m//g" | wc -m | tr -d " "; }
_center() { local t="$1" w="$2" v; v=$(_ansi_len "$t"); local l=$((w-v)); printf "%*s%s%*s" $((l/2)) "" "$t" $((l-l/2)) ""; }
_metallic_apply() {
  local t="$1" b="$2" s="${3:-}" trm="${t#"${t%%[! ]*}"}"; trm="${trm%"${trm##*[!]}"}"
  local len=${#trm} lead="${t%%[! ]*}" ll=${#lead} ctr sl=$(( len / 5 + 1 )) tl=$(( len / 3 + 1 ))
  [[ -n "$s" ]] && ctr=$(( ll + s )) || ctr=$(( ll + len / 2 ))
  local out="" i ch
  for (( i=0; i<${#t}; i++ )); do
    ch="${t:i:1}"; [[ "$ch" == " " ]] && { out+=" "; continue; }
    local d=$(( i > ctr ? i - ctr : ctr - i ))
    if (( d < sl )); then out+="${WHITE}${ch}"; elif (( d < tl )); then out+="${M_SHINE}${ch}"; else out+="${b}${ch}"; fi
  done
  printf "%s%s" "$out" "$NC"
}
# Scroll region: fix banner at top
tput csr "$BH" "$(( $(tput lines 2>/dev/null || echo 40) - 1 ))"
trap "tput csr 0 \$(( \$(tput lines 2>/dev/null || echo 40) - 1 )); exit" EXIT TERM INT
trap "tput csr \$BH \$(( \$(tput lines 2>/dev/null || echo 40) - 1 ))" WINCH 2>/dev/null || true
step=-8
while true; do
  kill -0 "$PPID" 2>/dev/null || exit 0
  printf "\033[s"
  for (( i=0; i<NF; i++ )); do
    local ci=$(( i * 16 / (NF>1?NF:1) )); ((ci>15)) && ci=15
    local c
    cols="$(tput cols 2>/dev/null || echo 80)"; W=$(( cols>72?68:cols-6 )); ((W<40)) && W=40
    GL=$(( (cols-W-2)/2 )); ((GL<0)) && GL=0; GR=$(( cols-W-2-GL )); ((GR<0)) && GR=0
    printf "\033[%d;1H%*s%s│${NC}" "$((FROW+i))" "$GL" "" "${TP[0]}"
    _center "$(_metallic_apply "${FL[$i]}" "${RK[$ci]}" "$step")" "$W"
    printf "%s│${NC}%*s" "${TP[15]}" "$GR" ""
  done
  for (( i=0; i<NT; i++ )); do
    local ci=$(( i * 16 / (NT>1?NT:1) )); ((ci>15)) && ci=15
    cols="$(tput cols 2>/dev/null || echo 80)"; W=$(( cols>72?68:cols-6 )); ((W<40)) && W=40
    GL=$(( (cols-W-2)/2 )); ((GL<0)) && GL=0; GR=$(( cols-W-2-GL )); ((GR<0)) && GR=0
    printf "\033[%d;1H%*s%s│${NC}" "$((FROW+NF+i))" "$GL" "" "${TP[0]}"
    _center "$(_metallic_apply "${TL[$i]}" "${RK[$ci]}" "$step")" "$W"
    printf "%s│${NC}%*s" "${TP[15]}" "$GR" ""
  done
  printf "\033[u"
  step=$(( step + 8 )); (( step > FW + 8 )) && step=-8
  sleep 0.04 2>/dev/null || true
done
'
  } > "$df"
  chmod +x "$df"
  bash "$df" & disown 2>/dev/null
  echo $! > "$pf"
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

  local l_border="${TP[0]}" r_border="${TP[15]}"

  _render_frame_line "top"

  # ---- Header row (vibrant) ----
  local hdr="${TP[1]}┄${NC}${TP[1]}┄${NC} ${M_SHINE}◈${NC} ${BOLD}${WHITE}KARNEL${NC} ${WHITE}✦${NC} ${BOLD}${WHITE}SYSTEMS${NC} ${M_SHINE}◈${NC} ${TP[1]}┄${NC}${TP[1]}┄${NC}"
  echo "${pad_l}${l_border}│${NC}$(_center "$hdr" "$W")${r_border}│${NC}${pad_r}"

  # ---- Empty row ----
  echo "${pad_l}${l_border}│${NC}${sp_line}${r_border}│${NC}${pad_r}"

  # ---- KARNEL figlet: plain RK gradient (no metallic) ----
  local num_fl=${#FIGLET_LINES[@]}
  local _fi _line _ci
  for (( _fi = 0; _fi < num_fl; _fi++ )); do
    _line="${FIGLET_LINES[$_fi]}"
    _ci=$(( _fi * 16 / (num_fl > 1 ? num_fl : 1) ))
    (( _ci > 15 )) && _ci=15
    echo "${pad_l}${l_border}│${NC}$( _center "${RK[$_ci]}${_line}${NC}" "$W" )${r_border}│${NC}${pad_r}"
  done

  # ---- TERMUX figlet: plain RK gradient (no metallic) ----
  local num_tl=${#TERMUX_FIGLET_LINES[@]}
  local _ti
  for (( _ti = 0; _ti < num_tl; _ti++ )); do
    _line="${TERMUX_FIGLET_LINES[$_ti]}"
    _ci=$(( _ti * 16 / (num_tl > 1 ? num_tl : 1) ))
    (( _ci > 15 )) && _ci=15
    echo "${pad_l}${l_border}│${NC}$( _center "${RK[$_ci]}${_line}${NC}" "$W" )${r_border}│${NC}${pad_r}"
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
  echo "${pad_l}${l_border}│${NC}$(_center "$div_line" "$W")${r_border}│${NC}${pad_r}"

  # ---- Dev & mobile ----
  local gem_line="${M_SHINE}◈${NC} ${BOLD}${RUBY}Dev${NC} ${WHITE}${BOLD}&${NC} ${BOLD}${OBSIDIAN}mobile${NC} ${M_SHINE}◈${NC}"
  echo "${pad_l}${l_border}│${NC}$(_center "$gem_line" "$W")${r_border}│${NC}${pad_r}"

  # ---- Version (bold green) ----
  echo "${pad_l}${l_border}│${NC}$(_center "${GREEN2}${BOLD}Karnel${NC} ${GREEN1}v${BANNER_VERSION}${NC}" "$W")${r_border}│${NC}${pad_r}"

  # ---- Author ----
  echo "${pad_l}${l_border}│${NC}$(_center "${DIM}by${NC} ${BOLD}${WHITE}israel${NC} ${WHITE}marques${NC}" "$W")${r_border}│${NC}${pad_r}"

  # ---- Empty row ----
  echo "${pad_l}${l_border}│${NC}${sp_line}${r_border}│${NC}${pad_r}"

  # ---- Info panel ----
  local PW=$(( W - 4 ))
  (( PW < 20 )) && PW=20
  local phline; phline=$(_repeat '─' "$PW")

  # Panel top
  echo "${pad_l}${l_border}│${NC} ${M_SHINE}╭${NC}${phline}${M_SHINE}╮${NC} ${r_border}│${NC}${pad_r}"

  # Panel header
  local ph=" ${M_SHINE}◈${NC} ${BOLD}${WHITE}STATUS${NC} ${M_SHINE}◈${NC} "
  echo "${pad_l}${l_border}│${NC} ${M_SHINE}│${NC}$(_center "$ph" "$PW")${M_SHINE}│${NC} ${r_border}│${NC}${pad_r}"

  # Panel separator
  local psep="" j
  for (( j = 0; j < PW; j++ )); do
    local m=$(( j % 4 ))
    if (( m == 0 )); then psep+="─"
    elif (( m == 1 )); then psep+="┄"
    elif (( m == 2 )); then psep+="·"
    else psep+="─"; fi
  done
  echo "${pad_l}${l_border}│${NC} ${TP[3]}│${NC}${DIM}${psep}${NC}${TP[11]}│${NC} ${r_border}│${NC}${pad_r}"

  # Panel data row
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

  # Panel bottom
  echo "${pad_l}${l_border}│${NC} ${M_SHINE}╰${NC}${phline}${M_SHINE}╯${NC} ${r_border}│${NC}${pad_r}"

  # ---- Empty row ----
  echo "${pad_l}${l_border}│${NC}${sp_line}${r_border}│${NC}${pad_r}"

  # ---- Decorative dot line ----
  local dot_line="" j
  for (( j = 0; j < W; j++ )); do
    if (( j == W/2 )); then
      dot_line+="${M_SHINE}◈${NC}"
    elif (( j % 4 == 0 )); then
      dot_line+="${DIM}·${NC}"
    elif (( j % 3 == 1 )); then
      dot_line+="${TP[$(( j * 4 / W > 15 ? 15 : j * 4 / W ))]}┄${NC}"
    else
      dot_line+="${DIM}─${NC}"
    fi
  done
  echo "${pad_l}${l_border}│${NC}${dot_line}${r_border}│${NC}${pad_r}"

  _render_frame_line "bot"
}

echo
if [[ -t 1 ]]; then
  _render 2>/dev/null || true
  _animate_figlet_fast 2>/dev/null || true
  _karnel_banner_launch_daemon 2>/dev/null || true
else
  _render 2>/dev/null || true
fi

# Cache banner for clear() override
_banner_output=$(_render 2>/dev/null) || true
_karnel_banner_cache="${XDG_CACHE_HOME:-$HOME/.cache}/karnel/banner_cache"
mkdir -p "$(dirname "$_karnel_banner_cache")" 2>/dev/null
[[ -t 1 ]] && echo "$_banner_output" > "$_karnel_banner_cache" 2>/dev/null

log_tip() { echo " ${TP[3]}●${NC} ${GRAY}Tip${NC} $*"; }

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

_tip_index_file="${XDG_CACHE_HOME:-$HOME/.cache}/karnel/.last_tip_index"
if [[ ${#KARNEL_TIPS[@]} -gt 0 ]]; then
  last_index=-1
  [[ -f "$_tip_index_file" ]] && last_index=$(cat "$_tip_index_file" 2>/dev/null || echo "-1")
  new_index=$last_index
  while [[ "$new_index" == "$last_index" ]]; do new_index=$(( RANDOM % ${#KARNEL_TIPS[@]} )); done
  echo "$new_index" >"$_tip_index_file"
  _tip="${KARNEL_TIPS[$new_index]:-}"
  [[ -n "$_tip" ]] && { echo; log_tip "$_tip"; }
fi
echo
