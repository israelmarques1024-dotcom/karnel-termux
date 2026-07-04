#!/usr/bin/env bash

import "@/utils/log"

LOG_FILE="$OMNI_CACHE/install_ai.log"
KIRO_DATA_DIR="$HOME/.local/share/omni-data/kiro-cli"

_kiro_cli_dependencies() {
  loading "Installing dependencies" _kiro_cli_dependencies_impl
}

_kiro_cli_dependencies_impl() {
  declare -A DEPS=(
    ["curl"]="curl"
    ["unzip"]="unzip"
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

_install_kiro_cli_curl() {
  loading "Installing Kiro CLI" _install_kiro_cli_curl_impl
}

_install_kiro_cli_curl_impl() {
  mkdir -p "$KIRO_DATA_DIR"

  # Try multiple installer URLs (Kiro was acquired by AWS)
  local install_urls=(
    "https://cli.kiro.dev/install"
    "https://raw.githubusercontent.com/kiro-ai/kiro-cli/main/install.sh"
  )

  local success=false
  for install_url in "${install_urls[@]}"; do
    if curl -fsSL --connect-timeout 15 "$install_url" 2>&1 | bash &>>"$LOG_FILE"; then
      success=true
      break
    fi
  done

  if [[ "$success" == "false" ]]; then
    log_warn "Online install failed - trying npm as fallback"
    _install_kiro_cli_npm
    return $?
  fi

  return 0
}

_install_kiro_cli_npm() {
  loading "Installing Kiro CLI via npm" _install_kiro_cli_npm_impl
}

_install_kiro_cli_npm_impl() {
  if ! command -v npm &>/dev/null; then
    log_warn "npm not available - cannot install Kiro CLI via npm"
    _install_kiro_cli_stub
    return $?
  fi

  if npm install -g @kiro/cli &>>"$LOG_FILE"; then
    log_success "Kiro CLI installed via npm"
    return 0
  fi

  log_warn "npm install failed - installing offline stub"
  _install_kiro_cli_stub
  return $?
}

_install_kiro_cli_stub() {
  log_warn "Kiro CLI: instalador online indisponivel (servico externo)"
  log_info "O dominio cli.kiro.dev nao esta acessivel — Kiro foi adquirido pela AWS"
  log_info "e o instalador original pode estar descontinuado."
  log_info "Nenhum arquivo foi criado. Tente novamente mais tarde ou visite kiro.dev."
  return 1
}

install_kiro_cli() {
  if command -v kiro &>/dev/null; then
    # Se encontrou o kiro, verifica se nao e stub
    local kiro_path
    kiro_path=$(command -v kiro)
    if [ -f "$kiro_path" ] && [ -x "$kiro_path" ] && ! grep -qiE "offline|unreachable|stub|indisponivel|inacessivel" "$kiro_path" 2>/dev/null; then
      log_info "Kiro CLI is already installed"
      return 2
    fi
    # Stub encontrado — remove e reinstala
    log_info "Kiro CLI stub encontrado — reinstalando..."
    rm -f "$kiro_path"
  fi

  log_info "Installing Kiro CLI..."

  mkdir -p "$(dirname "$LOG_FILE")"

  _kiro_cli_dependencies || return 1
  _install_kiro_cli_curl || return 1

  # Validacao final: command -v + nao-stub
  if command -v kiro &>/dev/null; then
    local kiro_path
    kiro_path=$(command -v kiro)
    if [ -f "$kiro_path" ] && [ -x "$kiro_path" ] && ! grep -qiE "offline|unreachable|stub|indisponivel|inacessivel" "$kiro_path" 2>/dev/null; then
      log_success "Kiro CLI installed successfully"
      return 0
    fi
  fi

  log_warn "Kiro CLI: instalador online indisponivel (servico externo)"
  log_info "O dominio cli.kiro.dev esta inacessivel — Kiro foi adquirido pela AWS"
  log_info "e o instalador original pode estar descontinuado."
  log_info "Nenhum stub foi criado. Tente novamente mais tarde."
  return 1
}

uninstall_kiro_cli() {
  if ! command -v kiro &>/dev/null; then
    log_info "Kiro CLI is not installed"
    return 2
  fi

  log_info "Uninstalling Kiro CLI..."
  mkdir -p "$(dirname "$LOG_FILE")"

  loading "Removing Kiro CLI" _uninstall_kiro_cli_impl

  log_success "Kiro CLI uninstalled"
  return 0
}

_uninstall_kiro_cli_impl() {
  rm -f "$HOME/.local/bin/kiro" "$HOME/.local/bin/kiro-cli" 2>/dev/null
  rm -f "$PREFIX/bin/kiro" 2>/dev/null
  rm -rf "$KIRO_DATA_DIR" 2>/dev/null
  return 0
}

update_kiro_cli() {
  if ! command -v kiro &>/dev/null; then
    log_error "Kiro CLI is not installed"
    return 1
  fi

  log_info "Updating Kiro CLI..."
  mkdir -p "$(dirname "$LOG_FILE")"

  loading "Updating Kiro CLI" _update_kiro_cli_impl

  log_success "Kiro CLI updated"
  return 0
}

_update_kiro_cli_impl() {
  local install_url="https://cli.kiro.dev/install"
  if ! curl -fsSL --connect-timeout 10 "$install_url" | bash &>>"$LOG_FILE"; then
    log_warn "Cannot reach cli.kiro.dev - skipping update"
    return 0
  fi
  return 0
}

reinstall_kiro_cli() {
  uninstall_kiro_cli
  install_kiro_cli
}
