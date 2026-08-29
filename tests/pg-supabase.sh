#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
TEST_ROOT=$(mktemp -d)
trap 'rm -rf "$TEST_ROOT"' EXIT

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
  return 0
}

assert_pg_failures_propagate() (
  export PREFIX="$TEST_ROOT/prefix"
  export KARNEL_CACHE="$TEST_ROOT/cache"
  mkdir -p "$PREFIX" "$KARNEL_CACHE"
  import() { :; }
  log_error() { :; }
  log_warn() { :; }
  log_info() { :; }
  log_success() { :; }
  separator() { :; }
  box() { :; }
  loading() { shift; "$@"; }
  # shellcheck source=../karnel/cli/commands/pg.sh
  source "$ROOT_DIR/karnel/cli/commands/pg.sh"

  check_pg_installed() { :; }
  pg_detect_data() { PG_DATA="$TEST_ROOT/data"; :; }
  pg_ctl() { return 1; }
  assert_failure "pg stop failure" pg_stop

  pg_stop() { return 1; }
  pg_start() { fail "pg restart started after failed stop"; }
  assert_failure "pg restart stop failure" pg_restart

  pg_stop() { :; }
  pg_start() { return 1; }
  assert_failure "pg restart start failure" pg_restart
  return 0
)

assert_pg_schedule_failure_propagates() (
  export PREFIX="$TEST_ROOT/schedule-prefix"
  export KARNEL_CACHE="$TEST_ROOT/schedule-cache"
  export KARNEL_PATH="$ROOT_DIR/karnel"
  mkdir -p "$PREFIX" "$KARNEL_CACHE"
  import() { :; }
  log_error() { :; }
  log_warn() { :; }
  log_success() { :; }
  separator() { :; }
  box() { :; }
  list_item() { :; }
  read_input() { printf -v "$2" '%s' 'testdb'; }
  read_select() { printf -v "$2" '%s' 'Hourly'; }
  crontab() {
    [[ "${1:-}" == '-l' ]] && return 0
    return 1
  }
  # shellcheck source=../karnel/cli/commands/pg.sh
  source "$ROOT_DIR/karnel/cli/commands/pg.sh"
  check_pg_installed() { :; }

  assert_failure "pg schedule crontab failure" pg_schedule
  return 0
)

assert_supabase_status_failure_propagates() (
  import() { :; }
  log_error() { :; }
  log_warn() { :; }
  # shellcheck source=../karnel/cli/commands/supabase.sh
  source "$ROOT_DIR/karnel/cli/commands/supabase.sh"

  supabase() { :; }
  supabase_safe() { return 1; }
  assert_failure "supabase remote status failure" supabase_remote_status
  return 0
)

assert_pg_failures_propagate
assert_pg_schedule_failure_propagates
assert_supabase_status_failure_propagates
printf 'PostgreSQL and Supabase contracts: 5 passed\n'
