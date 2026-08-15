#!/usr/bin/env bash

import "@/utils/log"
import "@/utils/colors"
import "@/utils/install"

LOG_FILE="$KARNEL_CACHE/install_npm.log"
TURBO_DATA_DIR="${KARNEL_DATA:-${XDG_DATA_HOME:-$HOME/.local/share}/karnel-data}/node-glibc"
NODE_VERSION="22.14.0"
NODE_URL="https://nodejs.org/dist/v${NODE_VERSION}/node-v${NODE_VERSION}-linux-arm64.tar.xz"
NODE_SHASUMS_URL="https://nodejs.org/dist/v${NODE_VERSION}/SHASUMS256.txt"
NODE_SHA256="08bfbf538bad0e8cbb0269f0173cca28d705874a67a22f60b57d99dc99e30050"
GLIBC_LIBDIR="/data/data/com.termux/files/usr/glibc/lib"

_has_glibc_node() {
	[[ -x "$TURBO_DATA_DIR/bin/node" ]]
}

_install_deps() {
	loading "Installing dependencies" _install_deps_impl
}

_install_deps_impl() {
	declare -A DEPS=(
		["curl"]="curl"
		["tar"]="tar"
		["binutils"]="aarch64-linux-android-strip"
		["python"]="python3"
	)

	local pkg_name bin_name
	for pkg_name in "${!DEPS[@]}"; do
		bin_name="${DEPS[$pkg_name]}"
		if ! command -v "$bin_name" &>/dev/null; then
			if ! yes | pkg install "$pkg_name" &>>"$LOG_FILE"; then
				log_error "Failed to install $pkg_name"
				return 1
			fi
		fi
	done

	return 0
}

_download() {
	local staging_dir="$1"
	local asset="node-v${NODE_VERSION}-linux-arm64.tar.xz"
	local archive="$staging_dir/$asset" shasums="$staging_dir/SHASUMS256.txt" manifest_hash

	curl -fsSL "$NODE_URL" -o "$archive" || { log_error "download failed"; return 1; }
	curl -fsSL "$NODE_SHASUMS_URL" -o "$shasums" || { log_error "SHASUMS256 download failed"; return 1; }
	manifest_hash=$(awk -v asset="$asset" '$2 == asset { print $1 }' "$shasums")
	[[ "$manifest_hash" == "$NODE_SHA256" ]] || { log_error "unexpected Node.js SHASUMS256 entry"; return 1; }
	verify_sha256 "$archive" "$NODE_SHA256" || return 1
	(
		cd "$staging_dir" || exit 1
		printf '%s  %s\n' "$manifest_hash" "$asset" | sha256sum -c -
	) &>>"$LOG_FILE" || { log_error "Node.js SHASUMS256 verification failed"; return 1; }
	safe_extract_tar "$archive" "$staging_dir" 1 || { log_error "extract failed"; return 1; }
	rm -f "$archive" "$shasums"
}

_strip() {
	local staging_dir="$1"
	[[ -f "$staging_dir/bin/node" ]] || { log_error "node binary not found"; return 1; }
	cp "$staging_dir/bin/node" "$staging_dir/bin/node.stripped" || return 1
	aarch64-linux-android-strip "$staging_dir/bin/node.stripped" &>>"$LOG_FILE"
}

_patch() {
	local staging_dir="$1"
	[[ -f "$staging_dir/bin/node.stripped" ]] || { log_error "stripped binary not found"; return 1; }
	local patch_script="$KARNEL_PATH/tools/npm/turbopack/bin/patch-interp.py"
	python3 "$patch_script" \
		"$staging_dir/bin/node.stripped" \
		"$GLIBC_LIBDIR/ld-linux-aarch64.so.1" &>>"$LOG_FILE" || {
			log_error "patch failed — see $LOG_FILE"
			return 1
		}
	mv "$staging_dir/bin/node.stripped" "$staging_dir/bin/node"
	chmod +x "$staging_dir/bin/node"
}

_turbopack_wrapper_owned() {
	local name="$1"
	local marker="$TURBO_DATA_DIR/.karnel-wrapper-$name"
	[[ -f "$marker" && -f "$PREFIX/bin/$name" ]] || return 1
	[[ "$(sha256sum "$PREFIX/bin/$name" 2>/dev/null)" == "$(<"$marker")" ]]
}

