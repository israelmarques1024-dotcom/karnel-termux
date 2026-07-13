#!/usr/bin/env bash

import "@/utils/log"
import "@/utils/colors"
import "@/utils/version"

LOG_FILE="$KARNEL_CACHE/install_ai.log"

install_kiro() {
  if command -v kiro &>/dev/null || command -v kiro-cli &>/dev/null; then
    log_info "Kiro is already installed"
    return 2
  fi

  log_info "Installing Kiro CLI..."

  # Try the official installer first
  log_info "Running official Kiro installer..."
  if echo "y" | curl -fsSL https://cli.kiro.dev/install 2>/dev/null | bash 2>>"$LOG_FILE"; then
    if command -v kiro &>/dev/null || command -v kiro-cli &>/dev/null; then
      log_success "Kiro installed successfully"
      return 0
    fi
  fi

  # Fallback: download directly from release server
  log_warn "Official installer failed, trying direct download..."

  local arch
  arch=$(uname -m)
  local manifest
  manifest=$(curl -fsSL "https://prod.download.cli.kiro.dev/stable/latest/manifest.json" 2>/dev/null)

  if [[ -z "$manifest" ]]; then
    log_error "Failed to fetch Kiro manifest"
    return 1
  fi

  # Find the arm64 linux package (prefer musl for Termux compatibility)
  local download_path
  # Try musl first (statically linked, works without glibc)
  download_path=$(echo "$manifest" | python3 -c "
import json,sys
d=json.load(sys.stdin)
for p in d['packages']:
    if p.get('architecture')=='aarch64' and p.get('os')=='linux' and 'tar' in p.get('fileType','').lower() and 'xz' not in p.get('fileType','').lower() and 'zst' not in p.get('fileType','').lower() and 'musl' in p.get('download',''):
        print(p['download'])
        break
" 2>/dev/null)
  # Fallback to glibc version
  if [[ -z "$download_path" ]]; then
    download_path=$(echo "$manifest" | python3 -c "
import json,sys
d=json.load(sys.stdin)
for p in d['packages']:
    if p.get('architecture')=='aarch64' and p.get('os')=='linux' and 'tar' in p.get('fileType','').lower() and 'xz' not in p.get('fileType','').lower() and 'zst' not in p.get('fileType','').lower() and 'musl' not in p.get('download',''):
        print(p['download'])
        break
" 2>/dev/null)
  fi

  if [[ -z "$download_path" ]]; then
    log_error "No compatible package found for $arch"
    return 1
  fi

  local tmpdir
  tmpdir=$(mktemp -d)
  log_info "Downloading Kiro (this may take a while)..."

  if curl -fsSL --connect-timeout 15 --max-time 300 \
    "https://prod.download.cli.kiro.dev/stable/$download_path" \
    -o "$tmpdir/kiro.tar.gz" 2>>"$LOG_FILE"; then

    if tar xzf "$tmpdir/kiro.tar.gz" -C "$tmpdir" 2>>"$LOG_FILE"; then
      local bin_path
      bin_path=$(find "$tmpdir" -name "kiro-cli" -type f -executable 2>/dev/null | head -1)
      if [[ -z "$bin_path" ]]; then
        bin_path=$(find "$tmpdir" -name "kiro*" -type f -executable 2>/dev/null | head -1)
      fi
      if [[ -n "$bin_path" ]]; then
        rm -f "$PREFIX/bin/kiro" "$PREFIX/bin/kiro-cli"
        cp "$bin_path" "$PREFIX/bin/kiro-cli"
        chmod +x "$PREFIX/bin/kiro-cli"
        # Create symlink for convenience
        ln -sf "$PREFIX/bin/kiro-cli" "$PREFIX/bin/kiro"
        rm -rf "$tmpdir"
        if command -v kiro-cli &>/dev/null || command -v kiro &>/dev/null; then
          log_success "Kiro installed from direct download"
          return 0
        fi
        # Binary exists but can't execute (missing glibc)
        if [[ -f "$PREFIX/bin/kiro-cli" ]]; then
          log_warn "Kiro binary installed but requires glibc to run"
          log_info "Install glibc: ${D_CYAN}pkg install glibc-repo glibc${NC}"
          log_info "Or use proot: ${D_CYAN}proot-distro install ubuntu${NC}"
          return 0
        fi
      fi
    fi
  fi

  rm -rf "$tmpdir"
  log_error "Failed to install Kiro"
  log_info "You can try manually: curl -fsSL https://cli.kiro.dev/install | bash"
  return 1
}

uninstall_kiro() {
  if ! command -v kiro &>/dev/null && ! command -v kiro-cli &>/dev/null; then
    log_info "Kiro is not installed"
    return 0
  fi

  log_info "Uninstalling Kiro..."
  rm -f "$PREFIX/bin/kiro" "$PREFIX/bin/kiro-cli"
  log_success "Kiro uninstalled"
  return 0
}

update_kiro() {
  _check_update_needed "Kiro CLI" "$(_get_installed_version kiro)" "$(_get_remote_github_version kiro-dev/kiro-cli)" _update_kiro_impl
}

_update_kiro_impl() {
  uninstall_kiro
  install_kiro
}

reinstall_kiro() {
  uninstall_kiro
  install_kiro
}
