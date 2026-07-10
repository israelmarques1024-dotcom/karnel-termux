#!/usr/bin/env bash

set -e

readonly P_BORDER='\e[38;5;33m'
readonly P_PRIMARY='\e[38;5;39m'
readonly P_DIM='\e[38;5;244m'
readonly P_OK='\e[38;5;42m'
readonly P_FAIL='\e[1;31m'
readonly P_HL='\e[38;5;213m'
readonly P_NC='\e[0m'

REPO="https://github.com/israel676767/karnel-termux"
BRANCH="main"
KARNEL_DATA="${XDG_DATA_HOME:-$HOME/.local/share}/karnel-data"
KARNEL_REPO="${XDG_DATA_HOME:-$HOME/.local/share}/karnel"
KARNEL_CACHE="${XDG_CACHE_HOME:-$HOME/.cache}/karnel"
KARNEL_CONFIG="${XDG_CONFIG_HOME:-$HOME/.config}/karnel"

TOTAL_STEPS=6
CURRENT_STEP=0

_cols() {
	if command -v tput &>/dev/null; then
		tput cols
	else
		echo 80
	fi
}

progress_bar() {
	local current=$1
	local total=$2
	local width=${3:-40}
	local percentage=$((current * 100 / total))
	local filled=$((current * width / total))
	local empty=$((width - filled))

	printf -v bar "%*s" "$filled" ""
	bar="${bar// /█}"
	printf -v space "%*s" "$empty" ""
	space="${space// /░}"

	printf "\r  ${P_BORDER}│${P_NC}${P_OK}%s${P_NC}${P_DIM}%s${P_NC}${P_BORDER}│${P_NC} ${P_PRIMARY}%3d%%${P_NC}" "${bar}" "${space}" "$percentage"
}

log_step() {
	local step="$1"
	local desc="$2"
	CURRENT_STEP=$((CURRENT_STEP + 1))
	printf "\r%*s\r" "$(_cols)" ""
	echo -e "\n  ${P_BORDER}◆${P_NC}  ${P_PRIMARY}${CURRENT_STEP}/${TOTAL_STEPS}${P_NC}  ${desc}"
}

log_ok() {
	echo -e "  ${P_OK}✔${P_NC}  $1"
}

log_fail() {
	echo -e "  ${P_FAIL}✖${P_NC}  $1" >&2
}

log_info() {
	echo -e "  ${P_BORDER}→${P_NC}  $1"
}

separator() {
	local cols=$(_cols)
	local line=$(printf "%${cols}s")
	echo -e "${P_DIM}${line// /─}${P_NC}"
}

banner() {
	echo
	echo -e "  ${P_BORDER}┌────────────────────────────────────┐${P_NC}"
	echo -e "  ${P_BORDER}│${P_NC}        ${P_PRIMARY}  ◈ KARNEL TERMUX ◈${P_NC}           ${P_BORDER}│${P_NC}"
	echo -e "  ${P_BORDER}│${P_NC} ${P_DIM}Modular Dev Environment for Termux${P_NC} ${P_BORDER}│${P_NC}"
	echo -e "  ${P_BORDER}└────────────────────────────────────┘${P_NC}"
	echo
}

bootstrap_dependencies() {
	local needed_tput=0
	local needed_git=0
	local needed_glow=0
	local needed_gh=0
	local needed_rg=0

	command -v tput &>/dev/null || needed_tput=1
	command -v git &>/dev/null || needed_git=1
	command -v glow &>/dev/null || needed_glow=1
	command -v gh &>/dev/null || needed_gh=1
	command -v rg &>/dev/null || needed_rg=1

	if [[ $needed_tput -eq 1 || $needed_git -eq 1 || $needed_glow -eq 1 || $needed_gh -eq 1 || $needed_rg -eq 1 ]]; then
		banner
	fi

	if [[ $needed_tput -eq 1 ]]; then
		echo -e "  ${P_BORDER}→${P_NC}  Installing ncurses-utils..."
		pkg install -y ncurses-utils &>/dev/null
		echo -e "  ${P_OK}✔${P_NC}  ncurses-utils installed"
		echo
	fi

	if [[ $needed_git -eq 1 ]]; then
		log_info "Installing git..."
		progress_bar 0 10
		pkg install -y git &>/dev/null
		progress_bar 10 10
		echo
		log_ok "git installed"
	fi

	if [[ $needed_glow -eq 1 ]]; then
		log_info "Installing glow..."
		progress_bar 0 10
		pkg install -y glow &>/dev/null
		progress_bar 10 10
		echo
		log_ok "glow installed"
	fi

	if [[ $needed_gh -eq 1 ]]; then
		log_info "Installing gh (GitHub CLI)..."
		progress_bar 0 10
		pkg install -y gh &>/dev/null
		progress_bar 10 10
		echo
		log_ok "gh installed"
	fi

	if [[ $needed_rg -eq 1 ]]; then
		log_info "Installing ripgrep..."
		progress_bar 0 10
		pkg install -y ripgrep &>/dev/null
		progress_bar 10 10
		echo
		log_ok "ripgrep installed"
	fi

	if [[ $needed_tput -eq 1 || $needed_git -eq 1 || $needed_glow -eq 1 || $needed_gh -eq 1 || $needed_rg -eq 1 ]]; then
		echo
		clear
	fi
}

