#!/usr/bin/env bash
# Public constants and layout state are consumed by separately imported modules.
# shellcheck disable=SC2034

ROBIN_REPO="https://github.com/apurvsinghgautam/robin.git"
ROBIN_DOCS_URL="https://github.com/apurvsinghgautam/robin"
ROBIN_VERSION="v2.8"
ROBIN_COMMIT="3c346fc6ba89034e71be38f3fa2912a633596435"
ROBIN_NOTICE_VERSION="2026-07-18.1"

ROBIN_ROOT="${ROBIN_ROOT:-$KARNEL_TOOLS/osint/robin}"
ROBIN_MANAGED_APP_DIR="$ROBIN_ROOT/app"
ROBIN_MANAGED_VENV_DIR="$ROBIN_ROOT/.venv"
ROBIN_CONFIG_DIR="${ROBIN_CONFIG_DIR:-$KARNEL_CONFIG/robin}"
ROBIN_ENV_FILE="$ROBIN_CONFIG_DIR/.env"
ROBIN_DATA_DIR="${ROBIN_DATA_DIR:-$KARNEL_DATA/robin}"
ROBIN_INVESTIGATIONS_DIR="$ROBIN_DATA_DIR/investigations"
ROBIN_PID_FILE="${ROBIN_PID_FILE:-$KARNEL_RUN/robin.pid}"
ROBIN_LOCK_DIR="${ROBIN_LOCK_DIR:-$KARNEL_RUN/robin.lock}"
ROBIN_LOG="${ROBIN_LOG:-$KARNEL_LOGS/robin.log}"
ROBIN_PORT="${ROBIN_PORT:-8501}"
ROBIN_START_TIMEOUT="${ROBIN_START_TIMEOUT:-60}"
ROBIN_PROC_ROOT="${ROBIN_PROC_ROOT:-/proc}"
ROBIN_ACK_FILE="$ROBIN_CONFIG_DIR/responsible-use"

_robin_refresh_layout() {
  if [[ -d "$ROBIN_ROOT/.git" && ! -d "$ROBIN_MANAGED_APP_DIR/.git" ]]; then
    ROBIN_LAYOUT="legacy"
    ROBIN_APP_DIR="$ROBIN_ROOT"
    ROBIN_VENV_DIR="$ROBIN_ROOT/.venv"
    ROBIN_ACTIVE_ENV_FILE="$ROBIN_ROOT/.env"
    ROBIN_ACTIVE_INVESTIGATIONS_DIR="$ROBIN_ROOT/investigations"
  else
    ROBIN_LAYOUT="managed"
    ROBIN_APP_DIR="$ROBIN_MANAGED_APP_DIR"
    ROBIN_VENV_DIR="$ROBIN_MANAGED_VENV_DIR"
    ROBIN_ACTIVE_ENV_FILE="$ROBIN_ENV_FILE"
    ROBIN_ACTIVE_INVESTIGATIONS_DIR="$ROBIN_INVESTIGATIONS_DIR"
  fi
}

_robin_refresh_layout

_robin_is_installed() {
  [[ -d "$ROBIN_APP_DIR/.git" && -x "$ROBIN_VENV_DIR/bin/python" ]]
}

_robin_python_path() {
  if [[ -x "$ROBIN_VENV_DIR/bin/python" ]]; then
    printf '%s\n' "$ROBIN_VENV_DIR/bin/python"
  elif command -v python3 &>/dev/null; then
    command -v python3
  else
    return 1
  fi
}

_robin_socket_open() {
  local host="$1"
  local port="$2"
  local python
  python=$(_robin_python_path) || return 1

  "$python" -c '
import socket
import sys

try:
    with socket.create_connection((sys.argv[1], int(sys.argv[2])), timeout=1):
        pass
except OSError:
    raise SystemExit(1)
' "$host" "$port" &>/dev/null
}

