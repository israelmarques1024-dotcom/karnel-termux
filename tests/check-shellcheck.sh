#!/usr/bin/env bash
set -euo pipefail

command -v shellcheck &>/dev/null || {
  printf 'shellcheck is required\n' >&2
  exit 1
}

scripts=()
while IFS= read -r file; do
  [[ -f "$file" ]] || continue
  first_line=""
  IFS= read -r first_line < "$file" || true
  case "$file:$first_line" in
    *.sh:*|*.bash:*|*:'#!/usr/bin/env bash'*|*:'#!/bin/bash'*|*:'#!/data/data/com.termux/files/usr/bin/bash'*)
      scripts+=("$file")
      ;;
  esac
done < <(git ls-files -co --exclude-standard)

shellcheck --severity=error "${scripts[@]}"
printf 'ShellCheck: %d Bash script(s), error gate clean\n' "${#scripts[@]}"
