#!/data/data/com.termux/files/usr/bin/bash

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

_install_odysseus_localhost() {
  loading "Installing Odysseus (localhost)" _install_odysseus_localhost_impl
}

_install_odysseus_localhost_impl() {
  mkdir -p "$ODYSSEUS_DATA_DIR"

  if command -v docker &>/dev/null; then
    if ! git clone https://github.com/pewdiepie-archdaemon/odysseus.git "$ODYSSEUS_DATA_DIR/repo" &>>"$LOG_FILE"; then
      log_error "Failed to clone Odysseus repository"
      return 1
    fi

    cd "$ODYSSEUS_DATA_DIR/repo"
    if ! docker compose up -d &>>"$LOG_FILE"; then
      log_error "Failed to start Odysseus with Docker"
      return 1
    fi
    cd "$OLDPWD"

    log_success "Odysseus is running at http://localhost:7000"
  else
    _install_odysseus_termux_proot
  fi
}

_install_odysseus_termux_proot() {
  mkdir -p "$(dirname "$LOG_FILE")"

  if ! command -v proot-distro &>/dev/null; then
    pkg install proot-distro -y &>>"$LOG_FILE"
  fi

  if [ ! -d "$(_odysseus_detect_ubuntu_root)" ]; then
    proot-distro install ubuntu:24.04 &>>"$LOG_FILE"
  fi

  _odysseus_proot_ubuntu /bin/bash -c '
    export DEBIAN_FRONTEND=noninteractive
    apt-get update && apt-get upgrade -y && apt-get install -y curl git docker.io docker-compose-v2 python3 python3-pip nodejs npm
  ' &>>"$LOG_FILE"

  _odysseus_proot_ubuntu /bin/bash -c '
    cd /root
    git clone https://github.com/pewdiepie-archdaemon/odysseus.git /root/odysseus
    cd /root/odysseus
    docker compose up -d
  ' &>>"$LOG_FILE"

  local ubuntu_root
  ubuntu_root="$(_odysseus_detect_ubuntu_root)"

  if [ -z "$ubuntu_root" ]; then
    log_error "Ubuntu rootfs not found"
    return 1
  fi

  local wrapper_path="$PREFIX/bin/odysseus"
  cat > "$wrapper_path" << 'WRAPPER'
#!/data/data/com.termux/files/usr/bin/bash
proot-distro login --shared-tmp ubuntu -- docker compose -f /root/odysseus/docker-compose.yml "$@"
WRAPPER
  chmod +x "$wrapper_path"

  log_success "Odysseus installed (proot-distro)"
  echo
  log_info "Odysseus web UI: ${D_CYAN}http://localhost:7000${NC}"
  log_info "Manage with: ${D_CYAN}odysseus up|down|logs${NC}"
}

install_odysseus() {
  if command -v odysseus &>/dev/null || [ -d "$ODYSSEUS_DATA_DIR/repo" ]; then
    log_info "Odysseus is already installed"
    return 2
  fi

  log_info "Installing Odysseus..."

  mkdir -p "$(dirname "$LOG_FILE")"

  _odysseus_dependencies || return 1

  if command -v docker &>/dev/null; then
    if [[ -t 0 ]] && [[ -t 1 ]]; then
      log_info "Select installation method for Odysseus:"
      read_select "Installation method" SELECTED_METHOD \
        "Localhost (Docker) - Web UI at http://localhost:7000" \
        "Termux (proot-distro) - Ubuntu container for Android"
      case "$SELECTED_METHOD" in
      *Localhost*) _install_odysseus_localhost;;
      *Termux*) _install_odysseus_termux_proot;;
      esac
    else
      _install_odysseus_localhost
    fi
  else
    log_info "Docker not available, installing via proot-distro..."
    _install_odysseus_termux_proot
  fi

  log_success "Odysseus installed successfully"
  return 0
}

uninstall_odysseus() {
  log_info "Uninstalling Odysseus..."
  mkdir -p "$(dirname "$LOG_FILE")"

  if [ -f "$PREFIX/bin/odysseus" ]; then
    rm -f "$PREFIX/bin/odysseus"
    rm -rf "$ODYSSEUS_DATA_DIR"
    log_success "Odysseus uninstalled"
    return 0
  fi

  if [ -d "$ODYSSEUS_DATA_DIR/repo" ]; then
    if command -v docker &>/dev/null; then
      cd "$ODYSSEUS_DATA_DIR/repo" && docker compose down -v &>>"$LOG_FILE"
    fi
    rm -rf "$ODYSSEUS_DATA_DIR"
    log_success "Odysseus uninstalled"
    return 0
  fi

  log_warn "Odysseus is not installed"
  return 1
}

update_odysseus() {
  log_info "Updating Odysseus..."
  mkdir -p "$(dirname "$LOG_FILE")"

  if [ -d "$ODYSSEUS_DATA_DIR/repo" ]; then
    cd "$ODYSSEUS_DATA_DIR/repo"
    git pull &>>"$LOG_FILE"
    docker compose up -d &>>"$LOG_FILE"
    cd "$OLDPWD"
    log_success "Odysseus updated"
    return 0
  fi

  log_error "Odysseus is not installed"
  return 1
}

reinstall_odysseus() {
  uninstall_odysseus
  install_odysseus
}
