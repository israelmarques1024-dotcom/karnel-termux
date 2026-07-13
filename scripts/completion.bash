_karnel_completions() {
  local cur prev words cword
  _init_completion || return

  local commands="backup brain cleanup doctor env help ia init install list open pg reinstall restore search show start status uninstall update upgrade version voice"
  local modules="ai auto db deploy dev editor lang npm shell ui"

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
      COMPREPLY=($(compgen -W "--quick --fix" -- "$cur"))
      ;;
    restore)
      COMPREPLY=($(compgen -f -- "$cur"))
      ;;
  esac
}

complete -F _karnel_completions karnel
