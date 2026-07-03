#!/usr/bin/env bash

BANNER_SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"
BANNER_VERSION="$(grep "^OMNI_VERSION=" "$BANNER_SCRIPT_DIR/env.sh" 2>/dev/null | cut -d'"' -f2)"

DGREEN="\033[0;32m"
NC="\033[0m"
GRAY="\033[0;90m"
D_CYAN="\033[0;36m"

R1="\033[38;5;196m"
R2="\033[38;5;160m"
R3="\033[38;5;124m"
R4="\033[38;5;88m"
R5="\033[38;5;226m"

P1="\033[38;5;93m"
P2="\033[38;5;129m"
P3="\033[38;5;55m"
P4="\033[38;5;92m"
P5="\033[38;5;183m"

BORDER="\033[38;5;33m"

_banner_count_ai() {
  local count=0
  for cmd in opencode claude gemini codex qwen vibe mimo hermes kimi ollama freebuff agy mmx pi engram codegraph command-code gentle-ai gga openclaude openclaw mistral-vibe minimax-cli antigravity-cli kiro heygen seedance veo3 odysseus; do
    command -v "$cmd" &>/dev/null && ((count++))
  done
  echo "$count"
}

_banner_count_lang() {
  local count=0
  for cmd in node python python3 rustc go clang php perl; do
    command -v "$cmd" &>/dev/null && ((count++))
  done
  echo "$count"
}

_banner_count_db() {
  local count=0
  command -v pg_ctl &>/dev/null && ((count++))
  command -v mariadb &>/dev/null && ((count++))
  command -v sqlite3 &>/dev/null && ((count++))
  command -v mongod &>/dev/null && ((count++))
  echo "$count"
}

_banner_uptime() {
  if [[ -f /proc/uptime ]]; then
    local secs
    secs=$(awk '{print int($1)}' /proc/uptime)
    local days=$((secs / 86400))
    local hours=$(( (secs % 86400) / 3600 ))
    local mins=$(( (secs % 3600) / 60 ))
    if (( days > 0 )); then printf "%dd %dh %dm" "$days" "$hours" "$mins"
    elif (( hours > 0 )); then printf "%dh %dm" "$hours" "$mins"
    else printf "%dm" "$mins"; fi
  else echo "?"; fi
}

_banner_ram_free() {
  if [[ -f /proc/meminfo ]]; then
    local free_kb
    free_kb=$(grep MemAvailable /proc/meminfo 2>/dev/null | awk '{print $2}')
    [[ -n "$free_kb" ]] && echo "$((free_kb / 1024))MB" || echo "?"
  else echo "?"; fi
}

# ── Alternating colors for center text ──
_CM="${R1}O${NC} ${BORDER}M${NC} ${P2}N${NC} ${R1}I${NC}"
_CA="${BORDER}C${NC} ${P2}A${NC} ${R1}T${NC} ${BORDER}A${NC} ${P2}L${NC} ${R1}Y${NC} ${BORDER}S${NC} ${P2}T${NC}"

# ── Strip ANSI for visible-length calculation ──
# Variables store \033 as literal text; convert to real ESC before stripping
_ansi_len() {
  local s="$1"
  local esc
  esc=$(printf '\033')
  s="${s//\\033/${esc}}"
  printf '%s' "$s" | sed 's/\x1b\[[0-9;]*m//g' | wc -c | tr -d ' '
}

# ── Center text to exactly N visible chars ──
_center() {
  local text="$1" width="$2"
  local vis
  vis=$(_ansi_len "$text")
  local total=$(( width - vis ))
  local left=$(( total / 2 ))
  local right=$(( total - left ))
  printf '%*s' "$left" ''
  printf '%s' "$text"
  printf '%*s' "$right" ''
}

