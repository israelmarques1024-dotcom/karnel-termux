#!/usr/bin/env bash

_karnel_completions() {
  local cur prev words cword
  _init_completion || return

  local commands="backup brain cleanup deploy doctor env help ia init install list open pg reinstall restore robin search show start status uninstall update upgrade version voice"
  local modules="ai auto db deploy dev editor games lang npm osint shell ui voice"

  if [[ $cword -eq 1 ]]; then
    COMPREPLY=($(compgen -W "$commands" -- "$cur"))
    return
  fi

  case "${words[1]}" in
    install|uninstall|update|reinstall|list|show)
      if [[ $cword -eq 2 ]]; then
        COMPREPLY=($(compgen -W "$modules" -- "$cur"))
      fi
      ;;
    doctor)
      COMPREPLY=($(compgen -W "termux code robin --quick --fix" -- "$cur"))
      ;;
    robin)
      COMPREPLY=($(compgen -W "start stop status config doctor update purge-data help" -- "$cur"))
      ;;
    restore)
      COMPREPLY=($(compgen -f -- "$cur"))
      ;;
  esac
}

complete -F _karnel_completions karnel
