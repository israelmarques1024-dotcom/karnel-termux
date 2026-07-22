#!/usr/bin/env bash

import "@/utils/log"
import "@/utils/version"

LOG_FILE="$KARNEL_CACHE/install_ai.log"
HERMES_HOME="$HOME/.hermes"
HERMES_DIR="$HERMES_HOME/hermes-agent"

_patch_psutil_for_termux() {
  python3 -c "import psutil; print(psutil.__version__)" 2>/dev/null && return 0
  local tmp="$PREFIX/tmp/psutil_patch"
  mkdir -p "$tmp"
  pip download psutil==7.2.2 --no-binary :all: --no-deps -d "$tmp" 2>/dev/null
  tar xzf "$tmp/psutil-7.2.2.tar.gz" -C "$tmp"
  sed -i 's/LINUX = sys.platform.startswith("linux")/LINUX = sys.platform.startswith(("linux", "android"))/' "$tmp/psutil-7.2.2/psutil/_common.py"
  pip install "$tmp/psutil-7.2.2"
  rm -rf "$tmp"
}

_prebuild_c_exts() {
  for pkg in ruamel.yaml.clib uvloop tornado; do
    pip install "$pkg" 2>/dev/null
  done
}

_install_hermes_agent_impl() {
  mkdir -p "$HERMES_HOME"

  # 1. Clone/pull repo
  if [ -d "$HERMES_DIR/.git" ]; then
    cd "$HERMES_DIR" && git pull
  else
    git clone https://github.com/NousResearch/hermes-agent.git "$HERMES_DIR"
  fi

  cd "$HERMES_DIR"

  # 2. Patch Python version constraint (3.14 compat)
  sed -i 's/requires-python = ">=3\.11,<3\.14"/requires-python = ">=3.11,<3.15"/' pyproject.toml

  # 3. Pre-build C extensions that OOM when built together
  _patch_psutil_for_termux
  _prebuild_c_exts

  # 4. Install (no constraints file — it hangs on Termux network)
  pip install --no-build-isolation .

  # 5. Create wrapper (pip skipped it due to --no-build-isolation)
  cat > "$PREFIX/bin/hermes" <<-WRAPPER
	#!/data/data/com.termux/files/usr/bin/python3
	from hermes_cli.main import main
	main()
	WRAPPER
  chmod +x "$PREFIX/bin/hermes"
}

install_hermes_agent() {
  if command -v hermes &>/dev/null; then
    log_info "Hermes Agent is already installed"
    return 2
  fi

  log_info "Installing Hermes Agent (gambiarra Termux)..."
  mkdir -p "$(dirname "$LOG_FILE")"

  loading "Installing Hermes Agent" _install_hermes_agent_impl

  if command -v hermes &>/dev/null; then
    log_success "Hermes Agent installed successfully"
    return 0
  else
    log_error "Failed to install Hermes Agent"
    return 1
  fi
}

uninstall_hermes_agent() {
  if ! command -v hermes &>/dev/null; then
    log_info "Hermes Agent is not installed"
    return 2
  fi
  log_info "Uninstalling Hermes Agent..."
  mkdir -p "$(dirname "$LOG_FILE")"

  loading "Removing Hermes Agent" _uninstall_hermes_agent_impl

  log_success "Hermes Agent uninstalled successfully"
  return 0
}

_uninstall_hermes_agent_impl() {
  if rm -rf "$HERMES_HOME" && rm -f "$PREFIX/bin/hermes" &>>"$LOG_FILE"; then
    return 0
  else
    log_error "Failed to uninstall Hermes Agent"
    return 1
  fi
}

update_hermes_agent() {
  _check_update_needed "Hermes Agent" "$(_get_installed_git_version "$HERMES_DIR")" "$(_get_remote_github_version NousResearch/hermes-agent)" _update_hermes_agent_impl
}

_update_hermes_agent_impl() {
  if ! hermes update 2>/dev/null; then
    # Fallback: re-pull and re-install
    cd "$HERMES_DIR" && git pull
    pip install --no-build-isolation .
  fi
  return 0
}

reinstall_hermes_agent() {
  uninstall_hermes_agent
  install_hermes_agent
}
