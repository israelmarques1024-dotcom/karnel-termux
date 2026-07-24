#!/usr/bin/env bash

import "@/utils/log"
import "@/utils/colors"
import "@/utils/tools"

update_main() {

  if [[ $# -eq 0 ]]; then
    echo
    box "Karnel Update"
    echo
    log_info "Usage: karnel update <target>"
    log_info "Usage: karnel update <target> --tool1 --tool2"
    echo
    log_info "Available targets:"
    echo
    list_item "karnel     - Update only Karnel-Termux framework"
    list_item "lang       - Update language packages (pkg upgrade)"
    list_item "db         - Update databases"
    list_item "ai         - Update AI tools (npm/pip/pkg)"
    list_item "editor     - Update Neovim configuration"
    list_item "dev        - Update development tools"
    list_item "npm        - Update Node.js global modules"
    list_item "shell      - Update ZSH plugins"
    list_item "ui         - Update Termux UI"
    list_item "auto       - Update Automation Tools"
    list_item "network    - Update network tools"
    list_item "utils      - Update utility scripts"
    list_item "games      - Update games"
    list_item "deploy     - Update deploy CLIs"
    list_item "voice      - Update voice command"
    list_item "osint      - Update OSINT tools"
    list_item "security   - Update security tools"
    list_item "plugin     - Update plugins"
    echo
    log_info "Update specific tools with flags:"
    echo
    list_item "karnel update ai --qwen-code --ollama"
    list_item "karnel update db --postgresql --sqlite"
    list_item "Run ${D_CYAN}karnel list <target>${NC} to see all available tools"
    echo
    return
  fi

  # Separate module target from tool flags
  local module_target=""
  local -a tool_flags=()
  local -a invalid_args=()

  for arg in "$@"; do
    if [[ "$arg" == --* ]]; then
      local flag="${arg#--}"
      tool_flags+=("$flag")
    elif [[ -z "$module_target" ]]; then
      module_target="$arg"
    else
      invalid_args+=("$arg")
    fi
  done

  # If there are invalid arguments, show error and abort
  if [[ ${#invalid_args[@]} -gt 0 ]]; then
    log_error "Invalid arguments: ${invalid_args[*]}"
    echo
    log_info "To update specific tools, use -- before the name:"
    log_info "  ${D_CYAN}karnel update $module_target --${invalid_args[0]}${NC}"
    echo
    return 1
  fi

  # If no module target specified, show error
  if [[ -z "$module_target" ]]; then
    log_error "No target specified"
    echo "Run 'karnel update' to see available targets"
    return 1
  fi

  # If no tool flags, update entire module (original behavior)
  if [[ ${#tool_flags[@]} -eq 0 ]]; then
    _update_full_module "$module_target"
  else
    # Update specific tools
    _update_specific_tools "$module_target" "${tool_flags[@]}"
  fi
}

# Update entire module (original behavior)
_update_full_module() {
  local target="$1"

  case "$target" in
  core|karnel)
    update_karnel
    ;;
  lang)
    import "@/modules/lang"
    update_lang
    ;;
  db)
    import "@/modules/db"
    update_db
    ;;
  ai)
    import "@/modules/ai"
    update_ai
    ;;
  editor)
    import "@/modules/editor"
    update_editor
    ;;
  dev)
    import "@/modules/dev"
    update_dev
    ;;
  npm)
    import "@/modules/npm"
    update_npm
    ;;
  shell)
    import "@/modules/shell"
    update_shell
    ;;
  ui)
    import "@/modules/ui"
    update_ui
    ;;
  auto)
    import "@/modules/auto"
    update_auto
    ;;
  games)
    import "@/tools/games/all"
    update_all_games
    ;;
  osint)
    import "@/modules/osint"
    update_osint
    ;;
  network)
    import "@/modules/network"
    update_network
    ;;
  utils)
    import "@/modules/utils"
    update_utils
    ;;
  plugin)
    import "@/modules/plugin"
    update_plugin_module
    ;;
  security)
    import "@/modules/security"
    update_security
    ;;
  deploy)
    import "@/modules/deploy"
    update_deploy
    ;;
  voice)
    import "@/modules/voice"
    update_voice
    ;;
  *)
    log_warn "Unknown update target: $target"
    echo "Run 'karnel update' to see available targets"
    ;;
  esac
}

