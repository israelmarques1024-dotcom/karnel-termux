#!/usr/bin/env bash

import "@/utils/log"
import "@/utils/colors"
import "@/utils/sponsor"

_sponsor_help() {
  echo
  separator_section "Sponsor Settings"
  echo
  printf "    ${D_CYAN}%-22s${NC} %s\n" "karnel sponsor status" "Show sponsor mode and installation source"
  printf "    ${D_CYAN}%-22s${NC} %s\n" "karnel sponsor on" "Enable sponsor messages for the independent distribution"
  printf "    ${D_CYAN}%-22s${NC} %s\n" "karnel sponsor off" "Disable sponsor messages"
  printf "    ${D_CYAN}%-22s${NC} %s\n" "karnel sponsor show" "Refresh and preview the current sponsor"
  echo
  log_info "Sponsor messages never collect commands, files, history, or personal data."
  echo
}

_sponsor_status() {
  local source state
  source="$(sponsor_install_source)"
  if sponsor_is_enabled; then
    state="enabled"
  else
    state="disabled"
  fi

  echo
  separator_section "Sponsor Status"
  echo
  printf "    ${D_CYAN}%-18s${NC} %s\n" "Installation" "$source"
  printf "    ${D_CYAN}%-18s${NC} %s\n" "Sponsor messages" "$state"
  printf "    ${D_CYAN}%-18s${NC} %s\n" "Frequency" "at most once every 24 hours"
  printf "    ${D_CYAN}%-18s${NC} %s\n" "Telemetry" "none"
  echo

  if [[ "$source" != "direct" ]]; then
    log_info "Automatic sponsor messages are unavailable in npm installations."
    echo
  fi
}

sponsor_main() {
  local action="${1:-status}"

  case "$action" in
    status)
      _sponsor_status
      ;;
    on)
      if sponsor_set_enabled on; then
        log_ok "Sponsor messages enabled."
      else
        local status=$?
        if [[ "$status" == "2" ]]; then
          log_error "Sponsor messages can only be enabled in the independent distribution."
          echo
          log_info "Use install-sponsored.sh instead of the npm package."
          return 2
        fi
        log_error "Could not enable sponsor messages."
        return 1
      fi
      ;;
    off)
      if sponsor_set_enabled off; then
        log_ok "Sponsor messages disabled."
      else
        log_error "Could not disable sponsor messages."
        return 1
      fi
      ;;
    show)
      if sponsor_force_show; then
        return 0
      fi
      local status=$?
      if [[ "$status" == "2" ]]; then
        log_error "Sponsor preview is only available in the independent distribution."
      else
        log_warn "No active sponsor is available right now."
      fi
      return "$status"
      ;;
    help|--help|-h)
      _sponsor_help
      ;;
    *)
      log_error "Unknown sponsor command: $action"
      _sponsor_help
      return 1
      ;;
  esac
}
