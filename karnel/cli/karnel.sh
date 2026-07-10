#!/usr/bin/env bash

# Importar funciones de log y colores para el help
import "@/utils/log"
import "@/utils/colors"

karnel_main() {
  local cmd="$1"
  shift || true

  # si no se pasa comando
  if [[ -z "$cmd" ]]; then
    if [[ -t 0 ]]; then
      karnel_tui
    else
      karnel_help
    fi
    return
  fi

  # special case: --version
  if [[ "$cmd" == "--version" ]]; then
    import "@/cli/commands/version"
    version_main
    return
  fi

  # reject any command name that is not a plain identifier (path-traversal guard)
  if [[ "$cmd" != */* && "$cmd" != *".."* && "$cmd" != .* && "$cmd" =~ ^[a-zA-Z0-9_-]+$ ]]; then
    :
  else
    log_error "Command not found: $cmd"
    echo
    karnel_help
    exit 1
  fi

  local command_file="$KARNEL_PATH/cli/commands/$cmd.sh"

  # verificar si existe el comando
  if [[ -f "$command_file" ]]; then
    import "@/cli/commands/$cmd"
    "${cmd}_main" "$@"
  else
    log_error "Command not found: $cmd"
    echo
    karnel_help
    exit 1
  fi
}

karnel_help() {
  echo
  box "◈ KARNEL v${KARNEL_VERSION} ◈"
  echo
  log_info "Usage: karnel <command> [options]"
  echo
  separator_section "Available Commands"
  echo
  printf "    ${D_CYAN}%-12s${NC} %s\n" "--version" "Show current version"
  printf "    ${D_CYAN}%-12s${NC} %s\n" "brain" "Second brain — save and search memories"
  printf "    ${D_CYAN}%-12s${NC} %s\n" "cleanup" "Clean caches, logs, and temp files"
  printf "    ${D_CYAN}%-12s${NC} %s\n" "env" "Manage environment variables"
  printf "    ${D_CYAN}%-12s${NC} %s\n" "install" "Install modules and packages"
  printf "    ${D_CYAN}%-12s${NC} %s\n" "show" "Show tool documentation"
  printf "    ${D_CYAN}%-12s${NC} %s\n" "update" "Update modules or framework"
  printf "    ${D_CYAN}%-12s${NC} %s\n" "uninstall" "Remove installed modules"
  printf "    ${D_CYAN}%-12s${NC} %s\n" "reinstall" "Uninstall + install modules"
  printf "    ${D_CYAN}%-12s${NC} %s\n" "open" "Open documentation in browser"
  printf "    ${D_CYAN}%-12s${NC} %s\n" "list" "List available tools in modules"
  printf "    ${D_CYAN}%-12s${NC} %s\n" "pg" "PostgreSQL database manager"
  printf "    ${D_CYAN}%-12s${NC} %s\n" "status" "Quick system overview"
  printf "    ${D_CYAN}%-12s${NC} %s\n" "doctor" "Diagnose and fix environment"
  printf "    ${D_CYAN}%-12s${NC} %s\n" "doctor --quick" "Quick diagnostics (skip slow checks)"
  printf "    ${D_CYAN}%-12s${NC} %s\n" "cleanup" "Clean caches, logs, and temp files"
  printf "    ${D_CYAN}%-12s${NC} %s\n" "upgrade" "Upgrade Karnel framework"
  printf "    ${D_CYAN}%-12s${NC} %s\n" "init" "Configure existing projects"
  printf "    ${D_CYAN}%-12s${NC} %s\n" "start" "Start services (editor, etc.)"
  printf "    ${D_CYAN}%-12s${NC} %s\n" "voice" "Speech-to-agent via microphone"
  printf "    ${D_CYAN}%-12s${NC} %s\n" "ia" "AI agent manager — sessions, install, routes"
  echo
  separator_section "Quick Start"
  echo
  list_item "Run: ${D_CYAN}karnel${NC} to see available commands"
  list_item "Run: ${D_CYAN}karnel open${NC} for official documentation"
  list_item "Run: ${D_CYAN}karnel install <module>${NC} to install modules"
  echo
  separator_section "Module Targets"
  echo
  log_info "Install, update, reinstall, uninstall, list, show or open:"
  echo
  printf "    ${D_GREEN}%-10s${NC} %s\n" "lang" "Node, Python, Perl, PHP, Rust, C/C++, Go"
  printf "    ${D_GREEN}%-10s${NC} %s\n" "db" "PostgreSQL, MariaDB, SQLite, MongoDB"
  printf "    ${D_GREEN}%-10s${NC} %s\n" "ai" "OpenCode, Gentle AI, Claude Code, etc."
  printf "    ${D_GREEN}%-10s${NC} %s\n" "editor" "code-server (VS Code in browser)"
  printf "    ${D_GREEN}%-10s${NC} %s\n" "dev" "GitHub CLI, wget, curl, fzf, etc."
  printf "    ${D_GREEN}%-10s${NC} %s\n" "npm" "Node.js global npm packages"
  printf "    ${D_GREEN}%-10s${NC} %s\n" "shell" "ZSH + Oh My Zsh + 10 plugins"
  printf "    ${D_GREEN}%-10s${NC} %s\n" "ui" "Font, Cursor, Extra-keys, Banner"
  printf "    ${D_GREEN}%-10s${NC} %s\n" "auto" "Automation Tools (n8n)"
  printf "    ${D_GREEN}%-10s${NC} %s\n" "deploy" "Vercel, Railway, Netlify CLIs"

  echo
  separator_section "Help"
  echo
  list_item "Run ${D_CYAN}karnel <command>${NC} for command-specific help"
  list_item "Example: ${D_CYAN}karnel pg${NC}, ${D_CYAN}karnel init${NC}"
  list_item "Docs: ${D_CYAN}karnel open${NC} — israel marques 🇧🇷 (12y)"
  echo
}

# =====================
# TUI Functions (dialog/whiptail)
# =====================

karnel_tui() {
  local TUI_BIN=""
  if command -v dialog &>/dev/null; then
    TUI_BIN="dialog"
  elif command -v whiptail &>/dev/null; then
    TUI_BIN="whiptail"
  fi

  if [[ -z "$TUI_BIN" ]] || [[ ! -t 0 ]] || [[ ! -w /dev/tty ]]; then
    karnel_fallback_tui
    return
  fi

  _tui_main_menu
}

_dialog_menu() {
  local title="$1"
  local prompt="$2"
  shift 2
  local options=("$@")
  local choice
  local menu_height=20
  local menu_width=65
  local list_height=$(( ${#options[@]} / 2 ))
  if (( list_height > 18 )); then list_height=18; fi
  if (( list_height < 6 )); then list_height=6; fi
  if [[ "$TUI_BIN" == "dialog" ]]; then
    choice=$(dialog --clear --backtitle "Karnel v$KARNEL_VERSION" --title "$title" --menu "$prompt" $menu_height $menu_width $list_height "${options[@]}" 2>&1 >/dev/tty)
  else
    choice=$(whiptail --backtitle "Karnel v$KARNEL_VERSION" --title "$title" --menu "$prompt" $menu_height $menu_width $list_height "${options[@]}" 2>&1 >/dev/tty)
  fi
  local exit_status=$?
  echo "$choice"
  return $exit_status
}

_dialog_checklist() {
  local title="$1"
  local prompt="$2"
  shift 2
  local options=("$@")
  local selections
  local list_height=$(( ${#options[@]} / 3 ))
  if (( list_height > 18 )); then list_height=18; fi
  if (( list_height < 6 )); then list_height=6; fi
  if [[ "$TUI_BIN" == "dialog" ]]; then
    selections=$(dialog --clear --backtitle "Karnel v$KARNEL_VERSION" --title "$title" --checklist "$prompt" 24 70 $list_height "${options[@]}" 2>&1 >/dev/tty)
  else
    selections=$(whiptail --backtitle "Karnel v$KARNEL_VERSION" --title "$title" --checklist "$prompt" 24 70 $list_height "${options[@]}" 2>&1 >/dev/tty)
  fi
  local exit_status=$?
  echo "$selections"
  return $exit_status
}

_dialog_input() {
  local title="$1"
  local prompt="$2"
  local init_val="$3"
  local text
  if [[ "$TUI_BIN" == "dialog" ]]; then
    text=$(dialog --clear --backtitle "Karnel v$KARNEL_VERSION" --title "$title" --inputbox "$prompt" 10 60 "$init_val" 2>&1 >/dev/tty)
  else
    text=$(whiptail --backtitle "Karnel v$KARNEL_VERSION" --title "$title" --inputbox "$prompt" 10 60 "$init_val" 2>&1 >/dev/tty)
  fi
  local exit_status=$?
  echo "$text"
  return $exit_status
}

_dialog_yesno() {
  local title="$1"
  local prompt="$2"
  if [[ "$TUI_BIN" == "dialog" ]]; then
    dialog --clear --backtitle "Karnel v$KARNEL_VERSION" --title "$title" --yesno "$prompt" 10 60 2>&1 >/dev/tty
  else
    whiptail --backtitle "Karnel v$KARNEL_VERSION" --title "$title" --yesno "$prompt" 10 60 2>&1 >/dev/tty
  fi
  return $?
}

_tui_main_menu() {
  while true; do
    local choice
    choice=$(_dialog_menu "Main Menu" "Select an action to perform:" \
      "brain" "Second Brain Manager" \
      "env" "Environment Variables Manager" \
      "install" "Install Packages/Modules" \
      "pg" "PostgreSQL Database Manager" \
      "init" "Project Initializer" \
      "voice" "Speech-to-Agent" \
      "ia" "AI Agent Manager" \
      "doctor" "Run Diagnostics" \
      "cleanup" "Clean caches and temp files" \
      "status" "Quick System Overview" \
      "upgrade" "Upgrade Karnel Framework" \
      "update" "Update Karnel" \
      "help" "Show Help Documentation" \
      "exit" "Exit")
    
    local exit_status=$?
    if [[ $exit_status -ne 0 ]] || [[ "$choice" == "exit" ]] || [[ -z "$choice" ]]; then
      clear
      source "$KARNEL_PATH/utils/banner.sh"
      break
    fi

    case "$choice" in
      brain) _tui_brain_menu ;;
      env) _tui_env_menu ;;
      install) _tui_install_menu ;;
      pg) _tui_pg_menu ;;
      init) _tui_init_menu ;;
      voice)
        clear
        karnel_main "voice"
        echo
        read -p "Press Enter to return to menu..." temp
        ;;
      ia)
        clear
        karnel_main "ia"
        echo
        read -p "Press Enter to return to menu..." temp
        ;;
      doctor)
        clear
        karnel_main "doctor"
        echo
        read -p "Press Enter to return to menu..." temp
        ;;
      cleanup)
        clear
        karnel_main "cleanup"
        echo
        read -p "Press Enter to return to menu..." temp
        ;;
      status)
        clear
        karnel_main "status"
        echo
        read -p "Press Enter to return to menu..." temp
        ;;
      upgrade)
        clear
        karnel_main "upgrade"
        echo
        read -p "Press Enter to return to menu..." temp
        ;;
      update)
        clear
        karnel_main "update"
        echo
        read -p "Press Enter to return to menu..." temp
        ;;
      help)
        clear
        karnel_help
        echo
        read -p "Press Enter to return to menu..." temp
        ;;
    esac
  done
}

_tui_brain_menu() {
  while true; do
    local sub_choice
    sub_choice=$(_dialog_menu "Second Brain Manager" "Select a brain operation:" \
      "ask" "Ask a question (AI integrated)" \
      "save" "Save a new memory" \
      "search" "Search existing memories" \
      "list" "List all memories" \
      "init" "Initialize Brain" \
      "graph" "View memory graph" \
      "sync" "Sync memories" \
      "reset" "Reset / Destroy Brain" \
      "back" "Back to Main Menu")
      
    local exit_status=$?
    if [[ $exit_status -ne 0 ]] || [[ "$sub_choice" == "back" ]] || [[ -z "$sub_choice" ]]; then
      break
    fi
    
    case "$sub_choice" in
      ask)
        local question
        question=$(_dialog_input "Brain Ask" "Enter your question for the brain:")
        if [[ $? -eq 0 ]] && [[ -n "$question" ]]; then
          clear
          karnel_main "brain" "ask" "$question"
          echo
          read -p "Press Enter to return..." temp
        fi
        ;;
      save)
        clear
        karnel_main "brain" "save"
        echo
        read -p "Press Enter to return..." temp
        ;;
      search)
        local query
        query=$(_dialog_input "Search Memories" "Enter search query:")
        if [[ $? -eq 0 ]] && [[ -n "$query" ]]; then
          clear
          karnel_main "brain" "search" "$query"
          echo
          read -p "Press Enter to return..." temp
        fi
        ;;
      list)
        clear
        karnel_main "brain" "list"
        echo
        read -p "Press Enter to return..." temp
        ;;
      init)
        clear
        karnel_main "brain" "init"
        echo
        read -p "Press Enter to return..." temp
        ;;
      graph)
        clear
        karnel_main "brain" "graph"
        echo
        read -p "Press Enter to return..." temp
        ;;
      sync)
        clear
        karnel_main "brain" "sync"
        echo
        read -p "Press Enter to return..." temp
        ;;
      reset)
        if _dialog_yesno "Reset Brain" "WARNING: This will delete ALL stored memories. Are you sure?"; then
          clear
          karnel_main "brain" "reset"
          echo
          read -p "Press Enter to return..." temp
        fi
        ;;
    esac
  done
}

_tui_env_menu() {
  while true; do
    local sub_choice
    sub_choice=$(_dialog_menu "Environment Variables Manager" "Select an operation:" \
      "set" "Set/Update a variable" \
      "unset" "Remove a variable" \
      "list" "List all user variables" \
      "back" "Back to Main Menu")
      
    local exit_status=$?
    if [[ $exit_status -ne 0 ]] || [[ "$sub_choice" == "back" ]] || [[ -z "$sub_choice" ]]; then
      break
    fi
    
    case "$sub_choice" in
      set)
        clear
        karnel_main "env" "set"
        echo
        read -p "Press Enter to return..." temp
        ;;
      unset)
        clear
        karnel_main "env" "unset"
        echo
        read -p "Press Enter to return..." temp
        ;;
      list)
        clear
        karnel_main "env" "ls"
        echo
        read -p "Press Enter to return..." temp
        ;;
    esac
  done
}

_tui_install_menu() {
  while true; do
    local target
    target=$(_dialog_menu "Install Modules" "Select target module to install:" \
      "ai" "AI Tools (OpenCode, Claude, Ollama, etc.)" \
      "db" "Databases (PostgreSQL, MariaDB, SQLite, MongoDB)" \
      "lang" "Programming Languages (Node, Python, Go, Rust, etc.)" \
      "editor" "Code Editor (code-server)" \
      "dev" "Development Tools (GitHub CLI, fzf, bat, etc.)" \
      "npm" "Node.js Global npm Packages" \
      "shell" "ZSH + Oh My Zsh + Plugins" \
      "ui" "Termux UI (font, cursor, extra-keys, banner)" \
      "auto" "Automation Tools (n8n)" \
      "back" "Back to Main Menu")
      
    local exit_status=$?
    if [[ $exit_status -ne 0 ]] || [[ "$target" == "back" ]] || [[ -z "$target" ]]; then
      break
    fi
    
    case "$target" in
      ai|db|lang|dev|shell|ui)
        _tui_install_checklist "$target"
        ;;
      *)
        if _dialog_yesno "Install Module" "Do you want to install module '$target' completely?"; then
          clear
          karnel_main "install" "$target"
          echo
          read -p "Press Enter to return..." temp
        fi
        ;;
    esac
  done
}

_tui_install_checklist() {
  local target="$1"
  local -a opts=()
  
  case "$target" in
    lang)
      opts=(
        "nodejs" "Node.js LTS" OFF
        "python" "Python" OFF
        "perl" "Perl" OFF
        "php" "PHP" OFF
        "rust" "Rust" OFF
        "clang" "C/C++ (clang)" OFF
        "golang" "Go (golang)" OFF
      )
      ;;
    db)
      opts=(
        "postgresql" "PostgreSQL" OFF
        "mariadb" "MariaDB" OFF
        "sqlite" "SQLite" OFF
        "mongodb" "MongoDB" OFF
      )
      ;;
    ai)
      opts=(
        "qwen-code" "Qwen Code" OFF
        "gemini-cli" "Gemini CLI" OFF
        "claude-code" "Claude Code" OFF
        "mistral-vibe" "Mistral Vibe" OFF
        "openclaude" "OpenClaude" OFF
        "openclaw" "OpenClaw" OFF
        "ollama" "Ollama" OFF
        "codex" "Codex CLI" OFF
        "opencode" "OpenCode" OFF
        "mimocode" "MiMo Code" OFF
        "engram" "Engram" OFF
        "codegraph" "CodeGraph" OFF
        "pi" "Pi" OFF
        "antigravity-cli" "Antigravity CLI" OFF
        "gentle-ai" "Gentle AI" OFF
        "minimax-cli" "Minimax CLI" OFF
        "gga" "GGA" OFF
        "hermes-agent" "Hermes Agent" OFF
        "kimi-code" "Kimi Code" OFF
        "command-code" "Command Code" OFF
        "freebuff" "Freebuff" OFF
        "crush" "Crush CLI" OFF
        "odysseus" "Odysseus" OFF
        "kilocode-cli" "Kilo Code CLI" OFF
        "kiro" "Kiro CLI" OFF
        "cline" "Cline CLI" OFF
        "kimchi-code" "Kimchi CLI" OFF
        "karnel-route" "karnelRoute" OFF
        "ctx7" "Context7 Docs" OFF
        "openspec" "OpenSpec SDD" OFF
      )
      ;;
    dev)
      opts=(
        "gh" "GitHub CLI" OFF
        "wget" "Wget" OFF
        "curl" "Curl" OFF
        "fzf" "Fzf" OFF
        "jq" "Jq" OFF
        "lsd" "LSD (modern ls)" OFF
        "bat" "Bat (modern cat)" OFF
        "proot" "Proot" OFF
        "ncurses" "Ncurses Utils" OFF
        "tmate" "Tmate" OFF
        "cloudflared" "Cloudflared" OFF
        "translate" "Translate Shell" OFF
        "html2text" "html2text" OFF
        "bc" "Bc (calculator)" OFF
        "tree" "Tree" OFF
        "imagemagick" "ImageMagick" OFF
        "shfmt" "Shfmt" OFF
        "make" "Make" OFF
        "udocker" "Udocker" OFF
      )
      ;;
    shell)
      opts=(
        "zsh" "ZSH shell" OFF
        "ohmyzsh" "Oh My Zsh" OFF
        "theme" "Powerlevel10k theme" OFF
        "plugins" "Plugins (autosuggest, etc.)" OFF
      )
      ;;
    ui)
      opts=(
        "font" "Meslo Nerd Font" OFF
        "cursor" "Green cursor" OFF
        "extra-keys" "Custom Termux keys" OFF
        "banner" "Startup banner" OFF
      )
      ;;
  esac
  
  local selections
  selections=$(_dialog_checklist "Install $target Tools" "Select tools to install (Space to select):" "${opts[@]}")
  local exit_status=$?
  
  if [[ $exit_status -eq 0 ]] && [[ -n "$selections" ]]; then
    local -a clean_selections=()
    for item in $selections; do
      local cleaned="${item//\"/}"
      cleaned="${cleaned//\'/}"
      if [[ -n "$cleaned" ]]; then
        clean_selections+=("--$cleaned")
      fi
    done
    
    if [[ ${#clean_selections[@]} -gt 0 ]]; then
      clear
      log_info "Running: karnel install $target ${clean_selections[*]}"
      karnel_main "install" "$target" "${clean_selections[@]}"
      echo
      read -p "Press Enter to return..." temp
    fi
  fi
}

_tui_pg_menu() {
  while true; do
    local sub_choice
    sub_choice=$(_dialog_menu "PostgreSQL Database Manager" "Select a pg operation:" \
      "status" "Check server status" \
      "start" "Start PostgreSQL server" \
      "stop" "Stop PostgreSQL server" \
      "restart" "Restart PostgreSQL server" \
      "init" "Initialize PostgreSQL database" \
      "list" "List all databases" \
      "create" "Create a new database" \
      "drop" "Drop a database" \
      "backup" "Backup a database" \
      "restore" "Restore a database from backup" \
      "shell" "Open psql shell" \
      "back" "Back to Main Menu")
      
    local exit_status=$?
    if [[ $exit_status -ne 0 ]] || [[ "$sub_choice" == "back" ]] || [[ -z "$sub_choice" ]]; then
      break
    fi
    
    case "$sub_choice" in
      status|start|stop|restart|init|list)
        clear
        karnel_main "pg" "$sub_choice"
        echo
        read -p "Press Enter to return..." temp
        ;;
      create)
        local db_name
        db_name=$(_dialog_input "Create Database" "Enter new database name:")
        if [[ $? -eq 0 ]] && [[ -n "$db_name" ]]; then
          clear
          karnel_main "pg" "create" "$db_name"
          echo
          read -p "Press Enter to return..." temp
        fi
        ;;
      drop)
        local db_name
        db_name=$(_dialog_input "Drop Database" "Enter database name to drop:")
        if [[ $? -eq 0 ]] && [[ -n "$db_name" ]]; then
          if _dialog_yesno "Drop Database" "WARNING: This will permanently delete database '$db_name'. Are you sure?"; then
            clear
            karnel_main "pg" "drop" "$db_name"
            echo
            read -p "Press Enter to return..." temp
          fi
        fi
        ;;
      backup)
        local db_name
        db_name=$(_dialog_input "Backup Database" "Enter database name to backup (leave empty for interactive):")
        if [[ $? -eq 0 ]]; then
          clear
          karnel_main "pg" "backup" "$db_name"
          echo
          read -p "Press Enter to return..." temp
        fi
        ;;
      restore)
        clear
        karnel_main "pg" "restore"
        echo
        read -p "Press Enter to return..." temp
        ;;
      shell)
        clear
        karnel_main "pg" "shell"
        echo
        read -p "Press Enter to return..." temp
        ;;
    esac
  done
}

_tui_init_menu() {
  while true; do
    local sub_choice
    sub_choice=$(_dialog_menu "Project Initializer" "Select a template to configure current directory:" \
      "next" "Next.js Project (Node.js)" \
      "react" "React + Vite Project (Node.js)" \
      "nest" "NestJS Project (Node.js)" \
      "express" "Express.js API (Node.js)" \
      "python" "Python FastAPI Project" \
      "go" "Go Gin/Fiber Project" \
      "rust" "Rust Axum/Actix Web Project" \
      "back" "Back to Main Menu")
      
    local exit_status=$?
    if [[ $exit_status -ne 0 ]] || [[ "$sub_choice" == "back" ]] || [[ -z "$sub_choice" ]]; then
      break
    fi
    
    clear
    karnel_main "init" "$sub_choice"
    echo
    read -p "Press Enter to return..." temp
  done
}

karnel_fallback_tui() {
  clear
  source "$KARNEL_PATH/utils/banner.sh"
  while true; do
    echo
    box "◈ KARNEL TUI MENU ◈"
    echo
    log_info "Select an option to run:"
    echo
    printf "    ${D_GREEN}%2d.${D_NC} %s\n" 1 "Second Brain Manager (brain)"
    printf "    ${D_GREEN}%2d.${D_NC} %s\n" 2 "Environment Variables Manager (env)"
    printf "    ${D_GREEN}%2d.${D_NC} %s\n" 3 "Install Packages/Modules (install)"
    printf "    ${D_GREEN}%2d.${D_NC} %s\n" 4 "PostgreSQL Database Manager (pg)"
    printf "    ${D_GREEN}%2d.${D_NC} %s\n" 5 "Project Initializer (init)"
    printf "    ${D_GREEN}%2d.${D_NC} %s\n" 6 "Speech-to-Agent (voice)"
    printf "    ${D_GREEN}%2d.${D_NC} %s\n" 7 "AI Agent Manager (ia)"
    printf "    ${D_GREEN}%2d.${D_NC} %s\n" 8 "Run Diagnostics (doctor)"
    printf "    ${D_GREEN}%2d.${D_NC} %s\n" 9 "Update Karnel (update)"
    printf "    ${D_GREEN}%2d.${D_NC} %s\n" 10 "Help & Documentation (help)"
    printf "    ${D_GREEN}%2d.${D_NC} %s\n" 11 "Exit"
    echo
    
    local choice
    read -p "  Enter choice (1-11): " choice
    
    case "$choice" in
      1) karnel_main "brain" ;;
      2) karnel_main "env" ;;
      3) karnel_main "install" ;;
      4) karnel_main "pg" ;;
      5) karnel_main "init" ;;
      6) karnel_main "voice" ;;
      7) karnel_main "ia" ;;
      8) karnel_main "doctor" ;;
      9) karnel_main "update" ;;
      10) karnel_help ;;
      11|q|exit) break ;;
      *) log_warn "Invalid option. Please try again." ;;
    esac
    echo
    read -p "  Press Enter to return to menu..." temp
    clear
    source "$KARNEL_PATH/utils/banner.sh"
  done
}
