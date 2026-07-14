#!/usr/bin/env bash

import "@/utils/log"
import "@/utils/version"

LOG_FILE="$KARNEL_CACHE/install_dev.log"
ZORK_DATA_DIR="$HOME/.local/share/karnel-data/zork"

ZORK_URLS=(
  "1:http://www.infocom-if.org/downloads/zork1.zip"
  "2:http://www.infocom-if.org/downloads/zork2.zip"
  "3:http://www.infocom-if.org/downloads/zork3.zip"
)

_install_zork_deps() {
  loading "Installing dependencies" _install_zork_deps_impl
}

_install_zork_deps_impl() {
  if ! command -v frotz &>/dev/null; then
    if ! pkg install frotz -y &>>"$LOG_FILE"; then
      log_error "Failed to install frotz"
      return 1
    fi
  fi
  if ! command -v unzip &>/dev/null; then
    if ! pkg install unzip -y &>>"$LOG_FILE"; then
      log_error "Failed to install unzip"
      return 1
    fi
  fi
  return 0
}

_download_zork_data() {
  loading "Downloading Zork games" _download_zork_data_impl
}

_download_zork_data_impl() {
  mkdir -p "$ZORK_DATA_DIR"

  for entry in "${ZORK_URLS[@]}"; do
    local num="${entry%%:*}"
    local url="${entry#*:}"
    local zip_file="$ZORK_DATA_DIR/zork${num}.zip"

    if [ -f "$ZORK_DATA_DIR/DATA/ZORK${num}.DAT" ]; then
      continue
    fi

    if ! curl -fsSL "$url" -o "$zip_file" &>>"$LOG_FILE"; then
      log_error "Failed to download Zork ${num}"
      return 1
    fi

    if ! unzip -o "$zip_file" -d "$ZORK_DATA_DIR" &>>"$LOG_FILE"; then
      log_error "Failed to extract Zork ${num}"
      return 1
    fi

    rm -f "$zip_file"
  done

  return 0
}

_create_zork_wrapper() {
  local wrapper="$PREFIX/bin/zork"
  cat > "$wrapper" << 'WRAPPER'
#!/usr/bin/env bash
ZORK_DIR="$HOME/.local/share/karnel-data/zork"
ROM_DIR="$ZORK_DIR/DATA"

if [ ! -d "$ROM_DIR" ]; then
  echo "Zork data not found. Run: karnel install zork"
  exit 1
fi

case "${1:-1}" in
  1|I|i) game="ZORK1.DAT" ;;
  2|II|ii) game="ZORK2.DAT" ;;
  3|III|iii) game="ZORK3.DAT" ;;
  *) echo "Usage: zork [1|2|3] (default: 1)"; exit 1 ;;
esac

shift 2>/dev/null || true
exec frotz "$ROM_DIR/$game" "$@"
WRAPPER
  chmod +x "$wrapper"
}

install_zork() {
  if command -v zork &>/dev/null; then
    log_info "Zork is already installed"
    return 2
  fi
  log_info "Installing Zork..."

  mkdir -p "$(dirname "$LOG_FILE")"

  _install_zork_deps || return 1
  _download_zork_data || return 1
  _create_zork_wrapper || return 1
  log_success "Zork installed"
  return 0
}

uninstall_zork() {
  if ! command -v zork &>/dev/null; then
    log_info "Zork is not installed"
    return 2
  fi
  log_info "Uninstalling Zork..."

  rm -f "$PREFIX/bin/zork"
  rm -rf "$ZORK_DATA_DIR"

  log_success "Zork uninstalled"
  return 0
}

update_zork() {
  log_info "Updating Zork..."
  rm -rf "$ZORK_DATA_DIR"
  _download_zork_data || return 1
  log_success "Zork updated"
  return 0
}

reinstall_zork() {
  uninstall_zork
  install_zork
}
