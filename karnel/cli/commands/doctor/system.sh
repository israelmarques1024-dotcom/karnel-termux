_doctor_system() {
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

    local free_mb=$((free_kb / 1024))
    if (( free_mb < 200 )); then
      log_warn "Low available memory (${ram_free}). Some tools may fail."
      ((warnings++))
    fi
  else
    log_warn "Could not read RAM details"
    ((warnings++))
  fi
}

_doctor_storage() {
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

  if [ -w "$KARNEL_PATH" ]; then
    log_success "Write permission in Karnel path: $KARNEL_PATH"
  else
    log_error "No write permission in Karnel path!"
    ((errors++))
  fi

  local dirs=("$KARNEL_CONFIG" "$KARNEL_CACHE" "$KARNEL_DATA")
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
}
