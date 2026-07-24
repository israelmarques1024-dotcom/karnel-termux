# shellcheck shell=bash

import "@/tools/plugins/install"

install_plugin_module() {
  separator
  box "Plugin Manager"
  separator
  log_info "The plugin manager is built in; no module installation is required."
  log_info "Use 'karnel plugin search' to discover approved plugins."
  log_info "Use 'karnel plugin install <name>' to install an approved plugin."
}

uninstall_plugin_module() {
  log_info "The plugin manager is built in. Remove individual plugins with: karnel plugin remove <name>"
}

update_plugin_module() {
  log_info "Updating approved plugins with atomic replacement..."
  update_all_plugins
}

reinstall_plugin_module() {
  local unsafe_flag="${1:-}"

  log_info "Reinstalling plugins with validated replacement..."
  reinstall_all_plugins "$unsafe_flag"
}
