#!/usr/bin/env bash

import "@/utils/log"
import "@/utils/version"

LOG_FILE="$KARNEL_CACHE/install_lang.log"

_install_python_pkg() {
	loading "Installing Python" _install_python_pkg_impl
}

_install_python_pkg_impl() {
	if ! pkg install python -y &>>"$LOG_FILE"; then
		log_error "Failed to install Python"
		return 1
	fi
	return 0
}

install_python() {
	if command -v python &>/dev/null; then
		log_info "Python is already installed"
		return 2
	fi
	log_info "Installing Python..."

	mkdir -p "$(dirname "$LOG_FILE")"
	_install_python_pkg || return 1
	log_success "Python installed"
	return 0
}

_uninstall_python_pkg() {
	loading "Uninstalling Python" _uninstall_python_pkg_impl
}

_uninstall_python_pkg_impl() {
	if ! pkg uninstall python -y &>>"$LOG_FILE"; then
		log_error "Failed to uninstall Python"
		return 1
	fi
	return 0
}

uninstall_python() {
	if ! command -v python &>/dev/null; then
		log_info "Python is not installed"
		return 2
	fi
	log_info "Uninstalling Python..."
	mkdir -p "$(dirname "$LOG_FILE")"
	_uninstall_python_pkg || return 1
	log_success "Python uninstalled"
	return 0
}

_update_python_pkg() {
	loading "Updating Python" _update_python_pkg_impl
}

_update_python_pkg_impl() {
	if ! pkg upgrade python -y &>>"$LOG_FILE"; then
		log_error "Failed to update Python"
		return 1
	fi
	return 0
}

update_python() {
	_check_update_needed "Python" "$(_get_installed_pkg_version python)" "$(_get_remote_pkg_version python)" _update_python_pkg
}

reinstall_python() {
	uninstall_python
	install_python
}
