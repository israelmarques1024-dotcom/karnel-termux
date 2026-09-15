#!/usr/bin/env bash

import "@/utils/log"
import "@/utils/uninstall"

LOG_FILE="$KARNEL_CACHE/install_ui.log"
TERMUX_DIR="$HOME/.termux"
CURSOR_BEGIN="# Karnel cursor begin"
CURSOR_END="# Karnel cursor end"

_install_cursor_impl() {
	mkdir -p "$(dirname "$LOG_FILE")" "$TERMUX_DIR"

	cat >>"$TERMUX_DIR/colors.properties" <<EOF

$CURSOR_BEGIN
cursor=#00FF00
$CURSOR_END
EOF

	log_success "Cursor color set to #00FF00 (green)"
	return 0
}

install_cursor() {
	if grep -qF "$CURSOR_BEGIN" "$TERMUX_DIR/colors.properties" 2>/dev/null; then
		log_info "Cursor Color already configured"
		return 0
	fi
	log_info "Installing Cursor Color..."
	loading "Installing Cursor Color" _install_cursor_impl
}

_uninstall_cursor_impl() {
	if grep -qF "$CURSOR_BEGIN" "$TERMUX_DIR/colors.properties" 2>/dev/null; then
		if ! remove_marked_block "$TERMUX_DIR/colors.properties" "$CURSOR_BEGIN" "$CURSOR_END"; then
			log_warn "Keeping malformed Karnel cursor configuration"
			return 0
		fi
		log_success "Cursor Color uninstalled"
	else
		log_warn "Cursor Color not configured"
	fi
}

uninstall_cursor() {
	if ! grep -qF "$CURSOR_BEGIN" "$TERMUX_DIR/colors.properties" 2>/dev/null; then
		log_info "Cursor Color is not installed"
		return 0
	fi
	log_info "Uninstalling Cursor Color..."
	loading "Uninstalling Cursor Color" _uninstall_cursor_impl
}

_update_cursor_impl() {
	install_cursor
}

update_cursor() {
	log_info "Updating Cursor Color..."
	loading "Updating Cursor Color" _update_cursor_impl
}

reinstall_cursor() {
	uninstall_cursor
	install_cursor
}
