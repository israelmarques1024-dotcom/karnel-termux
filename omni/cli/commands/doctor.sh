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

  # ===== 9. PYTHON COMPATIBILITY CHECKS =====
  echo
  separator_section "Python Compatibility (Termux patches)"
  echo

  # psutil Android check
  if python3 -c "import psutil; print(psutil.__version__)" &>/dev/null; then
    log_success "psutil: $(python3 -c 'import psutil; print(psutil.__version__)') — Android patch OK"
  else
    log_warn "psutil not installed — needed by hermes-agent and other AI tools"
    ((warnings++))
    fix_commands+=("pip install psutil==7.2.2")
    fix_descriptions+=("Install psutil for Python process monitoring")
    fix_callbacks+=("_fix_psutil")
  fi

  # Python version constraint check (pyproject.toml files)
  local constraint_issues=0
  while IFS= read -r -d '' pyproject; do
    local require_py
    require_py=$(grep -E 'requires-python\s*=' "$pyproject" 2>/dev/null | grep -oP '>=3\.\d+,<3\.\d+')
    if [[ -n "$require_py" ]]; then
      local max_ver
      max_ver=$(echo "$require_py" | grep -oP '<3\.\K\d+')
      if [[ -n "$max_ver" ]] && (( max_ver <= 14 )); then
        log_warn "Constraint in $(basename "$(dirname "$pyproject")"): $require_py may block Python 3.14"
        ((constraint_issues++))
      fi
    fi
  done < <(timeout 10 find "$HOME/.hermes" "$HOME/omni" -name "pyproject.toml" -maxdepth 3 -print0 2>/dev/null || true)
  if (( constraint_issues == 0 )); then
    log_success "No Python version constraints blocking 3.14"
  fi

  # C extension build capability
  local cc_test="$PREFIX/tmp/cext_test.c"
  echo '#include <Python.h>' > "$cc_test"
  if python3-config --includes &>/dev/null && \
     clang $(python3-config --includes) -shared -fPIC -o /dev/null -x c - <<<'#include <Python.h>' &>/dev/null; then
    log_success "C extensions can be compiled (Python.h + clang OK)"
  else
    log_warn "C extension build may fail — clang or Python headers issue"
    ((warnings++))
    fix_commands+=("pkg install -y clang python-dev")
    fix_descriptions+=("Install C build dependencies for Python extensions")
    fix_callbacks+=("_fix_pkg_install")
  fi
  rm -f "$cc_test"

  # uv availability (used by hermes-agent installer)
  if command -v uv &>/dev/null; then
    log_success "uv package manager: available"
  else
    log_info "uv not installed (used by hermes-agent, optional)"
  fi

  # pip check — detect broken dependencies
  local pip_check_output
  pip_check_output=$(timeout 15 pip check 2>&1 | grep -i "broken\|missing\|conflict\|incompatible" || true)
  if [[ -z "$pip_check_output" ]]; then
    log_success "pip dependencies: consistent"
  else
    log_warn "pip dependency issues detected"
    echo "$pip_check_output" | while IFS= read -r line; do
      list_item "$line"
    done
    ((warnings++))
    local broken_pkgs
    broken_pkgs=$(timeout 10 pip check 2>&1 | grep -oP '^\S+' | head -3 | tr '\n' ' ')
    if [[ -n "$broken_pkgs" ]]; then
      fix_commands+=("pip install --upgrade --force-reinstall $broken_pkgs")
      fix_descriptions+=("Fix pip dependency conflicts: $broken_pkgs")
      fix_callbacks+=("_fix_pip_check")
    fi
  fi

  # ===== 10. OMNI FRAMEWORK =====
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
  if [[ -f "$HOME/.zshrc" ]]; then
    shell_config="$HOME/.zshrc"
  elif [[ -f "$HOME/.bashrc" ]]; then
    shell_config="$HOME/.bashrc"
  fi

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

  local -a ai_cmds=("opencode" "claude" "gemini" "codex" "qwen" "vibe" "mimo" "hermes" "kimi" "ollama" "freebuff" "pi" "agy" "mmx" "gentle-ai" "gga" "engram" "codegraph" "kilocode" "kiro" "crush" "odysseus" "openclaude" "openclaw" "command-code" "kimchi" "cline" "omni-route" "ctx7" "openspec")
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

  # Registry consistency check
  local registry_file="$OMNI_PATH/tools/ai/all.sh"
  if [[ -f "$registry_file" ]]; then
    local registered_tools
    registered_tools=$(grep -cE '^[[:space:]]*"[^:]+:[^:]+:[^"]+"' "$registry_file" 2>/dev/null || echo 0)
    local installed_ai
    installed_ai=0
    for cmd in "${ai_cmds[@]}"; do
      command -v "$cmd" &>/dev/null && ((installed_ai++))
    done
    log_info "AI registry: $registered_tools tools | Installed: $installed_ai"
  fi

  # Check for discontinued tools still referenced in active installers
  local -a removed_tools=()
  for tool_dir in "$OMNI_PATH/omni/tools/ai/"*/; do
    local tool_name
    tool_name=$(basename "${tool_dir%/}")
    if [[ ! -f "$tool_dir/install.sh" && ! -f "$tool_dir/all.sh" ]]; then
      removed_tools+=("$tool_name")
    fi
  done
  if [[ ${#removed_tools[@]} -gt 0 ]]; then
    log_warn "Orphaned tool directories (no installer): ${removed_tools[*]}"
    ((warnings++))
  fi

  # ===== SHEBANG & BINARY HEALTH =====
  echo
  separator_section "Binary & Shebang Health"
  echo

  # Check for bad shebangs (#!/usr/bin/env) in PREFIX/bin (fast grep)
  local bad_shebangs=0
  local bad_files
  bad_files=$(timeout 10 rg -l "^#!/usr/bin/env" "$PREFIX/bin/" 2>/dev/null || true)
  if [[ -n "$bad_files" ]]; then
    bad_shebangs=$(echo "$bad_files" | wc -l)
    log_warn "$bad_shebangs binary(s) with #!/usr/bin/env — will fail on Termux"
    echo "$bad_files" | while IFS= read -r f; do
      list_item "$(basename "$f")"
    done
    ((warnings++))
    fix_commands+=("omni install npm --all 2>/dev/null || true")
    fix_descriptions+=("Reinstall npm tools to fix shebangs")
    fix_callbacks+=("_fix_npm_shebangs")
  else
    log_success "All binaries have valid shebangs"
  fi

  # Check for broken symlinks in PREFIX/bin
  local broken_symlinks=0
  for f in "$PREFIX/bin/"*; do
    [[ -L "$f" ]] && [[ ! -e "$f" ]] && ((broken_symlinks++))
  done
  if (( broken_symlinks > 0 )); then
    log_warn "$broken_symlinks broken symlink(s) in $PREFIX/bin"
    ((warnings++))
    fix_commands+=("find $PREFIX/bin -type l ! -exec test -e {} \; -delete")
    fix_descriptions+=("Remove broken symlinks from PREFIX/bin")
    fix_callbacks+=("_fix_broken_symlinks")
  else
    log_success "No broken symlinks in $PREFIX/bin"
  fi

  # Detect glibc-dependent binaries (need proot)
  local glibc_bins=0
  local -a glibc_dependent=("kimchi")
  for cmd in "${glibc_dependent[@]}"; do
    local path
    path=$(command -v "$cmd" 2>/dev/null)
    if [[ -n "$path" ]]; then
      if file "$path" 2>/dev/null | grep -qi "ELF\|executable" && \
         ! ldd "$path" &>/dev/null 2>&1; then
        log_info "$cmd: glibc binary (needs proot)"
        if command -v proot-distro &>/dev/null; then
          log_success "  proot-distro available as fallback"
        else
          log_warn "  $cmd needs proot but proot-distro not installed"
          ((warnings++))
        fi
        ((glibc_bins++))
      fi
    fi
  done
  if (( glibc_bins == 0 )); then
    log_success "No glibc-dependent binaries detected"
  fi

  # ===== SHELL CONFIGURATION =====
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

  # ===== CACHE & BUILD ARTIFACTS =====
  echo
  separator_section "Cache & Build Artifacts"
  echo

  # npm cache
  local npm_cache_dir
  npm_cache_dir=$(npm config get cache 2>/dev/null)
  if [[ -n "$npm_cache_dir" ]] && [[ -d "$npm_cache_dir" ]]; then
    local npm_cache_size
    npm_cache_size=$(du -sh "$npm_cache_dir" 2>/dev/null | awk '{print $1}')
    log_info "npm cache: $npm_cache_size"
    if [[ "$npm_cache_size" =~ [0-9]+G ]]; then
      log_warn "npm cache is large (${npm_cache_size}) — consider cleaning"
      ((warnings++))
      fix_commands+=("npm cache clean --force 2>/dev/null")
      fix_descriptions+=("Clean npm cache")
      fix_callbacks+=("_fix_npm_cache")
    fi
  fi

  # pip cache
  local pip_cache_dir
  pip_cache_dir=$(pip cache dir 2>/dev/null)
  if [[ -n "$pip_cache_dir" ]] && [[ -d "$pip_cache_dir" ]]; then
    local pip_cache_size
    pip_cache_size=$(du -sh "$pip_cache_dir" 2>/dev/null | awk '{print $1}')
    log_info "pip cache: $pip_cache_size"
    if [[ "$pip_cache_size" =~ [0-9]+G ]]; then
      log_warn "pip cache is large (${pip_cache_size})"
      ((warnings++))
      fix_commands+=("pip cache purge 2>/dev/null")
      fix_descriptions+=("Clean pip cache")
      fix_callbacks+=("_fix_pip_cache")
    fi
  fi

  # Python __pycache__ bloat
  local pycache_size
  pycache_size=$(find "$PREFIX/lib/python3.*" -name "__pycache__" -type d -exec du -sk {} + 2>/dev/null | awk '{s+=$1}END{printf "%.0f", s/1024}')
  if [[ -n "$pycache_size" ]] && (( pycache_size > 50 )); then
    log_info "Python __pycache__: ${pycache_size}MB"
    if (( pycache_size > 200 )); then
      log_warn "Large Python cache (${pycache_size}MB) — may slow imports"
      fix_commands+=("find $PREFIX/lib/python3.* -name __pycache__ -exec rm -rf {} + 2>/dev/null")
      fix_descriptions+=("Clean Python __pycache__ directories")
      fix_callbacks+=("_fix_pycache")
    fi
  fi

  # cargo cache (if rust installed)
  if [[ -d "$HOME/.cargo/registry" ]]; then
    local cargo_size
    cargo_size=$(du -sh "$HOME/.cargo/registry" 2>/dev/null | awk '{print $1}')
    log_info "cargo registry: $cargo_size"
  fi

  # omni cache
  if [[ -d "$OMNI_CACHE" ]]; then
    local omni_cache_size
    omni_cache_size=$(du -sh "$OMNI_CACHE" 2>/dev/null | awk '{print $1}')
    log_info "omni cache: $omni_cache_size"
  fi

  # Zombie/stale build processes
  local stale_builds
  stale_builds=$(pgrep -f "pip.*install\|npm.*install\|cargo.*build" 2>/dev/null | wc -l)
  if (( stale_builds > 0 )); then
    log_warn "$stale_builds build process(es) still running"
    list_item "Run 'kill \$(pgrep -f \"pip.*install\")' to clean up"
  fi

  # ===== PHANTOM PROCESS KILLER =====
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

  # ===== PROOT / GLIBC ENVIRONMENT =====
  echo
  separator_section "Proot & glibc Environment"
  echo

  if command -v proot-distro &>/dev/null; then
    log_success "proot-distro: available"
    local ubuntu_installed=false
    if proot-distro list 2>/dev/null | grep -qi ubuntu; then
      ubuntu_installed=true
      log_success "Ubuntu proot container: installed"
    else
      log_info "Ubuntu proot container: not installed (needed by kimchi)"
      fix_commands+=("proot-distro install ubuntu 2>/dev/null")
      fix_descriptions+=("Install Ubuntu proot container for glibc tools")
      fix_callbacks+=("_fix_proot_ubuntu")
    fi
  else
    log_info "proot-distro not installed (optional, needed for kimchi)"
    fix_commands+=("pkg install -y proot-distro")
    fix_descriptions+=("Install proot-distro for glibc compatibility")
    fix_callbacks+=("_fix_pkg_install")
  fi

  if command -v proot &>/dev/null; then
    log_success "proot: available"
  else
    log_info "proot not installed (optional)"
  fi

  # ===== TERMUX:API =====
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

  # DNS resolution
  if nslookup github.com &>/dev/null || host github.com &>/dev/null; then
    log_success "DNS resolution: OK"
  else
    log_warn "DNS resolution failed"
    ((warnings++))
    fix_commands+=("echo 'nameserver 8.8.8.8' > $PREFIX/etc/resolv.conf")
    fix_descriptions+=("Set Google DNS (8.8.8.8) for Termux")
    fix_callbacks+=("_fix_dns")
  fi

  if curl -fsSL --max-time 5 https://github.com &>/dev/null; then
    log_success "HTTPS connectivity: OK"
  else
    log_warn "Network connectivity issue detected"
    ((warnings++))
  fi

  # Termux mirror speed
  local active_mirror=""
  if [[ -f "$PREFIX/etc/apt/sources.list" ]]; then
    active_mirror=$(grep -oP 'https?://[^ ]+' "$PREFIX/etc/apt/sources.list" 2>/dev/null | head -1)
  fi
  if [[ -n "$active_mirror" ]]; then
    local mirror_host
    mirror_host=$(echo "$active_mirror" | awk -F/ '{print $3}')
    local ping_time
    ping_time=$(timeout 5 ping -c 1 -W 3 "$mirror_host" 2>/dev/null | grep -oP 'time=\K[0-9.]+' || echo "slow")
    log_info "Termux mirror: $mirror_host (${ping_time}ms)"
    if [[ "$ping_time" == "slow" ]]; then
      log_warn "Termux mirror is slow — consider switching"
      fix_commands+=("termux-change-repo")
      fix_descriptions+=("Switch to a faster Termux mirror")
      fix_callbacks+=("_fix_mirror")
    fi
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

  # ===== ZSH PLUGINS & OMNI INTEGRATION =====
  echo
  separator_section "Zsh Plugins & Omni Integration"
  echo

  local zsh_plugins_dir="$HOME/.oh-my-zsh/custom/plugins"
  if [[ -d "$zsh_plugins_dir" ]]; then
    local -a needed_plugins=("history-substring-search" "you-should-use")
    for plugin in "${needed_plugins[@]}"; do
      if [[ -d "$zsh_plugins_dir/$plugin" ]]; then
        log_success "zsh plugin: $plugin"
      else
        log_info "zsh plugin: $plugin not found (optional)"
      fi
    done
  else
    local zsh_custom="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"
    if [[ ! -d "$zsh_custom" ]]; then
      log_info "Oh My Zsh not installed (optional)"
    fi
  fi

  # Check omni module loading
  if [[ -f "$HOME/.zshrc" ]] && grep -q "omni" "$HOME/.zshrc" 2>/dev/null; then
    log_success "Omni integration in .zshrc"
  fi

  # Check url-quote-magic for parse errors (Termux zsh bug)
  local uqm_file="$PREFIX/share/zsh/functions/Zle/url-quote-magic"
  if [[ -f "$uqm_file" ]] && grep -q '((${~localschema})' "$uqm_file" 2>/dev/null; then
    log_warn "url-quote-magic: double-paren parse error found (zsh 5.9 bug)"
    log_warn "url-quote-magic has known double-paren syntax error"
    fix_commands+=("true")
    fix_descriptions+=("Patch url-quote-magic double-paren parse error")
    fix_callbacks+=("_fix_url_quote_magic")
  fi

  # ===== GPU / OPENGL INFO =====
  echo
  separator_section "GPU & Hardware Acceleration"
  echo

  if command -v termux-info &>/dev/null; then
    local gpu_info
    gpu_info=$(termux-info 2>/dev/null | grep -i "gpu\|render\|opengl" | head -3)
    if [[ -n "$gpu_info" ]]; then
      log_success "GPU: $(echo "$gpu_info" | tr -s ' ')"
    fi
  fi

  # Check /dev/dri or /dev/ Mali for GPU acceleration
  if [[ -e /dev/dri/renderD128 ]] || [[ -e /dev/mali0 ]]; then
    log_success "GPU render node accessible"
  fi

  # ===== ENCODING & LOCALE =====
  echo
  separator_section "Locale & Encoding"
  echo

  if locale 2>/dev/null | grep -qi "utf8\|utf-8"; then
    log_success "UTF-8 locale: OK"
  else
    log_warn "UTF-8 locale not set — may cause encoding issues"
    ((warnings++))
    fix_commands+=("echo 'export LANG=en_US.UTF-8' >> $HOME/.zshrc")
    fix_descriptions+=("Set UTF-8 locale in shell config")
    fix_callbacks+=("_fix_locale")
  fi


  # ===== BATTERY & POWER MANAGEMENT =====
  echo
  separator_section "Battery & Power Management"
  echo

  if command -v termux-battery-status &>/dev/null; then
    local battery_info
    battery_info=$(termux-battery-status 2>/dev/null)
    if [[ -n "$battery_info" ]]; then
      local battery_pct
      battery_pct=$(echo "$battery_info" | python3 -c "import json,sys; print(json.load(sys.stdin).get('percentage',0))" 2>/dev/null || echo "?")
      log_success "Battery: ${battery_pct}%"

      # Check if battery is critically low
      if [[ "$battery_pct" =~ ^[0-9]+$ ]] && (( battery_pct < 15 )); then
        log_warn "Battery critically low (${battery_pct}%) — processes may be killed"
        ((warnings++))
      fi

      # Check charging status
      local charging
      charging=$(echo "$battery_info" | python3 -c "import json,sys; print(json.load(sys.stdin).get('status','Unknown'))" 2>/dev/null || echo "?")
      log_info "Charging status: $charging"
    fi
  else
    log_info "termux-battery-status not available (install termux-api)"
  fi

  # Check battery optimization exemption
  if command -v termux-wake-lock &>/dev/null; then
    log_success "termux-wake-lock available (prevents sleep)"
  else
    log_info "termux-wake-lock not installed (optional, prevents background killing)"
  fi

  # ===== API KEYS VALIDATION =====
  echo
  separator_section "API Keys & Environment"
  echo

  local -a api_keys=("OPENAI_API_KEY" "ANTHROPIC_API_KEY" "GOOGLE_API_KEY" "GEMINI_API_KEY" "OPENROUTER_API_KEY" "DEEPSEEK_API_KEY" "MISTRAL_API_KEY")
  local keys_found=0

  for key in "${api_keys[@]}"; do
    if [[ -n "${!key:-}" ]]; then
      local val="${!key}"
      local masked="${val:0:8}****${val: -4}"
      log_success "$key: $masked"
      ((keys_found++))
    fi
  done

  if [[ $keys_found -eq 0 ]]; then
    log_info "No API keys found in environment"
    log_info "Set keys with: ${D_CYAN}omni env set${NC}"
  else
    log_info "$keys_found API key(s) configured"
  fi

  # Check for .env files with leaked keys
  local leaked_keys=0
  while IFS= read -r -d '' envfile; do
    if grep -qE '(sk-[a-zA-Z0-9]{20,}|ghp_[a-zA-Z0-9]{36}|xoxb-[0-9])' "$envfile" 2>/dev/null; then
      log_warn "Potential API key found in: $envfile"
      ((leaked_keys++))
    fi
  done < <(find "$HOME" -maxdepth 3 -name '.env' -not -path '*/node_modules/*' -not -path '*/.git/*' -print0 2>/dev/null || true)

  if (( leaked_keys > 0 )); then
    log_warn "$leaked_keys file(s) with potential API keys in tracked directories"
    ((warnings++))
  fi

  # ===== PROCESS HEALTH =====
  echo
  separator_section "Process Health"
  echo

  # Check for zombie processes
  local zombies
  zombies=$(ps aux 2>/dev/null | awk '$8 ~ /^Z/ {count++} END {print count+0}')
  if (( zombies > 0 )); then
    log_warn "$zombies zombie process(es) detected"
    ((warnings++))
    fix_commands+=("kill -9 \$(ps aux | awk '\\$8 ~ /^Z/ {print \\$2}') 2>/dev/null")
    fix_descriptions+=("Kill zombie processes")
    fix_callbacks+=("_fix_zombies")
  else
    log_success "No zombie processes"
  fi

  # Check for orphaned node/python processes
  local orphan_count=0
  orphan_count=$(pgrep -c -f 'node.*omni\|python.*omni' 2>/dev/null || echo 0)
  if (( orphan_count > 2 )); then
    log_warn "$orphan_count Omni-related processes running (may be stale)"
    ((warnings++))
  fi

  # ===== STORAGE I/O HEALTH =====
  echo
  separator_section "Storage I/O Health"
  echo

  local io_test_file="$HOME/.cache/omni_io_test"
  mkdir -p "$(dirname "$io_test_file")" 2>/dev/null
  local io_start io_end io_time
  io_start=$(date +%s%N 2>/dev/null || echo 0)
  dd if=/dev/zero of="$io_test_file" bs=4096 count=100 2>/dev/null
  io_end=$(date +%s%N 2>/dev/null || echo 0)
  rm -f "$io_test_file" 2>/dev/null

  if [[ $io_start -gt 0 ]] && [[ $io_end -gt 0 ]]; then
    io_time=$(( (io_end - io_start) / 1000000 ))
    if (( io_time < 100 )); then
      log_success "Storage I/O: fast (${io_time}ms for 400KB)"
    elif (( io_time < 500 )); then
      log_info "Storage I/O: moderate (${io_time}ms for 400KB)"
    else
      log_warn "Storage I/O: slow (${io_time}ms for 400KB) — may affect performance"
      ((warnings++))
    fi
  fi

  # ===== WIFI / NETWORK QUALITY =====
  echo
  separator_section "Network Quality"
  echo

  if command -v ping &>/dev/null; then
    local ping_result
    ping_result=$(timeout 10 ping -c 3 -W 5 8.8.8.8 2>/dev/null)
    if [[ -n "$ping_result" ]]; then
      local avg_ping
      avg_ping=$(echo "$ping_result" | grep 'avg' | awk -F'/' '{print $5}')
      if [[ -n "$avg_ping" ]]; then
        local ping_int=${avg_ping%.*}
        if (( ping_int < 50 )); then
          log_success "Network latency: excellent (${avg_ping}ms)"
        elif (( ping_int < 150 )); then
          log_info "Network latency: good (${avg_ping}ms)"
        else
          log_warn "Network latency: high (${avg_ping}ms)"
          ((warnings++))
        fi
      fi
    fi
  fi

  # ===== SHELL HISTORY & PRIVACY =====
  echo
  separator_section "Shell Privacy"
  echo

  local histfiles=("$HOME/.zsh_history" "$HOME/.bash_history" "$HOME/.local/share/zsh/history")
  for histfile in "${histfiles[@]}"; do
    if [[ -f "$histfile" ]]; then
      local hist_size
      hist_size=$(du -sh "$histfile" 2>/dev/null | awk '{print $1}')
      local hist_lines
      hist_lines=$(wc -l < "$histfile" 2>/dev/null || echo 0)
      log_info "History: $(basename "$histfile") ($hist_size, $hist_lines lines)"

      # Check for sensitive patterns in recent history
      if grep -qiE '(password=|secret=|token=|api_key=)' "$histfile" 2>/dev/null; then
        log_warn "Potential secrets found in shell history"
        ((warnings++))
        log_info "Run: ${D_CYAN}omni brain save${NC} to protect sensitive data"
      fi
    fi
  done

  # ===== USB & EXTERNAL STORAGE =====
  echo
  separator_section "USB & External"
  echo

  if [[ -d /storage ]]; then
    local storage_count
    storage_count=$(ls -1 /storage 2>/dev/null | grep -v '^emulated$\|^self$' | wc -l)
    if (( storage_count > 0 )); then
      log_success "External storage: $storage_count volume(s) mounted"
    else
      log_info "No external storage mounted"
    fi
  fi

  # Check USB devices
  if [[ -d /dev/bus/usb ]]; then
    local usb_count
    usb_count=$(ls /dev/bus/usb/ 2>/dev/null | wc -l)
    if (( usb_count > 0 )); then
      log_info "USB: $usb_count bus(es) detected"
    fi
  fi

  # ===== GENERATE REPORT =====
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
  for dir in "$OMNI_CONFIG" "$OMNI_CACHE" "$OMNI_DATA"; do
    mkdir -p "$dir" 2>/dev/null
    chmod 755 "$dir" 2>/dev/null
  done
  return 0
}

_fix_pkg_install() {
  local pkg_to_install=""
  case "$1" in
    pkg) pkg_to_install="$2" ;;
    *) pkg_to_install="${fix_commands[$i]:-}" ;;
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
  if [[ -f "$HOME/.zshrc" ]]; then
    shell_config="$HOME/.zshrc"
  elif [[ -f "$HOME/.bashrc" ]]; then
    shell_config="$HOME/.bashrc"
  fi
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
  if [[ -f "$HOME/.zshrc" ]]; then
    config="$HOME/.zshrc"
  elif [[ -f "$HOME/.bashrc" ]]; then
    config="$HOME/.bashrc"
  fi
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
  for dir in "$OMNI_CONFIG" "$OMNI_CACHE" "$OMNI_DATA" "$HOME/.local/share/omni-data"; do
    [[ -d "$dir" ]] || mkdir -p "$dir" 2>/dev/null
  done
  return 0
}

