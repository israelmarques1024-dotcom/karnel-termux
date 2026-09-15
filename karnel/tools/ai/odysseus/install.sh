#!/usr/bin/env bash

import "@/utils/log"
import "@/utils/install"
import "@/utils/version"
import "@/utils/colors"

: "${KARNEL_DATA:=${XDG_DATA_HOME:-$HOME/.local/share}/karnel-data}"
LOG_FILE="$KARNEL_CACHE/install_ai.log"
ODYSSEUS_DATA_DIR="$KARNEL_DATA/odysseus"
ODYSSEUS_REPO="https://github.com/pewdiepie-archdaemon/odysseus.git"
ODYSSEUS_COMMIT="f9235ebbf13f693a6fd29ce70b097f6ec83705bf"
ODYSSEUS_WRAPPER="$PREFIX/bin/odysseus"
ODYSSEUS_CLI_LOG_FILE="$LOG_FILE"
ODYSSEUS_NATIVE_PYTHON="$PREFIX/glibc/bin/python"

_odysseus_wrapper_owned() {
  local marker="$ODYSSEUS_DATA_DIR/.karnel-wrapper-odysseus"
  [[ -f "$marker" && -f "$ODYSSEUS_WRAPPER" ]] || return 1
  [[ "$(sha256sum "$ODYSSEUS_WRAPPER" 2>/dev/null)" == "$(<"$marker")" ]]
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
  local ubuntu_root="${1:-}" repo_dir
  if [[ -e "$ODYSSEUS_DATA_DIR" ]] && ! _odysseus_data_owned; then
    log_error "Refusing to replace unowned Odysseus data: $ODYSSEUS_DATA_DIR"
    return 1
  fi
  if [[ -e "$ODYSSEUS_WRAPPER" ]] && ! _odysseus_wrapper_owned; then
    log_error "Refusing to replace unowned command: $ODYSSEUS_WRAPPER"
    return 1
  fi
  if command -v odysseus &>/dev/null && ! _odysseus_wrapper_owned; then
    log_error "Refusing to shadow the existing odysseus command: $(command -v odysseus)"
    return 1
  fi
  [[ -n "$ubuntu_root" ]] || return 0
  repo_dir="$(_odysseus_repo_dir "$ubuntu_root")"
  if [[ -e "$repo_dir" ]] && ! _odysseus_repo_owned "$repo_dir"; then
    log_error "Refusing to replace unowned Odysseus repository: $repo_dir"
    return 1
  fi
}

# ===== HOST DEPS (métodos sem proot-distro) =====

_odysseus_dependencies() {
  loading "Installing dependencies" _odysseus_dependencies_impl
}

