#!/usr/bin/env bash

import "@/utils/log"
import "@/utils/colors"

supabase_main() {
  local subcommand="${1:-help}"
  shift 2>/dev/null || true

  case "$subcommand" in
    help|--help|-h)
      supabase_help
      ;;
    doctor)
      supabase_doctor
      ;;
    types)
      supabase_types "$@"
      ;;
    migrate)
      supabase_migrate "$@"
      ;;
    remote-start|remote)
      supabase_remote "$@"
      ;;
    remote-status|status)
      supabase_remote_status
      ;;
    link)
      supabase_link "$@"
      ;;
    install)
      import "@/tools/deploy/supabase/install"
      install_supabase
      ;;
    uninstall)
      import "@/tools/deploy/supabase/install"
      uninstall_supabase
      ;;
    *)
      log_error "Unknown supabase subcommand: $subcommand"
      echo
      supabase_help
      return 1
      ;;
  esac
}

supabase_help() {
  echo
  box "◈ SUPABASE CLI ◈"
  echo
  log_info "Usage: karnel supabase <subcommand> [options]"
  echo
  separator_section "Subcommands"
  echo
  printf "    ${D_CYAN}%-20s${NC} %s\n" "doctor" "Check Supabase environment compatibility"
  printf "    ${D_CYAN}%-20s${NC} %s\n" "types" "Generate TypeScript types from remote DB"
  printf "    ${D_CYAN}%-20s${NC} %s\n" "migrate" "Run database migrations (remote)"
  printf "    ${D_CYAN}%-20s${NC} %s\n" "link" "Link project to Supabase remote"
  printf "    ${D_CYAN}%-20s${NC} %s\n" "remote-start" "Start remote services guide"
  printf "    ${D_CYAN}%-20s${NC} %s\n" "remote-status" "Check remote connection status"
  printf "    ${D_CYAN}%-20s${NC} %s\n" "install" "Install/update Supabase CLI"
  printf "    ${D_CYAN}%-20s${NC} %s\n" "uninstall" "Remove Supabase CLI"
  echo
  separator_section "Architecture"
  echo
  log_info "Termux: edit files, run remote commands"
  log_info "Linux host (VPS/Codespaces): Docker + local stack"
  echo
  list_item "Remote commands work via ${D_CYAN}supabase link${NC} + API token"
  list_item "Local stack (${D_CYAN}supabase start${NC}) needs Docker — not supported on Termux"
  echo
  log_info "Examples:"
  list_item "${D_CYAN}karnel supabase doctor${NC} — check environment"
  list_item "${D_CYAN}karnel supabase link --project-ref abcdef${NC}"
  list_item "${D_CYAN}karnel supabase types generate --linked > types/supabase.ts${NC}"
  list_item "${D_CYAN}karnel supabase migrate up${NC}"
  echo
}

supabase_doctor() {
  echo
  box "◈ SUPABASE DOCTOR ◈"
  echo
  log_info "Checking Supabase environment..."
  echo

  local warnings=0

  # Check if supabase CLI is installed
  if ! command -v supabase &>/dev/null; then
    log_error "Supabase CLI is not installed"
    log_info "Install with: ${D_CYAN}karnel supabase install${NC}"
    echo
    return 1
  fi

  local ver
  ver=$(supabase --version 2>/dev/null | head -1)
  log_success "Supabase CLI: $ver"

  # Check for project linkage
  if [[ -f "supabase/config.toml" ]]; then
    log_success "supabase/config.toml found (project configured)"
    if grep -q "project_id" supabase/config.toml 2>/dev/null; then
      local pid
      pid=$(grep "project_id" supabase/config.toml | head -1 | cut -d'"' -f2)
      log_success "Project ID: ${pid:-configured}"
    fi
  else
    log_warn "No supabase/config.toml in current directory"
    log_info "Run ${D_CYAN}supabase link${NC} in a project with Supabase"
    ((warnings++))
  fi

  # Check for Docker (local stack not available)
  if command -v docker &>/dev/null; then
    log_info "Docker available (for Linux host, not Termux)"
  else
    log_info "Docker not available (expected on Termux)"
  fi
  log_info "Local stack (supabase start) requires Docker on a Linux host"

  # Check network (can reach supabase.com)
  if curl -fsSL --max-time 5 https://api.supabase.com &>/dev/null; then
    log_success "Network: Supabase API reachable"
  else
    log_warn "Cannot reach Supabase API (api.supabase.com)"
    ((warnings++))
  fi

  # Check for linked project
  if supabase status 2>/dev/null | grep -qi "linked\|link"; then
    log_success "Project is linked to Supabase"
  else
    log_info "No linked project in current directory"
  fi

  echo
  if [[ $warnings -eq 0 ]]; then
    log_success "Supabase environment looks good"
  else
    log_warn "$warnings warning(s) found"
  fi
  echo
}

supabase_types() {
  if ! command -v supabase &>/dev/null; then
    log_error "Supabase CLI not installed — run ${D_CYAN}karnel supabase install${NC}"
    return 1
  fi
  log_info "Generating TypeScript types from Supabase..."
  log_info "Usage: supabase gen types typescript --linked > types/supabase.ts"
  echo
  if [[ -f "supabase/config.toml" ]]; then
    supabase gen types typescript --linked 2>/dev/null
  else
    log_warn "No linked project found"
    log_info "Run ${D_CYAN}supabase link${NC} first or check directory"
  fi
}

supabase_migrate() {
  if ! command -v supabase &>/dev/null; then
    log_error "Supabase CLI not installed — run ${D_CYAN}karnel supabase install${NC}"
    return 1
  fi
  supabase db "$@"
}

supabase_remote() {
  echo
  box "◈ SUPABASE REMOTE ENVIRONMENT ◈"
  echo
  log_info "For full local development, use a Linux host:"
  echo
  list_item "1. SSH into a Linux VPS, Codespaces, or local Linux machine"
  list_item "2. Install Docker: ${D_CYAN}curl -fsSL https://get.docker.com | sh${NC}"
  list_item "3. Install Supabase CLI on that machine"
  list_item "4. Clone your project there"
  list_item "5. Run ${D_CYAN}supabase start${NC} for local stack"
  echo
  log_info "From Termux, you can still:"
  list_item "${D_CYAN}supabase link --project-ref <ref>${NC}"
  list_item "${D_CYAN}supabase db push${NC}"
  list_item "${D_CYAN}supabase db pull${NC}"
  list_item "${D_CYAN}supabase gen types typescript --linked${NC}"
  list_item "${D_CYAN}supabase functions deploy <name>${NC}"
  list_item "${D_CYAN}supabase secrets set NAME=VALUE${NC}"
  echo
}

supabase_remote_status() {
  if ! command -v supabase &>/dev/null; then
    log_error "Supabase CLI not installed"
    return 1
  fi
  supabase status 2>/dev/null || log_warn "Unable to check Supabase status"
}

supabase_link() {
  if ! command -v supabase &>/dev/null; then
    log_error "Supabase CLI not installed — run ${D_CYAN}karnel supabase install${NC}"
    return 1
  fi
  supabase link "$@"
}
