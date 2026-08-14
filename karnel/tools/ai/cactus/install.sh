#!/usr/bin/env bash

import "@/utils/log"

: "${KARNEL_DATA:=${XDG_DATA_HOME:-$HOME/.local/share}/karnel-data}"
CACTUS_VERSION="2.0.1"
CACTUS_DATA_DIR="$KARNEL_DATA/cactus"
CACTUS_CONTAINER_DIR="/opt/karnel/cactus"
CACTUS_WRAPPER="$PREFIX/bin/cactus"

_cactus_data_owned() {
  [[ -f "$CACTUS_DATA_DIR/.karnel-managed" ]]
}

_cactus_wrapper_owned() {
  local marker="$CACTUS_DATA_DIR/.karnel-wrapper-cactus"
  [[ -f "$marker" && -f "$CACTUS_WRAPPER" ]] || return 1
  [[ "$(sha256sum "$CACTUS_WRAPPER" 2>/dev/null)" == "$(<"$marker")" ]]
}

_cactus_proot() {
  proot-distro login --shared-tmp ubuntu -- "$@"
}

_cactus_container_owned() {
  command -v proot-distro &>/dev/null || return 1
  _cactus_proot test -f "$CACTUS_CONTAINER_DIR/.karnel-managed" &>/dev/null
}

_cactus_verify_ownership() {
  if [[ -e "$CACTUS_DATA_DIR" ]] && ! _cactus_data_owned; then
    log_error "Refusing to replace unowned Cactus data: $CACTUS_DATA_DIR"
    return 1
  fi
  if [[ -e "$CACTUS_WRAPPER" ]] && ! _cactus_wrapper_owned; then
    log_error "Refusing to replace unowned command: $CACTUS_WRAPPER"
    return 1
  fi
  if command -v cactus &>/dev/null && ! _cactus_wrapper_owned; then
    log_error "Refusing to shadow the existing cactus command: $(command -v cactus)"
    return 1
  fi
  if command -v proot-distro &>/dev/null &&
    _cactus_proot test -e "$CACTUS_CONTAINER_DIR" &>/dev/null &&
    ! _cactus_container_owned; then
    log_error "Refusing to replace unowned Cactus data in Ubuntu: $CACTUS_CONTAINER_DIR"
    return 1
  fi
}

_cactus_ensure_ubuntu() {
  case "$(uname -m)" in
    aarch64|arm64) ;;
    *)
      log_error "Cactus currently provides a Linux wheel only for ARM64"
      return 1
      ;;
  esac
  if ! command -v proot-distro &>/dev/null; then
    pkg install proot-distro -y || return 1
  fi
  if ! proot-distro login ubuntu -- true &>/dev/null; then
    proot-distro install ubuntu:24.04 || return 1
  fi
}

_cactus_validate() {
  _cactus_proot "$CACTUS_CONTAINER_DIR/venv/bin/cactus" --help &>/dev/null
}

_install_cactus_inside_ubuntu() {
  _cactus_proot /bin/bash -c '
    set -e
    export DEBIAN_FRONTEND=noninteractive
    if [ -f /etc/apt/sources.list.d/ubuntu.sources ]; then
      official_source=/etc/apt/sources.list.d/ubuntu.sources
    else
      official_source=/etc/apt/sources.list
    fi
    apt_options=(-o "Dir::Etc::sourcelist=$official_source" -o "Dir::Etc::sourceparts=-")
    apt-get "${apt_options[@]}" update -qq
    apt-get "${apt_options[@]}" install -y -qq ca-certificates python3 python3-pip python3-venv
    if [ -e /opt/karnel/cactus ] && [ ! -f /opt/karnel/cactus/.karnel-managed ]; then
      echo "Refusing to replace unowned /opt/karnel/cactus" >&2
      exit 1
    fi
    rm -rf /opt/karnel/cactus
    mkdir -p /opt/karnel/cactus
    : > /opt/karnel/cactus/.karnel-managed
    if python3 -c "import sys; raise SystemExit(sys.version_info >= (3, 14))"; then
      python3 -m venv /opt/karnel/cactus/venv
    else
      python3 -m venv /opt/karnel/cactus/bootstrap
      /opt/karnel/cactus/bootstrap/bin/python -m pip install --upgrade uv
      export UV_PYTHON_INSTALL_DIR=/opt/karnel/cactus/python
      /opt/karnel/cactus/bootstrap/bin/uv python install 3.13
      /opt/karnel/cactus/bootstrap/bin/uv venv --seed --python 3.13 /opt/karnel/cactus/venv
    fi
    /opt/karnel/cactus/venv/bin/python -m pip install --upgrade "cactus-compute==2.0.1"
    /opt/karnel/cactus/venv/bin/cactus --help >/dev/null
  '
}

