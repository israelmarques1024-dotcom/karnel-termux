#!/usr/bin/env bash

import "@/utils/log"

HERDR_BIN="$PREFIX/bin/herdr"
HERDR_DATA_DIR="$KARNEL_DATA/herdr"
HERDR_MARKER="$HERDR_DATA_DIR/.karnel-managed"
HERDR_WRAPPER_MARKER="$HERDR_DATA_DIR/.karnel-wrapper-herdr"
HERDR_MANIFEST_URL="https://herdr.dev/latest.json"

_herdr_binary_owned() {
  [[ -f "$HERDR_WRAPPER_MARKER" && -f "$HERDR_BIN" ]] || return 1
  [[ "$(sha256sum "$HERDR_BIN" 2>/dev/null)" == "$(<"$HERDR_WRAPPER_MARKER")" ]]
}

_herdr_verify_ownership() {
  if [[ -e "$HERDR_DATA_DIR" && ! -f "$HERDR_MARKER" ]]; then
    log_error "Refusing to replace unowned data directory: $HERDR_DATA_DIR"
    return 1
  fi
  if [[ -e "$HERDR_BIN" ]] && ! _herdr_binary_owned; then
    log_error "Refusing to replace unowned command: $HERDR_BIN"
    return 1
  fi
}

_herdr_detect_target() {
  local os arch
  os="$(uname -s | tr '[:upper:]' '[:lower:]')"
  [[ "$os" == "linux" ]] || {
    log_error "Herdr supports Linux/macOS; this system reports: $os"
    return 1
  }
  arch="$(uname -m)"
  case "$arch" in
    aarch64 | arm64) arch="aarch64" ;;
    x86_64 | amd64) arch="x86_64" ;;
    *) log_error "Unsupported architecture for Herdr: $arch"; return 1 ;;
  esac
  printf 'linux-%s' "$arch"
}

_herdr_resolve() {
  local target="$1" manifest tmpf rc
  manifest="$(curl -fsSL --retry 3 --connect-timeout 10 --max-time 20 "$HERDR_MANIFEST_URL" 2>/dev/null)" || return 1
  tmpf="$(mktemp "${KARNEL_CACHE}/.herdr-manifest.XXXXXX")" || return 1
  printf '%s' "$manifest" >"$tmpf"
  python3 -c '
import sys, json
with open(sys.argv[1]) as fh:
    data = json.load(fh)
target = sys.argv[2]
assets = data.get("assets", {})
sha = data.get("sha256", {})
url = assets.get(target)
digest = sha.get(target)
version = data.get("version")
if not url or not digest:
    sys.exit(1)
print(url)
print(digest)
print(version or "")
' "$tmpf" "$target"
  rc=$?
  rm -f "$tmpf"
  return $rc
}

_herdr_download_and_install() {
  local target="$1" info url sha version tmp actual temporary_bin

  info="$(_herdr_resolve "$target")" || {
    log_error "Failed to resolve the Herdr release for $target"
    return 1
  }
  url="$(printf '%s' "$info" | sed -n '1p')"
  sha="$(printf '%s' "$info" | sed -n '2p')"
  version="$(printf '%s' "$info" | sed -n '3p')"

  if [[ ! "$sha" =~ ^[0-9a-fA-F]{64}$ ]]; then
    log_error "Herdr release manifest did not include a valid SHA-256 for $target"
    return 1
  fi
  sha="${sha,,}"

  mkdir -p "$KARNEL_DATA" "$PREFIX/bin" "${KARNEL_CACHE}" || return 1
  _herdr_verify_ownership || return 1

  tmp="$(mktemp -d "${KARNEL_CACHE}/.herdr.XXXXXX")" || return 1
  if ! curl -fsSL --retry 3 --connect-timeout 10 --max-time 120 "$url" -o "$tmp/herdr"; then
    rm -rf "$tmp"
    log_error "Failed to download Herdr from $url"
    return 1
  fi

  actual="$(sha256sum "$tmp/herdr" 2>/dev/null | awk '{print $1}')"
  if [[ "$actual" != "$sha" ]]; then
    rm -rf "$tmp"
    log_error "Herdr checksum verification failed (expected $sha, got $actual)"
    return 1
  fi

  temporary_bin="$(mktemp "$PREFIX/bin/.herdr.XXXXXX")" || { rm -rf "$tmp"; return 1; }
  if ! install -m 755 "$tmp/herdr" "$temporary_bin" || ! mv -f "$temporary_bin" "$HERDR_BIN"; then
    rm -f "$temporary_bin"
    rm -rf "$tmp"
    log_error "Failed to install the Herdr binary"
    return 1
  fi

  mkdir -p "$HERDR_DATA_DIR" || return 1
  sha256sum "$HERDR_BIN" >"$HERDR_WRAPPER_MARKER" || return 1
  : >"$HERDR_MARKER"
  rm -rf "$tmp"
}

install_herdr() {
  if command -v herdr &>/dev/null; then
    log_info "Herdr is already installed"
    return 2
  fi

  local target
  target="$(_herdr_detect_target)" || return 1

  log_info "Installing Herdr..."
  _herdr_download_and_install "$target" || return 1
  log_success "Herdr installed"
}

uninstall_herdr() {
  if [[ ! -e "$HERDR_BIN" && ! -d "$HERDR_DATA_DIR" ]]; then
    log_info "Herdr is not installed"
    return 2
  fi

  if _herdr_binary_owned && ! rm -f "$HERDR_BIN"; then
    log_error "Failed to remove the Herdr command"
    return 1
  fi
  if [[ -f "$HERDR_MARKER" ]] && ! rm -rf "$HERDR_DATA_DIR"; then
    log_error "Failed to uninstall Herdr"
    return 1
  fi
  log_success "Herdr uninstalled"
}

update_herdr() {
  local target
  target="$(_herdr_detect_target)" || return 1

  log_info "Updating Herdr..."
  _herdr_download_and_install "$target" || return 1
  log_success "Herdr updated"
}

reinstall_herdr() {
  uninstall_herdr || [[ $? -eq 2 ]] || return 1
  install_herdr
}
