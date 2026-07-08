#!/usr/bin/env bash

import "@/utils/log"
import "@/utils/colors"

voice_help() {
  echo
  box "OMNI VOICE — Speech-to-Agent"
  echo
  log_info "Capture voice, review in ${EDITOR:-nano}, copy to clipboard, launch any AI agent."
  echo
  log_info "Usage: omni voice [agent] [options]"
  echo
  separator_section "Agents"
  echo
  printf "    ${D_CYAN}%-16s${NC} %s\n" "kilo" "kilo --prompt \"prompt\""
  printf "    ${D_CYAN}%-16s${NC} %s\n" "opencode" "opencode run \"prompt\""
  printf "    ${D_CYAN}%-16s${NC} %s\n" "claude-code" "claude -p \"prompt\""
  printf "    ${D_CYAN}%-16s${NC} %s\n" "codex" "codex \"prompt\""
  printf "    ${D_CYAN}%-16s${NC} %s\n" "gemini-cli" "gemini -p \"prompt\""
  printf "    ${D_CYAN}%-16s${NC} %s\n" "hermes-agent" "hermes chat -q \"prompt\""
  printf "    ${D_CYAN}%-16s${NC} %s\n" "kimi-code" "kimi -p \"prompt\""
  printf "    ${D_CYAN}%-16s${NC} %s\n" "mimocode" "mimo run \"prompt\""
  printf "    ${D_CYAN}%-16s${NC} %s\n" "mistral-vibe" "vibe --prompt \"prompt\""
  printf "    ${D_CYAN}%-16s${NC} %s\n" "openclaude" "openclaude --bg \"prompt\""
  printf "    ${D_CYAN}%-16s${NC} %s\n" "pi" "pi -p \"prompt\""
  printf "    ${D_CYAN}%-16s${NC} %s\n" "qwen-code" "qwen -p \"prompt\""
  printf "    ${D_CYAN}%-16s${NC} %s\n" "crush" "crush \"prompt\""
  printf "    ${D_CYAN}%-16s${NC} %s\n" "kiro" "kiro-cli \"prompt\""
  printf "    ${D_CYAN}%-16s${NC} %s\n" "text" "Print prompt to stdout (no agent)"
  echo
  separator_section "Options"
  echo
  printf "    ${D_CYAN}%-20s${NC} %s\n" "--lang <code>" "Speech language (e.g. pt-BR, en-US, es)"
  printf "    ${D_CYAN}%-20s${NC} %s\n" "--raw" "Skip ${EDITOR:-nano} editing, use raw capture"
  printf "    ${D_CYAN}%-20s${NC} %s\n" "--no-clip" "Skip clipboard copy"
  echo
  separator_section "Examples"
  echo
  printf "    ${D_CYAN}omni voice${NC}                         # Show this help\n"
  printf "    ${D_CYAN}omni voice opencode${NC}                # Capture -> ${EDITOR:-nano} -> opencode\n"
  printf "    ${D_CYAN}omni voice claude-code --lang pt-BR${NC} # Portuguese speech -> claude\n"
  printf "    ${D_CYAN}omni voice text --raw${NC}              # Capture -> print (no edit)\n"
  printf "    ${D_CYAN}omni voice text --no-clip${NC}          # Capture -> edit -> print\n"
  echo
  separator_section "Requirements"
  echo
  list_item "Termux:API package: ${D_CYAN}pkg install termux-api${NC}"
  list_item "${EDITOR:-nano} editor: ${D_CYAN}omni install editor${NC}"
  list_item "Termux:API app: ${D_CYAN}https://omni-catalyst.vercel.app/termux/api${NC}"
  echo
}

