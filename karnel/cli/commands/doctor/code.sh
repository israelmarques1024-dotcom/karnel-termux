#!/usr/bin/env bash

import "@/utils/log"
import "@/utils/colors"
import "@/cli/commands/doctor/code_detect"
import "@/cli/commands/doctor/code_langs"
import "@/cli/commands/doctor/code_exec"

_doctor_code_language_dir() {
  local lang="$1" fallback="$2" manifest manifest_lang manifest_path
  for manifest in "${PROJECT_MANIFESTS[@]}"; do
    IFS=':' read -r manifest_lang manifest_path <<< "$manifest"
    if [[ "$manifest_lang" == "$lang" && -f "$manifest_path" ]]; then
      dirname "$manifest_path"
      return
    fi
  done
  printf '%s\n' "$fallback"
}

doctor_code() {
  local target_dir="" mode="quick" fix_mode="none" output="text"
  local -a args=()

  # Parse options
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --quick|-q) mode="quick" ;;
      --standard|-s) mode="standard" ;;
      --deep|-d) mode="deep" ;;
      --fix|--safe-fix) fix_mode="safe" ;;
      --aggressive-fix) fix_mode="aggressive" ;;
      --json|-j) output="json" ;;
      --help|-h) _doctor_code_help; return ;;
      --) shift; args+=("$@"); break ;;
      -*)
        if [[ -d "$1" ]]; then
          target_dir="$1"
        else
          log_warn "Unknown option: $1"
          _doctor_code_help
          return 1
        fi ;;
      *)
        if [[ -z "$target_dir" ]] && [[ -d "$1" ]]; then
          target_dir="$1"
        else
          args+=("$1")
        fi ;;
    esac
    shift
  done

  target_dir="${target_dir:-${args[0]:-${PWD}}}"
  target_dir="$(cd "$target_dir" 2>/dev/null && pwd)" || {
    log_error "Directory not found: $target_dir"; return 1
  }

  local human_output=true
  [[ "$output" == "json" ]] && human_output=false
  local fix_msg=""
  [[ "$fix_mode" != "none" ]] && fix_msg=" + fix: $fix_mode"
  if $human_output; then
    echo
    box "◈ KARNEL DOCTOR — CODE ◈"
    echo
    log_info "Analyzing: ${D_CYAN}$target_dir${NC}"
    log_info "Mode: ${D_CYAN}$mode${NC}${fix_msg}"
    echo
  fi

  _exec_init || return 1

  if ! _detect_project "$target_dir"; then
    return 1
  fi

  if [[ ${#PROJECT_LANGS[@]} -eq 0 ]]; then
    if $human_output; then
      log_warn "No recognized project structure found."
      echo
      log_info "Supported files:"; echo
      for sig in "package.json" "tsconfig.json" "pyproject.toml" "requirements.txt" \
                 "go.mod" "Cargo.toml" "Gemfile" "composer.json" "pubspec.yaml" \
                 "CMakeLists.txt" "Dockerfile" "pom.xml" "build.gradle" "*.csproj" \
                 "mix.exs" "build.zig" "flake.nix" "Project.toml" "*.sh" "*.sql"; do
        printf "    ${D_CYAN}%s${NC}\n" "$sig"
      done
      echo
    else
      _format_report "$output" "$target_dir"
    fi
    return
  fi

  # Deduplicate langs
  local -A seen; local unique_langs=()
  for l in "${PROJECT_LANGS[@]}"; do [[ -z "${seen[$l]}" ]] && seen[$l]=1 && unique_langs+=("$l"); done

  local manifest_map=()
  for m in "${PROJECT_MANIFESTS[@]}"; do
    IFS=':' read -r ml mp <<< "$m"
    manifest_map+=("$ml|$mp")
  done

  if $human_output; then
    separator_section "Ecosystems Detected"
    echo
    for lang in "${unique_langs[@]}"; do
      local found_man=""; local found_fw=""
      for m in "${manifest_map[@]}"; do
        IFS='|' read -r ml mp <<< "$m"
        [[ "$ml" == "$lang" ]] && found_man="$mp"
      done
      for fw_entry in "${PROJECT_FRAMEWORKS[@]}"; do
        IFS=':' read -r fw_lang fw_name <<< "$fw_entry"
        [[ "$fw_lang" == "$lang" ]] && found_fw="$fw_name"
      done
      printf "    ${D_GREEN}✔${NC} %s" "$lang"
      [[ -n "$found_man" ]] && printf " ${D_CYAN}(%s)${NC}" "$(basename "$(dirname "$found_man")" 2>/dev/null || printf '%s' "$(basename "$found_man")")"
      [[ -n "$found_fw" ]] && printf " → ${D_YELLOW}%s${NC}" "$found_fw"
      echo
    done

    if [[ ${#PROJECT_SUBDIRS[@]} -gt 0 ]]; then
      echo; separator_section "Subprojects"
      for sp in "${PROJECT_SUBDIRS[@]}"; do
        IFS=':' read -r sp_name _sp_path sp_langs _sp_fws <<< "$sp"
        printf "    ${D_CYAN}├─${NC} %s ${D_GREEN}(%s)${NC}\n" "$sp_name" "${sp_langs// /, }"
      done
    fi

    echo; separator_section "Analysis"
    echo
  fi

  $human_output && log_info "Analyzing ${D_CYAN}cross-language checks${NC} in ${D_CYAN}$target_dir${NC}..."
  _exec_run_lang "Cross-language" "$target_dir" "$mode" true
  for lang in "${unique_langs[@]}"; do
    local language_dir
    language_dir=$(_doctor_code_language_dir "$lang" "$target_dir")
    if $human_output; then
      log_info "Analyzing ${D_CYAN}$lang${NC} in ${D_CYAN}$language_dir${NC}..."
    fi
    _exec_run_lang "$lang" "$language_dir" "$mode" false
  done

  # Apply fixes if requested
  if [[ "$fix_mode" != "none" ]]; then
    if $human_output; then
      echo; separator_section "Auto-Fix"
      echo
    fi
    local fix_count=0
    for entry in "${_CODE_RESULTS[@]}"; do
      IFS='|' read -r severity lang tool category _ _ <<< "$entry"
      case "$severity" in
        error|warning|info) ;;
        *) continue ;;
      esac
      while IFS= read -r te; do
        [[ -z "$te" ]] && continue
        local t_name t_category t_fix t_safety fix_file=""
        _parse_lang_tool "$te"
        t_name="${PARSED_LANG_TOOL[0]}"
        t_category="${PARSED_LANG_TOOL[1]}"
        t_fix="${PARSED_LANG_TOOL[3]}"
        t_safety="${PARSED_LANG_TOOL[4]}"
        [[ "$t_name" == "$tool" && "$t_category" == "$category" && -n "$t_fix" ]] || continue
        if [[ "$fix_mode" == "safe" && "$t_safety" != "safe" ]]; then
          $human_output && log_info "Skipping $tool — fix is not classified as safe"
          continue
        fi
        local fix_dir="$target_dir" include_registry_global=false
        if [[ "$lang" == "Cross-language" ]]; then
          include_registry_global=true
        else
          fix_dir=$(_doctor_code_language_dir "$lang" "$target_dir")
        fi
        if [[ "$t_fix" == *'{}'* ]]; then
          fix_file=$(_find_tool_sample "$tool" "$lang" "$fix_dir") || continue
        fi
        if $human_output; then
          _exec_apply_fix "$tool" "$t_fix" "$lang" "$fix_file" "$fix_dir" || continue
        else
          _exec_apply_fix "$tool" "$t_fix" "$lang" "$fix_file" "$fix_dir" >&2 || continue
        fi
        fix_count=$((fix_count + 1))
      done < <(_get_lang_tools "$lang" "$mode" "$include_registry_global")
    done
    if (( fix_count == 0 )) && $human_output; then
      log_info "No auto-fixes available for current findings"
    fi
  fi

  _format_report "$output" "$target_dir"
  $human_output && echo
}

_doctor_code_help() {
  echo; box "◈ KARNEL DOCTOR — CODE ◈"
  echo
  log_info "Usage: karnel doctor code [options] [directory]"
  echo
  separator_section "Analysis Modes"
  printf "    ${D_CYAN}%-20s${NC} %s\n" "--quick, -q" "Syntax, format, lint, type-check, tests (default)"
  printf "    ${D_CYAN}%-20s${NC} %s\n" "--standard, -s" "Adds security, deps, coverage"
  printf "    ${D_CYAN}%-20s${NC} %s\n" "--deep, -d" "All registered check categories"
  echo
  separator_section "Fix Modes"
  printf "    ${D_CYAN}%-20s${NC} %s\n" "--fix, --safe-fix" "Apply safe auto-fixes only"
  printf "    ${D_CYAN}%-20s${NC} %s\n" "--aggressive-fix" "Apply fixes not classified as safe"
  echo
  separator_section "Output"
  printf "    ${D_CYAN}%-20s${NC} %s\n" "--json, -j" "Machine-readable JSON output"
  echo
  separator_section "Examples"
  list_item "${D_CYAN}karnel doctor code${NC} — Quick analysis of current dir"
  list_item "${D_CYAN}karnel doctor code --standard${NC} — Standard analysis"
  list_item "${D_CYAN}karnel doctor code --deep ~/projects/myapp${NC} — Deep analysis"
  list_item "${D_CYAN}karnel doctor code --fix${NC} — Quick + safe auto-fix"
  list_item "${D_CYAN}karnel doctor code --json > report.json${NC} — JSON output"
  echo
}
