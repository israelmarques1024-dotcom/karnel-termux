#!/usr/bin/env bash

import "@/utils/log"
import "@/utils/install"
import "@/utils/version"
import "@/utils/colors"

LOG_FILE="$KARNEL_CACHE/install_ai.log"
ODYSSEUS_DATA_DIR="$HOME/.local/share/karnel-data/odysseus"
ODYSSEUS_REPO="https://github.com/pewdiepie-archdaemon/odysseus.git"
ODYSSEUS_COMMIT="f9235ebbf13f693a6fd29ce70b097f6ec83705bf"

_odysseus_wrapper_owned() {
  local marker="$ODYSSEUS_DATA_DIR/.karnel-wrapper-odysseus"
  [[ -f "$marker" && -f "$PREFIX/bin/odysseus" ]] || return 1
  [[ "$(sha256sum "$PREFIX/bin/odysseus" 2>/dev/null)" == "$(<"$marker")" ]]
}

_odysseus_data_owned() {
  [[ -f "$ODYSSEUS_DATA_DIR/.karnel-managed" ]]
}

_odysseus_repo_dir() {
  printf '%s/root/odysseus\n' "$1"
}

_odysseus_repo_owned() {
  [[ -f "$1/.karnel-managed" ]] ||
    { declare -F _pinned_git_repo_owned &>/dev/null && _pinned_git_repo_owned "$1" "$ODYSSEUS_REPO"; }
}

_odysseus_prepare_repo() {
  local ubuntu_root="$1" repo_dir remote
  repo_dir="$(_odysseus_repo_dir "$ubuntu_root")"
  if _odysseus_repo_owned "$repo_dir" && ! _pinned_git_repo_owned "$repo_dir" "$ODYSSEUS_REPO"; then
    remote=$(git -C "$repo_dir" remote get-url origin 2>/dev/null) || return 1
    [[ "$remote" == "$ODYSSEUS_REPO" || "$remote" == "${ODYSSEUS_REPO%.git}" ]] || {
      log_error "Refusing to adopt Odysseus repository with unexpected origin: $remote"
      return 1
    }
    printf '%s\n%s\n' 'karnel-pinned-git-v1' "$ODYSSEUS_REPO" >"$repo_dir/.karnel-pinned-git" || return 1
  fi
  install_pinned_git_repo "$ODYSSEUS_REPO" "$ODYSSEUS_COMMIT" "$repo_dir" || return 1
  : >"$repo_dir/.karnel-managed"
}

_odysseus_verify_ownership() {
  local ubuntu_root="$1" repo_dir
  if [[ -e "$ODYSSEUS_DATA_DIR" ]] && ! _odysseus_data_owned; then
    log_error "Refusing to replace unowned Odysseus data: $ODYSSEUS_DATA_DIR"
    return 1
  fi
  if [[ -e "$PREFIX/bin/odysseus" ]] && ! _odysseus_wrapper_owned; then
    log_error "Refusing to replace unowned command: $PREFIX/bin/odysseus"
    return 1
  fi
  [[ -n "$ubuntu_root" ]] || return 0
  repo_dir="$(_odysseus_repo_dir "$ubuntu_root")"
  if [[ -e "$repo_dir" ]] && ! _odysseus_repo_owned "$repo_dir"; then
    log_error "Refusing to replace unowned Odysseus repository: $repo_dir"
    return 1
  fi
}

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

  local ubuntu_root
  ubuntu_root="$(_odysseus_detect_ubuntu_root)"
  _odysseus_verify_ownership "$ubuntu_root" || return 1

  if [ ! -d "$ubuntu_root" ]; then
    if ! proot-distro install ubuntu:24.04 &>>"$LOG_FILE"; then
      log_error "Failed to install Ubuntu rootfs"
      return 1
    fi
  fi

  ubuntu_root="$(_odysseus_detect_ubuntu_root)"
  if [ -z "$ubuntu_root" ]; then
    log_error "Ubuntu rootfs not found"
    return 1
  fi
  _odysseus_verify_ownership "$ubuntu_root" || return 1
  _odysseus_prepare_repo "$ubuntu_root" || return 1
  if ! _odysseus_proot_ubuntu /bin/bash -c '
    export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
    export DEBIAN_FRONTEND=noninteractive

    apt-get update -qq && apt-get upgrade -y -qq && apt-get install -y -qq curl git python3-pip

    python3 -m pip install --break-system-packages \
      fastapi uvicorn python-multipart python-dotenv httpx pydantic pydantic-settings \
      mcp bcrypt sqlalchemy aiosqlite jinja2 aiofiles python-dateutil \
      pyotp qrcode croniter pypdf beautifulsoup4 charset-normalizer \
      numpy chromadb-client fastembed youtube-transcript-api markdown \
      nh3 icalendar caldav pytest pytest-asyncio
  ' &>>"$LOG_FILE"; then
    log_error "Failed to install Odysseus dependencies"
    return 1
  fi

  if ! _odysseus_proot_ubuntu /bin/bash -c '
    export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

    cd /root/odysseus
    if [ -f requirements.txt ]; then
      python3 -m pip install --break-system-packages -r requirements.txt 2>&1
    fi
  ' &>>"$LOG_FILE"; then
    log_error "Failed to install Odysseus repository"
    return 1
  fi

  local wrapper_path="$PREFIX/bin/odysseus"
  mkdir -p "$PREFIX/bin" "$ODYSSEUS_DATA_DIR" || return 1
  local temporary
  temporary="$(mktemp "$PREFIX/bin/.odysseus.XXXXXX")" || return 1
  cat > "$temporary" << WRAPPER