_odysseus_dependencies_impl() {
  declare -A DEPS=(
    ["git"]="git"
    ["curl"]="curl"
    ["python"]="python"
    ["python-glibc"]="python-glibc"
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
  proot-distro login --shared-tmp ubuntu -- "$@"
}

# ===== INSTALL PRINCIPAL (proot-distro) =====

_install_odysseus_impl() {
  mkdir -p "$(dirname "$LOG_FILE")"

  if ! command -v proot-distro &>/dev/null; then
    if ! pkg install proot-distro -y &>>"$LOG_FILE"; then
      log_error "Failed to install proot-distro"
      return 1
    fi
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

    apt-get update -qq && apt-get install -y -qq curl git python3-pip python3-venv

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

  local wrapper_path="$ODYSSEUS_WRAPPER"
  mkdir -p "$PREFIX/bin" "$ODYSSEUS_DATA_DIR" || return 1
  local temporary
  temporary="$(mktemp "$PREFIX/bin/.odysseus.XXXXXX")" || return 1
  cat > "$temporary" << WRAPPER
#!$PREFIX/bin/bash
exec proot-distro login --shared-tmp ubuntu -- /bin/bash -c 'cd /root/odysseus && exec python3 app.py "\$@"' odysseus "\$@"
WRAPPER
  chmod +x "$temporary"
  mv -f "$temporary" "$wrapper_path" || return 1
  sha256sum "$wrapper_path" >"$ODYSSEUS_DATA_DIR/.karnel-wrapper-odysseus" || return 1
  : >"$ODYSSEUS_DATA_DIR/.karnel-managed"
  printf 'proot' >"$ODYSSEUS_DATA_DIR/.install-method"

  log_success "Odysseus installed (proot-distro)"
  echo
  log_info "Start with: ${D_CYAN}odysseus${NC}"
  log_info "Web UI at: ${D_CYAN}http://localhost:7000${NC}"
}

# ===== INSTALL NATIVO (python-glibc do Termux) =====

_odysseus_native_glibc_run() {
  glibc-runner -s "$ODYSSEUS_NATIVE_PYTHON" "$@"
}

_odysseus_install_deps_native_impl() {
  if [[ ! -f $PREFIX/etc/apt/sources.list.d/glibc.list ]]; then
    if ! yes | pkg install glibc-repo &>>"$LOG_FILE"; then
      log_error "Failed to install glibc-repo"
      return 1
    fi
  fi
  if [[ ! -f $PREFIX/glibc/lib/libc.so.6 ]]; then
    if ! yes | pkg install glibc &>>"$LOG_FILE"; then
      log_error "Failed to install glibc"
      return 1
    fi
  fi
  if [[ ! -f $ODYSSEUS_NATIVE_PYTHON ]]; then
    if ! yes | pkg install python-glibc &>>"$LOG_FILE"; then
      log_error "Failed to install python-glibc"
      return 1
    fi
  fi
  if [[ ! -f $PREFIX/glibc/bin/pip ]]; then
    if ! yes | pkg install python-pip-glibc &>>"$LOG_FILE"; then
      log_error "Failed to install python-pip-glibc"
      return 1
    fi
  fi
  return 0
}

_odysseus_install_deps_native() {
  loading "Installing glibc and Python dependencies" _odysseus_install_deps_native_impl
}

_odysseus_native_repo_dir() {
  printf '%s/odysseus\n' "$ODYSSEUS_DATA_DIR"
}

_odysseus_install_pip_native_impl() {
  local install_args=""
  if [ "${1:-install}" = "update" ]; then
    install_args="--upgrade"
  fi

  local req_file="$(_odysseus_native_repo_dir)/requirements.txt"
  if [ -f "$req_file" ]; then
    if ! _odysseus_native_glibc_run -m pip install $install_args -r "$req_file" &>>"$LOG_FILE"; then
      log_error "Failed to install Odysseus Python dependencies (glibc)"
      return 1
    fi
  fi

  local core_deps=(fastapi uvicorn python-multipart python-dotenv httpx pydantic pydantic-settings mcp bcrypt sqlalchemy aiosqlite jinja2 aiofiles python-dateutil pyotp qrcode croniter pypdf beautifulsoup4 charset-normalizer numpy chromadb-client fastembed youtube-transcript-api markdown nh3 icalendar caldav pytest pytest-asyncio)
  if ! _odysseus_native_glibc_run -m pip install $install_args "${core_deps[@]}" &>>"$LOG_FILE"; then
    log_error "Failed to install Odysseus core dependencies (glibc)"
    return 1
  fi
  return 0
}

_odysseus_install_pip_native() {
  log_info "This installs the Odysseus Python app and its dependencies into the glibc Python environment"
  loading "Installing Odysseus (pip)" _odysseus_install_pip_native_impl "$@"
}

_odysseus_verify_native_impl() {
  if ! { printf 'import fastapi, uvicorn\n' | timeout 300 glibc-runner -s "$ODYSSEUS_NATIVE_PYTHON" -; } &>>"$LOG_FILE"; then
    log_error "Odysseus native install failed validation — your glibc setup cannot run it; use the proot-distro method"
    rm -f "$ODYSSEUS_WRAPPER"
    return 1
  fi
  return 0
}

_odysseus_verify_native() {
  loading "Verifying Odysseus (glibc)" _odysseus_verify_native_impl
}

_odysseus_create_native_wrapper_impl() {
  local repo_dir="$(_odysseus_native_repo_dir)"
  mkdir -p "$PREFIX/bin" "$ODYSSEUS_DATA_DIR" || return 1
  local temporary
  temporary="$(mktemp "$PREFIX/bin/.odysseus.XXXXXX")" || return 1
  cat > "$temporary" << WRAPPER
#!$PREFIX/bin/bash
# Karnel-managed Odysseus wrapper (glibc native)
cd "$repo_dir" || exit 1
exec glibc-runner -s "$ODYSSEUS_NATIVE_PYTHON" app.py "\$@"
WRAPPER
  chmod +x "$temporary"
  mv -f "$temporary" "$ODYSSEUS_WRAPPER" || return 1
  sha256sum "$ODYSSEUS_WRAPPER" >"$ODYSSEUS_DATA_DIR/.karnel-wrapper-odysseus" || return 1
  return 0
}

_odysseus_create_native_wrapper() {
  loading "Creating wrapper" _odysseus_create_native_wrapper_impl
}

_install_odysseus_native() {
  mkdir -p "$(dirname "$LOG_FILE")"

  local repo_dir="$(_odysseus_native_repo_dir)"
  install_pinned_git_repo "$ODYSSEUS_REPO" "$ODYSSEUS_COMMIT" "$repo_dir" || return 1
  : >"$repo_dir/.karnel-managed"

  _odysseus_install_deps_native || return 1
  _odysseus_install_pip_native || return 1
  _odysseus_verify_native || return 1
  _odysseus_create_native_wrapper || return 1

  mkdir -p "$ODYSSEUS_DATA_DIR"
  : >"$ODYSSEUS_DATA_DIR/.karnel-managed"
  printf 'native' >"$ODYSSEUS_DATA_DIR/.install-method"
  log_success "Odysseus installed natively (python-glibc)"
  echo
  log_info "Start with: ${D_CYAN}odysseus${NC}"
  log_info "Web UI at: ${D_CYAN}http://localhost:7000${NC}"
  return 0
}

# ===== MAIN INSTALL =====

_odysseus_install_method() {
  if [ -f "$ODYSSEUS_DATA_DIR/.install-method" ]; then
    cat "$ODYSSEUS_DATA_DIR/.install-method"
  elif _odysseus_data_owned && _odysseus_wrapper_owned && [ -d "$(_odysseus_native_repo_dir)" ]; then
    echo "native"
  elif _odysseus_data_owned && _odysseus_wrapper_owned && [ -n "$(_odysseus_detect_ubuntu_root)" ]; then
    echo "proot"
  else
    echo ""
  fi
}

install_odysseus() {
  local method
  method="$(_odysseus_install_method)"
  if [ -n "$method" ]; then
    _do_update_odysseus
    return $?
  fi

  local ubuntu_root
  ubuntu_root="$(_odysseus_detect_ubuntu_root)"
  _odysseus_verify_ownership "$ubuntu_root" || return 1

  log_info "Select installation method for Odysseus:"

  local SELECTED_METHOD
  read_select "Installation method" SELECTED_METHOD \
    "proot-distro (ubuntu container, recommended)" \
    "glibc native (Termux python-glibc)"

  case "$SELECTED_METHOD" in
  *proot-distro*)
    _odysseus_dependencies || return 1
    _install_odysseus_impl || return 1
    ;;
  *glibc*)
    _install_odysseus_native || return 1
    ;;
  esac

  log_success "Odysseus installed successfully"
  return 0
}

