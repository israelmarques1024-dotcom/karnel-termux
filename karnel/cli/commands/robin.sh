#!/usr/bin/env bash

import "@/utils/log"
import "@/utils/colors"
import "@/tools/osint/robin/common"

_robin_ensure_installed() {
  if ! _robin_is_installed; then
    log_error "Robin is not completely installed"
    log_info "Install or repair it with: karnel install osint --robin"
    return 1
  fi
}

_robin_configured_provider_count() {
  local env_file="$1"
  local key value provider
  local -A providers=()
  [[ -r "$env_file" ]] || {
    printf '0\n'
    return
  }

  while IFS='=' read -r key value; do
    [[ "$key" =~ ^[A-Z][A-Z0-9_]*$ ]] || continue
    value="${value%\"}"
    value="${value#\"}"
    [[ -n "$value" && "$value" != your_* && "$value" != change_me* ]] || continue
    case "$key" in
      OPENAI_API_KEY) provider="openai" ;;
      ANTHROPIC_API_KEY) provider="anthropic" ;;
      GOOGLE_API_KEY) provider="google" ;;
      OPENROUTER_API_KEY|OPENROUTER_BASE_URL) provider="openrouter" ;;
      OLLAMA_BASE_URL) provider="ollama" ;;
      LLAMA_CPP_BASE_URL) provider="llama-cpp" ;;
      CUSTOM_API_BASE_URL|CUSTOM_API_KEY|CUSTOM_API_MODEL) provider="custom" ;;
      *) continue ;;
    esac
    providers["$provider"]=1
  done < "$env_file"
  printf '%s\n' "${#providers[@]}"
}

_robin_terminate_managed_process() {
  local pid="$1"
  local start_time="$2"
  _robin_process_matches "$pid" "$start_time" || return 0
  kill "$pid" 2>/dev/null || return 1

  local attempt
  for ((attempt = 0; attempt < 15; attempt++)); do
    _robin_process_matches "$pid" "$start_time" || return 0
    sleep 1
  done
  _robin_process_matches "$pid" "$start_time" || return 0
  log_warn "Robin did not stop gracefully; sending SIGKILL"
  kill -9 "$pid" 2>/dev/null || return 1

  for ((attempt = 0; attempt < 5; attempt++)); do
    _robin_process_matches "$pid" "$start_time" || return 0
    sleep 1
  done
  ! _robin_process_matches "$pid" "$start_time"
}

_robin_start_tor() {
  if _robin_socket_open 127.0.0.1 9050; then
    log_info "Tor SOCKS proxy ja esta disponivel"
    return 0
  fi
  if ! command -v tor &>/dev/null; then
    log_error "Tor is not installed. Run: pkg install tor"
    return 1
  fi

  log_info "Iniciando Tor..."
  tor --RunAsDaemon 1 &>>"$ROBIN_LOG" || {
    log_error "Falha ao iniciar o Tor"
    return 1
  }

  local attempt
  for ((attempt = 0; attempt < 30; attempt++)); do
    if _robin_socket_open 127.0.0.1 9050; then
      log_success "Tor SOCKS proxy pronto em 127.0.0.1:9050"
      return 0
    fi
    sleep 1
  done

  log_error "Tor iniciou, mas o proxy SOCKS nao ficou pronto em 30 segundos"
  return 1
}

robin_main() {
  local subcommand="${1:-help}"
  [[ $# -gt 0 ]] && shift

  case "$subcommand" in
    help|--help|-h)
      _robin_help
      return
      ;;
    start|stop|status|config|doctor|update|purge-data)
      _robin_print_disclaimer
      ;;
    *)
      log_error "Unknown robin subcommand: $subcommand"
      echo
      _robin_help
      return 1
      ;;
  esac

  case "$subcommand" in
    start) _robin_start "$@" ;;
    stop) _robin_stop "$@" ;;
    status) _robin_status "$@" ;;
    config) _robin_config "$@" ;;
    doctor) _robin_doctor "$@" ;;
    update) _robin_update "$@" ;;
    purge-data) _robin_purge_data "$@" ;;
  esac
}

