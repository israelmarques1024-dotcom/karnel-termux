#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
TEST_ROOT=$(mktemp -d)
trap 'rm -rf "$TEST_ROOT"' EXIT

export HOME="$TEST_ROOT/home"
export XDG_CONFIG_HOME="$TEST_ROOT/xdg/config"
export XDG_CACHE_HOME="$TEST_ROOT/xdg/cache"
export XDG_DATA_HOME="$TEST_ROOT/xdg/data"
export XDG_STATE_HOME="$TEST_ROOT/xdg/state"
export XDG_RUNTIME_DIR="$TEST_ROOT/xdg/runtime"
mkdir -p "$HOME" "$XDG_CONFIG_HOME" "$XDG_CACHE_HOME" "$XDG_DATA_HOME" "$XDG_STATE_HOME" "$XDG_RUNTIME_DIR"
chmod 700 "$XDG_RUNTIME_DIR"

pass=0
fail() {
  printf 'FAIL: %s\n' "$1" >&2
  exit 1
}
assert_failure() {
  local description="$1"
  shift
  if "$@" >/dev/null 2>&1; then
    fail "$description unexpectedly succeeded"
  fi
  ((pass += 1))
}

# Failed imports remain retryable and successful imports are cached.
fixture="$TEST_ROOT/import-root"
mkdir -p "$fixture/utils" "$fixture/retry"
cp "$ROOT_DIR/karnel/utils/bootstrap.sh" "$fixture/utils/bootstrap.sh"
printf '%s\n' '((import_attempts += 1))' '((import_attempts > 1))' > "$fixture/retry/module.sh"
KARNEL_PATH="$fixture"
import_attempts=0
# shellcheck source=/dev/null
source "$fixture/utils/bootstrap.sh"
assert_failure "first import failure" import "@/retry/module"
import "@/retry/module" || fail "failed import was not retried"
import "@/retry/module" || fail "successful import was not cached"
[[ "$import_attempts" == "2" ]] || fail "import executed $import_attempts times"
((pass += 2))

# Canonical paths may legitimately contain two consecutive dots in a name.
mkdir -p "$fixture/valid..name"
printf '%s\n' 'canonical_dot_name_loaded=1' >"$fixture/valid..name/module.sh"
import "@/valid..name/module" || fail "canonical path containing '..' was rejected"
[[ "${canonical_dot_name_loaded:-}" == 1 ]] || fail "canonical '..' module was not loaded"
((pass += 1))

# Empty, orphaned, and PID-reused locks are recovered with bounded attempts.
lock_root="$TEST_ROOT/locks"
mkdir -p "$lock_root"
for lock_case in empty orphan reused; do
  lock="$lock_root/$lock_case.lock"
  mkdir "$lock"
  case "$lock_case" in
    orphan) printf '%s\n' 99999999 >"$lock/pid" ;;
    reused)
      printf '%s\n' "$$" >"$lock/pid"
      printf '%s\n' "$(( $(_karnel_process_start_time "$$") + 1 ))" >"$lock/start"
      ;;
  esac
  _karnel_acquire_lock "$lock" || fail "$lock_case lock was not recovered"
  _karnel_release_lock "$lock" || fail "$lock_case lock was not released"
done
((pass += 3))

# Existing environment values must never be included in env set output.
KARNEL_PATH="$ROOT_DIR/karnel"
import() { :; }
log_error() { printf '%s\n' "$*"; }
log_warn() { printf '%s\n' "$*"; }
log_info() { printf '%s\n' "$*"; }
log_success() { printf '%s\n' "$*"; }
separator() { :; }
separator_section() { :; }
box() { :; }
list_item() { :; }
read_input() { printf -v "$2" '%s' 'API_TOKEN'; }
read_secret() { printf -v "$2" '%s' 'replacement'; }
read_confirm() { printf -v "$2" '%s' 'n'; }
D_CYAN= D_YELLOW= D_RED= D_GREEN= D_DIM= D_NC= NC= GRAY=
printf '%s\n' 'export API_TOKEN=existing-super-secret' > "$HOME/.bashrc"
# shellcheck source=../karnel/cli/commands/env.sh
source "$ROOT_DIR/karnel/cli/commands/env.sh"
env_output=$(env_set)
[[ "$env_output" != *existing-super-secret* ]] || fail "env set disclosed the existing value"
((pass += 1))

# Unknown start/list targets fail, including mixed list batches.
# shellcheck source=../karnel/cli/commands/start.sh
source "$ROOT_DIR/karnel/cli/commands/start.sh"
# shellcheck source=../karnel/cli/commands/list.sh
source "$ROOT_DIR/karnel/cli/commands/list.sh"
_list_lang() { :; }
assert_failure "unknown start target" start_main missing
assert_failure "unknown list target" list_main missing
assert_failure "mixed list target" list_main lang missing

