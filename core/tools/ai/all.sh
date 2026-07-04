#!/usr/bin/env bash

import "@/utils/log"

LOG_FILE="$OMNI_CACHE/install_ai.log"

AI_TOOLS=(
  "qwen-code"         "gemini-cli"       "claude-code"      "mistral-vibe"
  "openclaude"        "openclaw"         "ollama"            "codex"
  "opencode"          "mimocode"         "engram"            "codegraph"
  "pi"                "antigravity-cli"  "gentle-ai"        "minimax-cli"
  "gga"               "hermes-agent"     "kimi-code"         "command-code"
  "freebuff"          "kilocode-cli"      "kiro-cli"         "heygen"            "seedance"
  "veo3"              "odysseus"         "kimchi-code"
)

for _tool in "${AI_TOOLS[@]}"; do
  source "$(dirname "$BASH_SOURCE")/$_tool/install.sh"
done
unset _tool

_batch_ai() {
  local action="$1"
  local action_past="$2"
  local count_var="$3"
  local count=0
  local failed=0
  local total=${#AI_TOOLS[@]}
  local current=0
  local func_name

  progress_start "$total" "${action_past}ing AI tools..."

  for tool in "${AI_TOOLS[@]}"; do
    func_name="${action}_${tool//-/_}"
    if declare -f "$func_name" &>/dev/null; then
      loading "${action_past^}ing ${tool}" "$func_name"
      case $? in 0) ((count++));; 1) ((failed++));; esac
    fi
    ((current++))
    progress_update "$current" "$total"
  done

  progress_done "$total"
  eval "$count_var=$count"
  return $failed
}

install_all_ai_tools() {
  _batch_ai "install" "install" "installed_count"
}

uninstall_all_ai_tools() {
  _batch_ai "uninstall" "uninstall" "uninstalled_count"
}

update_all_ai_tools() {
  _batch_ai "update" "update" "updated_count"
}

reinstall_all_ai_tools() {
  _batch_ai "reinstall" "reinstall" "reinstalled_count"
}