# ===== NEW FIX CALLBACKS =====

_fix_psutil() {
  local tmp="$PREFIX/tmp/psutil_patch"
  mkdir -p "$tmp"
  pip download psutil==7.2.2 --no-binary :all: --no-deps -d "$tmp" 2>/dev/null || return 1
  tar xzf "$tmp/psutil-7.2.2.tar.gz" -C "$tmp"
  sed -i 's/LINUX = sys.platform.startswith("linux")/LINUX = sys.platform.startswith(("linux", "android"))/' "$tmp/psutil-7.2.2/psutil/_common.py"
  pip install "$tmp/psutil-7.2.2" 2>/dev/null
  local rc=$?
  rm -rf "$tmp"
  return $rc
}

_fix_pip_check() {
  local broken
  broken=$(pip check 2>&1 | grep -oP '^\S+' | head -3)
  if [[ -n "$broken" ]]; then
    pip install --upgrade --force-reinstall $broken 2>/dev/null
  fi
  return 0
}

_fix_npm_shebangs() {
  local fixed=0
  for f in "$PREFIX/bin/"*; do
    [[ -f "$f" ]] || continue
    local shebang
    shebang=$(head -1 "$f" 2>/dev/null | tr -d '\0')
    if [[ "$shebang" == "#!/usr/bin/env node" ]]; then
      sed -i "1s|^.*$|#!$PREFIX/bin/node|" "$f"
      ((fixed++))
    elif [[ "$shebang" == "#!/usr/bin/env bash" ]] || [[ "$shebang" == "#!/usr/bin/env sh" ]]; then
      sed -i "1s|^.*$|#!$PREFIX/bin/bash|" "$f"
      ((fixed++))
    fi
  done
  return 0
}

