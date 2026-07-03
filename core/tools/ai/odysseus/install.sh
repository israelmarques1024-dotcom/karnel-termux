#!/usr/bin/env bash

import "@/utils/log"
import "@/utils/colors"

LOG_FILE="$OMNI_CACHE/install_ai.log"
ODYSSEUS_DATA_DIR="$HOME/.local/share/omni-data/odysseus"

_odysseus_dependencies() {
  loading "Installing dependencies" _odysseus_dependencies_impl
}

_odysseus_dependencies_impl() {
  declare -A DEPS=(
    ["git"]="git"
    ["curl"]="curl"
    ["proot-distro"]="proot-distro"
  )

  local pkg_name bin_name
  for pkg_name in "${!DEPS[@]}"; do
    bin_name="${DEPS[$pkg_name]}"
    if ! command -v "$bin_name" &>/dev/null; then
      if ! pkg install "$pkg_name" -y &>>"$LOG_FILE"; then
        log_error "Failed to install $pkg_name"
        return 1
      fi
    fi
  done

  return 0
}

_odysseus_detect_ubuntu_root() {
  local root
  root="$(find /data/data/com.termux -maxdepth 10 -type d \
    -name "rootfs" -path "*/containers/ubuntu/*" 2>/dev/null | head -1)"

  if [ -z "$root" ]; then
    root="$(find /data/data/com.termux -maxdepth 10 -type d \
      -name "ubuntu" -path "*/installed-rootfs/*" 2>/dev/null | head -1)"
  fi

  echo "$root"
}

_odysseus_proot_ubuntu() {
  proot-distro login \
    --shared-tmp \
    ubuntu \
    -- "$@"
}

_install_odysseus_impl() {
  mkdir -p "$(dirname "$LOG_FILE")"

  if ! command -v proot-distro &>/dev/null; then
    pkg install proot-distro -y &>>"$LOG_FILE"
  fi

  if [ ! -d "$(_odysseus_detect_ubuntu_root)" ]; then
    proot-distro install ubuntu:24.04 &>>"$LOG_FILE"
  fi

  _odysseus_proot_ubuntu /bin/bash -c '
    export DEBIAN_FRONTEND=noninteractive
    apt-get update && apt-get upgrade -y && apt-get install -y curl git python3 python3-pip nodejs npm
  ' &>>"$LOG_FILE"

  _odysseus_proot_ubuntu /bin/bash -c '
    cd /root
    if [ ! -d /root/odysseus ]; then
      git clone https://github.com/pewdiepie-archdaemon/odysseus.git /root/odysseus
    fi
    cd /root/odysseus
    if [ -f package.json ]; then
      npm install
    elif [ -f requirements.txt ]; then
      pip3 install -r requirements.txt
    fi
  ' &>>"$LOG_FILE"

  local ubuntu_root
  ubuntu_root="$(_odysseus_detect_ubuntu_root)"

  if [ -z "$ubuntu_root" ]; then
    log_error "Ubuntu rootfs not found"
    return 1
  fi

  local wrapper_path="$PREFIX/bin/odysseus"
  cat > "$wrapper_path" << 'WRAPPER'
#!/usr/bin/env bash
proot-distro login --shared-tmp ubuntu -- bash -c "cd /root/odysseus && node server.js \"$@\""
WRAPPER
  chmod +x "$wrapper_path"

  log_success "Odysseus installed (proot-distro)"
  echo
  log_info "Manage with: ${D_CYAN}odysseus${NC}"
}

install_odysseus() {
  if command -v odysseus &>/dev/null || [ -d "$ODYSSEUS_DATA_DIR/repo" ]; then
    log_info "Odysseus is already installed"
    return 2
  fi

  log_info "Installing Odysseus..."

  mkdir -p "$(dirname "$LOG_FILE")"

  _odysseus_dependencies || return 1

  log_info "Installing via proot-distro Ubuntu (Docker not available on Termux)..."
  _install_odysseus_impl

  log_success "Odysseus installed successfully"
  return 0
}

uninstall_odysseus() {
  log_info "Uninstalling Odysseus..."
  mkdir -p "$(dirname "$LOG_FILE")"

  if [ -f "$PREFIX/bin/odysseus" ]; then
    rm -f "$PREFIX/bin/odysseus"
  fi

  if [ -d "$ODYSSEUS_DATA_DIR" ]; then
    rm -rf "$ODYSSEUS_DATA_DIR"
  fi

  log_success "Odysseus uninstalled"
  return 0
}

update_odysseus() {
  log_info "Updating Odysseus..."
  mkdir -p "$(dirname "$LOG_FILE")"

  _odysseus_proot_ubuntu /bin/bash -c '
    cd /root/odysseus && git pull
  ' &>>"$LOG_FILE" && log_success "Odysseus updated" || {
    log_error "Failed to update Odysseus"
    return 1
  }
}

reinstall_odysseus() {
  uninstall_odysseus
  install_odysseus
}
