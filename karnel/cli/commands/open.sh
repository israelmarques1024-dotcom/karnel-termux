#!/usr/bin/env bash

import "@/utils/log"
import "@/utils/colors"

OPEN_BASE_URL="https://kerneltermux.vercel.app"

open_main() {
	if [[ $# -eq 0 ]]; then
		open_help
		return
	fi

	local target="$1"
	local url=""

	case "$target" in
	karnel | help)
		url="$OPEN_BASE_URL"
		;;
	lang | db | ai | editor | dev | npm | shell | ui | auto | deploy)
		url="$OPEN_BASE_URL/karnel/$target"
		;;
	--help | -h)
		open_help
		return
		;;
	*)
		log_error "Unknown target: $target"
		echo
		open_help
		return 1
		;;
	esac

	if ! command -v termux-open-url &>/dev/null; then
		log_error "termux-open-url not found. Are you running in Termux?"
		return 1
	fi

	termux-open-url "$url"
	log_success "Opening: ${D_CYAN}$url${NC}"
}

open_help() {
	echo
	box "Karnel Open"
	echo
	log_info "Usage: karnel open <target>"
	echo
	log_info "Open official documentation in browser"
	echo
	separator_section "Targets"
	echo
	printf "    ${D_GREEN}%-14s${NC} ${D_DIM}%s${NC}\n" "karnel" "Karnel website"
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
	echo
	separator_section "Website"
	echo
	list_item "${D_CYAN}$OPEN_BASE_URL${NC}"
	echo
}
