#!/usr/bin/env bash

import "@/utils/log"
import "@/utils/colors"

deploy_main() {
  if [[ $# -eq 0 ]]; then
    echo
    box "Karnel Deploy"
    echo
    log_info "Usage: karnel deploy <tool>"
    echo
    log_info "Available tools:"
    echo
    list_item "vercel    - Deploy to Vercel"
    list_item "railway   - Deploy to Railway"
    list_item "netlify   - Deploy to Netlify"
    echo
    log_info "Usage: ${D_CYAN}karnel deploy vercel${NC}"
    echo
    return
  fi

  local tool="$1"
  case "$tool" in
  vercel)
    if ! command -v vercel &>/dev/null; then
      log_warn "Vercel CLI not installed. Run: karnel install npm --vercel"
      return 1
    fi
    exec vercel "${@:2}"
    ;;
  railway)
    if ! command -v railway &>/dev/null; then
      log_warn "Railway CLI not installed. Run: karnel install deploy --railway"
      return 1
    fi
    exec railway "${@:2}"
    ;;
  netlify)
    if ! command -v netlify &>/dev/null; then
      log_warn "Netlify CLI not installed. Run: karnel install deploy --netlify"
      return 1
    fi
    exec netlify "${@:2}"
    ;;
  *)
    log_warn "Unknown deploy tool: $tool"
    echo "Available: vercel, railway, netlify"
    return 1
    ;;
  esac
}
