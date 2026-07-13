#!/usr/bin/env bash

import "@/utils/log"
import "@/utils/version"

LOG_FILE="$KARNEL_CACHE/install_lang.log"

_install_perl_pkg() {
	loading "Installing Perl" _install_perl_pkg_impl
}

_install_perl_pkg_impl() {
	if ! pkg install perl -y &>>"$LOG_FILE"; then
		log_error "Failed to install Perl"
		return 1
	fi
	return 0
}

install_perl() {
	if command -v perl &>/dev/null; then
		log_info "Perl is already installed"
		return 2
	fi
	log_info "Installing Perl..."

	mkdir -p "$(dirname "$LOG_FILE")"
	_install_perl_pkg || return 1
	log_success "Perl installed"
	return 0
}

_uninstall_perl_pkg() {
	loading "Uninstalling Perl" _uninstall_perl_pkg_impl
}

_uninstall_perl_pkg_impl() {
	if ! pkg uninstall perl -y &>>"$LOG_FILE"; then
		log_error "Failed to uninstall Perl"
		return 1
	fi
	return 0
}

uninstall_perl() {
	if ! command -v perl &>/dev/null; then
		log_info "Perl is not installed"
		return 2
	fi
	log_info "Uninstalling Perl..."
	mkdir -p "$(dirname "$LOG_FILE")"
	_uninstall_perl_pkg || return 1
	log_success "Perl uninstalled"
	return 0
}

_update_perl_pkg() {
	loading "Updating Perl" _update_perl_pkg_impl
}

_update_perl_pkg_impl() {
	if ! pkg upgrade perl -y &>>"$LOG_FILE"; then
		log_error "Failed to update Perl"
		return 1
	fi
	return 0
}

update_perl() {
	_check_update_needed "Perl" "$(_get_installed_pkg_version perl)" "$(_get_remote_pkg_version perl)" _update_perl_pkg
}

reinstall_perl() {
	uninstall_perl
	install_perl
}
