#!/usr/bin/env bash

# Importar funciones de log y colores para el help
import "@/utils/log"
import "@/utils/colors"

omni_main() {
  local cmd="$1"
  shift || true

  # si no se pasa comando
  if [[ -z "$cmd" ]]; then
    omni_help
    return
  fi

  local command_file="$OMNI_PATH/cli/commands/$cmd.sh"

  # verificar si existe el comando
  if [[ -f "$command_file" ]]; then
    import "@/cli/commands/$cmd"
    "${cmd}_main" "$@"
  else
    log_error "Command not found: $cmd"
    echo
    omni_help
    exit 1
  fi
}

omni_help() {
  echo
  box "◈ OMNI v${OMNI_VERSION} ◈"
  echo
  log_info "Usage: omni <command> [options]"
  echo
  separator_section "Available Commands"
  echo
  printf "    ${D_CYAN}%-12s${NC} %s\n" "--version" "Show current version"
  printf "    ${D_CYAN}%-12s${NC} %s\n" "brain" "Second brain — save and search memories"
  printf "    ${D_CYAN}%-12s${NC} %s\n" "env" "Manage environment variables"
  printf "    ${D_CYAN}%-12s${NC} %s\n" "install" "Install modules and packages"
  printf "    ${D_CYAN}%-12s${NC} %s\n" "show" "Show tool documentation"
  printf "    ${D_CYAN}%-12s${NC} %s\n" "update" "Update modules or framework"
  printf "    ${D_CYAN}%-12s${NC} %s\n" "uninstall" "Remove installed modules"
  printf "    ${D_CYAN}%-12s${NC} %s\n" "reinstall" "Uninstall + install modules"
  printf "    ${D_CYAN}%-12s${NC} %s\n" "open" "Open documentation in browser"
  printf "    ${D_CYAN}%-12s${NC} %s\n" "list" "List available tools in modules"
  printf "    ${D_CYAN}%-12s${NC} %s\n" "pg" "PostgreSQL database manager"
  printf "    ${D_CYAN}%-12s${NC} %s\n" "doctor" "Diagnose and fix environment"
  printf "    ${D_CYAN}%-12s${NC} %s\n" "init" "Configure existing projects"
  printf "    ${D_CYAN}%-12s${NC} %s\n" "voice" "Speech-to-agent via microphone"
  echo
  separator_section "Quick Start"
  echo
  list_item "Run: ${D_CYAN}omni${NC} to see available commands"
  list_item "Run: ${D_CYAN}omni open${NC} for official documentation"
  list_item "Run: ${D_CYAN}omni install <module>${NC} to install modules"
  echo
  separator_section "Module Targets"
  echo
  log_info "Install, update, reinstall, uninstall, list, show or open:"
  echo
  printf "    ${D_GREEN}%-10s${NC} %s\n" "lang" "Node, Python, Perl, PHP, Rust, C/C++, Go"
  printf "    ${D_GREEN}%-10s${NC} %s\n" "db" "PostgreSQL, MariaDB, SQLite, MongoDB"
  printf "    ${D_GREEN}%-10s${NC} %s\n" "ai" "OpenCode, Gentle AI, Claude Code, etc."
  printf "    ${D_GREEN}%-10s${NC} %s\n" "editor" "Neovim + NvChad + Plugins"
  printf "    ${D_GREEN}%-10s${NC} %s\n" "dev" "GitHub CLI, wget, curl, fzf, etc."
  printf "    ${D_GREEN}%-10s${NC} %s\n" "npm" "Node.js global npm packages"
  printf "    ${D_GREEN}%-10s${NC} %s\n" "shell" "ZSH + Oh My Zsh + 10 plugins"
  printf "    ${D_GREEN}%-10s${NC} %s\n" "ui" "Font, Cursor, Extra-keys, Banner"
  printf "    ${D_GREEN}%-10s${NC} %s\n" "auto" "Automation Tools (n8n)"
  printf "    ${D_GREEN}%-10s${NC} %s\n" "deploy" "Vercel, Railway, Netlify CLIs"

  echo
  separator_section "Help"
  echo
  list_item "Run ${D_CYAN}omni <command>${NC} for command-specific help"
  list_item "Example: ${D_CYAN}omni pg${NC}, ${D_CYAN}omni init${NC}"
  list_item "Docs: ${D_CYAN}omni open${NC} — israel marques 🇧🇷 (12y)"
  echo
}
