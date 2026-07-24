# shellcheck shell=bash

import "@/tools/plugins/install"

plugin_main() {
  if [[ $# -eq 0 ]]; then
    plugin_help
    return 0
  fi

  local subcmd="$1"
  shift

  case "$subcmd" in
  install)
    _plugin_install_main "$@"
    ;;
  remove|uninstall)
    if [[ $# -ne 1 ]]; then
      log_error "Usage: karnel plugin remove <name>"
      return 1
    fi
    uninstall_plugin "$1"
    ;;
  update)
    _plugin_update_main "$@"
    ;;
  list|ls)
    if [[ $# -ne 0 ]]; then
      log_error "Usage: karnel plugin list"
      return 1
    fi
    _list_plugins
    ;;
  search)
    _search_plugins "$@"
    ;;
  create|scaffold)
    if [[ $# -ne 1 ]]; then
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

_plugin_install_main() {
  local target=""
  local unsafe_flag=""
  local argument

  for argument in "$@"; do
    case "$argument" in
    --unsafe)
      if [[ -n "$unsafe_flag" ]]; then
        log_error "--unsafe was supplied more than once."
        return 1
      fi
      unsafe_flag="--unsafe"
      ;;
    --*)
      log_error "Unknown install option: $argument"
      return 1
      ;;
    *)
      if [[ -n "$target" ]]; then
        log_error "Usage: karnel plugin install <approved-name|owner/repo> [--unsafe]"
        return 1
      fi
      target="$argument"
      ;;
    esac
  done

  if [[ -z "$target" ]]; then
    log_error "Usage: karnel plugin install <approved-name|owner/repo> [--unsafe]"
    return 1
  fi
  install_plugin "$target" "$unsafe_flag"
}

_plugin_update_main() {
  local name=""
  local unsafe_flag=""
  local argument

  for argument in "$@"; do
    case "$argument" in
    --unsafe)
      if [[ -n "$unsafe_flag" ]]; then
        log_error "--unsafe was supplied more than once."
        return 1
      fi
      unsafe_flag="--unsafe"
      ;;
    --*)
      log_error "Unknown update option: $argument"
      return 1
      ;;
    *)
      if [[ -n "$name" ]]; then
        log_error "Usage: karnel plugin update <name> [--unsafe]"
        return 1
      fi
      name="$argument"
      ;;
    esac
  done

  if [[ -z "$name" ]]; then
    log_error "Usage: karnel plugin update <name> [--unsafe]"
    return 1
  fi
  update_plugin "$name" "$unsafe_flag"
}

plugin_help() {
  echo
  box "Plugin Manager"
  echo
  log_info "Usage: karnel plugin <subcommand> [options]"
  echo
  separator_section "Subcommands"
  echo
  printf "    ${D_CYAN}%-30s${NC} %s\n" "install <name|owner/repo>" "Install an approved registry plugin"
  printf "    ${D_CYAN}%-30s${NC} %s\n" "install <owner/repo> --unsafe" "Install an unreviewed plugin after confirmation"
  printf "    ${D_CYAN}%-30s${NC} %s\n" "remove <name>" "Remove a plugin safely"
  printf "    ${D_CYAN}%-30s${NC} %s\n" "update <name>" "Atomically update an approved plugin"
  printf "    ${D_CYAN}%-30s${NC} %s\n" "list" "List installed plugins and trust source"
  printf "    ${D_CYAN}%-30s${NC} %s\n" "search [query] [filters]" "Search the approved registry"
  printf "    ${D_CYAN}%-30s${NC} %s\n" "create <name>" "Create a validated local plugin"
  echo
  separator_section "Search Filters"
  echo
  printf "    ${D_CYAN}%-30s${NC} %s\n" "--command <name>" "Only plugins that provide a command"
  printf "    ${D_CYAN}%-30s${NC} %s\n" "--compatible" "Only plugins compatible with this Karnel version"
  printf "    ${D_CYAN}%-30s${NC} %s\n" "--capability <name>" "Filter declared capabilities"
  echo
  log_warn "Plugins run Bash with the permissions of your current user. Bash plugins are not sandboxed."
  log_info "Approved registry plugins are reviewed metadata, not an isolation boundary."
  echo
  separator_section "Examples"
  echo
  echo "  karnel plugin search --compatible"
  echo "  karnel plugin install karnel-hello"
  echo "  karnel plugin install username/repo --unsafe"
  echo "  karnel plugin update karnel-hello"
  echo "  karnel plugin remove karnel-hello"
}

