PLUGINS_DIR="${KARNEL_DATA}/plugins"

_plugin_dir() {
  echo "$PLUGINS_DIR/$1"
}

_plugin_manifest() {
  echo "$(_plugin_dir "$1")/karnel-plugin.json"
}

_plugin_installed() {
  [[ -f "$(_plugin_manifest "$1")" ]]
}

_plugin_name_from_repo() {
  local repo="$1"
  basename "$repo" | sed 's/\.git$//'
}

install_plugin() {
  local repo="$1"
  local name
  name="$(_plugin_name_from_repo "$repo")"

  if _plugin_installed "$name"; then
    log_info "Plugin '$name' is already installed"
    return 2
  fi

  mkdir -p "$PLUGINS_DIR"
  log_info "Installing plugin '$name' from $repo..."

  if ! git clone "https://github.com/$repo.git" "$(_plugin_dir "$name")" 2>/dev/null; then
    log_error "Failed to clone $repo"
    return 1
  fi

  if [[ ! -f "$(_plugin_manifest "$name")" ]]; then
    log_warn "Plugin '$name' has no karnel-plugin.json manifest"
    log_info "Creating default manifest..."
    cat > "$(_plugin_manifest "$name")" <<MANIFEST
{
  "name": "$name",
  "version": "1.0.0",
  "description": "Plugin installed from $repo",
  "commands": [],
  "tools": []
}
MANIFEST
  fi

  chmod +x "$(_plugin_dir "$name")/commands/"*.sh 2>/dev/null || true

  log_success "Plugin '$name' installed"
  return 0
}

uninstall_plugin() {
  local name="$1"

  if ! _plugin_installed "$name"; then
    log_info "Plugin '$name' is not installed"
    return 2
  fi

  log_info "Removing plugin '$name'..."
  rm -rf "$(_plugin_dir "$name")"
  log_success "Plugin '$name' removed"
  return 0
}

update_plugin() {
  local name="$1"

  if ! _plugin_installed "$name"; then
    log_info "Plugin '$name' is not installed"
    return 2
  fi

  log_info "Updating plugin '$name'..."
  if ! git -C "$(_plugin_dir "$name")" pull 2>/dev/null; then
    log_error "Failed to update '$name'"
    return 1
  fi

  log_success "Plugin '$name' updated"
  return 0
}

reinstall_plugin() {
  local name="$1"
  uninstall_plugin "$name"
  local repo
  repo="$(git -C "$(_plugin_dir "$name")" remote get-url origin 2>/dev/null || echo "")"
  repo="${repo#https://github.com/}"
  repo="${repo%.git}"
  if [[ -n "$repo" ]]; then
    install_plugin "$repo"
  else
    log_error "Cannot determine repository for '$name'"
    return 1
  fi
}

_list_plugins() {
  mkdir -p "$PLUGINS_DIR"
  local found=0
  for dir in "$PLUGINS_DIR"/*/; do
    [[ -d "$dir" ]] || continue
    local name
    name="$(basename "$dir")"
    if [[ -f "$dir/karnel-plugin.json" ]]; then
      local desc
      desc="$(sed -n 's/.*"description": "\(.*\)",/\1/p' "$dir/karnel-plugin.json" 2>/dev/null || echo "No description")"
      printf "  ${D_GREEN}%-20s${NC} %s\n" "$name" "$desc"
      found=1
    fi
  done
  [[ $found -eq 0 ]] && echo "  No plugins installed"
}

_plugin_commands() {
  mkdir -p "$PLUGINS_DIR"
  for dir in "$PLUGINS_DIR"/*/; do
    [[ -d "$dir" ]] || continue
    local cmd_dir="$dir/commands"
    [[ -d "$cmd_dir" ]] || continue
    for cmd_file in "$cmd_dir"/*.sh; do
      [[ -f "$cmd_file" ]] || continue
      local cmd_name
      cmd_name="$(basename "$cmd_file" .sh)"
      echo "$cmd_file:$cmd_name"
    done
  done
}

_plugin_dispatch() {
  local cmd="$1"
  shift
  while IFS=':' read -r cmd_file cmd_name; do
    if [[ "$cmd_name" == "$cmd" ]]; then
      source "$cmd_file"
      if declare -f "${cmd_name}_main" &>/dev/null; then
        "${cmd_name}_main" "$@"
        return $?
      fi
    fi
  done < <(_plugin_commands)
  return 1
}
