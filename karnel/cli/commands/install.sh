#!/usr/bin/env bash

import "@/utils/log"
import "@/utils/colors"

# Generic tool installer helper
_install_tool() {
  local tool_name="$1"
  local install_func="$2"
  local display_name="${3:-$tool_name}"

  if command -v "$tool_name" &>/dev/null; then
    log_info "$display_name is already installed"
    return 2
  fi

  $install_func
  return $?
}

# Generic module installer with progress tracking
_install_tools_in_module() {
  local module="$1"
  local action="${2:-install}"
  shift 2
  local -a tools=("$@")

  local success_count=0
  local failed_count=0
  local total=${#tools[@]}
  local current=0

  progress_start "$total" "${action^}ing tools..."

  for tool in "${tools[@]}"; do
    ((current++))

    local func_name="${action}_${tool//-/_}"
    loading "${action^}ing ${tool}" "$func_name"
    case $? in
      0|2) ((success_count++)) ;;
      1) ((failed_count++)) ;;
    esac

    progress_update "$current" "$total"
  done

  progress_done "$total"
  if [[ $success_count -gt 0 ]]; then
    log_success "$success_count tool(s) ${action}ed"
  fi
  if [[ $failed_count -gt 0 ]]; then
    log_warn "$failed_count tool(s) failed to ${action}"
  fi
  echo

  return 0
}

install_main() {

  if [[ $# -eq 0 ]]; then
    echo
    box "Karnel Install"
    echo
    log_info "Usage: karnel install <target>"
    log_info "Usage: karnel install <target> --tool1 --tool2"
    echo
    log_info "Available targets:"
    echo
    list_item "lang       - Language packages (Node.js, Python, Perl, PHP, Rust, C, C++, Go)"
    list_item "db         - Databases (PostgreSQL, MariaDB, SQLite, MongoDB, Redis)"
    list_item "ai         - AI tools (OpenCode, Gentle AI, Claude Code, etc.)"
    list_item "editor     - Code editor (code-server, neovim, nvchad)"
    list_item "dev        - Development tools"
    list_item "npm        - Node.js global modules (npm packages)"
    list_item "shell      - ZSH + Oh My Zsh + plugins"
    list_item "ui         - Termux UI (font, cursor, extra-keys, banner)"
    list_item "auto       - Automation Tools (n8n)"
    list_item "deploy     - Deploy CLIs (Vercel, Railway, Netlify)"

    echo
    log_info "Install specific tools with flags:"
    echo
    list_item "karnel install ai --qwen-code --ollama"
    list_item "karnel install db --postgresql --sqlite"
    list_item "karnel install dev --gh --fzf --jq"
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
      # Remove -- prefix
      local flag="${arg#--}"
      tool_flags+=("$flag")
    elif [[ -z "$module_target" ]]; then
      module_target="$arg"
    else
      # Extra argument without -- is invalid
      invalid_args+=("$arg")
    fi
  done

  # If there are invalid arguments, show error and abort
  if [[ ${#invalid_args[@]} -gt 0 ]]; then
    log_error "Invalid arguments: ${invalid_args[*]}"
    echo
    log_info "To install specific tools, use -- before the name:"
    log_info "  ${D_CYAN}karnel install $module_target --${invalid_args[0]}${NC}"
    echo
    log_info "Correct example: ${D_CYAN}karnel install ai --opencode --ollama${NC}"
    return 1
  fi

  # If no module target specified, show error
  if [[ -z "$module_target" ]]; then
    log_error "No target specified"
    echo "Run 'karnel install' to see available targets"
    return 1
  fi

  # If no tool flags, install entire module (original behavior)
  if [[ ${#tool_flags[@]} -eq 0 ]]; then
    _install_full_module "$module_target"
  else
    # Install specific tools
    _install_specific_tools "$module_target" "${tool_flags[@]}"
  fi
}

# Install entire module (original behavior)
_install_full_module() {
  local target="$1"

  case "$target" in
  db)
    import "@/modules/db"
    install_db
    ;;
  ai)
    import "@/modules/ai"
    install_ai
    ;;
  editor)
    import "@/modules/editor"
    install_editor
    ;;
  lang)
    import "@/modules/lang"
    install_lang
    ;;
  dev)
    import "@/modules/dev"
    install_dev
    ;;
  npm)
    import "@/modules/npm"
    install_npm
    ;;
  shell)
    import "@/modules/shell"
    install_shell
    ;;
  ui)
    import "@/modules/ui"
    setup_ui
    ;;
  auto)
    import "@/modules/auto"
    install_auto
    ;;
  deploy)
    import "@/modules/deploy"
    install_deploy
    ;;
  voice)
    import "@/modules/voice"
    install_voice
    ;;
  *)
    log_warn "Unknown install target: $target"
    echo "Run 'karnel install' to see available targets"
    ;;
  esac
}