#!$PREFIX/bin/bash
exec proot-distro login --shared-tmp ubuntu -- bash -c 'cd /root/odysseus && exec python3 app.py "\$@"' bash "\$@"
WRAPPER
  chmod +x "$temporary"
  mv -f "$temporary" "$wrapper_path" || return 1
  sha256sum "$wrapper_path" >"$ODYSSEUS_DATA_DIR/.karnel-wrapper-odysseus" || return 1
  : >"$ODYSSEUS_DATA_DIR/.karnel-managed"

  log_success "Odysseus installed (proot-distro)"
  echo
  log_info "Start with: ${D_CYAN}odysseus${NC}"
  log_info "Web UI at: ${D_CYAN}http://localhost:7000${NC}"
}

_install_odysseus_native() {
  mkdir -p "$(dirname "$LOG_FILE")"

  local ubuntu_root
  ubuntu_root="$(_odysseus_detect_ubuntu_root)"
  _odysseus_verify_ownership "$ubuntu_root" || return 1
  _odysseus_prepare_repo "$ubuntu_root" || return 1

  if ! command -v glibc-repo &>/dev/null && ! command -v glibc &>/dev/null; then
    pkg install glibc-repo glibc clang curl git tar -y &>>"$LOG_FILE" || true
  fi

  if ! _odysseus_proot_ubuntu /bin/bash -c '
    export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
    export DEBIAN_FRONTEND=noninteractive

    cd /root/odysseus
    if [ -f requirements.txt ]; then
      python3 -m pip install --break-system-packages -r requirements.txt 2>&1
    fi
  ' &>>"$LOG_FILE"; then
    log_error "Failed to install Odysseus repository"
    return 1
  fi

  mkdir -p "$PREFIX/bin" "$ODYSSEUS_DATA_DIR" || return 1
  local wrapper_path="$PREFIX/bin/odysseus"
  local temporary
  temporary="$(mktemp "$PREFIX/bin/.odysseus.XXXXXX")" || return 1
  cat > "$temporary" << WRAPPER
#!$PREFIX/bin/bash
exec proot-distro login --shared-tmp ubuntu -- bash -c 'cd /root/odysseus && exec python3 app.py "\$@"' bash "\$@"
WRAPPER
  chmod +x "$temporary"
  mv -f "$temporary" "$wrapper_path" || return 1
  sha256sum "$wrapper_path" >"$ODYSSEUS_DATA_DIR/.karnel-wrapper-odysseus" || return 1
  : >"$ODYSSEUS_DATA_DIR/.karnel-managed"

  log_success "Odysseus installed (native glibc)"
  echo
  log_info "Start with: ${D_CYAN}odysseus${NC}"
  log_info "Web UI at: ${D_CYAN}http://localhost:7000${NC}"
}

install_odysseus() {
  local ubuntu_root
  ubuntu_root="$(_odysseus_detect_ubuntu_root)"
  if _odysseus_wrapper_owned && _odysseus_data_owned; then
    log_info "Odysseus is already installed"
    return 2
  fi

  _odysseus_verify_ownership "$ubuntu_root" || return 1

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

  _odysseus_wrapper_owned && rm -f "$PREFIX/bin/odysseus"
  _odysseus_data_owned && rm -rf "$ODYSSEUS_DATA_DIR"

  local ubuntu_root repo_dir
  ubuntu_root="$(_odysseus_detect_ubuntu_root)"
  if [[ -n "$ubuntu_root" ]]; then
    repo_dir="$(_odysseus_repo_dir "$ubuntu_root")"
    _odysseus_repo_owned "$repo_dir" && rm -rf "$repo_dir"
  fi

  log_success "Odysseus uninstalled"
  return 0
}

update_odysseus() {
  _do_update_odysseus
}

_do_update_odysseus() {
  local ubuntu_root
  ubuntu_root="$(_odysseus_detect_ubuntu_root)"
  _odysseus_verify_ownership "$ubuntu_root" || return 1
  if [[ -z "$ubuntu_root" ]] || ! _odysseus_prepare_repo "$ubuntu_root"; then
    log_error "Failed to update Odysseus"
    return 1
  fi
}

reinstall_odysseus() {
  uninstall_odysseus
  install_odysseus
}
