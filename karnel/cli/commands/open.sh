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
		url="$OPEN_BASE_URL/karnel"
		;;
	lang)
		url="$OPEN_BASE_URL/karnel/lang"
		;;
	db)
		url="$OPEN_BASE_URL/karnel/db"
		;;
	ai)
		url="$OPEN_BASE_URL/karnel/ai"
		;;
	editor)
		url="$OPEN_BASE_URL/karnel/editor"
		;;
	dev)
		url="$OPEN_BASE_URL/karnel/dev"
		;;
	npm)
		url="$OPEN_BASE_URL/karnel/npm"
		;;
	shell)
		url="$OPEN_BASE_URL/karnel/shell"
		;;
	ui)
		url="$OPEN_BASE_URL/karnel/ui"
		;;
	auto)
		url="$OPEN_BASE_URL/karnel/auto"
		;;
	deploy)
		url="$OPEN_BASE_URL/karnel/deploy"
		;;
  cleanup)
    url="$OPEN_BASE_URL/karnel/cleanup"
    ;;
  network)
    url="$OPEN_BASE_URL/karnel/network"
    ;;
  utils)
    url="$OPEN_BASE_URL/karnel/utils"
    ;;
  games)
    url="$OPEN_BASE_URL/karnel/games"
    ;;
  voice)
    url="$OPEN_BASE_URL/karnel/voice"
    ;;
  osint|robin)
    url="$OPEN_BASE_URL/karnel/osint"
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

	if command -v termux-open-url &>/dev/null; then
		termux-open-url "$url"
		log_success "Opening: ${D_CYAN}$url${NC}"
	elif command -v termux-open &>/dev/null; then
		termux-open "$url"
		log_success "Opening: ${D_CYAN}$url${NC}"
	else
		log_error "termux-open-url not found. Are you running in Termux?"
		echo "Documentation at: $url"
		return 1
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
  printf "    ${D_GREEN}%-14s${NC} ${D_DIM}%s${NC}\n" "games" "Games"
  printf "    ${D_GREEN}%-14s${NC} ${D_DIM}%s${NC}\n" "cleanup" "Cache cleanup"
  printf "    ${D_GREEN}%-14s${NC} ${D_DIM}%s${NC}\n" "network" "Network tools"
  printf "    ${D_GREEN}%-14s${NC} ${D_DIM}%s${NC}\n" "utils" "Utility tools"
  printf "    ${D_GREEN}%-14s${NC} ${D_DIM}%s${NC}\n" "voice" "Voice command"
  printf "    ${D_GREEN}%-14s${NC} ${D_DIM}%s${NC}\n" "osint" "OSINT tools"
  echo
	separator_section "Website"
	echo
	list_item "${D_CYAN}$OPEN_BASE_URL${NC}"
	echo
}