_robin_start() {
  local accept=false
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --accept-responsible-use) accept=true ;;
      --help|-h) _robin_help; return ;;
      *) log_error "Unknown start option: $1"; return 1 ;;
    esac
    shift
  done

  _robin_ensure_installed || return 1
  _robin_require_acknowledgement "$accept" || return 1
  _robin_acquire_lock || return 1
  local rc=0
  local launched_pid=""
  local launched_start=""

  if _robin_managed_process_running; then
    if _robin_http_healthy; then
      log_warn "Robin ja esta em execucao (PID: $ROBIN_PID)"
      log_info "Acesse: http://127.0.0.1:$ROBIN_PORT"
      _robin_release_lock
      return 0
    fi
    log_error "A Robin process exists but its health endpoint is not responding"
    _robin_release_lock
    return 1
  fi

  if [[ -f "$ROBIN_PID_FILE" ]]; then
    log_warn "Ignoring a stale Robin PID record; no process was signaled"
    rm -f "$ROBIN_PID_FILE"
  fi

  if _robin_socket_open 127.0.0.1 "$ROBIN_PORT"; then
    log_error "Port $ROBIN_PORT is already in use by another process"
    _robin_release_lock
    return 1
  fi

  mkdir -p "$KARNEL_LOGS" "$KARNEL_RUN"
  chmod 700 "$KARNEL_LOGS" "$KARNEL_RUN" 2>/dev/null || true
  _robin_rotate_log
  _robin_start_tor || rc=$?

  if (( rc == 0 )); then
    log_info "Iniciando Robin Streamlit..."
    (
      umask 077
      cd "$ROBIN_APP_DIR" || exit 1
      nohup "$ROBIN_VENV_DIR/bin/python" -m streamlit run ui.py \
        --server.address 127.0.0.1 \
        --server.port "$ROBIN_PORT" \
        --server.headless true \
        --server.fileWatcherType none \
        --browser.gatherUsageStats false \
        &>>"$ROBIN_LOG" &
      printf '%s\n' "$!"
    ) > "$ROBIN_PID_FILE.launch"

    read -r launched_pid < "$ROBIN_PID_FILE.launch"
    rm -f "$ROBIN_PID_FILE.launch"
    if [[ ! "$launched_pid" =~ ^[1-9][0-9]*$ ]]; then
      log_error "Failed to capture the Robin process ID"
      rc=1
    else
      sleep 1
      launched_start=$(_robin_proc_start_time "$launched_pid") || rc=1
      if (( rc == 0 )); then
        _robin_write_pid "$launched_pid" || rc=1
      fi
    fi
  fi

  if (( rc == 0 )); then
    local attempt
    for ((attempt = 0; attempt < ROBIN_START_TIMEOUT; attempt++)); do
      if ! _robin_managed_process_running; then
        rc=1
        break
      fi
      if _robin_http_healthy; then
        log_success "Robin pronto (PID: $ROBIN_PID)"
        log_info "Acesse: http://127.0.0.1:$ROBIN_PORT"
        log_info "Para encerrar: karnel robin stop"
        break
      fi
      sleep 1
    done
    if (( attempt >= ROBIN_START_TIMEOUT )); then
      rc=1
    fi
  fi

  if (( rc != 0 )); then
    local cleanup_pid="$launched_pid"
    local cleanup_start="$launched_start"
    if _robin_managed_process_running; then
      cleanup_pid="$ROBIN_PID"
      cleanup_start="$ROBIN_PID_START"
    fi
    if [[ -n "$cleanup_pid" && -n "$cleanup_start" ]] &&
       ! _robin_terminate_managed_process "$cleanup_pid" "$cleanup_start"; then
      log_error "Failed to stop the unhealthy Robin process; PID record was preserved"
      if [[ ! -f "$ROBIN_PID_FILE" ]]; then
        _robin_write_pid "$cleanup_pid" || true
      fi
    else
      rm -f "$ROBIN_PID_FILE"
    fi
    log_error "Robin did not become healthy within ${ROBIN_START_TIMEOUT}s"
    log_info "Runtime log: $ROBIN_LOG"
  fi

  _robin_release_lock
  return "$rc"
}

