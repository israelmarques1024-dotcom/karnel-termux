#!/usr/bin/env bash

import "@/utils/log"
import "@/utils/colors"

doctor_main() {
  echo
  box "◈ OMNI DOCTOR ◈"
  echo
  log_info "Diagnosing your Termux and Omni environment..."
  echo

  local warnings=0
  local errors=0
  local fixed=0
  local -a fix_commands=()
  local -a fix_descriptions=()
  local -a fix_callbacks=()

  # ===== 1. SYSTEM INFO =====
  local arch
  arch=$(uname -m)

  local android_ver
  android_ver=$(getprop ro.build.version.release 2>/dev/null)
  android_ver="${android_ver:-Unknown}"

  local termux_ver=""
  if command -v termux-info &>/dev/null; then
    termux_ver=$(timeout 5 termux-info 2>/dev/null | grep -i "termux_version" | head -n1 | cut -d'=' -f2)
  fi
  if [[ -z "$termux_ver" ]]; then
    termux_ver=$(dpkg -s termux-tools 2>/dev/null | grep -i version | awk '{print $2}')
  fi
  termux_ver="${termux_ver:-Unknown}"

  log_success "Android Version: $android_ver"
  log_success "Termux Version: $termux_ver"
  log_success "CPU Architecture: $arch"

  # ===== 2. DISK SPACE & RAM =====
  echo
  separator_section "System Resources"
  echo

  local free_space
  free_space=$(df -h "$HOME" | awk 'NR==2 {print $4}')
  log_success "Available disk space: $free_space"

  local ram_total="Unknown"
  local ram_free="Unknown"
  if [[ -f /proc/meminfo ]]; then
    local total_kb free_kb
    total_kb=$(grep MemTotal /proc/meminfo | awk '{print $2}')
    ram_total="$((total_kb / 1024)) MB"
    free_kb=$(grep MemAvailable /proc/meminfo | awk '{print $2}')
    ram_free="$((free_kb / 1024)) MB"
    log_success "RAM: Total: $ram_total | Available: $ram_free"

    # Warn if low memory
    local free_mb=$((free_kb / 1024))
    if (( free_mb < 200 )); then
      log_warn "Low available memory (${ram_free}). Some tools may fail."
      ((warnings++))
    fi
  else
    log_warn "Could not read RAM details"
    ((warnings++))
  fi

  # ===== 3. STORAGE & PERMISSIONS =====
  echo
  separator_section "Storage & Permissions"
  echo

  local storage_status="Accessible"
  if ls /sdcard &>/dev/null || [ -d "$HOME/storage" ]; then
    log_success "Shared storage is accessible"
  else
    log_warn "Shared storage is not linked"
    storage_status="Not Linked"
    ((warnings++))
    fix_commands+=("termux-setup-storage")
    fix_descriptions+=("Link shared storage for file access")
    fix_callbacks+=("_fix_storage")
  fi

  if [ -w "$OMNI_PATH" ]; then
    log_success "Write permission in Omni path: $OMNI_PATH"
  else
    log_error "No write permission in Omni path!"
    ((errors++))
  fi

  local dirs=("$OMNI_CONFIG" "$OMNI_CACHE" "$OMNI_DATA")
  for dir in "${dirs[@]}"; do
    if [ -d "$dir" ] && [ -w "$dir" ]; then
      log_success "Directory OK: $(basename "$dir")"
    else
      log_warn "Directory missing or read-only: $(basename "$dir")"
      ((warnings++))
      fix_commands+=("mkdir -p \"$dir\" && chmod 755 \"$dir\"")
      fix_descriptions+=("Recreate directory: $(basename "$dir")")
      fix_callbacks+=("_fix_mkdir")
    fi
  done

  # ===== 4. LANGUAGES & CRITICAL TOOLS =====
  echo
  separator_section "Languages & Critical Tools"
  echo

  local -a critical_deps=("git" "rg" "jq" "curl" "tar" "node" "python" "rustc" "go" "clang" "make")
  for dep in "${critical_deps[@]}"; do
    if command -v "$dep" &>/dev/null; then
      local version=""
      case "$dep" in
        git) version=$(git --version | awk '{print $3}') ;;
        node) version=$(node --version) ;;
        python) version=$(python3 --version 2>/dev/null || python --version 2>/dev/null | awk '{print $2}') ;;
        rustc) version=$(rustc --version | awk '{print $2}') ;;
        go) version=$(go version | awk '{print $3}') ;;
        clang) version=$(clang --version | head -1 | awk '{print $3}') ;;
        *) version="installed" ;;
      esac
      log_success "$dep: $version"
    else
      log_warn "$dep is not installed"
      ((warnings++))
      local pkg_to_install="$dep"
      [[ "$dep" == "rg" ]] && pkg_to_install="ripgrep"
      [[ "$dep" == "rustc" ]] && pkg_to_install="rust"
      [[ "$dep" == "go" ]] && pkg_to_install="golang"
      [[ "$dep" == "python" ]] && pkg_to_install="python"
      fix_commands+=("pkg install -y $pkg_to_install")
      fix_descriptions+=("Install missing: $pkg_to_install")
      fix_callbacks+=("_fix_pkg_install")
    fi
  done

  # ===== 5. PACKAGE MANAGER HEALTH =====
  echo
  separator_section "Package Manager & System Health"
  echo

  if dpkg --audit &>/dev/null; then
    log_success "dpkg package manager is healthy"
  else
    log_error "dpkg has interrupted installations!"
    ((errors++))
    fix_commands+=("dpkg --configure -a && apt-get -f install -y")
    fix_descriptions+=("Fix broken dpkg/apt state")
    fix_callbacks+=("_fix_dpkg")
  fi

  # Check for held packages
  local held_pkgs
  held_pkgs=$(dpkg --get-selections 2>/dev/null | grep -c "hold" || true)
  if (( held_pkgs > 0 )); then
    log_warn "$held_pkgs package(s) are held back"
    ((warnings++))
  fi

  # Check apt sources
  if [[ -f "$PREFIX/etc/apt/sources.list" ]]; then
    local source_lines
    source_lines=$(wc -l < "$PREFIX/etc/apt/sources.list")
    if (( source_lines == 0 )); then
      log_error "APT sources list is empty!"
      ((errors++))
      fix_commands+=("pkg update -y")
      fix_descriptions+=("Refresh APT sources")
      fix_callbacks+=("_fix_apt_update")
    else
      log_success "APT sources configured ($source_lines entries)"
    fi
  fi

  # ===== 6. NODE.JS / NPM =====
  echo
  separator_section "Node.js & NPM"
  echo

  if command -v node &>/dev/null; then
    local node_ver
    node_ver=$(node --version)
    log_success "Node.js: $node_ver"

    if command -v npm &>/dev/null; then
      local npm_ver
      npm_ver=$(npm --version)
      log_success "NPM: $npm_ver"

      # Check npm global prefix permissions
      local npm_prefix
      npm_prefix=$(npm config get prefix 2>/dev/null)
      if [[ -n "$npm_prefix" ]] && [[ -d "$npm_prefix" ]]; then
        if [[ -w "$npm_prefix" ]]; then
          log_success "NPM global directory is writable"
        else
          log_warn "NPM global directory is not writable: $npm_prefix"
          ((warnings++))
          fix_commands+=("mkdir -p \"\$HOME/.npm-global\" && npm config set prefix \"\$HOME/.npm-global\"")
          fix_descriptions+=("Fix NPM global directory permissions")
          fix_callbacks+=("_fix_npm_prefix")
        fi
      fi

      # Check for npm cache bloat
      local npm_cache_size
      npm_cache_size=$(du -sh "$(npm config get cache 2>/dev/null)" 2>/dev/null | awk '{print $1}')
      if [[ -n "$npm_cache_size" ]]; then
        log_info "NPM cache size: $npm_cache_size"
      fi
    else
      log_warn "NPM is not installed"
      ((warnings++))
      fix_commands+=("pkg install -y nodejs-lts")
      fix_descriptions+=("Install Node.js with NPM")
      fix_callbacks+=("_fix_pkg_install")
    fi
  else
    log_warn "Node.js is not installed"
    ((warnings++))
    fix_commands+=("pkg install -y nodejs-lts")
    fix_descriptions+=("Install Node.js LTS")
    fix_callbacks+=("_fix_pkg_install")
  fi

  # ===== 7. PYTHON =====
  echo
  separator_section "Python Environment"
  echo

  local py_cmd=""
  for py in python3.12 python3.11 python3.10 python3.9 python3 python; do
    if command -v "$py" &>/dev/null; then
      py_cmd="$py"
      break
    fi
  done

  if [[ -n "$py_cmd" ]]; then
    local py_ver
    py_ver=$("$py_cmd" --version 2>&1 | awk '{print $2}')
    log_success "Python: $py_cmd ($py_ver)"

    # Check pip
    if "$py_cmd" -m pip --version &>/dev/null; then
      local pip_ver
      pip_ver=$("$py_cmd" -m pip --version | awk '{print $2}')
      log_success "Pip: $pip_ver"
    else
      log_warn "Pip is not installed for $py_cmd"
      ((warnings++))
      fix_commands+=("$py_cmd -m ensurepip && $py_cmd -m pip install --upgrade pip")
      fix_descriptions+=("Install/upgrade pip for $py_cmd")
      fix_callbacks+=("_fix_pip")
    fi

    # Check venv module
    if "$py_cmd" -m venv --help &>/dev/null; then
      log_success "Python venv module available"
    else
      log_warn "Python venv module not available"
      ((warnings++))
      local venv_pkg="python-venv"
      [[ "$py_cmd" == "python3.11" ]] && venv_pkg="python3.11-venv"
      [[ "$py_cmd" == "python3.10" ]] && venv_pkg="python3.10-venv"
      fix_commands+=("pkg install -y $venv_pkg")
      fix_descriptions+=("Install venv module for $py_cmd")
      fix_callbacks+=("_fix_pkg_install")
    fi
  else
    log_warn "Python is not installed"
    ((warnings++))
    fix_commands+=("pkg install -y python")
    fix_descriptions+=("Install Python")
    fix_callbacks+=("_fix_pkg_install")
  fi

  # ===== 8. POSTGRESQL =====
  echo
  separator_section "PostgreSQL Database"
  echo

  local pg_installed=false
  if command -v pg_ctl &>/dev/null; then
    pg_installed=true
    local pg_ver
    pg_ver=$(postgres --version 2>/dev/null | awk '{print $3}')
    log_success "PostgreSQL installed: $pg_ver"

    # Check if data directory exists
    local pg_data_found=false
    local pg_data_dirs=(
      "$PREFIX/var/lib/postgresql/data"
      "$PREFIX/var/lib/postgresql"
      "$HOME/.termux/postgresql/data"
      "$HOME/.termux/postgresql"
    )
    for dir in "${pg_data_dirs[@]}"; do
      if [[ -d "$dir" ]] && [[ -f "$dir/PG_VERSION" ]]; then
        pg_data_found=true
        log_success "Data directory found: $dir"
        break
      fi
    done

    if [[ "$pg_data_found" == "false" ]]; then
      log_warn "PostgreSQL not initialized (no data directory)"
      ((warnings++))
      fix_commands+=("omni pg init && omni pg start")
      fix_descriptions+=("Initialize and start PostgreSQL")
      fix_callbacks+=("_fix_pg_init")
    else
      # Check if running
      if pg_ctl -D "$dir" status &>/dev/null; then
        log_success "PostgreSQL: RUNNING"
      else
        log_warn "PostgreSQL: STOPPED"
        ((warnings++))
        fix_commands+=("omni pg start")
        fix_descriptions+=("Start PostgreSQL server")
        fix_callbacks+=("_fix_pg_start")
      fi
    fi
  else
    log_warn "PostgreSQL is not installed"
    ((warnings++))
    fix_commands+=("omni install db --postgresql")
    fix_descriptions+=("Install PostgreSQL")
    fix_callbacks+=("_fix_pg_install")
  fi

  # ===== 9. OMNI FRAMEWORK =====
  echo
  separator_section "Omni Framework"
  echo

  # Check Omni version
  local omni_ver="unknown"
  if [[ -n "${OMNI_VERSION:-}" ]]; then
    omni_ver="$OMNI_VERSION"
  fi
  log_success "Omni version: $omni_ver"

  # Check symlinks
  if [[ -L "$PREFIX/bin/omni" ]]; then
    log_success "CLI symlink: omni"
  else
    log_warn "CLI symlinks missing"
    ((warnings++))
    fix_commands+=("ln -sf \"$OMNI_PATH/bin/omni\" \"$PREFIX/bin/omni\"")
    fix_descriptions+=("Recreate CLI symlinks")
    fix_callbacks+=("_fix_symlinks")
  fi

  # Check if banner is installed in shell config
  local shell_config=""
  [[ -f "$HOME/.zshrc" ]] && shell_config="$HOME/.zshrc"
  [[ -f "$HOME/.bashrc" ]] && shell_config="$HOME/.bashrc"

  if [[ -n "$shell_config" ]]; then
    if grep -qF "# ===== Omni Banner =====" "$shell_config" 2>/dev/null; then
      log_success "Banner installed in $(basename "$shell_config")"
    else
      log_warn "Banner not installed in $(basename "$shell_config")"
      ((warnings++))
      fix_commands+=("omni install ui --banner")
      fix_descriptions+=("Install Omni banner in shell")
      fix_callbacks+=("_fix_banner")
    fi
  fi

  # ===== 10. AI TOOLS STATUS =====
  echo
  separator_section "AI Tools Installed"
  echo

  local -a ai_cmds=("opencode" "claude" "gemini" "codex" "qwen" "vibe" "mimo" "hermes" "kimi" "ollama" "freebuff" "pi" "agy" "mmx" "gentle-ai" "gga" "engram" "codegraph" "kilo" "heygen" "seedance" "veo3" "odysseus" "openclaude" "openclaw" "command-code" "kimchi")
  local ai_count=0

  for cmd in "${ai_cmds[@]}"; do
    if command -v "$cmd" &>/dev/null; then
      log_success "$cmd: installed"
      ((ai_count++))
    fi
  done

  if (( ai_count == 0 )); then
    log_warn "No AI tools installed"
    ((warnings++))
    fix_commands+=("omni install ai")
    fix_descriptions+=("Install all AI tools")
    fix_callbacks+=("_fix_ai_install")
  else
    log_info "$ai_count AI tool(s) installed"
  fi

  # ===== 11. SHELL CONFIGURATION =====
  echo
  separator_section "Shell Configuration"
  echo

  if [[ -f "$HOME/.zshrc" ]]; then
    log_success "ZSH config: .zshrc exists"

    # Check for syntax errors
    if zsh -n "$HOME/.zshrc" 2>/dev/null; then
      log_success ".zshrc syntax: OK"
    else
      log_error ".zshrc has syntax errors!"
      ((errors++))
      fix_commands+=("cp \"$HOME/.zshrc\" \"$HOME/.zshrc.bak\" && omni install shell")
      fix_descriptions+=("Backup and reinstall shell config")
      fix_callbacks+=("_fix_shell_syntax")
    fi
  elif [[ -f "$HOME/.bashrc" ]]; then
    log_success "Bash config: .bashrc exists"
  else
    log_warn "No shell config found"
    ((warnings++))
  fi

  # ===== 12. PHANTOM PROCESS KILLER =====
  echo
  separator_section "Android Compatibility"
  echo

  if [[ "$android_ver" =~ ^(12|13|14|15|16) ]]; then
    log_warn "Android $android_ver: Phantom Process Killer may kill Termux processes"
    log_info "Fix: Run via ADB:"
    list_item "adb shell device_config put activity_manager max_phantom_processes 2147483647"
    ((warnings++))
  else
    log_success "No phantom killer warnings apply"
  fi

  # ===== 13. TERMUX:API =====
  echo
  separator_section "Termux:API"
  echo

  if command -v termux-info &>/dev/null; then
    log_success "Termux:API is installed"
  else
    log_warn "Termux:API not installed (needed for voice commands)"
    ((warnings++))
    fix_commands+=("pkg install -y termux-api")
    fix_descriptions+=("Install Termux:API for voice features")
    fix_callbacks+=("_fix_pkg_install")
  fi

  # ===== 14. GIT CONFIGURATION =====
  echo
  separator_section "Git Configuration"
  echo

  if command -v git &>/dev/null; then
    local git_user git_email
    git_user=$(git config --global user.name 2>/dev/null)
    git_email=$(git config --global user.email 2>/dev/null)
    if [[ -n "$git_user" ]] && [[ -n "$git_email" ]]; then
      log_success "Git user: $git_user <$git_email>"
    else
      log_warn "Git user.name or user.email not configured"
      ((warnings++))
    fi
  fi

  # ===== 15. SSH KEYS =====
  echo
  separator_section "SSH Keys"
  echo

  if [[ -f "$HOME/.ssh/id_ed25519" ]] || [[ -f "$HOME/.ssh/id_rsa" ]]; then
    log_success "SSH key found"
  else
    log_warn "No SSH key found (needed for GitHub)"
    ((warnings++))
    fix_commands+=("ssh-keygen -t ed25519 -f ~/.ssh/id_ed25519 -N ''")
    fix_descriptions+=("Generate SSH key for GitHub")
    fix_callbacks+=("_fix_ssh_key")
  fi

  # ===== 16. NETWORK CONNECTIVITY =====
  echo
  separator_section "Network"
  echo

  if curl -fsSL --max-time 5 https://github.com &>/dev/null; then
    log_success "Network connectivity: OK"
  else
    log_warn "Network connectivity issue detected"
    ((warnings++))
  fi

  # ===== 17. OPENSSH =====
  if command -v sshd &>/dev/null; then
    log_success "OpenSSH server available"
  else
    log_info "OpenSSH server not installed (optional)"
  fi

  # ===== 18. DISK SPACE CHECK =====
  echo
  separator_section "Disk Health"
  echo

  local free_space_kb
  free_space_kb=$(df "$HOME" | awk 'NR==2 {print $4}')
  if [[ -n "$free_space_kb" ]]; then
    local free_mb=$((free_space_kb / 1024))
    if (( free_mb < 500 )); then
      log_warn "Low disk space: ${free_mb}MB free. Consider cleaning cache."
      ((warnings++))
      fix_commands+=("rm -rf ~/.cache/omni/install_*.log 2>/dev/null; pkg clean -y 2>/dev/null")
      fix_descriptions+=("Clean cache and unused packages")
      fix_callbacks+=("_fix_disk_cleanup")
    else
      log_success "Disk space: OK (${free_mb}MB free)"
    fi
  fi

  # ===== 19. OMNI DATA DIRS =====
  echo
  separator_section "Omni Data Integrity"
  echo

  local omni_dirs=("$OMNI_CONFIG" "$OMNI_CACHE" "$OMNI_DATA" "$HOME/.local/share/omni-data")
  for dir in "${omni_dirs[@]}"; do
    if [[ -d "$dir" ]]; then
      local size
      size=$(du -sh "$dir" 2>/dev/null | awk '{print $1}')
      log_success "$(basename "$dir"): ${size:-0}"
    else
      log_warn "Missing: $(basename "$dir")"
      ((warnings++))
      fix_commands+=("mkdir -p \"$dir\"")
      fix_descriptions+=("Create missing dir: $(basename "$dir")")
      fix_callbacks+=("_fix_mkdir_single")
    fi
  done

  # ===== 20. GENERATE REPORT =====
  local report_dir="$OMNI_DATA/doctor_reports"
  mkdir -p "$report_dir"
  local report_file="$report_dir/doctor_report_latest.md"

  cat >"$report_file" <<EOF
