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
    export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
    export DEBIAN_FRONTEND=noninteractive

    apt-get update -qq && apt-get upgrade -y -qq && apt-get install -y -qq curl git python3-pip

    python3 -m pip install --break-system-packages \
      fastapi uvicorn python-multipart python-dotenv httpx pydantic pydantic-settings \
      mcp bcrypt sqlalchemy aiosqlite jinja2 aiofiles python-dateutil \
      pyotp qrcode croniter pypdf beautifulsoup4 charset-normalizer \
      numpy chromadb-client fastembed youtube-transcript-api markdown \
      nh3 icalendar caldav pytest pytest-asyncio
  ' &>>"$LOG_FILE"

  _odysseus_proot_ubuntu /bin/bash -c '
    export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

    if [ ! -d /root/odysseus ]; then
      git clone --depth 1 https://github.com/pewdiepie-archdaemon/odysseus.git /root/odysseus
    fi

    cd /root/odysseus
    if [ -f requirements.txt ]; then
      python3 -m pip install --break-system-packages -r requirements.txt 2>&1
    fi
  ' &>>"$LOG_FILE"

  local ubuntu_root
  ubuntu_root="$(_odysseus_detect_ubuntu_root)"

  if [ -z "$ubuntu_root" ]; then
    log_error "Ubuntu rootfs not found"
    return 1
  fi

  local wrapper_path="$PREFIX/bin/odysseus"
  cat > "$wrapper_path" << WRAPPER
#!$PREFIX/bin/bash
exec proot-distro login --shared-tmp ubuntu -- bash -c 'cd /root/odysseus && exec python3 app.py "\$@"' bash "\$@"
WRAPPER
  chmod +x "$wrapper_path"

  log_success "Odysseus installed (proot-distro)"
  echo
  log_info "Start with: ${D_CYAN}odysseus${NC}"
  log_info "Web UI at: ${D_CYAN}http://localhost:7000${NC}"
}

_install_odysseus_native() {
  mkdir -p "$(dirname "$LOG_FILE")"

  if ! command -v glibc-repo &>/dev/null && ! command -v glibc &>/dev/null; then
    pkg install glibc-repo glibc clang curl git tar -y &>>"$LOG_FILE" || true
  fi

  _odysseus_proot_ubuntu /bin/bash -c '
    export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
    export DEBIAN_FRONTEND=noninteractive

    if [ ! -d /root/odysseus ]; then
      git clone --depth 1 https://github.com/pewdiepie-archdaemon/odysseus.git /root/odysseus
    fi

    cd /root/odysseus
    if [ -f requirements.txt ]; then
      python3 -m pip install --break-system-packages -r requirements.txt 2>&1
    fi
  ' &>>"$LOG_FILE"

  mkdir -p "$ODYSSEUS_DATA_DIR"
  local wrapper_path="$PREFIX/bin/odysseus"
  cat > "$wrapper_path" << WRAPPER
#!$PREFIX/bin/bash
exec proot-distro login --shared-tmp ubuntu -- bash -c 'cd /root/odysseus && exec python3 app.py "\$@"' bash "\$@"
WRAPPER
  chmod +x "$wrapper_path"

  log_success "Odysseus installed (native glibc)"
  echo
  log_info "Start with: ${D_CYAN}odysseus${NC}"
  log_info "Web UI at: ${D_CYAN}http://localhost:7000${NC}"
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
