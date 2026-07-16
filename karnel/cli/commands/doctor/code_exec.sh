#!/usr/bin/env bash

declare -g _CODE_REPORT_DIR=""
declare -ga _CODE_RESULTS=()

_exec_init() {
  _CODE_REPORT_DIR="$KARNEL_DATA/doctor_code_reports"
  mkdir -p "$_CODE_REPORT_DIR" || return 1
  _CODE_RESULTS=()
}

_exec_run_tool() {
  local tool="$1" cat="$2" cmd="$3" lang="$4" file="$5" dir="${6:-$PWD}"
  local full_cmd; full_cmd="$(_tool_command "$cmd" "$file")"

  if ! (cd "$dir" && _is_tool_available "$tool"); then
    _CODE_RESULTS+=("__MISSING__|$lang|$tool|$cat|||")
    return 2
  fi

  local out rc
  if out="$(cd "$dir" && _run_tool_check "$tool" "$full_cmd" 30)"; then
    rc=0
  else
    rc=$?
  fi

  if [[ "$out" == "__TOOL_NOT_FOUND__" ]]; then
    _CODE_RESULTS+=("__MISSING__|$lang|$tool|$cat|||")
    return 2
  fi

  local severity="info" count=0
  if (( rc != 0 )); then
    severity="error"
    count=1
    if [[ -z "$out" ]]; then
      if (( rc == 124 )); then
        out="Timed out after 30 seconds"
      else
        out="Command exited with status $rc"
      fi
    fi
  elif [[ -z "$out" ]]; then
    severity="ok"
  else
    local lower; lower=$(printf '%s\n' "$out" | tr '[:upper:]' '[:lower:]')
    if printf '%s\n' "$lower" | grep -qE 'error|fail|critical|fatal|panic'; then
      severity="error"
      count=$(printf '%s\n' "$lower" | grep -cE 'error|fail|critical|fatal|panic' || true)
    elif printf '%s\n' "$lower" | grep -qE 'warning|warn|deprecated|should'; then
      severity="warning"
      count=$(printf '%s\n' "$lower" | grep -cE 'warning|warn|deprecated|should' || true)
    fi
  fi

  local detail line_count
  detail=$(printf '%s\n' "$out" | head -5 | tr '\n' '; ')
  line_count=$(printf '%s\n' "$out" | wc -l)
  (( line_count > 5 )) && detail+="..."
  _CODE_RESULTS+=("$severity|$lang|$tool|$cat|$count|$detail")
  return "$rc"
}

