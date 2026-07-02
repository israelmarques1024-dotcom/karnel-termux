#!/data/data/com.termux/files/usr/bin/bash

import "@/utils/log"

LOG_FILE="$OMNI_CACHE/install_lang.log"

_install_nodejs_pkg() {
	loading "Installing Node.js LTS" _install_nodejs_pkg_impl
}

_install_nodejs_pkg_impl() {
	if ! pkg install nodejs-lts -y &>>"$LOG_FILE"; then
		log_error "Failed to install Node.js LTS"
		return 1
	fi
	return 0
}

install_nodejs() {
	if command -v node &>/dev/null; then
		log_info "Node.js LTS is already installed"
		return 2
	fi
	log_info "Installing Node.js LTS..."

	mkdir -p "$(dirname "$LOG_FILE")"
	_install_nodejs_pkg || return 1
	log_success "Node.js LTS installed"
	return 0
}

_uninstall_nodejs_pkg() {
	loading "Uninstalling Node.js LTS" _uninstall_nodejs_pkg_impl
}

_uninstall_nodejs_pkg_impl() {
	if ! pkg uninstall nodejs-lts -y &>>"$LOG_FILE"; then
		log_error "Failed to uninstall Node.js LTS"
		return 1
	fi
	return 0
}

uninstall_nodejs() {
	if ! command -v node &>/dev/null; then
		log_info "Node.js LTS is not installed"
		return 2
	fi
	log_info "Uninstalling Node.js LTS..."
	mkdir -p "$(dirname "$LOG_FILE")"
	_uninstall_nodejs_pkg || return 1
	log_success "Node.js LTS uninstalled"
	return 0
}

_update_nodejs_pkg() {
	loading "Updating Node.js LTS" _update_nodejs_pkg_impl
}

_update_nodejs_pkg_impl() {
	if ! pkg upgrade nodejs-lts -y &>>"$LOG_FILE"; then
		log_error "Failed to update Node.js LTS"
		return 1
	fi
	return 0
}

update_nodejs() {
	log_info "Updating Node.js LTS..."
	mkdir -p "$(dirname "$LOG_FILE")"
	_update_nodejs_pkg || return 1
	log_success "Node.js LTS updated"
	return 0
}

reinstall_nodejs() {
	uninstall_nodejs
	install_nodejs
}