# ── Render banner (62 inner chars per line) ──
_render() {
  local W=62
  echo -e "  ${BORDER}+$(printf '%0*d' "$W" | tr '0' '-')+${NC}"
  echo -e "  ${BORDER}|${NC}$(_center "${R5}*${NC}" "$W")${BORDER}|${NC}"
  echo -e "  ${BORDER}|${NC}$(_center "${R2}ooo${NC}" "$W")${BORDER}|${NC}"

  # ── Gem rows: " <ruby> <gap> <obsidian> " ──
  # vis = 1 + rv + gap + ov + 1 = 62  =>  gap = 60 - rv - ov
  local _rv=(1 3 5 7 5 3 1)
  local _ov=(1 3 5 7 5 3 1)
  local _rc=("${R5}*${NC}" "${R2}ooo${NC}" "${R3}ooooo${NC}" "${R4}ooooooo${NC}" "${R3}ooooo${NC}" "${R2}ooo${NC}" "${R5}*${NC}")
  local _oc=("${P1}*${NC}" "${P2}ooo${NC}" "${P3}ooooo${NC}" "${P4}ooooooo${NC}" "${P5}ooooo${NC}" "${P4}ooo${NC}" "${P3}*${NC}")
  local i gap mid
  for i in 0 1 2 3 4 5 6; do
    gap=$(( 60 - _rv[i] - _ov[i] ))
    if [[ $i -eq 2 ]]; then
      mid="$(_center "${_CM}" "$gap")"
    elif [[ $i -eq 4 ]]; then
      mid="$(_center "${_CA}" "$gap")"
    else
      mid="$(printf '%*s' "$gap" '')"
    fi
    echo -e "  ${BORDER}|${NC} ${_rc[$i]}${mid}${_oc[$i]} ${BORDER}|${NC}"
  done

  echo -e "  ${BORDER}|${NC}$(_center "${R2}ooo${NC}" "$W")${BORDER}|${NC}"
  echo -e "  ${BORDER}|${NC}$(_center "${R5}*${NC}" "$W")${BORDER}|${NC}"
  echo -e "  ${BORDER}|${NC}$(printf '%*s' "$W" '')${BORDER}|${NC}"
  echo -e "  ${BORDER}|${NC}$(_center "${R1}d${NC} ${R2}RUBY${NC} & ${P2}OBSIDIAN${NC} ${P1}d${NC}" "$W")${BORDER}|${NC}"
  [[ -n "$BANNER_VERSION" ]] && echo -e "  ${BORDER}|${NC}$(_center "${GRAY}Omni${NC} ${DGREEN}v${BANNER_VERSION}${NC}" "$W")${BORDER}|${NC}"
  echo -e "  ${BORDER}|${NC}$(_center "${GRAY}by israel marques${NC}" "$W")${BORDER}|${NC}"
  echo -e "  ${BORDER}|${NC}$(printf '%*s' "$W" '')${BORDER}|${NC}"
  echo -e "  ${BORDER}|${NC}$(_center "${GRAY}AI${NC}: ${DGREEN}$(_banner_count_ai)${NC}  ${GRAY}Lang${NC}: ${DGREEN}$(_banner_count_lang)${NC}  ${GRAY}DB${NC}: ${DGREEN}$(_banner_count_db)${NC}  ${GRAY}Up${NC}: ${DGREEN}$(_banner_uptime)${NC}  ${GRAY}RAM${NC}: ${DGREEN}$(_banner_ram_free)${NC}" "$W")${BORDER}|${NC}"
  echo -e "  ${BORDER}|${NC}$(_center "${D_CYAN}Run${NC} ${DGREEN}omni${NC} ${D_CYAN}to get started${NC}" "$W")${BORDER}|${NC}"
  echo -e "  ${BORDER}+$(printf '%0*d' "$W" | tr '0' '-')+${NC}"
}

echo
_render

# ── Persistent banner after clear ──
_omni_banner_cache="${XDG_CACHE_HOME:-$HOME/.cache}/omni/banner_cache"
mkdir -p "$(dirname "$_omni_banner_cache")" 2>/dev/null

if [[ -t 1 ]] && [[ -z "${_OMNI_RECURSING:-}" ]]; then
  _render > "$_omni_banner_cache" 2>/dev/null
  _omni_cache_file="$_omni_banner_cache"
  clear() {
    command clear
    if [[ -z "${_OMNI_RECURSING:-}" ]]; then
      _OMNI_RECURSING=1
      [[ -f "$_omni_cache_file" ]] && cat "$_omni_cache_file"
      unset _OMNI_RECURSING
    fi
  }