voice_main() {
  local agent="${1:-}"
  local lang=""
  local skip_edit=false
  local no_clip=false
  local extra_args=()
  local parsed=false

  # Parse options before agent
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --lang) lang="$2"; shift 2 ;;
      --raw) skip_edit=true; shift ;;
      --no-clip) no_clip=true; shift ;;
      --help|-h) voice_help; return ;;
      --) shift; break ;;
      *) break ;;
    esac
  done

  agent="${1:-}"

  if [[ -z "$agent" ]] || [[ "$agent" == "--help" ]] || [[ "$agent" == "-h" ]]; then
    voice_help
    return
  fi

  # Normalize ! alias
  [[ "$agent" == "!" ]] && agent="text"

  # -- dependency checks --
  if ! command -v termux-speech-to-text &>/dev/null; then
    if command -v termux-dialog &>/dev/null; then
      log_warn "Using legacy termux-dialog (upgrade Termux:API for better STT)"
    else
      log_error "Termux:API is not installed"
      list_item "Install the package: ${D_CYAN}pkg install termux-api${NC}"
      list_item "Install the app: https://omni-catalyst.vercel.app/termux/api"
      separator
      return 1
    fi
  fi

  if ! command -v "${EDITOR:-nano}" &>/dev/null && [[ "$skip_edit" == "false" ]]; then
    log_warn "${EDITOR:-nano} not installed — falling back to --raw mode"
    skip_edit=true
  fi

  # -- start Termux API activity --
  local api_ok=0
  if command -v termux-api-start &>/dev/null; then
    termux-api-start &>/dev/null || api_ok=$?
  else
    api_ok=1
  fi
  if [[ $api_ok -ne 0 ]]; then
    log_warn "Failed to start Termux API activity — speech may not work"
  fi

  local is_text=false
  [[ "$agent" == "text" ]] && is_text=true

  # -- capture voice --
  $is_text || log_info "Listening through the microphone..."
  local raw=""

  if command -v termux-speech-to-text &>/dev/null; then
    if [[ -n "$lang" ]]; then
      raw="$(termux-speech-to-text -l "$lang" 2>/dev/null)"
    else
      raw="$(termux-speech-to-text 2>/dev/null)"
    fi
  elif command -v termux-dialog &>/dev/null; then
    raw="$(termux-dialog speech 2>/dev/null | grep -i "text" | cut -d '"' -f 4)"
  fi

  if [[ -z "$raw" ]]; then
    log_error "No speech detected or dialog cancelled"
    separator
    return 1
  fi

  # -- skip editor if --raw --
  local prompt="$raw"
  if [[ "$skip_edit" == "false" ]] && [[ -t 0 ]] && [[ -t 1 ]]; then
    local tmpfile
    tmpfile="$(mktemp)"
    echo "$raw" >"$tmpfile"
    $is_text || log_info "Review the prompt in ${EDITOR:-nano}, fix mistakes, then save and quit"
    ${EDITOR:-nano} "$tmpfile" </dev/tty >/dev/tty || true
    prompt="$(< "$tmpfile")"
    rm -f "$tmpfile"
  elif [[ "$skip_edit" == "false" ]] && ! { [[ -t 0 ]] && [[ -t 1 ]]; }; then
    $is_text || log_warn "No TTY available, skipping editor — using raw capture"
  fi

  prompt="${prompt## }"
  prompt="${prompt%% }"

  if [[ -z "$prompt" ]]; then
    log_error "Prompt is empty after editing"
    separator
    return 1
  fi

  # -- copy to clipboard --
  if [[ "$no_clip" == "false" ]] && command -v termux-clipboard-set &>/dev/null; then
    echo "$prompt" | termux-clipboard-set
    $is_text || log_info "Prompt copied to clipboard"
  fi

  # -- "text" -> just print --
  if [[ "$is_text" == "true" ]]; then
    echo "$prompt"
    return
  fi

  # -- dispatch to agent --
  log_info "Launching ${D_CYAN}$agent${NC} with prompt..."
  echo

  case "$agent" in
    kilo)
      kilo --prompt "$prompt"
      ;;
    opencode)
      opencode run "$prompt"
      ;;
    claude-code)
      claude -p "$prompt"
      ;;
    codex)
      codex "$prompt"
      ;;
    gemini-cli)
      gemini -p "$prompt"
      ;;
    hermes-agent)
      hermes chat -q "$prompt"
      ;;
    kimi-code)
      kimi -p "$prompt"
      ;;
    mimocode)
      mimo run "$prompt"
      ;;
    mistral-vibe)
      vibe --prompt "$prompt"
      ;;
    openclaude)
      openclaude --bg "$prompt"
      ;;
    pi)
      pi -p "$prompt"
      ;;
    qwen-code)
      qwen -p "$prompt"
      ;;
    crush)
      crush "$prompt"
      ;;
    kiro)
      kiro-cli "$prompt"
      ;;
    *)
      log_error "Unknown agent: $agent"
      echo
      log_info "Supported agents:"
      echo "  kilo, opencode, claude-code, codex, gemini-cli, hermes-agent,"
      echo "  kimi-code, mimocode, mistral-vibe, openclaude, pi, qwen-code, crush, kiro"
      echo
      log_info "Special: text (print only), ! (alias for text)"
      separator
      return 1
      ;;
  esac
}
