#!/usr/bin/env bash
set -euo pipefail

failures=0
checked=0

while IFS= read -r file; do
  [[ -f "$file" ]] || continue
  first_line=""
  IFS= read -r first_line < "$file" || true

  case "$file:$first_line" in
    *.sh:*|*.bash:*|*:'#!/usr/bin/env bash'*|*:'#!/bin/bash'*|*:'#!/data/data/com.termux/files/usr/bin/bash'*)
      ((checked += 1))
      if ! bash -n "$file"; then
        printf 'Bash syntax failed: %s\n' "$file" >&2
        ((failures += 1))
      fi
      ;;
    *.zsh:*|*:'#!/usr/bin/env zsh'*|*:'#!/bin/zsh'*)
      ((checked += 1))
      if ! zsh -n "$file"; then
        printf 'Zsh syntax failed: %s\n' "$file" >&2
        ((failures += 1))
      fi
      ;;
  esac
done < <(git ls-files -co --exclude-standard)

printf 'Syntax: %d script(s) checked, %d failure(s)\n' "$checked" "$failures"
(( failures == 0 ))
