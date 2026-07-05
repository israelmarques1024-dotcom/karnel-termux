#!/usr/bin/env bash

import "@/utils/log"

_install_voice_tool() {
  log_info "All voice dependencies are managed by Termux:API"
  log_info "To use voice, install the Termux:API app from:"
  log_info "  https://omni-catalyst.vercel.app/termux/api"
  return 0
}
