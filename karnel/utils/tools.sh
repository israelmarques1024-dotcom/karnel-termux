#!/usr/bin/env bash

_batch_tool_action() {
  local module="$1"
  local action="$2"
  shift 2
  local -a tools=("$@")
  local success_count=0
  local failed_count=0
  local skipped_count=0

  import "@/tools/$module/all"

  for tool in "${tools[@]}"; do
    local func_name="${action}_${tool//-/_}"
    if declare -f "$func_name" &>/dev/null; then
      "$func_name"
      case $? in
        0) ((success_count++));;
        2) ((skipped_count++));;
        *) ((failed_count++));;
      esac
    else
      log_warn "Unknown $module tool: $tool"
      ((failed_count++))
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
