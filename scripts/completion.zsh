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
    'reinstall:Uninstall + install modules'
    'restore:Restore from a backup'
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
    'lang:Programming languages'
    'npm:Node.js packages'
    'shell:ZSH shell plugins'
    'ui:Termux UI components'
  )
  _describe 'module' modules
}

_karnel_ai_tools() {
  local -a tools=(
    '--qwen-code:Qwen Code'
    '--gemini-cli:Gemini CLI'
    '--claude-code:Claude Code'
    '--ollama:Ollama'
    '--opencode:OpenCode'
    '--codex:Codex CLI'
  )
  _describe 'tool' tools
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
          _arguments '--quick[Quick mode]' '--fix[Auto-fix]'
          ;;
        *)
          _default
          ;;
      esac
      ;;
  esac
}

compdef _karnel karnel
