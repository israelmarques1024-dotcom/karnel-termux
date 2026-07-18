#!/usr/bin/env bash

import "@/utils/log"
import "@/utils/version"
import "@/tools/osint/robin/common"

LOG_FILE="$KARNEL_CACHE/install_osint.log"
ROBIN_INSTALLER_DIR="$(dirname "${BASH_SOURCE[0]}")"
ROBIN_TERMUX_REQUIREMENTS="$ROBIN_INSTALLER_DIR/requirements-termux.txt"
ROBIN_STREAMLIT_VERSION="1.59.2"

_robin_package_installed() {
  [[ "$(dpkg-query -W -f='${db:Status-Abbrev}' "$1" 2>/dev/null)" == "ii " ]]
}

_robin_verify_termux() {
  if [[ ! -x "$PREFIX/bin/pkg" ]] || [[ "$PREFIX" != *"com.termux"* ]]; then
    log_error "Robin native installation requires a supported Termux environment"
    return 1
  fi

  local free_kb
  free_kb=$(df -Pk "$HOME" 2>/dev/null | awk 'NR == 2 { print $4 }')
  if [[ "$free_kb" =~ ^[0-9]+$ ]] && (( free_kb < 400000 )); then
    log_error "Robin requires at least 400 MB of free storage"
    return 1
  fi

  local architecture
  architecture=$(dpkg --print-architecture 2>/dev/null || printf 'unknown')
  if [[ "$architecture" != "aarch64" ]]; then
    log_warn "Robin is validated on Termux aarch64; detected: $architecture"
  fi
}