install_dependencies() {
	log_step 1 "Verifying dependencies"
	progress_bar 5 10
	progress_bar 10 10
	echo
	log_ok "Dependencies ready (git, ncurses-utils, glow, gh, ripgrep)"
}

setup_directories() {
	log_step 2 "Setting up directories"

	mkdir -p "$KARNEL_REPO" "$KARNEL_DATA" "$KARNEL_CACHE" "$KARNEL_CONFIG"

	log_info "Repo    $KARNEL_REPO"
	log_info "Data    $KARNEL_DATA"
	log_info "Cache   $KARNEL_CACHE"
	log_info "Config  $KARNEL_CONFIG"
	log_ok "Directories created"
}

clone_repo() {
	log_step 3 "Cloning repository"

	local script_dir
	script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
	local is_dev_install=0

	if [[ -d "$script_dir/.git" ]] && [[ "$script_dir" != "$KARNEL_REPO" ]]; then
		is_dev_install=1
	fi

	if [[ $is_dev_install -eq 1 ]]; then
		KARNEL_REPO="$script_dir"
		log_info "Developer installation detected"
		log_ok "Using local repository"
	elif [[ -d "$KARNEL_REPO/.git" ]]; then
		progress_bar 3 10
		git -C "$KARNEL_REPO" pull origin "$BRANCH" &>/dev/null
		progress_bar 10 10
		echo
		log_ok "Repository updated"
	else
		progress_bar 0 10
		git clone --depth=1 -b "$BRANCH" "$REPO" "$KARNEL_REPO" &>/dev/null &
		local pid=$!
		local dots=0
		while kill -0 "$pid" 2>/dev/null; do
			dots=$(( (dots + 1) % 4 ))
			printf "\r  Cloning%s    " "$(printf '%*s' "$dots" '' | tr ' ' '.')"
			sleep 0.5
		done
		wait "$pid"
		progress_bar 10 10
		echo
		log_ok "Repository cloned"
	fi

	export KARNEL_REPO
}

create_symlink() {
	log_step 4 "Creating symlinks"

	rm -f "$PREFIX/bin/karnel"
	ln -sf "$KARNEL_REPO/karnel/bin/karnel" "$PREFIX/bin/karnel"

	if [[ -L "$PREFIX/bin/karnel" ]]; then
		log_ok "Symlink created: karnel → ${KARNEL_REPO}/karnel/bin/karnel"
	else
		log_fail "Failed to create symlink"
		return 1
	fi
}

save_config() {
	log_step 5 "Saving configuration"

	cat >"$KARNEL_CONFIG/config" <<EOF
karnel_repo='$KARNEL_REPO'
karnel_data='$KARNEL_DATA'
karnel_cache='$KARNEL_CACHE'
karnel_config='$KARNEL_CONFIG'
EOF

	log_ok "Configuration saved"
}

show_final_message() {
	echo
	separator
	echo -e "  ${P_OK}◆${P_NC}  ${P_PRIMARY}Karnel Installed${P_NC}"
	separator
	echo
	echo -e "  ${P_DIM}Author:${P_NC}  ${P_HL}israel marques${P_NC}"
	echo
	echo -e "  ${P_DIM}Run${P_NC}  ${P_HL}karnel${P_NC}  ${P_DIM}to get started${P_NC}"
	echo
	echo -e "  ${P_DIM}Install modules:${P_NC}"
	echo
	printf "    ${P_PRIMARY}%-20s${P_NC} ${P_DIM}%s${P_NC}\n" "karnel install lang" "Programming languages"
	printf "    ${P_PRIMARY}%-20s${P_NC} ${P_DIM}%s${P_NC}\n" "karnel install db" "Databases"
	printf "    ${P_PRIMARY}%-20s${P_NC} ${P_DIM}%s${P_NC}\n" "karnel install ai" "AI tools"
	printf "    ${P_PRIMARY}%-20s${P_NC} ${P_DIM}%s${P_NC}\n" "karnel install editor" "Code editor"
	printf "    ${P_PRIMARY}%-20s${P_NC} ${P_DIM}%s${P_NC}\n" "karnel install dev" "Dev tools"
	printf "    ${P_PRIMARY}%-20s${P_NC} ${P_DIM}%s${P_NC}\n" "karnel install npm" "Node.js tools"
	printf "    ${P_PRIMARY}%-20s${P_NC} ${P_DIM}%s${P_NC}\n" "karnel install shell" "ZSH shell"
	printf "    ${P_PRIMARY}%-20s${P_NC} ${P_DIM}%s${P_NC}\n" "karnel install ui" "Termux UI"
	printf "    ${P_PRIMARY}%-20s${P_NC} ${P_DIM}%s${P_NC}\n" "karnel install auto" "n8n"
	echo
}

main() {
	bootstrap_dependencies
	banner
	install_dependencies
	setup_directories
	clone_repo
	create_symlink
	save_config
	show_final_message
}

main
