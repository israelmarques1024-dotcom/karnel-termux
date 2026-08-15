#!/usr/bin/env bash

import "@/utils/log"
import "@/utils/colors"

show_main() {
	if [[ $# -eq 0 ]]; then
		echo
		box "Karnel Show"
		echo
		log_info "Usage: karnel show <module> --<tool>"
		echo
		log_info "Display help information for a specific tool."
		echo
    log_info "Available targets:"
    echo
    list_item "karnel show ai --opencode"
    list_item "karnel show ai --ollama"
    list_item "karnel show db --postgresql"
    list_item "karnel show dev --gh"
    list_item "karnel show npm --typescript"
    list_item "karnel show osint --robin"
    list_item "karnel show backup              Show backup docs"
    list_item "karnel show restore             Show restore docs"
		echo
		log_info "Run ${D_CYAN}karnel list <module>${NC} to see available tools"
		echo
		return
	fi

	local module=""
	local tool=""

	for arg in "$@"; do
		if [[ "$arg" == "--help" || "$arg" == "-h" ]]; then
			show_main
			return
		elif [[ "$arg" == --* ]]; then
			tool="${arg#--}"
		elif [[ -z "$module" ]]; then
			module="$arg"
		fi
	done

	if [[ -z "$module" ]]; then
		log_error "Usage: karnel show <module> --<tool>"
		return 1
	fi

  if [[ "$module" == "backup" ]]; then
    _show_backup_docs "$tool"
    return
  fi

  if [[ "$module" == "restore" ]]; then
    _show_restore_docs "$tool"
    return
  fi

  if [[ -z "$tool" ]]; then
    separator_section "$module - Available Tools"
    echo
    local tool_dir="$KARNEL_PATH/tools/$module"
    if [[ ! -d "$tool_dir" ]]; then
      log_error "Unknown module: $module"
      return 1
    fi
    local documented_tools=0
    for t in "$tool_dir"/*/; do
      local name="${t%/}"
      name="${name##*/}"
      if [[ -f "$tool_dir/$name/README.md" ]]; then
        ((documented_tools++))
        local first_line
        first_line=$(head -1 "$tool_dir/$name/README.md" 2>/dev/null)
        printf "    ${D_CYAN}%-16s${NC} %s\n" "$name" "${first_line#\# }"
      fi
    done
    if [[ $documented_tools -eq 0 ]]; then
      log_warn "No tool documentation is available for $module"
      return 1
    fi
    echo
    log_info "Run ${D_CYAN}karnel show $module --<tool>${NC} for details"
    echo
    return
  fi

  local readme_path
  readme_path="$(realpath "$KARNEL_PATH/tools/$module/$tool/README.md" 2>/dev/null)"

  if [[ -z "$readme_path" ]]; then
    log_error "No documentation found for $module/$tool"
    return 1
  fi

  if [[ "$readme_path" != "$KARNEL_PATH/tools/"* ]] || [[ "$readme_path" == *".."* ]]; then
    log_error "Access denied: path traversal detected"
    return 1
  fi

  if [[ ! -f "$readme_path" ]]; then
    log_error "No documentation found for $module/$tool"
    return 1
  fi

	separator_section "$tool ($module)"

	if command -v glow &>/dev/null; then
		glow "$readme_path"
	elif command -v pygmentize &>/dev/null; then
		pygmentize -l markdown "$readme_path" 2>/dev/null | less -R
	else
		log_info "Showing documentation for $module/$tool:"
		echo
		cat "$readme_path"
	fi

  echo
  separator
  echo
}

_show_backup_docs() {
  local tool="$1"
  if [[ -n "$tool" ]]; then
    separator_section "backup ($tool)"
    echo
    log_warn "backup is a CLI command, not a tool module"
    echo
    return
  fi

  separator_section "backup - Full Termux Backup"
  echo
  list_item "karnel backup                   Salva configs selecionadas + metadados de pacotes"
  list_item "karnel backup --cloud           Salva + upload Google Drive"
  echo
  log_info "O backup inclui:"
  list_item "Lista de todos os pacotes (dpkg --get-selections)"
  list_item "Catálogo dos instaladores Karnel (informativo)"
  list_item "Configs do shell (.bashrc, .zshrc, .profile)"
  list_item "Configurações do Termux (fontes, cores, propriedades)"
  list_item "Configuração e chaves públicas SSH (chaves privadas são excluídas)"
  list_item "Configs de apps (~/.config), sem .env/credenciais conhecidas"
  list_item "Repositórios APT"
  list_item "Lista de pacotes embutida no arquivo"
  log_info "Backup e snapshot usam a mesma filtragem; tokens, .env e chaves privadas não são exportados."
  echo
  log_info "Cloud: envia o arquivo e o checksum via rclone."
  list_item "Configure: rclone config  (nomeie o remote como 'karnel')"
  echo
}

_show_restore_docs() {
  local tool="$1"
  if [[ -n "$tool" ]]; then
    separator_section "restore ($tool)"
    echo
    log_warn "restore is a CLI command, not a tool module"
    echo
    return
  fi

  separator_section "restore - Full Termux Restore"
  echo
  list_item "karnel restore                  Restaura o backup mais recente com rollback"
  list_item "karnel restore <arquivo>        Restaura um arquivo específico"
  list_item "karnel restore --cloud          Restaura do Google Drive"
  echo
  log_info "O restore:"
  list_item "Extrai configs para ~/"
  list_item "Restaura lista de pacotes (dpkg)"
  list_item "Reinstala ferramentas Karnel"
  echo
}
