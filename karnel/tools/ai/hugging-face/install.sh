#!/usr/bin/env bash

import "@/utils/log"

: "${KARNEL_DATA:=${XDG_DATA_HOME:-$HOME/.local/share}/karnel-data}"
HUGGING_FACE_DATA_DIR="$KARNEL_DATA/hugging-face"
HUGGING_FACE_VENV="$HUGGING_FACE_DATA_DIR/venv"
HUGGING_FACE_WRAPPER="$PREFIX/bin/hf"

_hugging_face_data_owned() {
  [[ -f "$HUGGING_FACE_DATA_DIR/.karnel-managed" ]]
}

_hugging_face_wrapper_owned() {
  local marker="$HUGGING_FACE_DATA_DIR/.karnel-wrapper-hf"
  [[ -f "$marker" && -f "$HUGGING_FACE_WRAPPER" ]] || return 1
  [[ "$(sha256sum "$HUGGING_FACE_WRAPPER" 2>/dev/null)" == "$(<"$marker")" ]]
}

_hugging_face_verify_ownership() {
  if [[ -e "$HUGGING_FACE_DATA_DIR" ]] && ! _hugging_face_data_owned; then
    log_error "Refusing to replace unowned Hugging Face data: $HUGGING_FACE_DATA_DIR"
    return 1
  fi
  if [[ -e "$HUGGING_FACE_WRAPPER" || -L "$HUGGING_FACE_WRAPPER" ]] && ! _hugging_face_wrapper_owned; then
    log_error "Refusing to replace unowned command: $HUGGING_FACE_WRAPPER"
    return 1
  fi
  if command -v hf &>/dev/null && ! _hugging_face_wrapper_owned; then
    log_error "Refusing to shadow the existing hf command: $(command -v hf)"
    return 1
  fi
}

_hugging_face_validate() {
  "$HUGGING_FACE_VENV/bin/hf" --help &>/dev/null
}

_hugging_face_install_packages() {
  local python="$HUGGING_FACE_VENV/bin/python"
  "$python" -m pip install --upgrade \
    'click>=8.1' 'filelock>=3.10' 'fsspec>=2023.5' 'httpx>=0.23,<1' \
    'packaging>=20.9' 'pyyaml>=5.1' shellingham 'tqdm>=4.42.1' \
    typer-slim 'typing-extensions>=3.7.4.3' || return 1
  # hf-xet has no Android wheel and its Rust bootstrap rejects the Android target.
  "$python" -m pip install --upgrade --no-deps 'huggingface_hub>=1,<2'
}

_hugging_face_write_wrapper() {
  local temporary
  temporary="$(mktemp "$PREFIX/bin/.hf.XXXXXX")" || return 1
  cat >"$temporary" <<EOF
#!$PREFIX/bin/bash
# Karnel-managed Hugging Face CLI wrapper
export HF_HUB_DISABLE_XET=1
exec $HUGGING_FACE_VENV/bin/hf "\$@"
EOF
  chmod 755 "$temporary" || { rm -f "$temporary"; return 1; }
  mv -f "$temporary" "$HUGGING_FACE_WRAPPER" || return 1
  sha256sum "$HUGGING_FACE_WRAPPER" >"$HUGGING_FACE_DATA_DIR/.karnel-wrapper-hf" || return 1
}

_install_hugging_face_impl() {
  if ! command -v python3 &>/dev/null; then
    pkg install python -y || return 1
  fi
  python3 -c 'import sys; raise SystemExit(sys.version_info < (3, 9))' || {
    log_error "Hugging Face CLI requires Python 3.9 or newer"
    return 1
  }

  mkdir -p "$HUGGING_FACE_DATA_DIR" "$PREFIX/bin" || return 1
  : >"$HUGGING_FACE_DATA_DIR/.karnel-managed" || return 1
  rm -rf "$HUGGING_FACE_VENV"
  python3 -m venv "$HUGGING_FACE_VENV" || return 1
  _hugging_face_install_packages || return 1
  _hugging_face_validate || return 1
  _hugging_face_write_wrapper
}

install_hugging_face() {
  if _hugging_face_data_owned && _hugging_face_wrapper_owned && _hugging_face_validate; then
    log_info "Hugging Face CLI is already installed"
    return 2
  fi
  _hugging_face_verify_ownership || return 1

  log_info "Installing Hugging Face CLI in an isolated environment..."
  if ! _install_hugging_face_impl; then
    _hugging_face_wrapper_owned && rm -f "$HUGGING_FACE_WRAPPER"
    _hugging_face_data_owned && rm -rf "$HUGGING_FACE_DATA_DIR"
    log_error "Failed to install Hugging Face CLI"
    return 1
  fi
  log_success "Hugging Face CLI installed"
  log_info "Authenticate with: hf auth login"
}

uninstall_hugging_face() {
  if ! _hugging_face_data_owned && ! _hugging_face_wrapper_owned; then
    if [[ -e "$HUGGING_FACE_DATA_DIR" || -e "$HUGGING_FACE_WRAPPER" || -L "$HUGGING_FACE_WRAPPER" ]]; then
      _hugging_face_verify_ownership
      return $?
    fi
    log_info "Hugging Face CLI is not installed by Karnel"
    return 2
  fi
  _hugging_face_verify_ownership || return 1

  _hugging_face_wrapper_owned && rm -f "$HUGGING_FACE_WRAPPER"
  _hugging_face_data_owned && rm -rf "$HUGGING_FACE_DATA_DIR"
  log_success "Hugging Face CLI uninstalled; credentials and model cache were preserved"
}

update_hugging_face() {
  _hugging_face_data_owned && _hugging_face_wrapper_owned || {
    log_error "Hugging Face CLI is not installed by Karnel"
    return 1
  }
  _hugging_face_verify_ownership || return 1
  _hugging_face_install_packages || return 1
  _hugging_face_validate || return 1
  log_success "Hugging Face CLI updated"
}

reinstall_hugging_face() {
  uninstall_hugging_face || [[ $? -eq 2 ]] || return 1
  install_hugging_face
}
