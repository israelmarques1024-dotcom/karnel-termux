#!/usr/bin/env bash

# evitar redeclaraciones
[[ -n "${__KARNEL_BOOTSTRAP_LOADED:-}" ]] && return
__KARNEL_BOOTSTRAP_LOADED=1

# registro de imports
declare -A __KARNEL_IMPORTED

# CAUTION: import() calls `source` from within a function. Any `declare` (without -g)
# in the sourced file creates LOCAL variables scoped to import(), not globals.
# Always use plain assignments (VAR=val) or `declare -g` for globals in sourced files.
import() {
	local base="${KARNEL_PATH}"
	local resolved="${1/@/$base}.sh"
	local canonical
	canonical="$(realpath "$resolved" 2>/dev/null || readlink -f "$resolved" 2>/dev/null || echo "$resolved")"

	if [[ "$canonical" != "$base"/* ]]; then
		echo "karnel: import error: path traversal denied: $1" >&2
		return 1
	fi

	if [[ -n "${__KARNEL_IMPORTED[$canonical]:-}" ]]; then
		return
	fi

	if [[ ! -f "$canonical" ]]; then
		echo "karnel: import error: $canonical not found" >&2
		return 1
	fi

	source "$canonical"
	local source_rc=$?
	(( source_rc == 0 )) || return "$source_rc"
	__KARNEL_IMPORTED[$canonical]=1
	return 0
}

_karnel_process_start_time() {
	local pid="$1" stat rest
	local -a fields
	[[ "$pid" =~ ^[1-9][0-9]*$ ]] || return 1
	IFS= read -r stat <"/proc/$pid/stat" 2>/dev/null || return 1
	rest="${stat##*) }"
	read -r -a fields <<<"$rest"
	[[ ${fields[19]:-} =~ ^[0-9]+$ ]] || return 1
	printf '%s\n' "${fields[19]}"
}

_karnel_lock_owner_is_live() {
	local lock="$1" pid recorded_start current_start
	[[ -f "$lock/pid" ]] && IFS= read -r pid <"$lock/pid" || return 1
	[[ "$pid" =~ ^[1-9][0-9]*$ ]] && kill -0 "$pid" 2>/dev/null || return 1

	# PID-only locks from older versions remain valid while that PID is alive.
	[[ -f "$lock/start" ]] || return 0
	IFS= read -r recorded_start <"$lock/start" || return 1
	current_start="$(_karnel_process_start_time "$pid")" || return 1
	[[ "$recorded_start" == "$current_start" ]]
}

_karnel_remove_stale_lock() {
	local lock="$1"
	[[ -d "$lock" && ! -L "$lock" ]] || return 1
	# rmdir is race-safe for an uninitialized lock: it fails if metadata appears.
	if [[ ! -e "$lock/pid" && ! -e "$lock/start" ]]; then
		rmdir -- "$lock" 2>/dev/null
		return $?
	fi
	rm -f -- "$lock/pid" "$lock/start" || return 1
	rmdir -- "$lock" 2>/dev/null
}

_karnel_acquire_lock() {
	local lock="$1" pid="${BASHPID:-$$}" start attempt
	start="$(_karnel_process_start_time "$pid")" || return 1

	for attempt in 1 2 3; do
		if mkdir -- "$lock" 2>/dev/null; then
			if printf '%s\n' "$pid" >"$lock/pid" && printf '%s\n' "$start" >"$lock/start"; then
				return 0
			fi
			_karnel_remove_stale_lock "$lock" || true
			return 1
		fi
		[[ -d "$lock" && ! -L "$lock" ]] || return 1
		_karnel_lock_owner_is_live "$lock" && return 1
		# Give a process that just created the directory time to publish metadata.
		(( attempt == 1 )) && sleep 0.05
		_karnel_lock_owner_is_live "$lock" && return 1
		_karnel_remove_stale_lock "$lock" || return 1
	done
	return 1
}

_karnel_release_lock() {
	_karnel_remove_stale_lock "$1"
}