_robin_verify_python() {
  if ! command -v python3 &>/dev/null; then
    log_info "Installing Python..."
    pkg install python -y &>>"$LOG_FILE" || {
      log_error "Failed to install Python"
      return 1
    }
  fi

  local version major minor
  version=$(python3 -c 'import sys; print(f"{sys.version_info.major}.{sys.version_info.minor}")' 2>/dev/null) || {
    log_error "Could not determine the Python version"
    return 1
  }
  major=${version%%.*}
  minor=${version#*.}
  if (( major < 3 || (major == 3 && minor < 10) )); then
    log_error "Python 3.10+ is required. Found: $version"
    return 1
  fi

  python3 -c 'import venv' &>/dev/null || {
    log_error "The Python venv module is unavailable. Reinstall the Termux python package."
    return 1
  }
}

_robin_install_system_deps() {
  if ! _robin_package_installed tur-repo; then
    log_info "Enabling the Termux User Repository for native Python packages..."
    pkg install tur-repo -y &>>"$LOG_FILE" || {
      log_error "Failed to enable tur-repo"
      return 1
    }
  fi

  local -a required_packages=(
    git
    tor
    curl
    build-essential
    python-numpy
    python-pandas
    python-pillow
    python-pyarrow
  )
  local -a missing_packages=()
  local package
  for package in "${required_packages[@]}"; do
    _robin_package_installed "$package" || missing_packages+=("$package")
  done

  if (( ${#missing_packages[@]} > 0 )); then
    log_info "Installing native dependencies: ${missing_packages[*]}"
    pkg install "${missing_packages[@]}" -y &>>"$LOG_FILE" || {
      log_error "Failed to install Robin native dependencies"
      return 1
    }
  fi
}

_robin_migrate_path() {
  local source="$1"
  local destination="$2"
  local label="$3"
  [[ -e "$source" || -L "$source" ]] || return 0

  if [[ ! -e "$destination" && ! -L "$destination" ]]; then
    mv "$source" "$destination" || return 1
    return 0
  fi

  local migrated
  migrated="${destination}.migrated.$(date +%Y%m%d_%H%M%S)"
  mv "$source" "$migrated" || return 1
  log_warn "$label already existed; legacy data was preserved at $migrated"
}

_robin_migrate_legacy_layout() {
  _robin_refresh_layout
  [[ "$ROBIN_LAYOUT" == "legacy" ]] || return 0

  if _robin_runtime_active; then
    log_error "Stop Robin before migrating its installation: karnel robin stop"
    return 1
  fi

  log_info "Migrating Robin to the managed data layout..."
  mkdir -p "$ROBIN_CONFIG_DIR" "$ROBIN_DATA_DIR"
  chmod 700 "$ROBIN_CONFIG_DIR" "$ROBIN_DATA_DIR" 2>/dev/null || true

  _robin_migrate_path "$ROBIN_ROOT/.env" "$ROBIN_ENV_FILE" "Robin configuration" || return 1
  _robin_migrate_path "$ROBIN_ROOT/investigations" "$ROBIN_INVESTIGATIONS_DIR" "Robin investigations" || return 1

  local legacy_root="${ROBIN_ROOT}.legacy.$$"
  mv "$ROBIN_ROOT" "$legacy_root" || return 1
  mkdir -p "$ROBIN_ROOT" || {
    mv "$legacy_root" "$ROBIN_ROOT"
    return 1
  }

  if [[ -d "$legacy_root/.venv" ]]; then
    mv "$legacy_root/.venv" "$ROBIN_MANAGED_VENV_DIR" || {
      rm -rf "$ROBIN_ROOT"
      mv "$legacy_root" "$ROBIN_ROOT"
      _robin_refresh_layout
      _robin_prepare_persistent_data "$ROBIN_APP_DIR" || true
      return 1
    }
  fi

  mv "$legacy_root" "$ROBIN_MANAGED_APP_DIR" || {
    [[ -d "$ROBIN_MANAGED_VENV_DIR" ]] && mv "$ROBIN_MANAGED_VENV_DIR" "$legacy_root/.venv"
    rmdir "$ROBIN_ROOT" 2>/dev/null || true
    mv "$legacy_root" "$ROBIN_ROOT" 2>/dev/null || true
    _robin_refresh_layout
    _robin_prepare_persistent_data "$ROBIN_APP_DIR" || true
    log_error "Migration failed; the legacy installation was restored"
    return 1
  }
  (umask 077; printf '%s\n' "managed-by-karnel" > "$ROBIN_ROOT/.managed-by-karnel")
  chmod 700 "$ROBIN_ROOT"
  _robin_refresh_layout
  _robin_prepare_persistent_data "$ROBIN_APP_DIR" || return 1
  log_success "Robin configuration and investigations migrated without data loss"
}

_robin_prepare_persistent_data() {
  local app_dir="$1"
  mkdir -p "$ROBIN_CONFIG_DIR" "$ROBIN_DATA_DIR" "$ROBIN_INVESTIGATIONS_DIR"
  chmod 700 "$ROBIN_CONFIG_DIR" "$ROBIN_DATA_DIR" "$ROBIN_INVESTIGATIONS_DIR" 2>/dev/null || true

  if [[ ! -f "$ROBIN_ENV_FILE" ]]; then
    if [[ -f "$app_dir/.env.example" ]]; then
      cp "$app_dir/.env.example" "$ROBIN_ENV_FILE" || return 1
    else
      (umask 077; : > "$ROBIN_ENV_FILE") || return 1
    fi
  fi
  chmod 600 "$ROBIN_ENV_FILE" || return 1

  if [[ -e "$app_dir/.env" && ! -L "$app_dir/.env" ]]; then
    _robin_migrate_path "$app_dir/.env" "$ROBIN_ENV_FILE" "Robin configuration" || return 1
  fi
  rm -f "$app_dir/.env"
  ln -s "$ROBIN_ENV_FILE" "$app_dir/.env" || return 1

  if [[ -e "$app_dir/investigations" && ! -L "$app_dir/investigations" ]]; then
    _robin_migrate_path "$app_dir/investigations" "$ROBIN_INVESTIGATIONS_DIR" "Robin investigations" || return 1
  fi
  rm -f "$app_dir/investigations"
  ln -s "$ROBIN_INVESTIGATIONS_DIR" "$app_dir/investigations" || return 1

  if [[ -d "$app_dir/.git/info" ]]; then
    local exclude_file="$app_dir/.git/info/exclude"
    grep -qxF '.env' "$exclude_file" 2>/dev/null || printf '.env\n' >> "$exclude_file"
    grep -qxF 'investigations' "$exclude_file" 2>/dev/null || printf 'investigations\n' >> "$exclude_file"
  fi
}

_robin_clone_candidate() {
  local app_candidate="$1"
  log_info "Downloading Robin $ROBIN_VERSION..."
  git clone --branch "$ROBIN_VERSION" --depth 1 "$ROBIN_REPO" "$app_candidate" &>>"$LOG_FILE" || {
    log_error "Failed to clone Robin $ROBIN_VERSION"
    return 1
  }

  local actual_commit
  actual_commit=$(git -C "$app_candidate" rev-parse HEAD 2>/dev/null) || return 1
  if [[ "$actual_commit" != "$ROBIN_COMMIT" ]]; then
    log_error "Robin source verification failed"
    log_error "Expected $ROBIN_COMMIT but received $actual_commit"
    return 1
  fi
}

_robin_create_venv() {
  local venv_candidate="$1"
  log_info "Creating the Robin Python environment..."
  python3 -m venv --system-site-packages "$venv_candidate" &>>"$LOG_FILE" || {
    log_error "Failed to create the Robin virtual environment"
    return 1
  }
}

_robin_install_python_deps() {
  local venv_dir="$1"
  local python="$venv_dir/bin/python"
  [[ -x "$python" ]] || return 1
  [[ -f "$ROBIN_TERMUX_REQUIREMENTS" ]] || {
    log_error "Missing Termux requirements: $ROBIN_TERMUX_REQUIREMENTS"
    return 1
  }

  log_info "Installing Robin Python dependencies..."
  "$python" -m pip install --upgrade pip setuptools wheel &>>"$LOG_FILE" || return 1
  "$python" -m pip install -r "$ROBIN_TERMUX_REQUIREMENTS" &>>"$LOG_FILE" || return 1

  # Termux supplies pyarrow 25 natively. Streamlit's current metadata still
  # caps pyarrow below 25, although Robin does not use Arrow-specific APIs.
  "$python" -m pip install --no-deps "streamlit==$ROBIN_STREAMLIT_VERSION" &>>"$LOG_FILE" || return 1
}

_robin_verify_install() {
  local app_dir="${1:-$ROBIN_APP_DIR}"
  local venv_dir="${2:-$ROBIN_VENV_DIR}"
  local python="$venv_dir/bin/python"
  [[ -x "$python" && -f "$app_dir/ui.py" ]] || return 1
  "$venv_dir/bin/pip" --version &>>"$LOG_FILE" || return 1
  "$venv_dir/bin/streamlit" --version &>>"$LOG_FILE" || return 1

  PYTHONPATH="$app_dir" "$python" -c '
import altair
import bs4
import dotenv
import itsdangerous
import langchain_anthropic
import langchain_community
import langchain_google_genai
import langchain_ollama
import langchain_openai
import numpy
import pandas
import PIL
import pyarrow
import pydeck
import requests
import socks
import streamlit
import health
import llm
import llm_utils
import scrape
import search
' &>>"$LOG_FILE" || return 1

  local source
  for source in "$app_dir"/*.py; do
    "$python" -m py_compile "$source" &>>"$LOG_FILE" || return 1
  done
}

_robin_relocate_venv() {
  local old_path="$1"
  local new_path="$2"
  "$new_path/bin/python" - "$old_path" "$new_path" <<'PY'
from pathlib import Path
import sys

old = sys.argv[1].encode()
new = sys.argv[2].encode()
for path in (Path(sys.argv[2]) / "bin").iterdir():
    if path.is_symlink() or not path.is_file():
        continue
    try:
        content = path.read_bytes()
    except OSError:
        continue
    if old in content:
        path.write_bytes(content.replace(old, new))
PY
}

_robin_candidate_health() {
  local app_dir="$1"
  local venv_dir="$2"
  local python="$venv_dir/bin/python"
  local port
  port=$(
    "$python" -c 'import socket; s=socket.socket(); s.bind(("127.0.0.1", 0)); print(s.getsockname()[1]); s.close()'
  ) || return 1

  local test_log="$ROBIN_ROOT/.health-check.log"
  (
    cd "$app_dir" || exit 1
    "$python" -m streamlit run ui.py \
      --server.address 127.0.0.1 \
      --server.port "$port" \
      --server.headless true \
      --server.fileWatcherType none \
      --browser.gatherUsageStats false
  ) &>"$test_log" &
  local pid=$!

  local healthy=false
  local attempt
  for ((attempt = 0; attempt < 45; attempt++)); do
    if ! kill -0 "$pid" 2>/dev/null; then
      break
    fi
    if curl --fail --silent --max-time 2 "http://127.0.0.1:$port/_stcore/health" 2>/dev/null | grep -qx "ok"; then
      healthy=true
      break
    fi
    sleep 1
  done

  kill "$pid" 2>/dev/null || true
  for ((attempt = 0; attempt < 10; attempt++)); do
    kill -0 "$pid" 2>/dev/null || break
    sleep 1
  done
  if kill -0 "$pid" 2>/dev/null; then
    kill -9 "$pid" 2>/dev/null || true
  fi
  if kill -0 "$pid" 2>/dev/null; then
    log_error "Could not terminate the temporary Streamlit health process"
    return 1
  fi
  wait "$pid" 2>/dev/null || true
  if $healthy; then
    rm -f "$test_log"
    return 0
  fi

  log_error "Streamlit health check failed. Details: $test_log"
  return 1
}

_robin_swap_candidate() {
  local app_candidate="$1"
  local venv_candidate="$2"
  local app_backup="$ROBIN_ROOT/.app-backup.$$"
  local venv_backup="$ROBIN_ROOT/.venv-backup.$$"

  local had_app=false
  local had_venv=false
  if [[ -d "$ROBIN_MANAGED_APP_DIR" ]]; then
    mv "$ROBIN_MANAGED_APP_DIR" "$app_backup" || {
      log_error "Could not back up the active Robin source"
      return 1
    }
    had_app=true
  fi
  if [[ -d "$ROBIN_MANAGED_VENV_DIR" ]]; then
    if ! mv "$ROBIN_MANAGED_VENV_DIR" "$venv_backup"; then
      $had_app && mv "$app_backup" "$ROBIN_MANAGED_APP_DIR"
      log_error "Could not back up the active Robin environment"
      return 1
    fi
    had_venv=true
  fi

  if ! mv "$app_candidate" "$ROBIN_MANAGED_APP_DIR"; then
    $had_app && mv "$app_backup" "$ROBIN_MANAGED_APP_DIR"
    $had_venv && mv "$venv_backup" "$ROBIN_MANAGED_VENV_DIR"
    log_error "Failed to activate the new Robin source; previous version restored"
    return 1
  fi
  if ! mv "$venv_candidate" "$ROBIN_MANAGED_VENV_DIR"; then
    rm -rf "$ROBIN_MANAGED_APP_DIR"
    $had_app && mv "$app_backup" "$ROBIN_MANAGED_APP_DIR"
    $had_venv && mv "$venv_backup" "$ROBIN_MANAGED_VENV_DIR"
    log_error "Failed to activate the new Robin installation; previous version restored"
    return 1
  fi

  if ! _robin_relocate_venv "$venv_candidate" "$ROBIN_MANAGED_VENV_DIR"; then
    rm -rf "$ROBIN_MANAGED_APP_DIR" "$ROBIN_MANAGED_VENV_DIR"
    [[ -d "$app_backup" ]] && mv "$app_backup" "$ROBIN_MANAGED_APP_DIR"
    [[ -d "$venv_backup" ]] && mv "$venv_backup" "$ROBIN_MANAGED_VENV_DIR"
    log_error "Failed to relocate the Robin environment; previous version restored"
    return 1
  fi

  _robin_refresh_layout
  if ! _robin_verify_install; then
    rm -rf "$ROBIN_MANAGED_APP_DIR" "$ROBIN_MANAGED_VENV_DIR"
    [[ -d "$app_backup" ]] && mv "$app_backup" "$ROBIN_MANAGED_APP_DIR"
    [[ -d "$venv_backup" ]] && mv "$venv_backup" "$ROBIN_MANAGED_VENV_DIR"
    _robin_refresh_layout
    log_error "Final Robin verification failed; previous version restored"
    return 1
  fi

  rm -rf "$app_backup" "$venv_backup"
  (umask 077; printf 'version=%s\ncommit=%s\n' "$ROBIN_VERSION" "$ROBIN_COMMIT" > "$ROBIN_ROOT/.managed-by-karnel")
}

_robin_install_release() {
  _robin_verify_termux || return 1
  _robin_verify_python || return 1
  _robin_install_system_deps || return 1
  _robin_migrate_legacy_layout || return 1

  if _robin_runtime_active; then
    log_error "Stop Robin before changing its installation: karnel robin stop"
    return 1
  fi

  mkdir -p "$ROBIN_ROOT" "$KARNEL_CACHE"
  chmod 700 "$ROBIN_ROOT" 2>/dev/null || true
  local app_candidate="$ROBIN_ROOT/.app-candidate.$$"
  local venv_candidate="$ROBIN_ROOT/.venv-candidate.$$"
  rm -rf "$app_candidate" "$venv_candidate"

  if ! _robin_clone_candidate "$app_candidate" ||
     ! _robin_prepare_persistent_data "$app_candidate" ||
     ! _robin_create_venv "$venv_candidate" ||
     ! _robin_install_python_deps "$venv_candidate" ||
     ! _robin_verify_install "$app_candidate" "$venv_candidate" ||
     ! _robin_candidate_health "$app_candidate" "$venv_candidate"; then
    rm -rf "$app_candidate" "$venv_candidate"
    log_error "Robin installation failed without changing the active version"
    log_info "Installation log: $LOG_FILE"
    return 1
  fi

  _robin_swap_candidate "$app_candidate" "$venv_candidate"
}

_robin_current_release() {
  _robin_refresh_layout
  [[ "$ROBIN_LAYOUT" == "managed" ]] || return 1
  [[ -d "$ROBIN_APP_DIR/.git" ]] || return 1
  [[ "$(git -C "$ROBIN_APP_DIR" rev-parse HEAD 2>/dev/null)" == "$ROBIN_COMMIT" ]] || return 1
  _robin_verify_install
}

_robin_show_success() {
  echo
  box "Robin instalado com sucesso"
  echo
  log_success "Release validada: $ROBIN_VERSION"
  log_info "Configure um provedor: karnel robin config"
  log_info "Execute o diagnostico: karnel robin doctor"
  log_info "Inicie a interface: karnel robin start"
  log_info "Abra: http://127.0.0.1:$ROBIN_PORT"
  echo
  log_info "Configuracao e investigacoes ficam fora do codigo e sobrevivem a reinstalacoes."
  echo
}

install_robin() {
  mkdir -p "$(dirname "$LOG_FILE")"
  _robin_acquire_lock || return 1
  if _robin_current_release; then
    log_info "Robin $ROBIN_VERSION is already installed and healthy"
    _robin_release_lock
    return 2
  fi

  local rc=0
  log_info "Installing Robin $ROBIN_VERSION..."
  _robin_install_release || rc=$?
  _robin_release_lock
  if (( rc == 0 )); then
    _robin_show_success
  fi
  return "$rc"
}

uninstall_robin() {
  _robin_refresh_layout
  if [[ ! -d "$ROBIN_APP_DIR" && ! -d "$ROBIN_VENV_DIR" ]]; then
    log_info "Robin is not installed"
    return 2
  fi

  _robin_acquire_lock || return 1
  local rc=0
  _robin_migrate_legacy_layout || rc=$?
  if (( rc == 0 )) && _robin_runtime_active; then
    log_error "Stop Robin before uninstalling it: karnel robin stop"
    rc=1
  fi

  if (( rc == 0 )); then
    rm -rf "$ROBIN_MANAGED_APP_DIR" "$ROBIN_MANAGED_VENV_DIR"
    rm -f "$ROBIN_PID_FILE"
    log_success "Robin application removed"
    log_info "Configuration preserved at: $ROBIN_CONFIG_DIR"
    log_info "Investigations preserved at: $ROBIN_INVESTIGATIONS_DIR"
  fi
  _robin_release_lock
  return "$rc"
}

update_robin() {
  _robin_refresh_layout
  if [[ ! -d "$ROBIN_APP_DIR" ]]; then
    log_error "Robin is not installed. Run: karnel install osint --robin"
    return 1
  fi
  _robin_acquire_lock || return 1
  if _robin_current_release; then
    log_info "Robin $ROBIN_VERSION is already up to date and healthy"
    _robin_release_lock
    return 2
  fi

  local rc=0
  log_info "Reconciling Robin with pinned release $ROBIN_VERSION..."
  _robin_install_release || rc=$?
  _robin_release_lock
  if (( rc == 0 )); then
    log_success "Robin updated to $ROBIN_VERSION"
  fi
  return "$rc"
}

reinstall_robin() {
  _robin_acquire_lock || return 1
  local rc=0
  log_info "Reinstalling Robin $ROBIN_VERSION without deleting user data..."
  _robin_install_release || rc=$?
  _robin_release_lock
  if (( rc == 0 )); then
    _robin_show_success
  fi
  return "$rc"
}
