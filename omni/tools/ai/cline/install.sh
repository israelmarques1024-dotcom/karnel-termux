#!/usr/bin/env bash

import "@/utils/log"
import "@/utils/colors"

LOG_FILE="$OMNI_CACHE/install_ai.log"

_cline_detect_ubuntu_root() {
  local root
  root="$(find /data/data/com.termux -maxdepth 10 -type d \
    -name "rootfs" -path "*/containers/ubuntu/*" 2>/dev/null | head -1)"

  if [ -z "$root" ]; then
    root="$(find /data/data/com.termux -maxdepth 10 -type d \
      -name "ubuntu" -path "*/installed-rootfs/*" 2>/dev/null | head -1)"
  fi

  echo "$root"
}

_cline_proot_ubuntu() {
  # Usa proot direto em vez de proot-distro login para evitar
  # bloqueio de execucao aninhada
  local root
  root="$(_cline_detect_ubuntu_root)"
  if [ -z "$root" ]; then
    log_error "Ubuntu container not found"
    return 1
  fi
  exec proot -r "$root" \
    -b /proc \
    -b /sys \
    -b /dev \
    -b /data:/data \
    -b /data/data/com.termux/files/home:/home/termux \
    -w /home/termux \
    "$@"
}

_cline_install_deps() {
  loading "Installing dependencies" _cline_install_deps_impl
}

_cline_install_deps_impl() {
  if ! command -v proot-distro &>/dev/null; then
    if ! pkg install proot-distro -y &>>"$LOG_FILE"; then
      log_error "Failed to install proot-distro"
      return 1
    fi
  fi

  if [ ! -d "$(_cline_detect_ubuntu_root)" ]; then
    loading "Installing Ubuntu container" _cline_install_ubuntu
  fi

  declare -A DEPS=(
    ["nodejs-lts"]="node"
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

_cline_install_global() {
  loading "Installing Cline CLI via npm" _cline_install_global_impl
}

_cline_install_global_impl() {
  # Step 1: Install cline via npm global
  if ! npm i -g cline &>>"$LOG_FILE"; then
    log_error "Failed to install cline via npm"
    return 1
  fi

  # Step 2: Download linux-arm64 binary (required for glibc/proot)
  local version
  version=$(npm view cline version 2>/dev/null || echo "3.0.38")
  local tarball="/tmp/cline-linux-arm64.tgz"
  if ! curl -fsSL \
    "https://registry.npmjs.org/@cline/cli-linux-arm64/-/cli-linux-arm64-${version}.tgz" \
    -o "$tarball" &>>"$LOG_FILE"; then
    log_error "Failed to download cline linux-arm64 binary (version: $version)"
    return 1
  fi

  # Step 3: Extract to global node_modules
  mkdir -p /data/data/com.termux/files/usr/lib/node_modules/@cline
  tar -xzf "$tarball" \
    -C /data/data/com.termux/files/usr/lib/node_modules/@cline/ &>>"$LOG_FILE"
  mv /data/data/com.termux/files/usr/lib/node_modules/@cline/package \
    /data/data/com.termux/files/usr/lib/node_modules/@cline/cli-linux-arm64 &>>"$LOG_FILE" || true
  rm -f "$tarball"

  # Step 4: Create cached binary for fast startup
  local binary="/data/data/com.termux/files/usr/lib/node_modules/@cline/cli-linux-arm64/bin/cline"
  local cached="/data/data/com.termux/files/usr/lib/node_modules/cline/bin/.cline"
  if [ -f "$binary" ]; then
    cp "$binary" "$cached" 2>/dev/null
    chmod 755 "$cached" 2>/dev/null
  fi

  # Step 5: Create proot wrapper (overwrites the npm-installed stub)
  _cline_create_wrapper

  return 0
}

_cline_create_wrapper() {
  cat > "$PREFIX/bin/cline" << PROOTWRAPPER
#!/data/data/com.termux/files/usr/bin/env bash
# Cline CLI wrapper — executa o binario glibc dentro do container Ubuntu via proot
# Gambi inteligente: usa proot direto (nao proot-distro) pra evitar bloqueio de
# execucao aninhada quando rodando dentro de outro PRoot.
# Instalado pelo Omni Catalyst (omni install ai --cline)

UBUNTU_ROOT="/data/data/com.termux/files/usr/var/lib/proot-distro/containers/ubuntu/rootfs"
CLINE_BIN="/data/data/com.termux/files/usr/lib/node_modules/@cline/cli-linux-arm64/bin/cline"

if [ ! -d "\$UBUNTU_ROOT" ]; then
  echo "Erro: Container Ubuntu nao encontrado em \$UBUNTU_ROOT"
  echo "Rode: proot-distro install ubuntu:24.04"
  exit 1
fi

if [ ! -f "\$CLINE_BIN" ]; then
  echo "Erro: Cline binary nao encontrado em \$CLINE_BIN"
  echo "Rode: npm i -g cline"
  exit 1
fi

exec proot -r "\$UBUNTU_ROOT" \
  -b /proc \
  -b /sys \
  -b /dev \
  -b /data:/data \
  -b /data/data/com.termux/files/home:/home/termux \
  -w /home/termux \
  "\$CLINE_BIN" "\$@"
PROOTWRAPPER
  chmod 755 "$PREFIX/bin/cline"
}

_cline_install_ubuntu() {
  proot-distro install ubuntu:24.04 &>>"$LOG_FILE"
}

install_cline() {
  if grep -q 'CLINE_BIN=' "$PREFIX/bin/cline" 2>/dev/null; then
    log_info "Cline is already installed"
    return 2
  fi
  log_info "Installing Cline CLI..."

  mkdir -p "$(dirname "$LOG_FILE")"

  _cline_install_deps || return 1
  _cline_install_global || return 1

  log_success "Cline CLI installed"
  return 0
}

uninstall_cline() {
  log_info "Uninstalling Cline CLI..."
  mkdir -p "$(dirname "$LOG_FILE")"

  if command -v cline &>/dev/null; then
    rm -f "$PREFIX/bin/cline"
  fi

  npm uninstall -g cline &>>"$LOG_FILE" || true
  rm -rf /data/data/com.termux/files/usr/lib/node_modules/@cline/cli-linux-arm64 &>>"$LOG_FILE" || true
  rm -f /data/data/com.termux/files/usr/lib/node_modules/cline/bin/.cline &>>"$LOG_FILE" || true

  log_success "Cline CLI uninstalled"
  return 0
}

update_cline() {
  log_info "Updating Cline CLI..."
  mkdir -p "$(dirname "$LOG_FILE")"

  loading "Updating Cline CLI" _update_cline_impl
  log_success "Cline CLI updated"
  return 0
}

_update_cline_impl() {
  if ! npm update -g cline &>>"$LOG_FILE"; then
    log_error "Failed to update cline"
    return 1
  fi

  # Re-download linux-arm64 binary and recreate wrapper
  _cline_install_global_impl || true
  return 0
}

reinstall_cline() {
  uninstall_cline
  install_cline
}
