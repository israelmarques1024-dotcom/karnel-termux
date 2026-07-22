#!/usr/bin/env bash
import "@/utils/log"
import "@/utils/version"

LOG_FILE="$KARNEL_CACHE/install_ai.log"

_codegraph_dependencies() {
	loading "Installing dependencies" _codegraph_dependencies_impl
}

_codegraph_dependencies_impl() {
	declare -A DEPS=(
		["nodejs-lts"]="node"
		["ripgrep"]="rg"
		["sqlite"]="sqlite"
		["git"]="git"
		["python"]="python"
		["clang"]="clang"
		["make"]="make"
		["curl"]="curl"
	)

	local pkg_name bin_name
	for pkg_name in "${!DEPS[@]}"; do
		bin_name="${DEPS[$pkg_name]}"
		if ! command -v "$bin_name" &>/dev/null; then
			if ! pkg install "$pkg_name" -y &>>"$LOG_FILE"; then
				log_error "Failed to install $pkg_name"
				return 1
			fi
		fi
	done

	return 0
}

_download_codegraph() {
	loading "Downloading CodeGraph" _download_codegraph_impl
}

_download_codegraph_impl() {
	LATEST_VERSION=$(curl -sI https://github.com/colbymchenry/codegraph/releases/latest | grep -i location | sed -E 's#.*/tag/([^[:space:]]+).*#\1#')
	LATEST_VERSION="${LATEST_VERSION#v}"

	if [ -z "$LATEST_VERSION" ]; then
		log_error "Failed to fetch latest CodeGraph version"
		return 1
	fi

	if ! [[ "$LATEST_VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
		log_error "Invalid CodeGraph version from release server: $LATEST_VERSION"
		return 1
	fi

	local tarball
	tarball=$(mktemp "$KARNEL_DATA/codegraph-XXXXXX.tar.gz")

	if ! curl -L "https://github.com/colbymchenry/codegraph/releases/download/v${LATEST_VERSION}/codegraph-linux-arm64.tar.gz" -o "$tarball" &>>"$LOG_FILE"; then
		log_error "Failed to download CodeGraph"
		rm -f "$tarball"
		return 1
	fi

	if ! tar -xzf "$tarball" -C "$KARNEL_DATA" &>>"$LOG_FILE"; then
		log_error "Failed to extract CodeGraph"
		rm -f "$tarball"
		return 1
	fi

	rm -f "$tarball"

	return 0
}

_write_codegraph_wrapper() {
	loading "Creating CodeGraph wrapper" _write_codegraph_wrapper_impl
}

_write_codegraph_wrapper_impl() {
	local wrapper_src="$KARNEL_PATH/tools/ai/codegraph/bin/codegraph"
	if [ ! -f "$wrapper_src" ]; then
		log_error "Wrapper template not found at $wrapper_src"
		return 1
	fi
	cp "$wrapper_src" "$PREFIX/bin/codegraph"
	chmod +x "$PREFIX/bin/codegraph"

	return 0
}

install_codegraph() {
	if command -v codegraph &>/dev/null; then
		log_info "CodeGraph is already installed"
		return 2
	fi
	log_info "Installing CodeGraph..."

	mkdir -p "$(dirname "$LOG_FILE")"

	_codegraph_dependencies || return 1
	_download_codegraph || return 1
	_write_codegraph_wrapper || return 1

	log_success "CodeGraph installed"
	return 0
}

uninstall_codegraph() {
	if ! command -v codegraph &>/dev/null; then
		log_info "CodeGraph is not installed"
		return 2
	fi
	log_info "Uninstalling CodeGraph..."
	mkdir -p "$(dirname "$LOG_FILE")"

	loading "Removing CodeGraph" _uninstall_codegraph_impl

	log_success "CodeGraph uninstalled"
	return 0
}

_uninstall_codegraph_impl() {
	if [[ -n "$KARNEL_DATA" && -d "$KARNEL_DATA/codegraph-linux-arm64" ]]; then
	  rm -rf "$KARNEL_DATA/codegraph-linux-arm64"
	fi
	if rm -f "$PREFIX/bin/codegraph" &>>"$LOG_FILE"; then
		return 0
	else
		log_error "Failed to remove old CodeGraph installation"
		return 1
	fi
}

update_codegraph() {
  _check_update_needed "CodeGraph" "$(_get_installed_version codegraph)" "$(_get_remote_github_version colbymchenry/codegraph)" _do_update_codegraph
}

_do_update_codegraph() {
  loading "Removing old CodeGraph" _update_codegraph_remove_impl
  _codegraph_dependencies || return 1
  _download_codegraph || return 1
  _write_codegraph_wrapper || return 1
  return 0
}

_update_codegraph_remove_impl() {
	if [[ -n "$KARNEL_DATA" && -d "$KARNEL_DATA/codegraph-linux-arm64" ]]; then
	  rm -rf "$KARNEL_DATA/codegraph-linux-arm64" &>>"$LOG_FILE"
	fi


	if ! rm -f "$PREFIX/bin/codegraph" &>>"$LOG_FILE"; then
		log_error "Failed to remove old CodeGraph wrapper"
		return 1
	fi

	return 0
}

reinstall_codegraph() {
	uninstall_codegraph
	install_codegraph
}
