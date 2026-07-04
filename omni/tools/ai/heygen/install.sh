#!/usr/bin/env bash

import "@/utils/log"

LOG_FILE="$OMNI_CACHE/install_ai.log"
HEYGEN_DATA_DIR="$HOME/.local/share/omni-data/heygen"

_heygen_dependencies() {
  loading "Installing dependencies" _heygen_dependencies_impl
}

_heygen_dependencies_impl() {
  declare -A DEPS=(
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

_install_heygen_cli() {
  loading "Installing HeyGen CLI" _install_heygen_cli_impl
}

_install_heygen_cli_impl() {
  mkdir -p "$HEYGEN_DATA_DIR"

  local install_url="https://static.heygen.ai/cli/install.sh"
  if ! curl -fsSL --connect-timeout 10 "$install_url" | bash &>>"$LOG_FILE"; then
    log_warn "Online install failed — static.heygen.ai inacessível"
    log_warn "Isso é uma limitação do serviço externo, não do Omni"
    # NÃO cria stub — apenas retorna erro.
    # O _validate_tool_installed em all.sh detectará corretamente como falha.
    return 1
  fi

  # Valida que o instalador realmente criou o binário
  if command -v heygen &>/dev/null; then
    return 0
  fi

  log_warn "Instalador do HeyGen executou mas binário 'heygen' não foi encontrado no PATH"
  return 1
}

install_heygen() {
  if command -v heygen &>/dev/null; then
    log_info "HeyGen CLI is already installed"
    return 2
  fi

  log_info "Installing HeyGen CLI..."

  mkdir -p "$(dirname "$LOG_FILE")"

  _heygen_dependencies || return 1
  _install_heygen_cli || return 1

  # Validação pós-instalação: só declara sucesso se o binário REAL existe
  if command -v heygen &>/dev/null; then
    log_success "HeyGen CLI installed successfully"
    return 0
  fi

  log_error "HeyGen CLI: binário não encontrado no PATH após instalação"
  return 1
}

uninstall_heygen() {
  if ! command -v heygen &>/dev/null; then
    log_info "HeyGen CLI is not installed"
    return 2
  fi

  log_info "Uninstalling HeyGen CLI..."
  mkdir -p "$(dirname "$LOG_FILE")"

  loading "Removing HeyGen CLI" _uninstall_heygen_impl

  log_success "HeyGen CLI uninstalled"
  return 0
}

_uninstall_heygen_impl() {
  rm -f "$HOME/.local/bin/heygen" 2>/dev/null
  rm -f "$PREFIX/bin/heygen" 2>/dev/null
  rm -rf "$HEYGEN_DATA_DIR" 2>/dev/null
  rm -rf "$HOME/.heygen" 2>/dev/null
  return 0
}

update_heygen() {
  if ! command -v heygen &>/dev/null; then
    log_error "HeyGen CLI is not installed"
    return 1
  fi

  log_info "Updating HeyGen CLI..."
  mkdir -p "$(dirname "$LOG_FILE")"

  loading "Updating HeyGen CLI" _update_heygen_impl

  log_success "HeyGen CLI updated"
  return 0
}

_update_heygen_impl() {
  if ! curl -fsSL --connect-timeout 10 https://static.heygen.ai/cli/install.sh | bash &>>"$LOG_FILE"; then
    log_warn "Cannot reach static.heygen.ai — serviço externo indisponível"
    log_warn "Nada foi alterado. Tente novamente mais tarde."
    return 1
  fi
  return 0
}

reinstall_heygen() {
  uninstall_heygen
  install_heygen
}