# Omni Doctor Diagnostic Report
Generated: $(date)

## System Info
- **Android**: $android_ver
- **Termux**: $termux_ver
- **Architecture**: $arch
- **Omni Version**: $omni_ver

## Resources
- **Disk Free**: $free_space
- **RAM Total**: $ram_total
- **RAM Free**: $ram_free

## Storage & Permissions
- **Shared Storage**: $storage_status
- **Omni Write Access**: $([ -w "$OMNI_PATH" ] && echo "Yes" || echo "No")

## PostgreSQL
- **Installed**: $pg_installed
- **Data Found**: ${pg_data_found:-unknown}

## AI Tools
- **Count**: $ai_count

## Summary
- **Errors**: $errors
- **Warnings**: $warnings
- **Fixed**: $fixed
EOF

  # ===== RESULTS =====
  echo
  separator
  log_success "Diagnostics completed!"
  list_item "Report saved: ${D_CYAN}$report_file${D_NC}"

  if [[ $errors -gt 0 ]]; then
    log_error "Found $errors error(s) and $warnings warning(s)."
  elif [[ $warnings -gt 0 ]]; then
    log_warn "Found $warnings warning(s). System is functional but can be optimized."
  else
    log_success "All systems healthy!"
  fi

  # ===== AUTO-FIX =====
  if [[ ${#fix_commands[@]} -gt 0 ]]; then
    echo
    separator_section "Auto-Fix Options"
    echo
    log_info "Detected $(( ${#fix_commands[@]} )) issue(s) that can be automatically fixed:"
    echo
    for ((i=0; i<${#fix_commands[@]}; i++)); do
      printf "    ${D_YELLOW}%2d.${D_NC} %s\n" $((i + 1)) "${fix_descriptions[$i]}"
    done
    echo

    local confirm
    read_confirm "Apply all auto-corrections?" confirm
    if [[ "$confirm" == "y" ]]; then
      echo
      for ((i=0; i<${#fix_commands[@]}; i++)); do
        log_info "Fixing: ${fix_descriptions[$i]}..."
        local callback="${fix_callbacks[$i]:-}"
        local success=false

        if [[ -n "$callback" ]] && type "$callback" &>/dev/null 2>&1; then
          "$callback" && success=true
        elif [[ -n "${fix_commands[$i]}" ]]; then
          eval "${fix_commands[$i]}" 2>/dev/null && success=true
        fi

        if [[ "$success" == "true" ]]; then
          ((fixed++))
          log_success "Fixed: ${fix_descriptions[$i]}"
        else
          log_warn "Could not fix: ${fix_descriptions[$i]}"
        fi
      done
      echo
      if (( fixed > 0 )); then
        log_success "Fixed $fixed issue(s)! Run 'omni doctor' again to verify."
      else
        log_warn "Some fixes could not be applied. Check errors above."
      fi
    fi
  fi
  echo
}

# ===== FIX CALLBACK FUNCTIONS =====

_fix_storage() {
  termux-setup-storage 2>/dev/null
  return $?
}

_fix_mkdir() {
  for dir in "${dirs[@]}"; do
    mkdir -p "$dir" 2>/dev/null
    chmod 755 "$dir" 2>/dev/null
  done
  return 0
}

_fix_pkg_install() {
  local pkg_to_install=""
  case "$1" in
    pkg) pkg_to_install="$2" ;;
    *) pkg_to_install="${fix_commands[$i]}" ;;
  esac
  local pkg_name=""
  if [[ "$pkg_to_install" =~ pkg\ install\ -y\ (.+) ]]; then
    pkg_name="${BASH_REMATCH[1]}"
  fi
  if [[ -n "$pkg_name" ]]; then
    pkg install -y "$pkg_name" 2>/dev/null
    return $?
  fi
  return 1
}

_fix_dpkg() {
  dpkg --configure -a 2>/dev/null
  apt-get -f install -y 2>/dev/null
  return $?
}

_fix_apt_update() {
  pkg update -y 2>/dev/null
  return $?
}

_fix_npm_prefix() {
  mkdir -p "$HOME/.npm-global"
  npm config set prefix "$HOME/.npm-global" 2>/dev/null
  return $?
}

_fix_pip() {
  local py_cmd=""
  for py in python3.12 python3.11 python3.10 python3.9 python3 python; do
    if command -v "$py" &>/dev/null; then py_cmd="$py"; break; fi
  done
  if [[ -n "$py_cmd" ]]; then
    "$py_cmd" -m ensurepip 2>/dev/null
    "$py_cmd" -m pip install --upgrade pip 2>/dev/null
    return $?
  fi
  return 1
}

_fix_pg_init() {
  source "$OMNI_PATH/utils/env.sh" 2>/dev/null
  import "@/modules/db" 2>/dev/null
  if type pg_init &>/dev/null; then
    pg_init 2>/dev/null
    pg_start 2>/dev/null
    return $?
  fi
  local pg_data="$HOME/.local/share/postgresql/data"
  mkdir -p "$pg_data" 2>/dev/null
  if command -v initdb &>/dev/null; then
    initdb -D "$pg_data" 2>/dev/null
    pg_ctl -D "$pg_data" -l "$HOME/.cache/omni/postgresql.log" start 2>/dev/null
    return $?
  fi
  return 1
}

_fix_pg_start() {
  local pg_data=""
  for dir in "$PREFIX/var/lib/postgresql/data" "$PREFIX/var/lib/postgresql" "$HOME/.termux/postgresql/data" "$HOME/.termux/postgresql" "$HOME/.local/share/postgresql/data"; do
    if [[ -d "$dir" ]] && [[ -f "$dir/PG_VERSION" ]]; then
      pg_data="$dir"
      break
    fi
  done
  if [[ -n "$pg_data" ]] && command -v pg_ctl &>/dev/null; then
    pg_ctl -D "$pg_data" -l "$HOME/.cache/omni/postgresql.log" start 2>/dev/null
    return $?
  fi
  return 1
}

_fix_pg_install() {
  source "$OMNI_PATH/utils/env.sh" 2>/dev/null
  import "@/modules/db" 2>/dev/null
  if type install_db &>/dev/null; then
    install_db 2>/dev/null
    return $?
  fi
  pkg install -y postgresql 2>/dev/null
  return $?
}

_fix_symlinks() {
  ln -sf "$OMNI_PATH/bin/omni" "$PREFIX/bin/omni" 2>/dev/null
  [[ -L "$PREFIX/bin/omni" ]]
}

_fix_banner() {
  local shell_config=""
  [[ -f "$HOME/.zshrc" ]] && shell_config="$HOME/.zshrc"
  [[ -f "$HOME/.bashrc" ]] && shell_config="$HOME/.bashrc"
  if [[ -z "$shell_config" ]]; then
    shell_config="$HOME/.zshrc"
    touch "$shell_config"
  fi
  local marker="# ===== Omni Banner ====="
  if ! grep -qF "$marker" "$shell_config" 2>/dev/null; then
    cat >>"$shell_config" <<EOF

$marker
source "$OMNI_UTILS/banner.sh"
EOF
    return 0
  fi
  return 0
}

_fix_ai_install() {
  log_info "Installing AI tools (this may take a while)..."
  source "$OMNI_PATH/utils/env.sh" 2>/dev/null
  import "@/modules/ai" 2>/dev/null
  if type install_ai &>/dev/null; then
    install_ai 2>/dev/null
    return $?
  fi
  return 1
}

_fix_shell_syntax() {
  local config=""
  [[ -f "$HOME/.zshrc" ]] && config="$HOME/.zshrc"
  [[ -f "$HOME/.bashrc" ]] && config="$HOME/.bashrc"
  if [[ -n "$config" ]]; then
    cp "$config" "${config}.bak" 2>/dev/null
    local marker="# ===== Omni Banner ====="
    local banner_block=""
    if grep -qF "$marker" "$config" 2>/dev/null; then
      local marker_line
      marker_line=$(grep -nF "$marker" "$config" | head -1 | cut -d: -f1)
      if [[ -n "$marker_line" ]]; then
        banner_block=$(sed -n "$((marker_line - 1)),\$p" "$config" 2>/dev/null)
      fi
    fi
    local tmpconfig
    tmpconfig=$(mktemp)
    sed '/^source.*\/dev\/null$/d; /^#.*syntax error/d' "$config" > "$tmpconfig" 2>/dev/null
    if [[ -n "$banner_block" ]]; then
      echo "" >> "$tmpconfig"
      echo "$banner_block" >> "$tmpconfig"
    fi
    cp "$tmpconfig" "$config" 2>/dev/null
    rm -f "$tmpconfig"
    return 0
  fi
  return 1
}

_fix_ssh_key() {
  mkdir -p "$HOME/.ssh"
  chmod 700 "$HOME/.ssh"
  ssh-keygen -t ed25519 -f "$HOME/.ssh/id_ed25519" -N '' 2>/dev/null
  return $?
}

_fix_disk_cleanup() {
  rm -rf ~/.cache/omni/install_*.log 2>/dev/null
  if command -v pkg &>/dev/null; then
    pkg clean -y 2>/dev/null
  fi
  return $?
}

_fix_mkdir_single() {
  for dir in "${omni_dirs[@]}"; do
    [[ -d "$dir" ]] || mkdir -p "$dir" 2>/dev/null
  done
  return 0
}
