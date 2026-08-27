#!/usr/bin/env bash

import "@/utils/log"
import "@/utils/colors"

OPEN_DOCS="https://israelmarques1024-dotcom.github.io/karnel-termux"

open_main() {
	if [[ $# -eq 0 ]]; then
		open_help
		return
	fi

	local target="$1"
	local url=""

	case "$target" in
	karnel | help)
		url="$OPEN_DOCS/"
		;;
	herdr)
		url="$OPEN_DOCS/karnel/utils"
		;;
	robin)
		url="$OPEN_DOCS/karnel/osint"
		;;
	supabase)
		url="$OPEN_DOCS/karnel/deploy"
		;;
	cleanup)
		url="$OPEN_DOCS/cli"
		;;
	--help | -h)
		open_help
		return
		;;
	*)
		if [[ -f "$KARNEL_PATH/modules/$target.sh" ]]; then
			url="$OPEN_DOCS/karnel/$target"
		else
			log_error "Unknown target: $target"
			echo
			open_help
			return 1
		fi
		;;
	esac

	if command -v termux-open-url &>/dev/null; then
		termux-open-url "$url" 2>/dev/null && {
			log_success "Opening: ${D_CYAN}$url${NC}"
			return 0
		}
		log_warn "Failed to open URL, printing to terminal instead"
		echo
		echo "  ${D_CYAN}$url${NC}"
		echo
	elif command -v termux-open &>/dev/null; then
		termux-open "$url" 2>/dev/null && {
			log_success "Opening: ${D_CYAN}$url${NC}"
			return 0
		}
		log_warn "Failed to open URL, printing to terminal instead"
		echo "  ${D_CYAN}$url${NC}"
	else
		log_info "Documentation at:"
		echo
		echo "  ${D_CYAN}$url${NC}"
		echo
	fi
}

open_help() {
	echo
	box "Karnel Open"
	echo
	log_info "Usage: karnel open <target>"
	echo
	log_info "Open documentation in browser"
	echo
	separator_section "Targets"
	echo
	printf "    ${D_GREEN}%-14s${NC} ${D_DIM}%s${NC}\n" "karnel" "Karnel overview"
	printf "    ${D_GREEN}%-14s${NC} ${D_DIM}%s${NC}\n" "lang" "Language modules"
	printf "    ${D_GREEN}%-14s${NC} ${D_DIM}%s${NC}\n" "db" "Database modules"
	printf "    ${D_GREEN}%-14s${NC} ${D_DIM}%s${NC}\n" "ai" "AI tools"
	printf "    ${D_GREEN}%-14s${NC} ${D_DIM}%s${NC}\n" "editor" "Code editor"
	printf "    ${D_GREEN}%-14s${NC} ${D_DIM}%s${NC}\n" "dev" "Dev tools"
	printf "    ${D_GREEN}%-14s${NC} ${D_DIM}%s${NC}\n" "npm" "Node.js tools"
	printf "    ${D_GREEN}%-14s${NC} ${D_DIM}%s${NC}\n" "shell" "ZSH shell"
	printf "    ${D_GREEN}%-14s${NC} ${D_DIM}%s${NC}\n" "ui" "Termux UI"
	printf "    ${D_GREEN}%-14s${NC} ${D_DIM}%s${NC}\n" "auto" "Automation tools"
	printf "    ${D_GREEN}%-14s${NC} ${D_DIM}%s${NC}\n" "deploy" "Deploy CLIs"
	printf "    ${D_GREEN}%-14s${NC} ${D_DIM}%s${NC}\n" "supabase" "Supabase CLI"
	printf "    ${D_GREEN}%-14s${NC} ${D_DIM}%s${NC}\n" "games" "Games"
	printf "    ${D_GREEN}%-14s${NC} ${D_DIM}%s${NC}\n" "cleanup" "Cache cleanup"
	printf "    ${D_GREEN}%-14s${NC} ${D_DIM}%s${NC}\n" "network" "Network tools"
	printf "    ${D_GREEN}%-14s${NC} ${D_DIM}%s${NC}\n" "utils" "Utility tools"
	printf "    ${D_GREEN}%-14s${NC} ${D_DIM}%s${NC}\n" "voice" "Voice command"
	printf "    ${D_GREEN}%-14s${NC} ${D_DIM}%s${NC}\n" "osint" "OSINT tools"
	printf "    ${D_GREEN}%-14s${NC} ${D_DIM}%s${NC}\n" "plugin" "Plugin system"
	printf "    ${D_GREEN}%-14s${NC} ${D_DIM}%s${NC}\n" "security" "Security tools"
	printf "    ${D_GREEN}%-14s${NC} ${D_DIM}%s${NC}\n" "herdr" "Herdr terminal AI assistant"
	echo
	separator_section "Website"
	echo
	list_item "${D_CYAN}$OPEN_DOCS${NC}"
	echo
}
