#!/usr/bin/env bash

# Sponsor runtime for the independent Karnel distribution.
# The npm package ships this reusable code but never enables it automatically.

KARNEL_SPONSOR_ENDPOINT="${KARNEL_SPONSOR_ENDPOINT:-https://karneltermux.vercel.app/api/sponsors?format=tsv}"
KARNEL_SPONSOR_INTERVAL="${KARNEL_SPONSOR_INTERVAL:-86400}"
KARNEL_SPONSOR_CACHE_TTL="${KARNEL_SPONSOR_CACHE_TTL:-21600}"

[[ "$KARNEL_SPONSOR_ENDPOINT" == https://* ]] || KARNEL_SPONSOR_ENDPOINT="https://karneltermux.vercel.app/api/sponsors?format=tsv"
[[ "$KARNEL_SPONSOR_INTERVAL" =~ ^[0-9]+$ ]] || KARNEL_SPONSOR_INTERVAL=86400
[[ "$KARNEL_SPONSOR_CACHE_TTL" =~ ^[0-9]+$ ]] || KARNEL_SPONSOR_CACHE_TTL=21600

_sponsor_source_file="${KARNEL_SPONSOR_SOURCE_FILE:-$KARNEL_CONFIG/install-source}"
_sponsor_state_file="${KARNEL_SPONSOR_STATE_FILE:-$KARNEL_CONFIG/sponsors}"
_sponsor_cache_file="${KARNEL_SPONSOR_CACHE_FILE:-$KARNEL_CACHE/sponsors.tsv}"
_sponsor_last_show_file="${KARNEL_SPONSOR_LAST_SHOW_FILE:-$KARNEL_CACHE/sponsor-last-show}"
_sponsor_refresh_lock="${KARNEL_SPONSOR_REFRESH_LOCK:-$KARNEL_CACHE/sponsor-refresh.lock}"

_sponsor_now() {
  date +%s
}

_sponsor_file_mtime() {
  local file="$1"
  stat -c %Y "$file" 2>/dev/null || date -r "$file" +%s 2>/dev/null || echo 0
}

sponsor_install_source() {
  if [[ -f "$_sponsor_source_file" ]]; then
    head -n 1 "$_sponsor_source_file" 2>/dev/null | tr -d '\r\n'
  else
    printf '%s\n' "unknown"
  fi
}

sponsor_is_enabled() {
  [[ "$(sponsor_install_source)" == "direct" ]] || return 1
  [[ "${KARNEL_SPONSORS:-on}" != "off" ]] || return 1
  [[ "${KARNEL_SPONSORS:-1}" != "0" ]] || return 1
  [[ "${CI:-}" != "true" && "${CI:-}" != "1" ]] || return 1

  if [[ -f "$_sponsor_state_file" ]]; then
    [[ "$(head -n 1 "$_sponsor_state_file" 2>/dev/null | tr -d '\r\n')" == "on" ]]
    return
  fi

  return 1
}

sponsor_set_enabled() {
  local value="${1:-}"
  mkdir -p "$KARNEL_CONFIG"

  case "$value" in
    on)
      if [[ "$(sponsor_install_source)" != "direct" ]]; then
        return 2
      fi
      printf '%s\n' "on" >"$_sponsor_state_file"
      chmod 600 "$_sponsor_state_file" 2>/dev/null || true
      ;;
    off)
      printf '%s\n' "off" >"$_sponsor_state_file"
      chmod 600 "$_sponsor_state_file" 2>/dev/null || true
      ;;
    *)
      return 1
      ;;
  esac
}