# ===== UNINSTALL =====

_uninstall_odysseus_native_impl() {
  _odysseus_native_glibc_run -m pip uninstall -y -r "$(_odysseus_native_repo_dir)/requirements.txt" &>>"$LOG_FILE" || true
  rm -f "$ODYSSEUS_WRAPPER"
  rm -rf "$ODYSSEUS_DATA_DIR"
  return 0
}

uninstall_odysseus() {
  log_info "Uninstalling Odysseus..."
  mkdir -p "$(dirname "$LOG_FILE")"

  local method
  method="$(_odysseus_install_method)"
  if [ -z "$method" ]; then
    if [ ! -e "$ODYSSEUS_DATA_DIR" ] && [ ! -e "$ODYSSEUS_WRAPPER" ]; then
      log_info "Odysseus is not installed"
      return 2
    fi
    _odysseus_verify_ownership || return 1
    _odysseus_wrapper_owned && rm -f "$ODYSSEUS_WRAPPER"
    _odysseus_data_owned && rm -rf "$ODYSSEUS_DATA_DIR"
    local ubuntu_root repo_dir
    ubuntu_root="$(_odysseus_detect_ubuntu_root)"
    if [[ -n "$ubuntu_root" ]]; then
      repo_dir="$(_odysseus_repo_dir "$ubuntu_root")"
      _odysseus_repo_owned "$repo_dir" && rm -rf "$repo_dir"
    fi
    log_success "Odysseus uninstalled"
    return 0
  fi

  _odysseus_verify_ownership || return 1

  if [ "$method" = "native" ]; then
    loading "Uninstalling Odysseus (glibc native)" _uninstall_odysseus_native_impl
    log_success "Odysseus uninstalled"
    return 0
  fi

  _odysseus_wrapper_owned && rm -f "$ODYSSEUS_WRAPPER"
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

# ===== UPDATE =====

_update_odysseus_proot_impl() {
  local ubuntu_root
  ubuntu_root="$(_odysseus_detect_ubuntu_root)"
  _odysseus_verify_ownership "$ubuntu_root" || return 1
  if [[ -z "$ubuntu_root" ]] || ! _odysseus_prepare_repo "$ubuntu_root"; then
    log_error "Failed to update Odysseus repository"
    return 1
  fi
  if ! _odysseus_proot_ubuntu /bin/bash -c '
    export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
    export DEBIAN_FRONTEND=noninteractive
    cd /root/odysseus
    if [ -f requirements.txt ]; then
      python3 -m pip install --break-system-packages -r requirements.txt 2>&1
    fi
  ' &>>"$LOG_FILE"; then
    log_error "Failed to update Odysseus dependencies"
    return 1
  fi
  log_success "Odysseus updated (proot-distro)"
  return 0
}

_do_update_odysseus() {
  local method
  method="$(_odysseus_install_method)"
  case "$method" in
  native)
    _odysseus_install_pip_native update || return 1
    _odysseus_verify_native || return 1
    log_success "Odysseus updated (glibc native)"
    return 0
    ;;
  proot)
    loading "Updating Odysseus (proot-distro)" _update_odysseus_proot_impl
    return $?
    ;;
  esac
  log_warn "Could not detect Odysseus installation method"
  return 1
}

update_odysseus() {
  _do_update_odysseus
}

# ===== REINSTALL =====

reinstall_odysseus() {
  uninstall_odysseus
  install_odysseus
}