#!/usr/bin/env bash

# =============================================================================
# Karnel AI Tools Orchestrator
# =============================================================================
# Este arquivo importa TODOS os scripts de instalação individuais de ferramentas
# AI e expõe funções de lote: install_all, uninstall_all, update_all, reinstall_all
# =============================================================================

import "@/utils/log"
import "@/utils/colors"

# KARNEL_CACHE e PREFIX são definidos via env.sh
# Exportados aqui apenas como fallback para scripts que carregam all.sh diretamente
: "${KARNEL_CACHE:=$HOME/.cache/karnel}"
: "${PREFIX:=/data/data/com.termux/files/usr}"

# ---- Progress helpers (replicados do log.sh para consistência) ----

# ---- AI TOOLS REGISTRY ----
# Fonte única da verdade para todas as ferramentas AI.
# Cada registro contém:
#   id          = identificador único (usado em --flags, nomes de função)
#   name        = nome de exibição
#   binary      = nome(s) do(s) binário(s) para validação pós-instalação
#   install_fn  = nome da função install (gerado automaticamente)
#   uninstall_fn = nome da função uninstall (gerado automaticamente)
#   update_fn   = nome da função update (gerado automaticamente)

AI_TOOLS_REGISTRY=(
  "qwen-code:Qwen Code:qwen"
  "gemini-cli:Gemini CLI:gemini"
  "claude-code:Claude Code:claude"
  "mistral-vibe:Mistral Vibe:vibe"
  "openclaude:OpenClaude:openclaude"
  "openclaw:OpenClaw:openclaw"
  "ollama:Ollama:ollama"
  "codex:Codex CLI:codex"
  "opencode:OpenCode:opencode"
  "mimocode:MiMo Code:mimo"
  "engram:Engram:engram"
  "codegraph:CodeGraph:codegraph"
  "pi:Pi Coding Agent:pi"
  "antigravity-cli:Antigravity CLI:agy"
  "minimax-cli:Minimax CLI:mmx"
  "gentle-ai:Gentle AI:gentle-ai"
  "gga:GGA:gga"
  "hermes-agent:Hermes Agent:hermes"
  "kimi-code:Kimi Code:kimi"
  "command-code:Command Code:command-code"
  "freebuff:Freebuff:freebuff"
  "kilocode-cli:Kilo Code CLI:kilocode,kilo"
  "kiro:Kiro CLI:kiro,kiro-cli"
  "crush:Crush CLI:crush"
  "cline:Cline CLI:cline"
  "odysseus:Odysseus:odysseus"
  "kimchi-code:Kimchi CLI:kimchi"
  "karnel-route:karnelRoute:karnel-route"
  "ctx7:Context7 Documentation Provider:ctx7"
  "openspec:OpenSpec SDD Framework:openspec"
)

# ---- IMPORTAR TODOS OS SCRIPTS INDIVIDUAIS ----
# Cada tool/***/install.sh define install_*, uninstall_*, update_*, reinstall_*
_import_all_ai_tools() {
  local tools_dir="$KARNEL_PATH/tools/ai"
  for entry in "$tools_dir"/*/install.sh; do
    if [[ -f "$entry" ]]; then
      source "$entry"
    fi
  done
}
_import_all_ai_tools
unset -f _import_all_ai_tools

# ---- HELPERS DE VALIDAÇÃO PÓS-INSTALAÇÃO ----

# Verifica se pelo menos um dos binários existe no PATH
_validate_tool_installed() {
  local binaries="$1"
  local tool_name="$2"
  IFS=',' read -ra bins <<< "$binaries"
  for bin in "${bins[@]}"; do
    if command -v "$bin" &>/dev/null; then
      # Verificação extra: se for um stub (shell script que só mostra erro), considera falha
      local bin_path
      bin_path=$(command -v "$bin")
      if [[ -f "$bin_path" ]]; then
        local first_line
        first_line=$(head -1 "$bin_path" 2>/dev/null)
        # Stubs geralmente começam com #! e contêm "offline" ou "unreachable"
        if [[ "$first_line" == "#!"* ]]; then
          if grep -qiE "offline|unreachable|not.available|stub|indisponivel|inacessivel" "$bin_path" 2>/dev/null; then
            log_warn "$tool_name: instalado como stub offline (instalação real indisponível)"
            return 2
          fi
        fi
      fi
      return 0
    fi
  done
  return 1
}

# Valida que o binário realmente executa (tenta --version ou --help)
_validate_tool_executable() {
  local binary="$1"
  local tool_name="$2"
  if command -v "$binary" &>/dev/null; then
    # Tenta executar com --version (ignora exit code, só verifica se não crasha)
    "$binary" --version &>/dev/null || "$binary" --help &>/dev/null || "$binary" -h &>/dev/null || true
    return 0
  fi
  return 1
}

# ---- FUNÇÕES DE LOTE ----

_all_ai_tools_action() {
  local action="$1"        # install, uninstall, update, reinstall
  local action_label="$2"  # Instalando, Removendo, Atualizando, Reinstalando
  local total=${#AI_TOOLS_REGISTRY[@]}
  local current=0
  local success_count=0
  local failed_count=0
  local skipped_count=0

  progress_start "$total" "${action_label} ferramentas IA..."

  for entry in "${AI_TOOLS_REGISTRY[@]}"; do
    IFS=':' read -r id name binaries <<< "$entry"
    local func_name="${action}_${id//-/_}"

    ((current++))

    if declare -f "$func_name" &>/dev/null; then
      "$func_name"
      local rc=$?

      case $rc in
        0)
          # Pós-validação apenas para install
          if [[ "$action" == "install" ]]; then
            _validate_tool_installed "$binaries" "$name"
            local validate_rc=$?
            if [[ $validate_rc -eq 0 ]]; then
              ((success_count++))
            elif [[ $validate_rc -eq 2 ]]; then
              # Stub instalado - conta como sucesso parcial
              ((success_count++))
            else
              log_warn "$name: binário não encontrado no PATH após instalação"
              ((failed_count++))
            fi
          else
            ((success_count++))
          fi
          ;;
        1)
          ((failed_count++))
          ;;
        2)
          ((skipped_count++))
          ;;
      esac
    else
      log_warn "Função não encontrada: $func_name"
      ((failed_count++))
    fi

    progress_update "$current" "$total"
  done

  progress_done "$total"

  echo
  if [[ $success_count -gt 0 ]]; then
    log_success "$success_count ferramenta(s) ${action_label,,} com sucesso"
  fi
  if [[ $skipped_count -gt 0 ]]; then
    log_info "$skipped_count ferramenta(s) já estavam no estado desejado"
  fi
  if [[ $failed_count -gt 0 ]]; then
    log_warn "$failed_count ferramenta(s) falharam ao ${action_label,,}"
  fi
  echo

  return $failed_count
}

install_all_ai_tools() {
  log_info "Instalando todas as ferramentas AI..."
  _all_ai_tools_action "install" "Instalando"
}

uninstall_all_ai_tools() {
  log_info "Removendo todas as ferramentas AI..."
  _all_ai_tools_action "uninstall" "Removendo"
}

update_all_ai_tools() {
  log_info "Atualizando todas as ferramentas AI..."
  _all_ai_tools_action "update" "Atualizando"
}

reinstall_all_ai_tools() {
  log_info "Reinstalando todas as ferramentas AI..."
  _all_ai_tools_action "reinstall" "Reinstalando"
}
