import "@/tools/plugins/install"

plugin_main() {
  if [[ $# -eq 0 ]]; then
    plugin_help
    return
  fi

  local subcmd="$1"
  shift

  case "$subcmd" in
  install)
    if [[ $# -lt 1 ]]; then
      log_error "Usage: karnel plugin install <user/repo>"
      return 1
    fi
    install_plugin "$1"
    ;;
  remove|uninstall)
    if [[ $# -lt 1 ]]; then
      log_error "Usage: karnel plugin remove <name>"
      return 1
    fi
    uninstall_plugin "$1"
    ;;
  update)
    if [[ $# -lt 1 ]]; then
      log_error "Usage: karnel plugin update <name>"
      return 1
    fi
    update_plugin "$1"
    ;;
  list|ls)
    _list_plugins
    ;;
  create|scaffold)
    if [[ $# -lt 1 ]]; then
      log_error "Usage: karnel plugin create <name>"
      return 1
    fi
    _scaffold_plugin "$1"
    ;;
  *)
    log_error "Unknown plugin subcommand: $subcmd"
    plugin_help
    return 1
    ;;
  esac
}

plugin_help() {
  echo
  box "Plugin Manager"
  echo
  log_info "Usage: karnel plugin <subcommand> [options]"
  echo
  separator_section "Subcommands"
  echo
  printf "    ${D_CYAN}%-20s${NC} %s\n" "install <user/repo>" "Install a plugin from GitHub"
  printf "    ${D_CYAN}%-20s${NC} %s\n" "remove <name>" "Uninstall a plugin"
  printf "    ${D_CYAN}%-20s${NC} %s\n" "update <name>" "Update a plugin"
  printf "    ${D_CYAN}%-20s${NC} %s\n" "list" "List installed plugins"
  printf "    ${D_CYAN}%-20s${NC} %s\n" "create <name>" "Scaffold a new plugin"
  echo
  echo "Plugins are installed from GitHub repos."
  echo "Each plugin must have a karnel-plugin.json manifest at root."
  echo
  separator_section "Examples"
  echo
  echo "  karnel plugin install username/my-karnel-plugin"
  echo "  karnel plugin list"
  echo "  karnel plugin remove my-karnel-plugin"
  echo "  karnel plugin create my-plugin"
}

_scaffold_plugin() {
  local name="$1"
  local dir="$(_plugin_dir "$name")"

  if [[ -d "$dir" ]]; then
    log_error "Plugin '$name' already exists"
    return 1
  fi

  mkdir -p "$dir/commands" "$dir/tools"

  cat > "$dir/karnel-plugin.json" <<EOF
{
  "name": "$name",
  "version": "1.0.0",
  "description": "My Karnel plugin",
  "commands": ["hello"],
  "tools": []
}
EOF

  cat > "$dir/commands/hello.sh" <<'EOF'
hello_main() {
  echo "Hello from plugin '$1'!"
  echo "Args: $*"
}
EOF

  chmod +x "$dir/commands/"*.sh
  log_success "Plugin '$name' scaffolded at $dir"
  echo "Edit $dir/karnel-plugin.json to configure"
  echo "Add commands in $dir/commands/"
  echo "Run: karnel hello"
}