_fix_broken_symlinks() {
  find "$PREFIX/bin" -type l ! -exec test -e {} \; -delete 2>/dev/null
  return 0
}

_fix_npm_cache() {
  npm cache clean --force 2>/dev/null
  return $?
}

_fix_pip_cache() {
  pip cache purge 2>/dev/null
  return $?
}

_fix_pycache() {
  find "$PREFIX/lib/python3.*" -name "__pycache__" -exec rm -rf {} + 2>/dev/null
  return 0
}

_fix_proot_ubuntu() {
  if command -v proot-distro &>/dev/null; then
    proot-distro install ubuntu 2>/dev/null
    return $?
  fi
  return 1
}

_fix_dns() {
  echo 'nameserver 8.8.8.8' > "$PREFIX/etc/resolv.conf" 2>/dev/null
  return $?
}

_fix_mirror() {
  if command -v termux-change-repo &>/dev/null; then
    termux-change-repo 2>/dev/null
    return $?
  fi
  return 1
}

_fix_locale() {
  local config="$HOME/.zshrc"
  if [[ ! -f "$config" ]] && [[ -f "$HOME/.bashrc" ]]; then
    config="$HOME/.bashrc"
  fi
  echo 'export LANG=en_US.UTF-8' >> "$config" 2>/dev/null
  return $?
}


_fix_zombies() {
  ps aux 2>/dev/null | awk '$8 ~ /^Z/ {print $2}' | xargs kill -9 2>/dev/null
  return 0
}

_fix_url_quote_magic() {
  local uqm_file="$PREFIX/share/zsh/functions/Zle/url-quote-magic"
  if [[ ! -f "$uqm_file" ]]; then
    return 1
  fi
  # Fix double-paren case patterns: (( -> ( for localschema and otherschema
  sed -i \
    -e 's/((${~localschema})/(${~localschema})/g' \
    -e 's/((${~otherschema})/(${~otherschema})/g' \
    "$uqm_file" 2>/dev/null
  return $?
}