# Fallback option dispatches the Karnel-specific update target.
tui_root="$TEST_ROOT/tui-root"
mkdir -p "$tui_root/utils"
printf '%s\n' 'render_banner() { :; }' > "$tui_root/utils/banner.sh"
KARNEL_PATH="$tui_root"
# shellcheck source=../karnel/cli/karnel.sh
source "$ROOT_DIR/karnel/cli/karnel.sh"
clear() { :; }
tui_dispatch=""
karnel_main() { tui_dispatch+="${1:-} ${2:-}"; }
karnel_fallback_tui <<< $'10\n\n12' >/dev/null
[[ "$tui_dispatch" == "update karnel" ]] || fail "fallback TUI dispatched '$tui_dispatch'"
((pass += 1))

# The effective dispatcher serializes mutable commands, including TUI calls.
unset -f karnel_main
# shellcheck source=../karnel/cli/karnel.sh
source "$ROOT_DIR/karnel/cli/karnel.sh"
mkdir -p "$tui_root/cli/commands" "$TEST_ROOT/dispatcher-run"
: >"$tui_root/cli/commands/backup.sh"
: >"$tui_root/cli/commands/restore.sh"
KARNEL_RUN="$TEST_ROOT/dispatcher-run"
dispatch_started="$TEST_ROOT/dispatch-started"
backup_main() {
  [[ "${KARNEL_LIFECYCLE_LOCK_HELD:-0}" == 1 ]] || return 1
  : >"$dispatch_started"
  sleep 0.3
}
restore_main() { backup_main; }
karnel_main backup >/dev/null & dispatch_pid=$!
for _ in {1..50}; do
  [[ -e "$dispatch_started" ]] && break
  sleep 0.01
done
[[ -e "$dispatch_started" ]] || fail "mutable dispatcher did not start"
if karnel_main restore >/dev/null 2>&1; then
  fail "concurrent restore bypassed backup lifecycle lock"
else
  [[ $? -eq 75 ]] || fail "concurrent restore returned the wrong lock status"
fi
wait "$dispatch_pid" || fail "locked backup dispatcher failed"
[[ ! -d "$KARNEL_RUN/lifecycle.lock" ]] || fail "dispatcher left lifecycle lock behind"
((pass += 1))

# Informational flags do not create state or invoke update clients.
fake_bin="$TEST_ROOT/bin"
mkdir -p "$fake_bin"
printf '%s\n' "#!$(command -v bash)" 'touch "$NETWORK_SENTINEL"' 'printf "not-a-version\n"' 'exit 1' > "$fake_bin/npm"
printf '%s\n' "#!$(command -v bash)" 'touch "$NETWORK_SENTINEL"' 'exit 1' > "$fake_bin/curl"
printf '%s\n' "#!$(command -v bash)" 'touch "$NETWORK_SENTINEL"' 'printf "not-a-version\n"' > "$fake_bin/timeout"
chmod +x "$fake_bin/npm" "$fake_bin/curl" "$fake_bin/timeout"
readonly_home="$TEST_ROOT/read-only-home"
network_sentinel="$TEST_ROOT/network-used"
mkdir -p "$readonly_home"
for flag in --help --version; do
  HOME="$readonly_home" \
    XDG_CONFIG_HOME="$readonly_home/config" \
    XDG_CACHE_HOME="$readonly_home/cache" \
    XDG_DATA_HOME="$readonly_home/data" \
    XDG_STATE_HOME="$readonly_home/state" \
    XDG_RUNTIME_DIR="$readonly_home/runtime" \
    NETWORK_SENTINEL="$network_sentinel" \
    PATH="$fake_bin:$PATH" \
    bash "$ROOT_DIR/karnel/bin/karnel" "$flag" >/dev/null
done
[[ ! -e "$network_sentinel" ]] || fail "informational flag invoked an update client"
[[ ! -e "$readonly_home/config" && ! -e "$readonly_home/cache" && ! -e "$readonly_home/data" ]] || fail "informational flag created XDG state"
((pass += 1))

# Failed/invalid checks do not publish a timestamp; valid checks publish atomically.
update_home="$TEST_ROOT/update-home"
mkdir -p "$update_home"
rm -f "$network_sentinel"
HOME="$update_home" \
  XDG_CONFIG_HOME="$update_home/config" \
  XDG_CACHE_HOME="$update_home/cache" \
  XDG_DATA_HOME="$update_home/data" \
  NETWORK_SENTINEL="$network_sentinel" \
  KARNEL_UPDATE_CHECK_WAIT=1 \
  PATH="$fake_bin:$PATH" \
  bash "$ROOT_DIR/karnel/bin/karnel" missing-command &>/dev/null || true
