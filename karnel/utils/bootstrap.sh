#!/usr/bin/env bash

# evitar redeclaraciones
[[ -n "${__KARNEL_BOOTSTRAP_LOADED:-}" ]] && return
__KARNEL_BOOTSTRAP_LOADED=1

# registro de imports
declare -A __KARNEL_IMPORTED

import() {
	local base="${KARNEL_PATH}"
	local path="${1//@/$base}.sh"

	if [[ -n "${__KARNEL_IMPORTED[$path]}" ]]; then
		return
	fi

	if [[ ! -f "$path" ]]; then
		echo "karnel: import error: $path not found" >&2
		return 1
	fi

	__KARNEL_IMPORTED[$path]=1
	source "$path"
}
