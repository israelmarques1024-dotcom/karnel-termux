#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
TEST_ROOT=$(mktemp -d)
trap 'rm -rf "$TEST_ROOT"' EXIT

FAKE_BIN="$TEST_ROOT/bin"
PREFIX="$TEST_ROOT/com.termux-prefix"
ARGS_FILE="$TEST_ROOT/bash-args"
mkdir -p "$FAKE_BIN" "$PREFIX/bin"

printf '#!%s\n' "$BASH" >"$FAKE_BIN/npm"
printf '%s\n' \
  'if [[ "$3" == "ignore-scripts" ]]; then' \
  '  printf "false\\n"' \
  'fi' >>"$FAKE_BIN/npm"
printf '#!%s\n' "$BASH" >"$FAKE_BIN/bash"
printf '%s\n' 'printf "%s\n" "$@" >"$NPM_POSTINSTALL_ARGS"' >>"$FAKE_BIN/bash"
chmod +x "$FAKE_BIN/npm" "$FAKE_BIN/bash"

PATH="$FAKE_BIN:$PATH" \
PREFIX="$PREFIX" \
NPM_POSTINSTALL_ARGS="$ARGS_FILE" \
KARNEL_TEST_TERMUX=1 \
node "$ROOT_DIR/scripts/npm-install.js" >/dev/null

expected_version=$(node -p "require('$ROOT_DIR/package.json').version")
expected=$(printf 'install.sh\n--ref\nv%s' "$expected_version")
actual=$(<"$ARGS_FILE")
if [[ "$actual" != "$expected" ]]; then
  printf 'FAIL: npm postinstall did not pin the packaged release\n' >&2
  exit 1
fi

printf 'npm postinstall contract: passed\n'