[[ -e "$network_sentinel" ]] || fail "waited update check did not invoke a client"
[[ ! -e "$update_home/cache/karnel/last_version_check" ]] || fail "failed update check wrote a timestamp"
[[ ! -d "$update_home/cache/karnel/.version_check.lock" ]] || fail "failed update check left its lock"
valid_bin="$TEST_ROOT/valid-bin"
mkdir -p "$valid_bin"
printf '%s\n' "#!$(command -v bash)" 'touch "$NETWORK_SENTINEL"' 'printf "9.9.9\n"' > "$valid_bin/npm"
cp "$fake_bin/curl" "$valid_bin/curl"
printf '%s\n' "#!$(command -v bash)" 'touch "$NETWORK_SENTINEL"' 'printf "9.9.9\n"' > "$valid_bin/timeout"
chmod +x "$valid_bin/npm" "$valid_bin/curl" "$valid_bin/timeout"
rm -f "$network_sentinel"
HOME="$update_home" \
  XDG_CONFIG_HOME="$update_home/config" \
  XDG_CACHE_HOME="$update_home/cache" \
  XDG_DATA_HOME="$update_home/data" \
  NETWORK_SENTINEL="$network_sentinel" \
  KARNEL_UPDATE_CHECK_WAIT=1 \
  PATH="$valid_bin:$PATH" \
  bash "$ROOT_DIR/karnel/bin/karnel" missing-command &>/dev/null || true
[[ -e "$network_sentinel" ]] || fail "valid update check did not invoke a client"
[[ -s "$update_home/cache/karnel/last_version_check" ]] || fail "valid update check did not write a timestamp"
if compgen -G "$update_home/cache/karnel/.last_version_check.*" >/dev/null; then
  fail "update check left a temporary timestamp"
fi
rm -f "$network_sentinel" "$update_home/cache/karnel/last_version_check"
mkdir "$update_home/cache/karnel/.version_check.lock"
HOME="$update_home" \
  XDG_CONFIG_HOME="$update_home/config" \
  XDG_CACHE_HOME="$update_home/cache" \
  XDG_DATA_HOME="$update_home/data" \
  NETWORK_SENTINEL="$network_sentinel" \
  KARNEL_UPDATE_CHECK_WAIT=1 \
  PATH="$valid_bin:$PATH" \
  bash "$ROOT_DIR/karnel/bin/karnel" missing-command &>/dev/null || true
[[ -e "$network_sentinel" ]] || fail "empty update lock was not recovered"
[[ ! -d "$update_home/cache/karnel/.version_check.lock" ]] || fail "recovered update lock was left behind"
((pass += 1))

# Karnel-owned directories are mode 0700 and symlink destinations are refused.
secure_root="$TEST_ROOT/secure"
mkdir -p "$secure_root/config" "$secure_root/cache" "$secure_root/data"
HOME="$secure_root/home" \
  XDG_CONFIG_HOME="$secure_root/config" \
  XDG_CACHE_HOME="$secure_root/cache" \
  XDG_DATA_HOME="$secure_root/data" \
  KARNEL_PATH="$ROOT_DIR/karnel" \
  bash -c 'source "$KARNEL_PATH/utils/env.sh"'
for directory in \
  "$secure_root/config/karnel" \
  "$secure_root/cache/karnel" \
  "$secure_root/data/karnel-data" \
  "$secure_root/data/karnel-data/tools" \
  "$secure_root/cache/karnel/run" \
  "$secure_root/cache/karnel/logs"; do
  [[ "$(stat -c '%a' "$directory")" == "700" ]] || fail "$directory is not mode 0700"
done
mkdir -p "$TEST_ROOT/outside"
symlink_root="$TEST_ROOT/symlink"
mkdir -p "$symlink_root/cache"
ln -s "$TEST_ROOT/outside" "$symlink_root/cache/karnel"
assert_failure "symlink XDG directory" env \
  HOME="$symlink_root/home" \
  XDG_CONFIG_HOME="$symlink_root/config" \
  XDG_CACHE_HOME="$symlink_root/cache" \
  XDG_DATA_HOME="$symlink_root/data" \
  KARNEL_PATH="$ROOT_DIR/karnel" \
  bash -c 'source "$KARNEL_PATH/utils/env.sh"'

printf 'Karnel CLI contracts: %d passed\n' "$pass"