_turbopack_verify_ownership() {
	local name
	if [[ -e "$TURBO_DATA_DIR" && ! -f "$TURBO_DATA_DIR/.karnel-managed" ]]; then
		log_error "Refusing to replace unowned data directory: $TURBO_DATA_DIR"
		return 1
	fi
	for name in node-glibc next-turbopack; do
		if [[ -e "$PREFIX/bin/$name" ]] && ! _turbopack_wrapper_owned "$name"; then
			log_error "Refusing to replace unowned command: $PREFIX/bin/$name"
			return 1
		fi
	done
}

_install_wrappers() {
	local src="$KARNEL_PATH/tools/npm/turbopack/bin"
	local name source target temporary
	for name in node-glibc next-turbopack; do
		source="$src/$name"
		[[ "$name" == "node-glibc" ]] && source="$src/node-glibc.sh"
		target="$PREFIX/bin/$name"
		temporary="$(mktemp "$PREFIX/bin/.${name}.XXXXXX")" || return 1
		if ! install -m 755 "$source" "$temporary" || ! mv -f "$temporary" "$target"; then
			rm -f "$temporary"
			return 1
		fi
		sha256sum "$target" >"$TURBO_DATA_DIR/.karnel-wrapper-$name" || return 1
	done
	: >"$TURBO_DATA_DIR/.karnel-managed"
}

_uninstall_node() {
	[[ -f "$TURBO_DATA_DIR/.karnel-managed" ]] && rm -rf -- "$TURBO_DATA_DIR"
}

_uninstall_wrappers() {
	local name
	for name in node-glibc next-turbopack; do
		_turbopack_wrapper_owned "$name" && rm -f -- "$PREFIX/bin/$name"
	done
}

install_turbopack() {
	case "$(uname -m)" in
		aarch64|arm64) ;;
		*) log_error "Turbopack glibc toolchain currently supports ARM64 only"; return 1 ;;
	esac
	if _has_glibc_node; then
		log_info "Turbopack toolchain already installed"
		read_confirm_default "Reinstall?" "n" REINSTALL
		[[ "$REINSTALL" != "y" ]] && { log_warn "Skipped"; return 2; }
	fi

	_install_deps || return 1
	mkdir -p "$(dirname "$LOG_FILE")" "$PREFIX/bin" "$(dirname "$TURBO_DATA_DIR")"
	_turbopack_verify_ownership || return 1
	local staging_dir old_dir wrapper_backup name
	staging_dir="$(mktemp -d "$(dirname "$TURBO_DATA_DIR")/.node-glibc.XXXXXX")" || return 1
	wrapper_backup="$(mktemp -d "$(dirname "$TURBO_DATA_DIR")/.node-glibc-wrappers.XXXXXX")" || { rm -rf "$staging_dir"; return 1; }
	for name in node-glibc next-turbopack; do
		[[ -e "$PREFIX/bin/$name" ]] && cp -p "$PREFIX/bin/$name" "$wrapper_backup/$name"
	done

	loading "Downloading Node.js linux-arm64" _download "$staging_dir" || { rm -rf "$staging_dir" "$wrapper_backup"; return 1; }
	loading "Stripping debug symbols" _strip "$staging_dir" || { rm -rf "$staging_dir" "$wrapper_backup"; log_error "strip failed"; return 1; }
	loading "Patching ELF interpreter" _patch "$staging_dir" || { rm -rf "$staging_dir" "$wrapper_backup"; return 1; }
	old_dir="${TURBO_DATA_DIR}.previous.$$"
	if [[ -e "$TURBO_DATA_DIR" ]] && ! mv "$TURBO_DATA_DIR" "$old_dir"; then
		rm -rf "$staging_dir" "$wrapper_backup"
		return 1
	fi
	if ! mv "$staging_dir" "$TURBO_DATA_DIR" || ! _install_wrappers; then
		rm -rf "$staging_dir" "$TURBO_DATA_DIR"
		[[ -e "$old_dir" ]] && mv "$old_dir" "$TURBO_DATA_DIR"
		for name in node-glibc next-turbopack; do
			if [[ -e "$wrapper_backup/$name" ]]; then
				mv -f "$wrapper_backup/$name" "$PREFIX/bin/$name"
			else
				rm -f "$PREFIX/bin/$name"
			fi
		done
		rm -rf "$wrapper_backup"
		return 1
	fi
	rm -rf "$old_dir" "$wrapper_backup"
	log_success "Turbopack toolchain installed"
}

uninstall_turbopack() {
	if ! _has_glibc_node; then
		log_warn "Turbopack is not installed"
		return 1
	fi

	loading "Removing CLI wrappers" _uninstall_wrappers
	loading "Removing Node.js glibc" _uninstall_node
	log_success "Turbopack toolchain removed"
}

update_turbopack() { install_turbopack; }
reinstall_turbopack() { install_turbopack; }