_sponsor_line_is_valid() {
  local line="$1"
  local id name message url extra
  IFS=$'\t' read -r id name message url extra <<<"$line"

  [[ -z "$extra" ]] || return 1
  [[ "$id" =~ ^[A-Za-z0-9_-]{1,64}$ ]] || return 1
  [[ -n "$name" && ${#name} -le 60 ]] || return 1
  [[ -n "$message" && ${#message} -le 160 ]] || return 1
  [[ "$url" == https://* && ${#url} -le 300 ]] || return 1

  [[ "$name$message$url" != *$'\e'* ]] || return 1
  [[ "$name$message$url" != *$'\r'* ]] || return 1
  return 0
}

_sponsor_cache_is_fresh() {
  [[ -s "$_sponsor_cache_file" ]] || return 1
  local now mtime
  now="$(_sponsor_now)"
  mtime="$(_sponsor_file_mtime "$_sponsor_cache_file")"
  (( now - mtime < KARNEL_SPONSOR_CACHE_TTL ))
}

_sponsor_refresh_cache() {
  command -v curl >/dev/null 2>&1 || return 1
  mkdir -p "$KARNEL_CACHE"

  if ! mkdir "$_sponsor_refresh_lock" 2>/dev/null; then
    return 0
  fi

  local tmp clean line valid_count=0 refresh_status=1
  tmp="${_sponsor_cache_file}.tmp.$$"
  clean="${_sponsor_cache_file}.clean.$$"

  if curl -fsSL --connect-timeout 2 --max-time 4 \
    -H "Accept: text/plain" \
    "$KARNEL_SPONSOR_ENDPOINT" -o "$tmp" 2>/dev/null; then
    : >"$clean"
    while IFS= read -r line || [[ -n "$line" ]]; do
      if _sponsor_line_is_valid "$line"; then
        printf '%s\n' "$line" >>"$clean"
        valid_count=$((valid_count + 1))
      fi
    done <"$tmp"

    if (( valid_count > 0 )); then
      mv -f "$clean" "$_sponsor_cache_file"
      chmod 600 "$_sponsor_cache_file" 2>/dev/null || true
    else
      rm -f "$clean" "$_sponsor_cache_file"
    fi
    refresh_status=0
  fi

  rm -f "$tmp" "$clean"
  rmdir "$_sponsor_refresh_lock" 2>/dev/null || true
  return "$refresh_status"
}

_sponsor_refresh_async() {
  [[ "${KARNEL_SPONSOR_NO_REFRESH:-0}" != "1" ]] || return 0
  (_sponsor_refresh_cache >/dev/null 2>&1) &
}

_sponsor_pick_line() {
  [[ -s "$_sponsor_cache_file" ]] || return 1
  local -a lines=()
  local line

  while IFS= read -r line || [[ -n "$line" ]]; do
    _sponsor_line_is_valid "$line" && lines+=("$line")
  done <"$_sponsor_cache_file"

  (( ${#lines[@]} > 0 )) || return 1
  printf '%s\n' "${lines[$((RANDOM % ${#lines[@]}))]}"
}

_sponsor_render_line() {
  local line="$1"
  local id name message url
  IFS=$'\t' read -r id name message url <<<"$line"
  _sponsor_line_is_valid "$line" || return 1

  echo
  printf '  %s\n' '────────────────────────────────────────────────────────'
  printf '  Patrocinado por %s\n' "$name"
  printf '  %s\n' "$message"
  printf '  Saiba mais: %s\n' "$url"
  printf '  %s\n' 'Desative com: karnel sponsor off'
  printf '  %s\n' '────────────────────────────────────────────────────────'
  echo
}

sponsor_render_cached() {
  local line
  line="$(_sponsor_pick_line)" || return 1
  _sponsor_render_line "$line"
}

_sponsor_command_is_excluded() {
  case "${1:-}" in
    ""|sponsor|help|--help|-h|--version|version|update|upgrade|uninstall|reinstall)
      return 0
      ;;
    *)
      return 1
      ;;
  esac
}

sponsor_maybe_show() {
  local command_name="${1:-}"
  local command_status="${2:-1}"

  [[ "$command_status" == "0" ]] || return 0
  [[ -t 1 ]] || return 0
  sponsor_is_enabled || return 0
  _sponsor_command_is_excluded "$command_name" && return 0

  if ! _sponsor_cache_is_fresh; then
    _sponsor_refresh_async
    return 0
  fi

  local now last=0
  now="$(_sponsor_now)"
  if [[ -f "$_sponsor_last_show_file" ]]; then
    last="$(head -n 1 "$_sponsor_last_show_file" 2>/dev/null || echo 0)"
  fi
  [[ "$last" =~ ^[0-9]+$ ]] || last=0

  (( now - last >= KARNEL_SPONSOR_INTERVAL )) || return 0

  if sponsor_render_cached; then
    printf '%s\n' "$now" >"$_sponsor_last_show_file"
    chmod 600 "$_sponsor_last_show_file" 2>/dev/null || true
  fi
}

sponsor_force_show() {
  sponsor_is_enabled || return 2

  if [[ "${KARNEL_SPONSOR_NO_REFRESH:-0}" != "1" ]]; then
    _sponsor_refresh_cache >/dev/null 2>&1 || return 1
  fi

  sponsor_render_cached
}