# Update specific tools within a module
_update_specific_tools() {
  local module="$1"
  shift
  if [[ "$module" == "osint" ]]; then
    import "@/tools/osint/robin/common"
    _robin_print_disclaimer
  fi
  _batch_tool_action "$module" "update" "$@"
}

# Actualizar Karnel-Termux
update_karnel() {
  separator
  box "◈ UPDATING KARNEL-TERMUX ◈"
  separator
  echo

  # Tries every method in order until one succeeds
  _update_try_git && { _update_cleanup; return 0; }
  _update_try_npm && { _update_cleanup; return 0; }
  _update_try_npm_install && { _update_cleanup; return 0; }
  _update_try_pnpm && { _update_cleanup; return 0; }
  _update_try_curl && { _update_cleanup; return 0; }

  log_error "All update methods failed"
  _update_show_manual

  echo
}

_update_cleanup() {
  rm -f "$KARNEL_CACHE/new_version" "$KARNEL_CACHE/last_version_check"
}

_update_try_git() {
  [[ -d "$KARNEL_PATH/../.git" ]] || return 1
  loading "Updating via git" _update_karnel_repo
  local rc=$?
  echo
  if [[ $rc -eq 0 ]]; then
    log_success "Karnel-Termux updated via git"
    source "$KARNEL_PATH/utils/env.sh" 2>/dev/null
    local new_ver="$KARNEL_VERSION"
    log_success "Version: v$new_ver"
    return 0
  elif [[ $rc -eq 2 ]]; then
    log_success "Karnel-Termux is already up to date"
    return 0
  fi
  log_error "Git update failed"
  return 1
}

_update_try_npm() {
  command -v npm &>/dev/null || return 1
  log_info "Trying npm update..."
  if npm update -g karnel-termux --ignore-scripts 2>/dev/null; then
    local new_ver
    new_ver=$(npm list -g karnel-termux 2>/dev/null | grep karnel-termux | grep -oP '@\K[0-9.]+' || echo "latest")
    log_success "Updated to v$new_ver via npm"
    return 0
  fi
  log_info "npm update not available, trying npm install..."
  return 1
}

_update_try_npm_install() {
  command -v npm &>/dev/null || return 1
  log_info "Trying npm install..."
  if npm install -g karnel-termux@latest --ignore-scripts 2>/dev/null; then
    local new_ver
    new_ver=$(npm list -g karnel-termux 2>/dev/null | grep karnel-termux | grep -oP '@\K[0-9.]+' || echo "latest")
    log_success "Updated to v$new_ver via npm install"
    return 0
  fi
  return 1
}

_update_try_pnpm() {
  command -v pnpm &>/dev/null || return 1
  log_info "Trying pnpm..."
  if pnpm add -g karnel-termux@latest 2>/dev/null; then
    log_success "Updated via pnpm"
    return 0
  fi
  return 1
}

_update_try_curl() {
  command -v curl &>/dev/null || return 1
  log_info "Trying curl reinstall..."
  local tmp_install
  tmp_install=$(mktemp)
  if curl -fsSL "https://raw.githubusercontent.com/israelmarques1024-dotcom/karnel-termux/main/install.sh" -o "$tmp_install" 2>/dev/null; then
    bash "$tmp_install" 2>/dev/null && { rm -f "$tmp_install"; log_success "Updated via curl"; return 0; }
  fi
  rm -f "$tmp_install"
  return 1
}

_update_show_manual() {
  log_info "Update manually with one of these:"
  echo
  echo "  npm install -g karnel-termux@latest"
  echo "  pnpm add -g karnel-termux@latest"
  echo "  bash -c \"\$(curl -fsSL https://raw.githubusercontent.com/israelmarques1024-dotcom/karnel-termux/main/install.sh)\""
  echo
}

_update_karnel_repo() {
  local repo_dir="$KARNEL_PATH/.."
  local old_head

  old_head=$(git -C "$repo_dir" rev-parse HEAD 2>/dev/null)

  if ! git -C "$repo_dir" pull --ff-only &>/dev/null; then
    return 1
  fi

  if [[ "$(git -C "$repo_dir" rev-parse HEAD 2>/dev/null)" == "$old_head" ]]; then
    return 2
  fi

  git -C "$repo_dir" log --oneline --no-decorate "$old_head..HEAD" 2>/dev/null | while IFS= read -r line; do
    printf "    ${CYAN}▸${NC} %s\n" "$line"
  done

  return 0
}
