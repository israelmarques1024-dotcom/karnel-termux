#!/usr/bin/env bash

# evitar redeclaraciones
[[ -n "${__KARNEL_BOOTSTRAP_LOADED:-}" ]] && return
__KARNEL_BOOTSTRAP_LOADED=1

# registro de imports
declare -A __KARNEL_IMPORTED

import() {
	local base="${KARNEL_PATH}"
	local resolved="${1//@/$base}.sh"
	local canonical
	canonical="$(realpath "$resolved" 2>/dev/null || echo "$resolved")"

	if [[ "$canonical" != "$base"/* ]]; then
		echo "karnel: import error: path traversal denied: $1" >&2
		return 1
	fi

	if [[ -n "${__KARNEL_IMPORTED[$canonical]}" ]]; then
		return
	fi

	if [[ ! -f "$canonical" ]]; then
		echo "karnel: import error: $canonical not found" >&2
		return 1
	fi

	__KARNEL_IMPORTED[$canonical]=1
	source "$canonical"
}
