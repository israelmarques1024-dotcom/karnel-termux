#compdef karnel

_karnel_commands() {
  local -a commands=(
    'backup:Backup tool manifest and configs'
    'brain:Second brain — save and search memories'
    'cleanup:Clean caches, logs, and temp files'
    'doctor:Diagnose and fix environment'
    'env:Manage environment variables'
    'help:Show help'
    'ia:AI agent manager'
    'init:Configure existing projects'
    'install:Install modules and packages'
    'list:List available tools in modules'
    'open:Open documentation in browser'
    'pg:PostgreSQL database manager'
    'plugin:Manage reviewed and local plugins'
    'reinstall:Uninstall + install modules'
    'restore:Restore from a backup'
    'robin:Manage Robin dark-web OSINT'
    'search:Search tools and memories'
    'show:Show tool documentation'
    'start:Start services'
    'status:Quick system overview'
    'uninstall:Remove installed modules'
    'update:Update modules or framework'
    'upgrade:Upgrade Karnel framework'
    'version:Show version'
    'voice:Speech-to-agent'
  )
  _describe 'command' commands
}

_karnel_modules() {
  local -a modules=(
    'ai:AI tools'
    'auto:Automation tools'
    'db:Databases'
    'deploy:Deployment CLIs'
    'dev:Development tools'
    'editor:Code editors'
    'games:Terminal games'
    'lang:Programming languages'
    'npm:Node.js packages'
    'osint:OSINT tools'
    'plugin:Built-in plugin manager'
    'shell:ZSH shell plugins'
    'ui:Termux UI components'
    'voice:Speech-to-agent tools'
  )
  _describe 'module' modules
}

_karnel() {
  local curcontext="$curcontext" state line
  typeset -A opt_args

  _arguments \
    '1: :->command' \
    '*: :->args'

  case $state in
    command)
      _karnel_commands
      ;;
    args)
      case $words[2] in
        install|uninstall|update|reinstall|list|show)
          if [[ ${#words[@]} -eq 3 ]]; then
            _karnel_modules
          fi
          ;;
        doctor)
          _arguments '1:subcommand:(termux code robin)' '--quick[Quick mode]' '--fix[Auto-fix]' '--network[Test Tor network]'
          ;;
        robin)
          _arguments '1:subcommand:(start stop status config doctor update purge-data help)' '--accept-responsible-use[Accept responsible-use notice]' '--network[Test Tor network]'
          ;;
        plugin)
          _arguments \
            '1:subcommand:(install remove update list search create)' \
            '--unsafe[Allow an unreviewed repository after confirmation]' \
            '--command[Filter registry by command]:command:' \
            '--compatible[Filter registry by Karnel compatibility]' \
            '--capability[Filter registry by declared capability]:capability:(network filesystem-read filesystem-write process environment)'
          ;;
        *)
          _default
          ;;
      esac
      ;;
  esac
}

compdef _karnel karnel
