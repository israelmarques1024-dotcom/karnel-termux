#!/usr/bin/env bash

import "@/utils/log"
import "@/utils/colors"

LOG_FILE="$OMNI_CACHE/install_ai.log"

install_ai() {
  separator
  box "Installing AI Tools"
  separator
  echo

  log_info "Installing AI tools..."
  echo
  log_info "☕ Grab a coffee! This process typically takes 1h-2h hours."
  log_info "   Don't worry, it's normal for this to take a while..."
  echo

  mkdir -p "$(dirname "$LOG_FILE")"

  # Captura o exit code do instalador batch
  local install_rc=0
  _install_ai_tools_wrapper || install_rc=$?

  separator

  if [ "$install_rc" -eq 0 ]; then
    log_success "AI tools installed successfully"
  else
    log_warn "AI tools installed with $install_rc failure(s)"
    log_info "Check the details above for which tools failed"
    log_info "Run ${D_CYAN}omni doctor${NC} for system diagnostics"
  fi

  echo
  log_info "Tools installed and their commands:"
  echo

  # Mostra apenas ferramentas que foram realmente instaladas (command -v)
  local _reg_entry _id _name _bins
  for _reg_entry in "${AI_TOOLS_REGISTRY[@]}"; do
    IFS=':' read -r _id _name _bins <<< "$_reg_entry"
    # Pega o primeiro binario da lista (separado por virgula)
    local _first_bin="${_bins%%,*}"
    if command -v "$_first_bin" &>/dev/null; then
      list_item "$_name ${GRAY}(${D_GREEN}$_first_bin${GRAY})"
    fi
  done

  echo
  return $install_rc
}

_install_ai_tools_wrapper() {
  import "@/tools/ai/all"
  install_all_ai_tools
}

uninstall_ai() {
  local found=false
	for cmd in opencode claude gemini codex qwen vibe mimo hermes kimi ollama freebuff heygen seedance veo3 odysseus openclaude openclaw engram codegraph pi agy mmx gentle-ai gga command-code kilo kimchi; do
    if command -v "$cmd" &>/dev/null; then
      found=true
      break
    fi
  done
  if [[ "$found" == "false" ]]; then
    log_info "AI Tools are not installed"
    return 0
  fi
  separator
  box "Uninstalling AI Tools"
  separator
  echo

  log_info "Uninstalling AI tools..."

  _uninstall_ai_tools_wrapper
  log_success "AI tools uninstalled"
}

_uninstall_ai_tools_wrapper() {
  import "@/tools/ai/all"
  uninstall_all_ai_tools
}

update_ai() {
  separator
  box "Updating AI Tools"
  separator
  echo

  log_info "Updating AI tools..."

  _update_ai_tools_wrapper
  log_success "AI tools updated"
}

_update_ai_tools_wrapper() {
  import "@/tools/ai/all"
  update_all_ai_tools
}

reinstall_ai() {
  separator
  box "Reinstalling AI Tools"
  separator
  echo

  log_info "Reinstalling AI tools..."
  echo

  _reinstall_ai_tools_wrapper
  log_success "AI tools reinstalled successfully"
  separator
  echo
  list_item "Qwen Code"
  list_item "Gemini CLI"
  list_item "Mistral Vibe"
  list_item "OpenClaude"
  list_item "Claude Code"
  list_item "OpenClaw"
  list_item "Ollama"
  list_item "Codex"
  list_item "OpenCode"
  list_item "MiMo Code"
  list_item "Engram"
  list_item "CodeGraph"
  list_item "Pi"
  list_item "Antigravity CLI"
  list_item "Minimax CLI"
  list_item "Gentle AI"
  list_item "GGA"
  list_item "Hermes Agent"
  list_item "Kimi Code"
  list_item "Command Code"
  list_item "Freebuff"
  list_item "Kilo Code CLI"
  list_item "HeyGen CLI"
  list_item "Seedance CLI"
  list_item "Veo 3 SDK"
  list_item "Odysseus"
  list_item "Kimchi CLI"
  echo
}

_reinstall_ai_tools_wrapper() {
  import "@/tools/ai/all"
  reinstall_all_ai_tools
}
