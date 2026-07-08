#!/usr/bin/env bash

import "@/utils/log"
import "@/utils/colors"

LOG_FILE="$OMNI_CACHE/install_ai.log"

_cline_install_deps() {
  loading "Installing dependencies" _cline_install_deps_impl
}

_cline_install_deps_impl() {
  declare -A DEPS=(
    ["nodejs-lts"]="node"
    ["glibc-repo"]=""
    ["glibc-runner"]="glibc-runner"
    ["glibc"]=""
  )

  local pkg_name bin_name
  for pkg_name in "${!DEPS[@]}"; do
    bin_name="${DEPS[$pkg_name]}"
    if [ -n "$bin_name" ] && command -v "$bin_name" &>/dev/null; then
      continue
    fi
    if ! pkg install "$pkg_name" -y &>>"$LOG_FILE"; then
      log_error "Failed to install $pkg_name"
      return 1
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

  # Step 2: Download linux-arm64 binary (glibc binary, roda via glibc-runner)
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

  # Step 5: Create wrapper usando glibc-runner (sem proot!)
  _cline_create_wrapper

  return 0
}

_cline_create_wrapper() {
  cat > "$PREFIX/bin/cline" << 'GLIBCWRAPPER'
#!/data/data/com.termux/files/usr/bin/env bash
# Cline CLI — roda nativamente no Termux via glibc-runner
# Usa o glibc do termux-user-repository (instalado via apt)
# Sem proot, sem container, sem opencode.
# Instalado pelo Omni Catalyst (omni install ai --cline)

CLINE_BIN="/data/data/com.termux/files/usr/lib/node_modules/cline/bin/.cline"

if [ ! -f "$CLINE_BIN" ]; then
  CLINE_BIN="/data/data/com.termux/files/usr/lib/node_modules/@cline/cli-linux-arm64/bin/cline"
fi

if [ ! -f "$CLINE_BIN" ]; then
  echo "Erro: Cline binary nao encontrado"
  echo "Rode: npm i -g cline"
  exit 1
fi

exec glibc-runner "$CLINE_BIN" "$@"
GLIBCWRAPPER
  chmod 755 "$PREFIX/bin/cline"
}

install_cline() {
  if grep -q 'glibc-runner' "$PREFIX/bin/cline" 2>/dev/null; then
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
