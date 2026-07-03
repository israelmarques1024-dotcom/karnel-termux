#!/usr/bin/env bash

# evitar redeclaraciones
[[ -n "${__OMNI_BOOTSTRAP_LOADED:-}" ]] && return
__OMNI_BOOTSTRAP_LOADED=1

# registro de imports
declare -A __OMNI_IMPORTED

import() {
	local base="${OMNI_PATH}"
	local path="${1//@/$base}.sh"

	if [[ -n "${__OMNI_IMPORTED[$path]}" ]]; then
		return
	fi

	if [[ ! -f "$path" ]]; then
		echo "omni: import error: $path not found" >&2
		exit 1
	fi

	__OMNI_IMPORTED[$path]=1
	source "$path"
}
