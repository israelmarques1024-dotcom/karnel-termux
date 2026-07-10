#!/usr/bin/env bash

import "@/utils/log"

_uninstall_voice_tool() {
  log_info "Termux:API can be removed with: pkg uninstall termux-api"
  return 0
}