_robin_http_healthy() {
  if command -v curl &>/dev/null; then
    [[ "$(curl --fail --silent --show-error --max-time 2 \
      "http://127.0.0.1:$ROBIN_PORT/_stcore/health" 2>/dev/null)" == "ok" ]]
    return $?
  fi

  local python
  python=$(_robin_python_path) || return 1
  "$python" -c '
import sys
import urllib.request

try:
    with urllib.request.urlopen(sys.argv[1], timeout=2) as response:
        body = response.read().decode().strip()
except Exception:
    raise SystemExit(1)
raise SystemExit(0 if body == "ok" else 1)
' "http://127.0.0.1:$ROBIN_PORT/_stcore/health" &>/dev/null
}

_robin_proc_start_time() {
  local pid="$1"
  local -a stat_fields=()
  [[ -r "$ROBIN_PROC_ROOT/$pid/stat" ]] || return 1
  read -r -a stat_fields < "$ROBIN_PROC_ROOT/$pid/stat" || return 1
  [[ ${#stat_fields[@]} -ge 22 ]] || return 1
  [[ "${stat_fields[2]}" != "Z" && "${stat_fields[2]}" != "X" ]] || return 1
  printf '%s\n' "${stat_fields[21]}"
}

_robin_process_matches() {
  local pid="$1"
  local recorded_start="${2:-}"
  [[ "$pid" =~ ^[1-9][0-9]*$ ]] || return 1
  kill -0 "$pid" 2>/dev/null || return 1

  local current_start
  current_start=$(_robin_proc_start_time "$pid") || return 1
  if [[ -n "$recorded_start" && "$current_start" != "$recorded_start" ]]; then
    return 1
  fi

  local cmdline=""
  if [[ -r "$ROBIN_PROC_ROOT/$pid/cmdline" ]]; then
    cmdline=$(tr '\0' ' ' < "$ROBIN_PROC_ROOT/$pid/cmdline")
  fi
  [[ "$cmdline" == *"streamlit"* && "$cmdline" == *"ui.py"* ]] || return 1

  local process_cwd=""
  process_cwd=$(readlink -f "$ROBIN_PROC_ROOT/$pid/cwd" 2>/dev/null || true)
  [[ "$process_cwd" == "$ROBIN_APP_DIR" ]] || return 1
}

_robin_read_pid() {
  ROBIN_PID=""
  ROBIN_PID_START=""
  [[ -r "$ROBIN_PID_FILE" ]] || return 1
  read -r ROBIN_PID ROBIN_PID_START < "$ROBIN_PID_FILE" || return 1
  [[ "$ROBIN_PID" =~ ^[1-9][0-9]*$ && "$ROBIN_PID_START" =~ ^[1-9][0-9]*$ ]]
}

_robin_managed_process_running() {
  _robin_read_pid || return 1
  _robin_process_matches "$ROBIN_PID" "$ROBIN_PID_START"
}

_robin_runtime_active() {
  _robin_managed_process_running || _robin_socket_open 127.0.0.1 "$ROBIN_PORT"
}

_robin_find_matching_processes() {
  local process_dir pid
  for process_dir in "$ROBIN_PROC_ROOT"/[0-9]*; do
    [[ -d "$process_dir" ]] || continue
    pid=${process_dir##*/}
    _robin_process_matches "$pid" && printf '%s\n' "$pid"
  done
}

_robin_write_pid() {
  local pid="$1"
  local start_time
  start_time=$(_robin_proc_start_time "$pid") || return 1
  mkdir -p "$KARNEL_RUN"
  chmod 700 "$KARNEL_RUN" 2>/dev/null || true
  local temporary="$ROBIN_PID_FILE.tmp.$$"
  (umask 077; printf '%s %s\n' "$pid" "$start_time" > "$temporary") || return 1
  mv "$temporary" "$ROBIN_PID_FILE"
}

_robin_acquire_lock() {
  mkdir -p "$KARNEL_RUN"
  chmod 700 "$KARNEL_RUN" 2>/dev/null || true

  if mkdir "$ROBIN_LOCK_DIR" 2>/dev/null; then
    (umask 077; printf '%s\n' "$$" > "$ROBIN_LOCK_DIR/pid")
    return 0
  fi

  local owner=""
  [[ -r "$ROBIN_LOCK_DIR/pid" ]] && read -r owner < "$ROBIN_LOCK_DIR/pid"
  if [[ "$owner" =~ ^[1-9][0-9]*$ ]] && kill -0 "$owner" 2>/dev/null; then
    log_error "Another Robin operation is already running (PID: $owner)"
    return 1
  fi

  rm -f "$ROBIN_LOCK_DIR/pid"
  rmdir "$ROBIN_LOCK_DIR" 2>/dev/null || {
    log_error "Could not clear stale Robin lock: $ROBIN_LOCK_DIR"
    return 1
  }
  mkdir "$ROBIN_LOCK_DIR" || return 1
  (umask 077; printf '%s\n' "$$" > "$ROBIN_LOCK_DIR/pid")
}

_robin_release_lock() {
  rm -f "$ROBIN_LOCK_DIR/pid"
  rmdir "$ROBIN_LOCK_DIR" 2>/dev/null || true
}

_robin_rotate_log() {
  [[ -f "$ROBIN_LOG" ]] || return 0
  local size
  size=$(wc -c < "$ROBIN_LOG" 2>/dev/null || printf '0')
  if (( size > 1048576 )); then
    mv -f "$ROBIN_LOG" "$ROBIN_LOG.1"
  fi
}

_robin_print_disclaimer() {
  echo
  box "ATENCAO - USO RESPONSAVEL"
  echo
  log_warn "Use Robin somente em pesquisas legais, autorizadas e eticas."
  log_info "Tor melhora a privacidade da conexao, mas nao garante anonimato."
  log_info "O Robin acessa paginas automaticamente; nao execute nem abra arquivos desconhecidos."
  log_info "Consultas, URLs, conteudo coletado e resumos podem ser enviados diretamente"
  log_info "ao provedor de IA configurado, fora da rede Tor, e processados por terceiros."
  log_info "Investigacoes sao salvas localmente em texto simples. Minimize dados pessoais"
  log_info "e siga as leis, politicas institucionais e termos dos provedores aplicaveis."
  log_info "Resultados de IA podem estar errados e nao constituem evidencia verificada."
  log_info "A interface deve permanecer em 127.0.0.1; nunca exponha a porta $ROBIN_PORT."
  log_info "Robin e um projeto independente: $ROBIN_DOCS_URL"
  echo
}

_robin_notice_accepted() {
  [[ -r "$ROBIN_ACK_FILE" ]] || return 1
  grep -qx "notice_version=$ROBIN_NOTICE_VERSION" "$ROBIN_ACK_FILE" 2>/dev/null
}

_robin_require_acknowledgement() {
  local explicit_accept="${1:-false}"
  _robin_notice_accepted && return 0

  if [[ "$explicit_accept" == "true" ]]; then
    :
  elif [[ -t 0 ]]; then
    log_info "Digite 'yes' para confirmar que leu e aceita o aviso acima:"
    local confirmation=""
    read -r confirmation
    if [[ "$confirmation" != "yes" ]]; then
      log_error "Confirmacao necessaria para iniciar o Robin"
      return 1
    fi
  else
    log_error "Uso nao interativo requer: karnel robin start --accept-responsible-use"
    return 1
  fi

  mkdir -p "$ROBIN_CONFIG_DIR"
  chmod 700 "$ROBIN_CONFIG_DIR" 2>/dev/null || true
  local temporary="$ROBIN_ACK_FILE.tmp.$$"
  {
    umask 077
    printf 'notice_version=%s\naccepted_at=%s\n' \
      "$ROBIN_NOTICE_VERSION" "$(date -u +%Y-%m-%dT%H:%M:%SZ)" > "$temporary"
  } || return 1
  mv "$temporary" "$ROBIN_ACK_FILE"
  log_success "Confirmacao registrada para o aviso $ROBIN_NOTICE_VERSION"
}