_find_tool_sample() {
  local tool="$1" lang="$2" dir="$3"
  local -a names=()

  case "$tool" in
    jq) names=(-name '*.json') ;;
    xmllint) names=(-name '*.xml') ;;
    *)
      case "$lang" in
        Shell) names=(-name '*.sh' -o -name '*.bash' -o -name '*.zsh') ;;
        SQL) names=(-name '*.sql') ;;
        C/C++|C|C++) names=(-name '*.c' -o -name '*.cpp' -o -name '*.cc' -o -name '*.h' -o -name '*.hpp') ;;
        PHP) names=(-name '*.php') ;;
        Ruby) names=(-name '*.rb') ;;
        Java) names=(-name '*.java') ;;
        Kotlin) names=(-name '*.kt' -o -name '*.kts') ;;
        Dart) names=(-name '*.dart') ;;
        Lua) names=(-name '*.lua') ;;
      esac
      ;;
  esac

  [[ ${#names[@]} -gt 0 ]] || return 1
  local sample
  sample=$(find "$dir" \
    \( -type d \( -name node_modules -o -name .git -o -name .venv -o -name venv -o -name target -o -name dist -o -name build -o -name vendor \) -prune \) -o \
    \( -type f \( "${names[@]}" \) -print -quit \) 2>/dev/null)
  [[ -n "$sample" ]] || return 1
  printf '%s\n' "$sample"
}

_exec_run_lang() {
  local lang="$1" dir="$2" mode="$3" include_global="${4:-true}"
  local entry tool category cmd_run sample

  while IFS= read -r entry; do
    [[ -z "$entry" ]] && continue
    _parse_lang_tool "$entry"
    tool="${PARSED_LANG_TOOL[0]}"
    category="${PARSED_LANG_TOOL[1]}"
    cmd_run="${PARSED_LANG_TOOL[2]}"

    sample=""
    if [[ "$cmd_run" == *'{}'* ]]; then
      sample=$(_find_tool_sample "$tool" "$lang" "$dir") || continue
    fi
    _exec_run_tool "$tool" "$category" "$cmd_run" "$lang" "$sample" "$dir" || true
  done < <(_get_lang_tools "$lang" "$mode" "$include_global")
}

_exec_apply_fix() {
  local tool="$1" fix_cmd="$2" lang="$3" file="$4" dir="${5:-$PWD}"
  local full_cmd; full_cmd="$(_tool_command "$fix_cmd" "$file")"

  if [[ "$fix_cmd" == *'{}'* && -z "$file" ]]; then
    log_warn "Cannot fix — no matching file found for $tool"
    return 1
  fi

  if ! (cd "$dir" && _is_tool_available "$tool"); then
    log_warn "Cannot fix — $tool not installed"
    return 1
  fi

  log_info "Applying fix: $tool ($lang)..."
  local out rc
  if out=$(cd "$dir" && timeout 60 bash -c "$full_cmd" 2>&1); then
    rc=0
  else
    rc=$?
  fi

  if (( rc == 0 )); then
    [[ -n "$out" ]] && log_info "$tool: $out"
    log_success "$tool fix applied"
    return 0
  fi

  log_warn "$tool fix failed (status $rc)${out:+: $out}"
  return "$rc"
}

_format_report() {
  local mode="${1:-text}" dir="$2"

  if [[ "$mode" == "json" ]]; then
    _format_json "$dir"
    return
  fi

  local lang_count=0 tool_count=0
  local -A langs_seen tools_seen

  # Collect unique langs and tools
  for entry in "${_CODE_RESULTS[@]}"; do
    IFS='|' read -r severity lang tool cat count detail <<< "$entry"
    [[ -z "$lang" || "$lang" == "__MISSING__" ]] && continue
    if [[ "$lang" != "Cross-language" && -z "${langs_seen[$lang]}" ]]; then
      langs_seen[$lang]=1
      lang_count=$((lang_count + 1))
    fi
    [[ -z "${tools_seen[$tool]}" ]] && tools_seen[$tool]=1 && ((tool_count++))
  done

  echo
  separator_section "Results"
  echo

  if [[ ${#_CODE_RESULTS[@]} -eq 0 ]]; then
    log_info "No analysis results — no tools were executed."
    echo
    return
  fi

  local errors=0 warnings=0 infos=0 missing=0
  for entry in "${_CODE_RESULTS[@]}"; do
    IFS='|' read -r severity lang tool cat count detail <<< "$entry"
    case "$severity" in
      __MISSING__) ((missing++)) ;;
      error) ((errors++)) ;;
      warning) ((warnings++)) ;;
      ok) ;;
      *) ((infos++)) ;;
    esac
  done

  printf "    ${D_CYAN}Languages:${NC} %-2d  ${D_CYAN}Tools:${NC} %-2d  ${D_CYAN}Checks:${NC} %-2d\n" "$lang_count" "$tool_count" "${#_CODE_RESULTS[@]}"
  echo
  printf "    ${D_RED}%-4s${NC} ${D_YELLOW}%-4s${NC} ${D_BLUE}%-4s${NC}\n" "Errors" "Warns" "Info"
  printf "    ${D_RED}%-4d${NC} ${D_YELLOW}%-4d${NC} ${D_BLUE}%-4d${NC}\n" "$errors" "$warnings" "$infos"
  if (( missing > 0 )); then
    echo; log_warn "$missing tool(s) not installed — install them for deeper analysis"
  fi

  echo
  separator_section "Detailed Findings"
  echo

  for entry in "${_CODE_RESULTS[@]}"; do
    IFS='|' read -r severity lang tool cat count detail <<< "$entry"
    if [[ "$severity" == "__MISSING__" ]]; then
      printf "    ${D_YELLOW}⚠${NC} %s ${D_CYAN}%s${NC} %s\n" "$lang" "$tool" "(not installed)"
      continue
    fi
    local color="$D_GREEN"
    case "$severity" in
      error) color="$D_RED" ;;
      warning) color="$D_YELLOW" ;;
      ok) color="$D_GREEN" ;;
      *) color="$D_BLUE" ;;
    esac
    if [[ "$severity" == "ok" ]]; then
      printf "    ${color}✔${NC} %s ${D_CYAN}%s${NC} (%s)\n" "$lang" "$tool" "$cat"
    else
      printf "    ${color}◈${NC} %s ${D_CYAN}%s${NC} [%s] %s\n" "$lang" "$tool" "$cat" "$(echo "$detail" | head -c 120)"
    fi
  done

  echo
  local report_file
  report_file="$_CODE_REPORT_DIR/doctor_code_$(date +%Y%m%d_%H%M%S).txt"
  _save_report "$report_file" "$dir"
}

_format_json() {
  local dir="$1"
  local first=true
  echo "{"
  printf '  "directory":"%s",\n' "$(_json_escape "$dir")"
  echo "  \"results\": ["
  for entry in "${_CODE_RESULTS[@]}"; do
    $first || echo ","
    first=false
    IFS='|' read -r severity lang tool cat count detail <<< "$entry"
    printf '    {"severity":"%s","language":"%s","tool":"%s","category":"%s","count":%d,"detail":"%s"}' \
      "$(_json_escape "$severity")" "$(_json_escape "$lang")" "$(_json_escape "$tool")" \
      "$(_json_escape "$cat")" "${count:-0}" "$(_json_escape "$detail")"
  done
  echo ""
  echo "  ]"
  echo "}"
}

_json_escape() {
  local value="$1"
  value="${value//\\/\\\\}"
  value="${value//\"/\\\"}"
  value="${value//$'\n'/\\n}"
  value="${value//$'\r'/\\r}"
  value="${value//$'\t'/\\t}"
  printf '%s' "$value"
}

_save_report() {
  local file="$1" dir="$2"
  {
    echo "Karnel Doctor Code Report"
    echo "Generated: $(date)"
    echo "Directory: $dir"
    echo "---"
    for entry in "${_CODE_RESULTS[@]}"; do
      IFS='|' read -r severity lang tool cat count detail <<< "$entry"
      echo "[$severity] $lang / $tool ($cat): $detail"
    done
  } > "$file" 2>/dev/null
  list_item "Report saved: ${D_CYAN}$file${NC}"
}
