#!/data/data/com.termux/files/usr/bin/bash

import "@/utils/log"
import "@/utils/colors"

LOG_FILE="$OMNI_CACHE/install_deploy.log"

install_deploy() {
  separator
  box "Installing Deploy CLIs"
  separator

  log_info "Installing deploy tools (Vercel, Railway, Netlify)..."
  mkdir -p "$(dirname "$LOG_FILE")"
  _install_deploy_wrapper
  log_success "Deploy tools installed"
  separator
}

_install_deploy_wrapper() {
  import "@/tools/deploy/all"
  install_all_deploy_tools
}

uninstall_deploy() {
  separator
  box "Uninstalling Deploy CLIs"
  separator
  import "@/tools/deploy/all"
  uninstall_all_deploy_tools
  separator
}

update_deploy() {
  separator
  box "Updating Deploy CLIs"
  separator
  import "@/tools/deploy/all"
  update_all_deploy_tools
  separator
}

reinstall_deploy() {
  separator
  box "Reinstalling Deploy CLIs"
  separator
  import "@/tools/deploy/all"
  reinstall_all_deploy_tools
  separator
}