_cactus_write_wrapper() {
  mkdir -p "$CACTUS_DATA_DIR" "$PREFIX/bin" || return 1
  : >"$CACTUS_DATA_DIR/.karnel-managed" || return 1
  local temporary
  temporary="$(mktemp "$PREFIX/bin/.cactus.XXXXXX")" || return 1
  cat >"$temporary" <<EOF
#!$PREFIX/bin/bash
# Karnel-managed Cactus wrapper
exec proot-distro login --shared-tmp ubuntu -- $CACTUS_CONTAINER_DIR/venv/bin/cactus "\$@"
EOF
  chmod 755 "$temporary" || { rm -f "$temporary"; return 1; }
  mv -f "$temporary" "$CACTUS_WRAPPER" || return 1
  sha256sum "$CACTUS_WRAPPER" >"$CACTUS_DATA_DIR/.karnel-wrapper-cactus" || return 1
}

install_cactus() {
  if _cactus_data_owned && _cactus_wrapper_owned && _cactus_container_owned && _cactus_validate; then
    log_info "Cactus is already installed"
    return 2
  fi
  _cactus_verify_ownership || return 1

  log_info "Installing Cactus $CACTUS_VERSION in Ubuntu (glibc compatibility)..."
  _cactus_ensure_ubuntu || return 1
  if ! _install_cactus_inside_ubuntu || ! _cactus_write_wrapper || ! _cactus_validate; then
    _cactus_wrapper_owned && rm -f "$CACTUS_WRAPPER"
    _cactus_data_owned && rm -rf "$CACTUS_DATA_DIR"
    log_error "Failed to install Cactus"
    return 1
  fi
  log_success "Cactus installed"
  log_info "Start with: cactus run Cactus-Compute/needle"
}

uninstall_cactus() {
  if ! _cactus_data_owned && ! _cactus_wrapper_owned && ! _cactus_container_owned; then
    if [[ -e "$CACTUS_DATA_DIR" || -e "$CACTUS_WRAPPER" ]]; then
      _cactus_verify_ownership
      return $?
    fi
    log_info "Cactus is not installed by Karnel"
    return 2
  fi
  _cactus_verify_ownership || return 1

  _cactus_wrapper_owned && rm -f "$CACTUS_WRAPPER"
  if _cactus_container_owned; then
    _cactus_proot rm -rf "$CACTUS_CONTAINER_DIR" || return 1
  fi
  _cactus_data_owned && rm -rf "$CACTUS_DATA_DIR"
  log_success "Cactus uninstalled; downloaded model data outside its environment was preserved"
}

update_cactus() {
  _cactus_data_owned && _cactus_wrapper_owned && _cactus_container_owned || {
    log_error "Cactus is not installed by Karnel"
    return 1
  }
  _cactus_verify_ownership || return 1
  _cactus_proot "$CACTUS_CONTAINER_DIR/venv/bin/python" -m pip install --upgrade 'cactus-compute>=2,<3' || return 1
  _cactus_validate || return 1
  log_success "Cactus updated"
}

reinstall_cactus() {
  uninstall_cactus || [[ $? -eq 2 ]] || return 1
  install_cactus
}