_search_plugins() {
  local query=""
  local command_filter=""
  local capability_filter=""
  local compatible_only=0
  local argument registry_file search_file count=0
  local name version description repo commands minimum capabilities comparison

  while [[ $# -gt 0 ]]; do
    argument="$1"
    shift
    case "$argument" in
    --command)
      if [[ $# -eq 0 ]] || ! _plugin_command_is_valid "$1"; then
        log_error "--command requires a safe command name."
        return 1
      fi
      command_filter="$1"
      shift
      ;;
    --capability)
      if [[ $# -eq 0 ]] || [[ ! "$1" =~ ^(network|filesystem-read|filesystem-write|process|environment)$ ]]; then
        log_error "--capability requires one of: network, filesystem-read, filesystem-write, process, environment."
        return 1
      fi
      capability_filter="$1"
      shift
      ;;
    --compatible)
      compatible_only=1
      ;;
    --help|-h)
      plugin_help
      return 0
      ;;
    --*)
      log_error "Unknown search option: $argument"
      return 1
      ;;
    *)
      if [[ -n "$query" ]]; then
        log_error "Search accepts at most one text query."
        return 1
      fi
      query="$argument"
      ;;
    esac
  done

  _plugin_require_jq || return 1
  _plugin_prepare_plugins_dir || return 1
  registry_file="$(mktemp "$PLUGINS_DIR/.karnel-registry.XXXXXX")" || return 1
  log_info "Fetching approved plugin registry..."
  if ! _plugin_fetch_registry "$registry_file"; then
    if ! _plugin_cleanup_temp_file "$registry_file"; then
      log_error "Failed to clean temporary registry data."
    fi
    return 1
  fi

  echo
  box "Available Approved Plugins"
  echo
  search_file="$(mktemp "$PLUGINS_DIR/.karnel-search.XXXXXX")" || {
    _plugin_cleanup_temp_file "$registry_file"
    return 1
  }
  if ! jq -r \
    --arg query "$query" \
    --arg command "$command_filter" \
    --arg capability "$capability_filter" '
      .plugins[] |
      select(
        ($query == "") or
        ([.name, .repo, .description] | join(" ") | ascii_downcase | contains($query | ascii_downcase))
      ) |
      select(($command == "") or (.commands | index($command) != null)) |
      select(($capability == "") or ((.capabilities // []) | index($capability) != null)) |
      [.name, .version, .description, .repo, (.commands | join(", ")), .minKarnelVersion, ((.capabilities // []) | join(", "))] | @tsv
    ' "$registry_file" >"$search_file"; then
    _plugin_cleanup_temp_file "$search_file"
    _plugin_cleanup_temp_file "$registry_file"
    log_error "Failed to parse approved plugin registry."
    return 1
  fi
  while IFS=$'\t' read -r name version description repo commands minimum capabilities; do
    if ((compatible_only == 1)); then
      comparison="$(_plugin_semver_compare "$KARNEL_VERSION" "$minimum")" || {
        _plugin_cleanup_temp_file "$search_file"
        _plugin_cleanup_temp_file "$registry_file"
        return 1
      }
      ((comparison >= 0)) || continue
    fi
    printf "  ${D_GREEN}%-20s${NC} v%-10s %s\n" "$name" "$version" "$description"
    printf "  ${D_CYAN}    install:${NC} karnel plugin install %s\n" "$name"
    printf "  ${D_DIM}    commands: %s | min Karnel: %s | capabilities: %s${NC}\n" "$commands" "$minimum" "${capabilities:-none}"
    count=$((count + 1))
  done <"$search_file"
  if ! _plugin_cleanup_temp_file "$search_file" || ! _plugin_cleanup_temp_file "$registry_file"; then
    log_error "Failed to clean temporary registry data."
    return 1
  fi

  if ((count == 0)); then
    echo "  No plugins match the selected filters."
  fi
  echo
}

_scaffold_plugin() {
  local name="$1"
  local staging candidate manifest checksum destination

  _plugin_validate_name "$name" || return 1
  _plugin_require_jq || return 1
  _plugin_prepare_plugins_dir || return 1
  destination="$PLUGINS_DIR/$name"
  if [[ -e "$destination" || -L "$destination" ]]; then
    log_error "Plugin '$name' already exists."
    return 1
  fi

  staging="$(mktemp -d "$PLUGINS_DIR/.karnel-create.XXXXXX")" || return 1
  candidate="$staging/$name"
  if ! mkdir -p -- "$candidate/commands"; then
    log_error "Failed to create plugin scaffold for '$name'."
    _plugin_cleanup_staging "$staging"
    return 1
  fi

  cat >"$candidate/commands/$name.sh" <<EOF
${name}_main() {
  printf '%s\\n' 'Hello from ${name}'
}
EOF
  cat >"$candidate/LICENSE" <<'EOF'
MIT License

Copyright (c) Karnel Plugin Authors

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
EOF

  manifest="$candidate/karnel-plugin.json"
  if ! jq -n \
    --arg name "$name" \
    --arg minimum "$KARNEL_VERSION" \
    '{schemaVersion: 1, name: $name, version: "0.1.0", description: "Local Karnel plugin", commands: [$name], minKarnelVersion: $minimum, license: "MIT", capabilities: []}' >"$manifest"; then
    _plugin_cleanup_staging "$staging"
    return 1
  fi
  checksum="$(_plugin_payload_checksum "$candidate")" || {
    _plugin_cleanup_staging "$staging"
    return 1
  }
  if ! jq --arg checksum "$checksum" '. + {checksum: $checksum}' "$manifest" >"$manifest.tmp"; then
    _plugin_cleanup_staging "$staging"
    return 1
  fi
  if ! mv -- "$manifest.tmp" "$manifest"; then
    _plugin_cleanup_staging "$staging"
    return 1
  fi

  candidate="$(_plugin_validate_plugin_contents "$candidate")" || {
    _plugin_cleanup_staging "$staging"
    return 1
  }
  if ! _plugin_check_command_collisions "$candidate" "$name"; then
    _plugin_cleanup_staging "$staging"
    return 1
  fi
  if ! _plugin_write_install_metadata "$candidate" "local" "" "" "" ""; then
    _plugin_cleanup_staging "$staging"
    return 1
  fi
  if ! _plugin_place_candidate "$candidate" "$name" 0; then
    _plugin_cleanup_staging "$staging"
    return 1
  fi

  _plugin_cleanup_staging "$staging" || return 1
  log_success "Plugin '$name' scaffolded at $destination."
  log_warn "Local plugins run with your user permissions and are not sandboxed."
  log_info "Edit the manifest and update checksum whenever plugin payload files change."
}
