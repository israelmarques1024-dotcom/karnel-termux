#!/data/data/com.termux/files/usr/bin/bash

import "@/utils/log"

LOG_FILE="$OMNI_CACHE/install_ai.log"

_veo3_dependencies() {
  loading "Installing dependencies" _veo3_dependencies_impl
}

_veo3_dependencies_impl() {
  declare -A DEPS=(
    ["python"]="python3"
    ["pip"]="pip"
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

_install_veo3_python() {
  loading "Installing Veo 3 SDK" _install_veo3_python_impl
}

_install_veo3_python_impl() {
  if ! pip install google-genai &>>"$LOG_FILE"; then
    log_error "Failed to install Veo 3 SDK"
    return 1
  fi
  return 0
}

install_veo3() {
  if pip show google-genai &>/dev/null; then
    log_info "Veo 3 SDK is already installed"
    return 2
  fi

  log_info "Installing Veo 3 SDK..."

  mkdir -p "$(dirname "$LOG_FILE")"

  _veo3_dependencies || return 1
  _install_veo3_python || return 1

  log_success "Veo 3 SDK installed successfully"
  log_info "Authenticate with: gcloud auth application-default login"
  return 0
}

uninstall_veo3() {
  if ! pip show google-genai &>/dev/null; then
    log_info "Veo 3 SDK is not installed"
    return 2
  fi

  log_info "Uninstalling Veo 3 SDK..."
  mkdir -p "$(dirname "$LOG_FILE")"

  loading "Removing Veo 3 SDK" _uninstall_veo3_impl

  log_success "Veo 3 SDK uninstalled"
  return 0
}

_uninstall_veo3_impl() {
  if ! pip uninstall google-genai -y &>>"$LOG_FILE"; then
    log_error "Failed to uninstall Veo 3 SDK"
    return 1
  fi
  return 0
}

update_veo3() {
  if ! pip show google-genai &>/dev/null; then
    log_error "Veo 3 SDK is not installed"
    return 1
  fi

  log_info "Updating Veo 3 SDK..."
  mkdir -p "$(dirname "$LOG_FILE")"

  loading "Updating Veo 3 SDK" _update_veo3_impl

  log_success "Veo 3 SDK updated"
  return 0
}

_update_veo3_impl() {
  if ! pip install --upgrade google-genai &>>"$LOG_FILE"; then
    log_error "Failed to update Veo 3 SDK"
    return 1
  fi
  return 0
}

reinstall_veo3() {
  uninstall_veo3
  install_veo3
}