# Install specific tools within a module
_install_specific_tools() {
  local module="$1"
  shift
  local -a tools=("$@")

  case "$module" in
  ai)
    import "@/tools/ai/all"
    local installed_count=0
    local failed_count=0

    # These entries MUST stay in sync with AI_TOOLS_REGISTRY in karnel/tools/ai/all.sh
    # To add a new tool: 1) create install.sh 2) add to AI_TOOLS_REGISTRY 3) add case here
    # Import the registry for _validate_tool_installed
    local -A _tool_binaries=()
    local _entry _id _name _bins
    for _entry in "${AI_TOOLS_REGISTRY[@]}"; do
      IFS=':' read -r _id _name _bins <<< "$_entry"
      _tool_binaries["$_id"]="$_bins"
    done

    for tool in "${tools[@]}"; do
      local func_name="install_${tool//-/_}"
      local tool_display="${tool//-/_}"

      if declare -f "$func_name" &>/dev/null; then
        "$func_name"
        local func_rc=$?

        case $func_rc in
          0)
            # Post-install validation: command -v for binaries
            local bins="${_tool_binaries[$tool]:-$tool}"
            local found_bin=""
            local _bin
            IFS=',' read -ra _bin_list <<< "$bins"
            for _bin in "${_bin_list[@]}"; do
              if command -v "$_bin" &>/dev/null; then
                # Check if it is a stub
                local _bin_path
                _bin_path=$(command -v "$_bin")
                if [ -f "$_bin_path" ] && [ -x "$_bin_path" ]; then
                  if ! grep -qiE "offline|unreachable|not.available|stub|indisponivel|inacessivel" "$_bin_path" 2>/dev/null || [ "$(head -c 2 "$_bin_path")" != "#!" ]; then
                    found_bin="$_bin"
                    break
                  fi
                fi
              fi
            done
            if [ -n "$found_bin" ]; then
              ((installed_count++))
            else
              log_warn "$tool: binary not found in PATH after installation"
              ((failed_count++))
            fi
            ;;
          1)
            ((failed_count++))
            ;;
          2)
            # Already installed (skipped)
            ((installed_count++))
            ;;
        esac
      else
        log_warn "Function not found: $func_name"
        ((failed_count++))
      fi
    done

    echo
    if [[ $installed_count -gt 0 ]]; then
      log_success "$installed_count AI tool(s) installed"
    fi
    if [[ $failed_count -gt 0 ]]; then
      log_warn "$failed_count tool(s) failed to install"
    fi
    echo
    ;;
  db)
    import "@/tools/db/all"
    local installed_count=0
    local failed_count=0

    for tool in "${tools[@]}"; do
      case "$tool" in
      postgresql)
        install_postgresql
        case $? in 0|2) ((installed_count++));; 1) ((failed_count++));; esac
        ;;
      mariadb)
        install_mariadb
        case $? in 0|2) ((installed_count++));; 1) ((failed_count++));; esac
        ;;
      sqlite)
        install_sqlite
        case $? in 0|2) ((installed_count++));; 1) ((failed_count++));; esac
        ;;
      mongodb)
        install_mongodb
        case $? in 0|2) ((installed_count++));; 1) ((failed_count++));; esac
        ;;
      redis)
        install_redis
        case $? in 0|2) ((installed_count++));; 1) ((failed_count++));; esac
        ;;
      *)
        log_warn "Unknown database: --$tool"
        ;;
      esac
    done

    echo
    if [[ $installed_count -gt 0 ]]; then
      log_success "$installed_count database(s) installed"
    fi
    if [[ $failed_count -gt 0 ]]; then
      log_warn "$failed_count database(s) failed to install"
    fi
    echo
    ;;
  dev)
    import "@/tools/dev/all"
    local installed_count=0
    local failed_count=0

    for tool in "${tools[@]}"; do
      case "$tool" in
      gh)
        install_gh
        case $? in 0|2) ((installed_count++));; 1) ((failed_count++));; esac
        ;;
      wget)
        install_wget
        case $? in 0|2) ((installed_count++));; 1) ((failed_count++));; esac
        ;;
      curl)
        install_curl
        case $? in 0|2) ((installed_count++));; 1) ((failed_count++));; esac
        ;;
      lsd)
        install_lsd
        case $? in 0|2) ((installed_count++));; 1) ((failed_count++));; esac
        ;;
      bat)
        install_bat
        case $? in 0|2) ((installed_count++));; 1) ((failed_count++));; esac
        ;;
      proot)
        install_proot
        case $? in 0|2) ((installed_count++));; 1) ((failed_count++));; esac
        ;;
      ncurses)
        install_ncurses
        case $? in 0|2) ((installed_count++));; 1) ((failed_count++));; esac
        ;;
      tmate)
        install_tmate
        case $? in 0|2) ((installed_count++));; 1) ((failed_count++));; esac
        ;;
      cloudflared)
        install_cloudflared
        case $? in 0|2) ((installed_count++));; 1) ((failed_count++));; esac
        ;;
      translate)
        install_translate
        case $? in 0|2) ((installed_count++));; 1) ((failed_count++));; esac
        ;;
      html2text)
        install_html2text
        case $? in 0|2) ((installed_count++));; 1) ((failed_count++));; esac
        ;;
      jq)
        install_jq
        case $? in 0|2) ((installed_count++));; 1) ((failed_count++));; esac
        ;;
      bc)
        install_bc
        case $? in 0|2) ((installed_count++));; 1) ((failed_count++));; esac
        ;;
      tree)
        install_tree
        case $? in 0|2) ((installed_count++));; 1) ((failed_count++));; esac
        ;;
      fzf)
        install_fzf
        case $? in 0|2) ((installed_count++));; 1) ((failed_count++));; esac
        ;;
      imagemagick)
        install_imagemagick
        case $? in 0|2) ((installed_count++));; 1) ((failed_count++));; esac
        ;;
      shfmt)
        install_shfmt
        case $? in 0|2) ((installed_count++));; 1) ((failed_count++));; esac
        ;;
      make)
        install_make
        case $? in 0|2) ((installed_count++));; 1) ((failed_count++));; esac
        ;;
      udocker)
        install_udocker
        case $? in 0|2) ((installed_count++));; 1) ((failed_count++));; esac
        ;;
      *)
        log_warn "Unknown tool: --$tool"
        ;;
      esac
    done

    echo
    if [[ $installed_count -gt 0 ]]; then
      log_success "$installed_count tool(s) installed"
    fi
    if [[ $failed_count -gt 0 ]]; then
      log_warn "$failed_count tool(s) failed to install"
    fi
    echo
    ;;
  npm)
    import "@/tools/npm/all"
    local installed_count=0
    local failed_count=0

    for tool in "${tools[@]}"; do
      case "$tool" in
      typescript)
        install_typescript
        case $? in 0|2) ((installed_count++));; 1) ((failed_count++));; esac
        ;;
      nestjs)
        install_nestjs
        case $? in 0|2) ((installed_count++));; 1) ((failed_count++));; esac
        ;;
      prettier)
        install_prettier
        case $? in 0|2) ((installed_count++));; 1) ((failed_count++));; esac
        ;;
      live-server)
        install_live_server
        case $? in 0|2) ((installed_count++));; 1) ((failed_count++));; esac
        ;;
      localtunnel)
        install_localtunnel
        case $? in 0|2) ((installed_count++));; 1) ((failed_count++));; esac
        ;;
      vercel)
        install_vercel
        case $? in 0|2) ((installed_count++));; 1) ((failed_count++));; esac
        ;;
      markserv)
        install_markserv
        case $? in 0|2) ((installed_count++));; 1) ((failed_count++));; esac
        ;;
      psqlformat)
        install_psqlformat
        case $? in 0|2) ((installed_count++));; 1) ((failed_count++));; esac
        ;;
      ncu)
        install_ncu
        case $? in 0|2) ((installed_count++));; 1) ((failed_count++));; esac
        ;;
      ngrok)
        install_ngrok
        case $? in 0|2) ((installed_count++));; 1) ((failed_count++));; esac
        ;;
      turbopack)
        install_turbopack
        case $? in 0|2) ((installed_count++));; 1) ((failed_count++));; esac
        ;;
      *)
        log_warn "Unknown node module: --$tool"
        ;;
      esac
    done

    echo
    if [[ $installed_count -gt 0 ]]; then
      log_success "$installed_count Node.js module(s) installed"
    fi
    if [[ $failed_count -gt 0 ]]; then
      log_warn "$failed_count module(s) failed to install"
    fi
    echo
    ;;
  lang)
    import "@/tools/lang/all"
    local installed_count=0
    local failed_count=0

    for tool in "${tools[@]}"; do
      case "$tool" in
      nodejs)
        install_nodejs
        case $? in 0|2) ((installed_count++));; 1) ((failed_count++));; esac
        ;;
      python)
        install_python
        case $? in 0|2) ((installed_count++));; 1) ((failed_count++));; esac
        ;;
      perl)
        install_perl
        case $? in 0|2) ((installed_count++));; 1) ((failed_count++));; esac
        ;;
      php)
        install_php
        case $? in 0|2) ((installed_count++));; 1) ((failed_count++));; esac
        ;;
      rust)
        install_rust
        case $? in 0|2) ((installed_count++));; 1) ((failed_count++));; esac
        ;;
      clang)
        install_clang
        case $? in 0|2) ((installed_count++));; 1) ((failed_count++));; esac
        ;;
      golang)
        install_golang
        case $? in 0|2) ((installed_count++));; 1) ((failed_count++));; esac
        ;;
      *)
        log_warn "Unknown language: --$tool"
        ;;
      esac
    done

    echo
    if [[ $installed_count -gt 0 ]]; then
      log_success "$installed_count language(s) installed"
    fi
    if [[ $failed_count -gt 0 ]]; then
      log_warn "$failed_count language(s) failed to install"
    fi
    echo
    ;;
  shell)
    import "@/tools/shell/all"
    local installed_count=0
    local failed_count=0

    for tool in "${tools[@]}"; do
      case "$tool" in
      powerlevel10k)
        install_powerlevel10k
        case $? in 0|2) ((installed_count++));; 1) ((failed_count++));; esac
        ;;
      zsh-defer)
        install_zsh_defer
        case $? in 0|2) ((installed_count++));; 1) ((failed_count++));; esac
        ;;
      zsh-autosuggestions)
        install_zsh_autosuggestions
        case $? in 0|2) ((installed_count++));; 1) ((failed_count++));; esac
        ;;
      zsh-syntax-highlighting)
        install_zsh_syntax_highlighting
        case $? in 0|2) ((installed_count++));; 1) ((failed_count++));; esac
        ;;
      history-substring)
        install_history_substring
        case $? in 0|2) ((installed_count++));; 1) ((failed_count++));; esac
        ;;
      zsh-completions)
        install_zsh_completions
        case $? in 0|2) ((installed_count++));; 1) ((failed_count++));; esac
        ;;
      fzf-tab)
        install_fzf_tab
        case $? in 0|2) ((installed_count++));; 1) ((failed_count++));; esac
        ;;
      you-should-use)
        install_you_should_use
        case $? in 0|2) ((installed_count++));; 1) ((failed_count++));; esac
        ;;
      zsh-autopair)
        install_zsh_autopair
        case $? in 0|2) ((installed_count++));; 1) ((failed_count++));; esac
        ;;
      better-npm)
        install_better_npm
        case $? in 0|2) ((installed_count++));; 1) ((failed_count++));; esac
        ;;
      *)
        log_warn "Unknown plugin: --$tool"
        ;;
      esac
    done

    echo
    if [[ $installed_count -gt 0 ]]; then
      log_success "$installed_count plugin(s) installed"
    fi
    if [[ $failed_count -gt 0 ]]; then
      log_warn "$failed_count plugin(s) failed to install"
    fi
    echo
    ;;
  editor)
    import "@/tools/editor/all"
    local installed_count=0
    local failed_count=0

    for tool in "${tools[@]}"; do
      case "$tool" in
      code-server)
        install_code_server
        case $? in 0|2) ((installed_count++));; 1) ((failed_count++));; esac
        ;;
      neovim)
        install_neovim
        case $? in 0|2) ((installed_count++));; 1) ((failed_count++));; esac
        ;;
      nvchad)
        install_nvchad
        case $? in 0|2) ((installed_count++));; 1) ((failed_count++));; esac
        ;;
      *)
        log_warn "Unknown editor component: --$tool"
        ;;
      esac
    done

    echo
    if [[ $installed_count -gt 0 ]]; then
      log_success "$installed_count editor component(s) installed"
    fi
    if [[ $failed_count -gt 0 ]]; then
      log_warn "$failed_count component(s) failed to install"
    fi
    echo
    ;;
  ui)
    import "@/tools/ui/all"
    local installed_count=0
    local failed_count=0

    for tool in "${tools[@]}"; do
      case "$tool" in
      font)
        install_font
        case $? in 0|2) ((installed_count++));; 1) ((failed_count++));; esac
        ;;
      extra-keys)
        install_extra_keys
        case $? in 0|2) ((installed_count++));; 1) ((failed_count++));; esac
        ;;
      cursor)
        install_cursor
        case $? in 0|2) ((installed_count++));; 1) ((failed_count++));; esac
        ;;
      banner)
        install_banner
        case $? in 0|2) ((installed_count++));; 1) ((failed_count++));; esac
        ;;
      *)
        log_warn "Unknown UI component: --$tool"
        ;;
      esac
    done

    echo
    if [[ $installed_count -gt 0 ]]; then
      log_success "$installed_count UI component(s) installed"
    fi
    if [[ $failed_count -gt 0 ]]; then
      log_warn "$failed_count component(s) failed to install"
    fi
    echo
    ;;
  auto)
    import "@/tools/auto/all"
    local installed_count=0
    local failed_count=0

    for tool in "${tools[@]}"; do
      case "$tool" in
      n8n)
        install_n8n
        case $? in 0|2) ((installed_count++));; 1) ((failed_count++));; esac
        ;;
      *)
        log_warn "Unknown automation tool: --$tool"
        ;;
      esac
    done

    echo
    if [[ $installed_count -gt 0 ]]; then
      log_success "$installed_count automation tool(s) installed"
    fi
    if [[ $failed_count -gt 0 ]]; then
      log_warn "$failed_count tool(s) failed to install"
    fi
    echo
    ;;
  deploy)
    import "@/tools/deploy/all"
    local installed_count=0
    local failed_count=0

    for tool in "${tools[@]}"; do
      case "$tool" in
      vercel)
        install_vercel
        case $? in 0|2) ((installed_count++));; 1) ((failed_count++));; esac
        ;;
      railway)
        install_railway
        case $? in 0|2) ((installed_count++));; 1) ((failed_count++));; esac
        ;;
      netlify)
        install_netlify
        case $? in 0|2) ((installed_count++));; 1) ((failed_count++));; esac
        ;;
      *)
        log_warn "Unknown deploy tool: --$tool"
        ;;
      esac
    done

    echo
    if [[ $installed_count -gt 0 ]]; then
      log_success "$installed_count deploy CLI(s) installed"
    fi
    if [[ $failed_count -gt 0 ]]; then
      log_warn "$failed_count CLI(s) failed to install"
    fi
    echo
    ;;
  *)
    log_warn "Unknown install target: $module"
    echo "Run 'karnel install' to see available targets"
    ;;
  esac
}