_robin_stop() {
  if [[ $# -gt 0 ]]; then
    log_error "karnel robin stop does not accept options"
    return 1
  fi
  _robin_acquire_lock || return 1

  if ! _robin_read_pid; then
    local -a matching_processes=()
    mapfile -t matching_processes < <(_robin_find_matching_processes)
    if (( ${#matching_processes[@]} == 1 )); then
      ROBIN_PID=${matching_processes[0]}
      ROBIN_PID_START=$(_robin_proc_start_time "$ROBIN_PID") || {
        log_error "Could not validate the unmanaged Robin process"
        _robin_release_lock
        return 1
      }
      log_warn "Adopting a validated Robin process without PID metadata (PID: $ROBIN_PID)"
      _robin_write_pid "$ROBIN_PID" || {
        log_error "Could not create safe PID metadata"
        _robin_release_lock
        return 1
      }
    elif (( ${#matching_processes[@]} > 1 )); then
      log_error "Multiple unmanaged Robin processes were found; no process was signaled"
      _robin_release_lock
      return 1
    elif _robin_http_healthy; then
      log_warn "A server responds on port $ROBIN_PORT but its identity is not Robin"
      log_warn "No process was signaled"
      _robin_release_lock
      return 1
    else
      log_info "Robin nao esta em execucao"
      rm -f "$ROBIN_PID_FILE"
      _robin_release_lock
      return 0
    fi
  fi

  if ! _robin_process_matches "$ROBIN_PID" "$ROBIN_PID_START"; then
    log_warn "Stale or unsafe PID record detected; no process was signaled"
    rm -f "$ROBIN_PID_FILE"
    _robin_release_lock
    return 1
  fi

  local pid="$ROBIN_PID"
  local start_time="$ROBIN_PID_START"
  log_info "Encerrando Robin (PID: $pid)..."
  if ! _robin_terminate_managed_process "$pid" "$start_time"; then
    log_error "Could not terminate Robin safely; PID record was preserved"
    _robin_release_lock
    return 1
  fi

  rm -f "$ROBIN_PID_FILE"
  log_success "Robin encerrado"
  log_info "Tor continua em execucao para nao interromper outros aplicativos"
  _robin_release_lock
}

_robin_status() {
  if [[ $# -gt 0 ]]; then
    log_error "karnel robin status does not accept options"
    return 1
  fi

  echo
  box "Robin Status"
  echo
  local errors=0

  if [[ -d "$ROBIN_APP_DIR/.git" ]]; then
    local commit version
    commit=$(git -C "$ROBIN_APP_DIR" rev-parse HEAD 2>/dev/null || printf 'unknown')
    version=$(git -C "$ROBIN_APP_DIR" describe --tags --exact-match 2>/dev/null || printf '%s' "${commit:0:7}")
    log_success "Robin: instalado ($version)"
    if [[ "$commit" == "$ROBIN_COMMIT" ]]; then
      log_success "Source pin: verificado"
    else
      log_warn "Source pin: diferente do release Karnel $ROBIN_VERSION"
    fi
    [[ "$ROBIN_LAYOUT" == "legacy" ]] && log_warn "Layout antigo detectado; execute: karnel robin update"
  else
    log_error "Robin source: ausente"
    ((errors++))
  fi

  if [[ -x "$ROBIN_VENV_DIR/bin/python" ]]; then
    log_success "Virtual env: ok"
  else
    log_error "Virtual env: ausente"
    ((errors++))
  fi

  if _robin_socket_open 127.0.0.1 9050; then
    log_success "Tor SOCKS: respondendo em 127.0.0.1:9050"
  elif command -v tor &>/dev/null; then
    log_warn "Tor: instalado, proxy parado"
  else
    log_error "Tor: nao instalado"
    ((errors++))
  fi

  if _robin_managed_process_running; then
    if _robin_http_healthy; then
      log_success "Streamlit: saudavel (PID: $ROBIN_PID)"
      log_info "URL: http://127.0.0.1:$ROBIN_PORT"
    else
      log_error "Streamlit: processo ativo, health check falhou"
      ((errors++))
    fi
  elif [[ -f "$ROBIN_PID_FILE" ]]; then
    log_warn "Streamlit: PID record obsoleto ou inseguro"
  elif _robin_http_healthy; then
    log_warn "Streamlit: servidor nao gerenciado responde na porta $ROBIN_PORT"
  else
    log_info "Streamlit: parado"
  fi

  local env_file="$ROBIN_ACTIVE_ENV_FILE"
  if [[ -f "$env_file" ]]; then
    local mode providers
    mode=$(stat -c '%a' "$env_file" 2>/dev/null || printf 'unknown')
    providers=$(_robin_configured_provider_count "$env_file")
    if [[ "$mode" == "600" ]]; then
      log_success "Configuracao: protegida ($providers provedor(es) configurado(s))"
    else
      log_warn "Configuracao: permissao $mode; execute karnel robin config para reparar"
    fi
  else
    log_warn "Configuracao: ausente"
  fi

  if [[ -d "$ROBIN_ACTIVE_INVESTIGATIONS_DIR" ]]; then
    local investigations
    investigations=$(printf '%s\n' "$ROBIN_ACTIVE_INVESTIGATIONS_DIR"/investigation_*.json)
    if [[ "$investigations" == *'*'* ]]; then
      investigations=0
    else
      investigations=$(printf '%s\n' "$investigations" | wc -l)
    fi
    log_info "Investigacoes salvas: $investigations"
  fi
  [[ -f "$ROBIN_LOG" ]] && log_info "Log: $ROBIN_LOG"
  echo
  (( errors == 0 ))
}

_robin_config() {
  if [[ $# -gt 0 ]]; then
    log_error "karnel robin config does not accept options"
    return 1
  fi
  _robin_ensure_installed || return 1

  _robin_acquire_lock || return 1
  local rc=0
  import "@/tools/osint/robin/install"
  _robin_migrate_legacy_layout || rc=$?
  if (( rc == 0 )); then
    _robin_prepare_persistent_data "$ROBIN_APP_DIR" || rc=$?
  fi
  if (( rc == 0 )); then
    chmod 700 "$ROBIN_CONFIG_DIR" 2>/dev/null || true
    chmod 600 "$ROBIN_ENV_FILE" || rc=$?
  fi
  _robin_release_lock
  (( rc == 0 )) || return "$rc"

  echo
  box "Configuracao do Robin"
  echo
  log_info "Arquivo protegido: $ROBIN_ENV_FILE"
  log_info "Edite com: nano $ROBIN_ENV_FILE"
  echo
  log_info "Provedores e endpoints suportados:"
  list_item "OPENAI_API_KEY"
  list_item "ANTHROPIC_API_KEY"
  list_item "GOOGLE_API_KEY"
  list_item "OPENROUTER_API_KEY / OPENROUTER_BASE_URL"
  list_item "OLLAMA_BASE_URL"
  list_item "LLAMA_CPP_BASE_URL"
  list_item "CUSTOM_API_BASE_URL / CUSTOM_API_KEY / CUSTOM_API_MODEL"
  echo
  log_warn "Trafego para provedores de IA normalmente nao passa pelo Tor."
  log_warn "Nunca compartilhe ou commite esse arquivo."
  echo
}

_robin_doctor() {
  local network=false
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --network) network=true ;;
      --help|-h) _robin_help; return ;;
      *) log_error "Unknown doctor option: $1"; return 1 ;;
    esac
    shift
  done

  echo
  box "Robin Doctor - Diagnostico"
  echo
  local errors=0

  if command -v python3 &>/dev/null; then
    local py_version
    py_version=$(python3 --version 2>&1)
    log_success "Python: $py_version"
  else
    log_error "Python 3: ausente"
    ((errors++))
  fi

  if [[ -x "$ROBIN_VENV_DIR/bin/python" ]]; then
    log_success "Virtual env: presente"
    import "@/tools/osint/robin/install"
    if _robin_verify_install "$ROBIN_APP_DIR" "$ROBIN_VENV_DIR"; then
      local streamlit_version pyarrow_version
      streamlit_version=$(
        "$ROBIN_VENV_DIR/bin/python" -c 'import streamlit; print(streamlit.__version__)'
      )
      pyarrow_version=$(
        "$ROBIN_VENV_DIR/bin/python" -c 'import pyarrow; print(pyarrow.__version__)'
      )
      log_success "Dependencias Robin: imports verificados"
      log_info "Streamlit $streamlit_version; pyarrow Termux $pyarrow_version"
    else
      log_error "Dependencias Robin: verificacao falhou"
      ((errors++))
    fi
  else
    log_error "Virtual env: ausente"
    ((errors++))
  fi

  if [[ -d "$ROBIN_APP_DIR/.git" ]]; then
    local commit
    commit=$(git -C "$ROBIN_APP_DIR" rev-parse HEAD 2>/dev/null || printf 'unknown')
    if [[ "$commit" == "$ROBIN_COMMIT" ]]; then
      log_success "Source: $ROBIN_VERSION verificado"
    else
      log_error "Source: commit inesperado ($commit)"
      ((errors++))
    fi
  else
    log_error "Source: ausente"
    ((errors++))
  fi

  if _robin_socket_open 127.0.0.1 9050; then
    log_success "Tor SOCKS: respondendo"
  elif command -v tor &>/dev/null; then
    log_info "Tor: instalado; o proxy sera iniciado por karnel robin start"
  else
    log_error "Tor: nao instalado"
    ((errors++))
  fi

  if _robin_socket_open 127.0.0.1 "$ROBIN_PORT"; then
    if _robin_http_healthy; then
      log_success "Streamlit: health endpoint ok"
    else
      log_error "Porta $ROBIN_PORT ocupada sem health check do Robin"
      ((errors++))
    fi
  else
    log_info "Porta $ROBIN_PORT: disponivel"
  fi

  if [[ -f "$ROBIN_ACTIVE_ENV_FILE" ]]; then
    local mode providers
    mode=$(stat -c '%a' "$ROBIN_ACTIVE_ENV_FILE" 2>/dev/null || printf 'unknown')
    providers=$(_robin_configured_provider_count "$ROBIN_ACTIVE_ENV_FILE")
    if [[ "$mode" == "600" ]]; then
      log_success ".env: permissao 600"
    else
      log_error ".env: permissao insegura ($mode)"
      ((errors++))
    fi
    if (( providers > 0 )); then
      log_success "Provedores configurados: $providers"
    else
      log_warn "Nenhum provedor real detectado; configure antes de investigar"
    fi
  else
    log_error ".env: ausente"
    ((errors++))
  fi

  if [[ -d "$ROBIN_ACTIVE_INVESTIGATIONS_DIR" && -w "$ROBIN_ACTIVE_INVESTIGATIONS_DIR" ]]; then
    log_success "Diretorio de investigacoes: gravavel"
  else
    log_error "Diretorio de investigacoes: ausente ou sem escrita"
    ((errors++))
  fi

  if $network; then
    log_info "Verificando uma requisicao HTTPS atraves do Tor..."
    if ! _robin_socket_open 127.0.0.1 9050; then
      log_error "Rede Tor: proxy parado; execute karnel robin start primeiro"
      ((errors++))
    elif curl --fail --silent --show-error --socks5-hostname 127.0.0.1:9050 \
      --max-time 30 --output /dev/null https://example.com; then
      log_success "Rede Tor: requisicao concluida"
    else
      log_error "Rede Tor: requisicao falhou"
      ((errors++))
    fi
  else
    log_info "Teste externo ignorado; use --network para verificar trafego Tor"
  fi

  echo
  if (( errors == 0 )); then
    log_success "Diagnostico concluido sem erros criticos"
    return 0
  fi
  log_error "Diagnostico encontrou $errors erro(s) critico(s)"
  return 1
}

_robin_update() {
  if [[ $# -gt 0 ]]; then
    log_error "karnel robin update does not accept options"
    return 1
  fi
  _robin_ensure_installed || return 1
  import "@/tools/osint/robin/install"
  update_robin
  local rc=$?
  [[ $rc -eq 2 ]] && return 0
  return "$rc"
}

_robin_purge_data() {
  local confirmed=false
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --yes) confirmed=true ;;
      *) log_error "Unknown purge-data option: $1"; return 1 ;;
    esac
    shift
  done

  _robin_acquire_lock || return 1
  import "@/tools/osint/robin/install"
  if ! _robin_migrate_legacy_layout; then
    _robin_release_lock
    return 1
  fi
  if _robin_runtime_active; then
    log_error "Stop Robin before deleting data: karnel robin stop"
    _robin_release_lock
    return 1
  fi
  log_warn "This permanently deletes Robin provider configuration and investigations:"
  list_item "$ROBIN_CONFIG_DIR"
  list_item "$ROBIN_DATA_DIR"

  if ! $confirmed; then
    if [[ ! -t 0 ]]; then
      log_error "Non-interactive purge requires: karnel robin purge-data --yes"
      _robin_release_lock
      return 1
    fi
    log_info "Digite 'PURGE' para confirmar a exclusao permanente:"
    local answer=""
    read -r answer
    [[ "$answer" == "PURGE" ]] || {
      log_info "Exclusao cancelada"
      _robin_release_lock
      return 1
    }
  fi

  if ! rm -rf "$ROBIN_CONFIG_DIR" "$ROBIN_DATA_DIR"; then
    log_error "Failed to delete Robin data"
    _robin_release_lock
    return 1
  fi
  if [[ -d "$ROBIN_APP_DIR" ]]; then
    _robin_prepare_persistent_data "$ROBIN_APP_DIR" || {
      _robin_release_lock
      return 1
    }
  fi
  log_success "Robin configuration and investigations were permanently deleted"
  _robin_release_lock
}

_robin_help() {
  echo
  box "Robin - OSINT Tool Manager"
  echo
  log_info "Uso: karnel robin <subcomando> [opcoes]"
  echo
  printf "    ${D_CYAN}%-14s${NC} %s\n" "start" "Start Tor and the loopback-only web interface"
  printf "    ${D_CYAN}%-14s${NC} %s\n" "stop" "Stop the managed Robin interface"
  printf "    ${D_CYAN}%-14s${NC} %s\n" "status" "Show installation and runtime state"
  printf "    ${D_CYAN}%-14s${NC} %s\n" "config" "Show protected provider configuration"
  printf "    ${D_CYAN}%-14s${NC} %s\n" "doctor" "Run local diagnostics; --network tests Tor traffic"
  printf "    ${D_CYAN}%-14s${NC} %s\n" "update" "Reconcile with Karnel's pinned Robin release"
  printf "    ${D_CYAN}%-14s${NC} %s\n" "purge-data" "Permanently delete config and investigations"
  echo
  log_info "First non-interactive start:"
  list_item "karnel robin start --accept-responsible-use"
  log_info "Documentacao: $ROBIN_DOCS_URL"
  echo
}
