#!/usr/bin/env bash

import "@/utils/log"
import "@/utils/colors"

search_main() {
  local query="$*"
  if [[ -z "$query" ]]; then
    echo
    box "◈ KARNEL SEARCH ◈"
    echo
    log_info "Search across all tools and brain memories"
    echo
    log_info "Usage: karnel search <query>"
    echo
    return
  fi

  echo
  box "◈ Search: $query ◈"
  echo

  local any_found=false

  separator_section "Tool Names"
  echo
  for reg_file in "$KARNEL_PATH/tools/"*/all.sh; do
    local mod
    mod=$(basename "$(dirname "$reg_file")")
    while IFS= read -r line; do
      local id name
      id=$(echo "$line" | cut -d: -f1 | tr -d '"' | xargs)
      name=$(echo "$line" | cut -d: -f2 | tr -d '"' | xargs)
      if echo "$id $name" | grep -qi "$query"; then
        list_item "${D_CYAN}$mod${NC}: $name ($id)"
        any_found=true
      fi
    done < <(grep -E '"[a-z].*:.*:.*"' "$reg_file" 2>/dev/null)
  done
  if ! $any_found; then
    log_info "No tools found matching '$query'"
  fi

  echo
  separator_section "Brain Memories"
  echo
  any_found=false
  if [[ -d "$KARNEL_DATA/brain" ]]; then
    while IFS= read -r file; do
      local title
      title=$(head -1 "$file" 2>/dev/null | sed 's/^# //')
      list_item "${D_CYAN}$(basename "$file")${NC}: ${title:-$file}"
      any_found=true
    done < <(grep -ril "$query" "$KARNEL_DATA/brain" 2>/dev/null)
    if ! $any_found; then
      log_info "No memories found matching '$query'"
    fi
  else
    log_info "Brain not initialized (run 'karnel brain init')"
  fi

  echo
}
