#!/usr/bin/env bash

import "@/utils/log"

LOG_FILE="$KARNEL_CACHE/install_ui.log"

KARNEL_BANNER_MARKER="# ===== Karnel Banner ====="
KARNEL_MOTD_BACKUP="$KARNEL_CACHE/motd.backup"

_backup_motd() {
	if [[ ! -e "$PREFIX/etc/motd" ]]; then
		return 0
	fi

	if [[ -e "$KARNEL_MOTD_BACKUP" ]]; then
		log_info "Termux MOTD already backed up"
		return 0
	fi

	log_info "Backing up Termux MOTD..."
	mv "$PREFIX/etc/motd" "$KARNEL_MOTD_BACKUP"
	log_success "Termux MOTD backed up to $KARNEL_MOTD_BACKUP"
}

_restore_motd() {
	if [[ ! -e "$KARNEL_MOTD_BACKUP" ]]; then
		return 0
	fi

	if [[ -e "$PREFIX/etc/motd" ]]; then
		log_warn "Termux MOTD already exists, skipping restore"
		return 0
	fi

	log_info "Restoring Termux MOTD..."
	mv "$KARNEL_MOTD_BACKUP" "$PREFIX/etc/motd"
	log_success "Termux MOTD restored"
}

_detect_shell_config() {
	if [[ -f "$HOME/.zshrc" ]]; then
		echo "$HOME/.zshrc"
	elif [[ -f "$HOME/.bashrc" ]]; then
		echo "$HOME/.bashrc"
	fi
}

_install_banner_impl() {
	local shell_config
	shell_config="$(_detect_shell_config)"

	if [[ -z "$shell_config" ]]; then
		log_warn "No shell config file found (.zshrc or .bashrc)"
		return 1
	fi

	if grep -qF "$KARNEL_BANNER_MARKER" "$shell_config" 2>/dev/null; then
		log_info "Karnel Banner already installed"
		return 0
	fi

	local banner_script="$KARNEL_UTILS/banner.sh"
	if [[ ! -f "$banner_script" ]]; then
		log_error "Banner script not found: $banner_script"
		return 1
	fi

	mkdir -p "$(dirname "$LOG_FILE")"

	cat >>"$shell_config" <<EOF

$KARNEL_BANNER_MARKER
source "$banner_script"

clear() {
	builtin clear 2>/dev/null || /usr/bin/clear 2>/dev/null || clear
	local _banner_cache="\${XDG_CACHE_HOME:-$HOME/.cache}/karnel/banner_cache"
	if [[ -f "$_banner_cache" ]]; then
		cat "$_banner_cache"
	fi
}
export -f clear 2>/dev/null
EOF

	log_success "Karnel Banner installed"

	_backup_motd

	log_warn "Restart Termux or run: source $shell_config"
	return 0
}

install_banner() {
	if grep -qF "$KARNEL_BANNER_MARKER" "$(_detect_shell_config)" 2>/dev/null; then
		log_info "Karnel Banner already installed"
		return 0
	fi
	log_info "Installing Karnel Banner..."
	mkdir -p "$(dirname "$LOG_FILE")"
	loading "Installing Banner" _install_banner_impl
}

_uninstall_banner_impl() {
	local shell_config
	shell_config="$(_detect_shell_config)"

	if [[ -z "$shell_config" ]]; then
		log_warn "No shell config file found"
		return 1
	fi

	if ! grep -qF "$KARNEL_BANNER_MARKER" "$shell_config" 2>/dev/null; then
		log_warn "Karnel Banner not installed"
		return 0
	fi

	local marker_line
	marker_line="$(grep -nF "$KARNEL_BANNER_MARKER" "$shell_config" | head -1 | cut -d: -f1)"

	if [[ -n "$marker_line" ]]; then
		local prev_line=$((marker_line - 1))
		if sed -n "${prev_line}p" "$shell_config" 2>/dev/null | grep -q '^$'; then
			sed -i "$((prev_line)),$((marker_line + 1))d" "$shell_config"
		else
			sed -i "$marker_line,$((marker_line + 1))d" "$shell_config"
		fi
		log_success "Karnel Banner uninstalled"
	else
		log_warn "Could not locate banner marker for removal"
		return 1
	fi

	_restore_motd

	return 0
}

uninstall_banner() {
	if ! grep -qF "$KARNEL_BANNER_MARKER" "$(_detect_shell_config)" 2>/dev/null; then
		log_warn "Karnel Banner not installed"
		return 0
	fi
	log_info "Uninstalling Karnel Banner..."
	loading "Uninstalling Banner" _uninstall_banner_impl
}

_update_banner_impl() {
	uninstall_banner
	install_banner
}

update_banner() {
	log_info "Updating Karnel Banner..."
	loading "Updating Banner" _update_banner_impl
}

reinstall_banner() {
	uninstall_banner
	install_banner
}
