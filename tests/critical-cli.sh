#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
TEST_ROOT=$(mktemp -d)
trap 'rm -rf "$TEST_ROOT"' EXIT
export KARNEL_CACHE="$TEST_ROOT/cache"
mkdir -p "$KARNEL_CACHE"

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
}

assert_restore_rejects_multiple_files() (
  export KARNEL_DATA="$TEST_ROOT/data"
  mkdir -p "$KARNEL_DATA/backups"
  : >"$KARNEL_DATA/backups/first.tar.gz"
  : >"$KARNEL_DATA/backups/second.tar.gz"
  import() { :; }
  log_error() { :; }
  # shellcheck source=../karnel/cli/commands/restore.sh
  source "$ROOT_DIR/karnel/cli/commands/restore.sh"

  assert_failure "restore with two files" restore_main first.tar.gz second.tar.gz
)

assert_agent_prompt_and_plan_guards() (
  import() { :; }
  log_warn() { :; }
  # shellcheck source=../karnel/cli/commands/agent.sh
  source "$ROOT_DIR/karnel/cli/commands/agent.sh"
  agent_parse_args explain rsync backups
  [[ "$AGENT_PROMPT" == "explain rsync backups" ]] || fail "agent lost positional prompt words"
  agent_parse_args --prompt explicit ignored words
  [[ "$AGENT_PROMPT" == "explicit" ]] || fail "explicit agent prompt lost precedence"

  # shellcheck source=../karnel/utils/agent_actions.sh
  source "$ROOT_DIR/karnel/utils/agent_actions.sh"
  _agent_cmd_is_readonly "git status" || fail "plan blocked git status"
  assert_failure "plan semicolon bypass" _agent_cmd_is_readonly "git status; rm -f victim"
  assert_failure "plan quoted command bypass" _agent_cmd_is_readonly "'r''m' -f victim"
  assert_failure "plan find delete" _agent_cmd_is_readonly "find . -delete"
)

assert_agent_context_rejects_zero() (
  export KARNEL_CONFIG="$TEST_ROOT/config"
  import() { :; }
  log_error() { :; }
  # shellcheck source=../karnel/utils/agent_llm.sh
  source "$ROOT_DIR/karnel/utils/agent_llm.sh"

  assert_failure "zero context window" agent_config_set context 0
)

assert_restore_rejects_multiple_files
assert_agent_prompt_and_plan_guards
assert_agent_context_rejects_zero
printf 'Critical CLI regressions: 7 passed\n'
