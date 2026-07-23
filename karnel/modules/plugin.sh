install_plugin_module() {
  separator
  box "Plugin Manager"
  separator

  log_info "Plugin system is built-in. No additional installation needed."
  echo
  log_info "Installing example plugin..."
  install_plugin "israelmarques1024-dotcom/karnel-termux" || true
}

uninstall_plugin_module() {
  log_info "Plugin system is built-in. Nothing to uninstall."
}

update_plugin_module() {
  log_info "Updating all plugins..."
  mkdir -p "$PLUGINS_DIR"
  for dir in "$PLUGINS_DIR"/*/; do
    [[ -d "$dir" ]] || continue
    local name; name="$(basename "$dir")"
    update_plugin "$name"
  done
}

reinstall_plugin_module() {
  log_info "Reinstalling all plugins..."
  mkdir -p "$PLUGINS_DIR"
  for dir in "$PLUGINS_DIR"/*/; do
    [[ -d "$dir" ]] || continue
    local name; name="$(basename "$dir")"
    reinstall_plugin "$name"
  done
}
