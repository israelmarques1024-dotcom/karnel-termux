#!/usr/bin/env bash

_tool_uses_central_ownership() {
  local identity="$1/$2"

  case "$identity" in
    lang/nodejs|lang/python|lang/perl|lang/php|lang/rust|lang/clang|lang/golang) ;;
    db/postgresql|db/mariadb|db/sqlite|db/mongodb|db/redis) ;;
    dev/gh|dev/wget|dev/curl|dev/lsd|dev/bat|dev/proot|dev/ncurses|dev/tmate|dev/openssh|dev/tmux|dev/cloudflared|dev/translate|dev/html2text|dev/jq|dev/bc|dev/tree|dev/fzf|dev/imagemagick|dev/shfmt|dev/make|dev/udocker|dev/snyk) ;;
    npm/typescript|npm/nestjs|npm/prettier|npm/live-server|npm/localtunnel|npm/vercel|npm/markserv|npm/psqlformat|npm/ncu|npm/ngrok) ;;
    security/nmap|security/hydra|security/dirb|security/john|security/aircrack-ng|security/smbclient|security/netcat|security/tcpdump|security/whois|security/hashcat|security/binwalk|security/foremost|security/steghide|security/exiftool) ;;
    auto/n8n|editor/code-server|editor/neovim) ;;
    *) return 1 ;;
  esac
}

_tool_ownership_marker() {
  if [[ -z "${KARNEL_DATA:-}" ]]; then
    log_error "KARNEL_DATA is required for tool ownership state"
    return 1
  fi
  printf '%s/ownership/%s/%s\n' "$KARNEL_DATA" "$1" "$2"
}

_mark_tool_owned() {
  local marker
  marker=$(_tool_ownership_marker "$1" "$2") || return 1
  mkdir -p "${marker%/*}" || return 1
  (umask 077; : >"$marker") || return 1
  chmod 600 "$marker"
}

_run_tool_lifecycle_action() {
  local module="$1"
  local action="$2"
  local tool="$3"
  local normalized="${tool//-/_}"
  local handler="${action}_${normalized}"
  local marker=""
  local protected=0
  local rc

  if _tool_uses_central_ownership "$module" "$tool"; then
    protected=1
    marker=$(_tool_ownership_marker "$module" "$tool") || return 1
  fi

  if (( protected )) && [[ "$action" != "install" && ! -f "$marker" ]]; then
    log_warn "Preserving unowned or legacy $module tool: $tool"
    return 2
  fi

  if [[ "$action" == "reinstall" ]]; then
    local uninstall_handler="uninstall_${normalized}"
    local install_handler="install_${normalized}"
    if ! declare -f "$uninstall_handler" &>/dev/null || ! declare -f "$install_handler" &>/dev/null; then
      log_error "Missing reinstall handlers for $tool"
      return 1
    fi
    "$uninstall_handler"
    rc=$?
    (( rc == 0 )) || return "$rc"
    "$install_handler"
    rc=$?
    if (( rc == 0 && protected )); then
      _mark_tool_owned "$module" "$tool" || return 1
    fi
    return "$rc"
  fi

  if ! declare -f "$handler" &>/dev/null; then
    log_error "Missing $action handler for $tool: $handler"
    return 1
  fi
  "$handler"
  rc=$?
  if (( rc == 0 && protected )); then
    if [[ "$action" == "install" ]]; then
      _mark_tool_owned "$module" "$tool" || return 1
    elif [[ "$action" == "uninstall" ]]; then
      rm -f "$marker" || return 1
    fi
  fi
  return "$rc"
}

_register_safe_reinstall_handlers() {
  local module="$1"
  shift
  local tool normalized
  for tool in "$@"; do
    normalized="${tool//-/_}"
    eval "reinstall_${normalized}() { _run_tool_lifecycle_action '$module' reinstall '$tool'; }"
  done
}

_batch_tool_action() {
  local module="$1"
  local action="$2"
  shift 2
  local -a tools=("$@")
  local success_count=0
  local failed_count=0
  local skipped_count=0

  # An explicit uninstall should actually remove owned data, even when no TTY
  # is attached (piped/non-interactive). Ownership is still guarded upstream.
  [[ "$action" == "uninstall" ]] && export KARNEL_REMOVE_DEFAULT=y

  import "@/tools/$module/all"

  for tool in "${tools[@]}"; do
    local normalized="${tool//-/_}"
    if [[ "$module" == "ai" ]] && declare -f _run_ai_tool_action &>/dev/null; then
      _run_ai_tool_action "$action" "$tool"
      case $? in
        0) ((success_count++));;
        2) ((skipped_count++));;
        *) ((failed_count++));;
      esac
    else
      if [[ "$action" == "reinstall" ]]; then
        if ! declare -f "uninstall_${normalized}" &>/dev/null || ! declare -f "install_${normalized}" &>/dev/null; then
          log_warn "Unknown $module tool: $tool"
          ((failed_count++))
          continue
        fi
      elif ! declare -f "${action}_${normalized}" &>/dev/null; then
        log_warn "Unknown $module tool: $tool"
        ((failed_count++))
        continue
      fi
      _run_tool_lifecycle_action "$module" "$action" "$tool"
      case $? in
        0) ((success_count++));;
        2) ((skipped_count++));;
        *) ((failed_count++));;
      esac
    fi
  done

  echo
  if [[ $success_count -gt 0 ]]; then
    log_success "$success_count tool(s) ${action}ed"
  fi
  if [[ $failed_count -gt 0 ]]; then
    log_warn "$failed_count tool(s) failed to ${action}"
  fi
  if [[ $skipped_count -gt 0 ]]; then
    log_info "$skipped_count tool(s) already in the requested state"
  fi

  (( failed_count == 0 ))
}