fi

# ── Tips ──
log_tip() { echo -e " ${D_CYAN}● Tip${NC} $*"; }

OMNI_TIPS=(
  "Keep Omni updated: ${D_CYAN}omni update omni${NC}"
  "Check your version: ${D_CYAN}omni --version${NC}"
  "Enable debug logs: ${D_CYAN}export OMNI_DEBUG=1${NC}"
  "Shell remembers your last directory"
  "Open framework docs: ${D_CYAN}omni open omni${NC}"
  "Install everything: ${D_CYAN}omni install lang db dev npm${NC}"
  "Install specific AI tools: ${D_CYAN}omni install ai --opencode --ollama${NC}"
  "See what's installed: ${D_CYAN}omni list ai${NC}"
  "Read tool docs: ${D_CYAN}omni show ai --opencode${NC}"
  "Update a specific tool: ${D_CYAN}omni update ai --opencode${NC}"
  "Update all AI tools: ${D_CYAN}omni update ai${NC}"
  "Update all databases: ${D_CYAN}omni update db${NC}"
  "Update ZSH plugins: ${D_CYAN}omni update shell${NC}"
  "Reinstall from scratch: ${D_CYAN}omni reinstall shell${NC}"
  "Remove a module: ${D_CYAN}omni uninstall npm${NC}"
  "Install all languages: ${D_CYAN}omni install lang${NC}"
  "Install Python: ${D_CYAN}omni install lang --python${NC}"
  "Install Rust: ${D_CYAN}omni install lang --rust${NC}"
  "Install Go: ${D_CYAN}omni install lang --golang${NC}"
  "Install all databases: ${D_CYAN}omni install db${NC}"
  "Start PostgreSQL: ${D_CYAN}omni pg init${NC} then ${D_CYAN}omni pg start${NC}"
  "Open psql shell: ${D_CYAN}omni pg shell${NC}"
  "Install all AI agents: ${D_CYAN}omni install ai${NC}"
  "Run Ollama locally: ${D_CYAN}omni install ai --ollama${NC}"
  "Install OpenCode: ${D_CYAN}omni install ai --opencode${NC}"
  "Install Claude Code: ${D_CYAN}omni install ai --claude-code${NC}"
  "Install Codex CLI: ${D_CYAN}omni install ai --codex${NC}"
  "Install Gemini CLI: ${D_CYAN}omni install ai --gemini-cli${NC}"
  "Install MiMo Code: ${D_CYAN}omni install ai --mimocode${NC}"
  "Install Neovim + NvChad: ${D_CYAN}omni install editor${NC}"
  "Fuzzy search: ${D_CYAN}omni install dev --fzf${NC}"
  "Modern ls: ${D_CYAN}omni install dev --lsd${NC}"
  "Syntax cat: ${D_CYAN}omni install dev --bat${NC}"
  "GitHub CLI: ${D_CYAN}omni install dev --gh${NC}"
  "Format shell scripts: ${D_CYAN}omni install dev --shfmt${NC}"
  "Process JSON: ${D_CYAN}omni install dev --jq${NC}"
  "Deploy to Vercel: ${D_CYAN}omni install npm --vercel${NC}"
  "Format code: ${D_CYAN}omni install npm --prettier${NC}"
  "TypeScript: ${D_CYAN}omni install npm --typescript${NC}"
  "Install ZSH + plugins: ${D_CYAN}omni install shell${NC}"
  "Customize Termux UI: ${D_CYAN}omni install ui${NC}"
  "Install banner: ${D_CYAN}omni install ui --banner${NC}"
  "Set API keys: ${D_CYAN}omni env set${NC}"
  "Second brain: ${D_CYAN}omni brain init${NC}"
  "Save memories: ${D_CYAN}omni brain save${NC}"
  "Voice-to-AI: ${D_CYAN}omni voice opencode${NC}"
  "Init Next.js: ${D_CYAN}cd my-app && omni init next${NC}"
  "Init Express: ${D_CYAN}cd api && omni init express${NC}"
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
