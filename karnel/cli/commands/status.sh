#!/usr/bin/env bash

import "@/utils/log"
import "@/utils/colors"

status_main() {
  echo
  box "Karnel Status"
  echo

  local -a services=()

  # Disk
  local disk
  disk=$(df -h "$HOME" | awk 'NR==2 {print $4}')
  log_success "Disk free: $disk"

  # RAM
  if [[ -f /proc/meminfo ]]; then
    local total_kb free_kb
    total_kb=$(grep MemTotal /proc/meminfo | awk '{print $2}')
    free_kb=$(grep MemAvailable /proc/meminfo | awk '{print $2}')
    log_success "RAM: $((total_kb/1024))MB total, $((free_kb/1024))MB free"
    if (( free_kb < 200000 )); then
      log_warn "Low memory"
    fi
  fi

  # Uptime
  if [[ -f /proc/uptime ]]; then
    local uptime_sec
    uptime_sec=$(awk '{print int($1)}' /proc/uptime)
    local days=$((uptime_sec / 86400))
    local hours=$(( (uptime_sec % 86400) / 3600 ))
    local mins=$(( (uptime_sec % 3600) / 60 ))
    log_info "Uptime: ${days}d ${hours}h ${mins}m"
  fi

  # PostgreSQL
  if command -v pg_ctl &>/dev/null; then
    if pg_isready -q 2>/dev/null; then
      log_success "PostgreSQL: RUNNING"
      services+=("pg")
    else
      log_warn "PostgreSQL: STOPPED"
    fi
  fi

  # code-server
  if command -v code-server &>/dev/null; then
    if pgrep -f "code-server" &>/dev/null; then
      log_success "code-server: RUNNING"
      services+=("code-server")
    else
      log_info "code-server: not started"
    fi
  fi

  # omni-route web
  if pgrep -f "omni-route-web" &>/dev/null; then
    log_success "omni-route: RUNNING"
    services+=("omni-route")
  fi

  # Robin OSINT
  import "@/tools/osint/robin/common"
  if [[ -d "$ROBIN_APP_DIR/.git" ]]; then
    if _robin_managed_process_running && _robin_http_healthy; then
      log_success "Robin: RUNNING (127.0.0.1:$ROBIN_PORT)"
      services+=("robin")
    else
      log_info "Robin: installed, not started"
    fi
  fi

  # Internet
  if command -v ping &>/dev/null; then
    if timeout 3 ping -c 1 -W 3 8.8.8.8 &>/dev/null; then
      log_success "Internet: OK"
    else
      log_warn "Internet: unreachable"
    fi
  fi

  # Karnel version
  log_success "Karnel: v$KARNEL_VERSION"

  # Last update check
  local last_check="$KARNEL_CACHE/last_version_check"
  if [[ -f "$last_check" ]]; then
    local check_time
    check_time=$(cat "$last_check" 2>/dev/null)
    local now
    now=$(date +%s)
    local age=$(( (now - check_time) / 86400 ))
    log_info "Last update check: ${age}d ago"
  fi

  echo
  local count=${#services[@]}
  if (( count > 0 )); then
    log_success "${count} service(s) running: ${services[*]}"
  else
    log_info "No services running"
  fi
  echo
}
