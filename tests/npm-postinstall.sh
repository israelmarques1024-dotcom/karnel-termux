#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
TEST_ROOT=$(mktemp -d)
trap 'rm -rf "$TEST_ROOT"' EXIT

PACKAGE_ROOT="$TEST_ROOT/package"
mkdir -p "$PACKAGE_ROOT/scripts" "$PACKAGE_ROOT/karnel/bin"
cp "$ROOT_DIR/scripts/npm-install.js" "$PACKAGE_ROOT/scripts/npm-install.js"
cp "$ROOT_DIR/install.sh" "$ROOT_DIR/package.json" "$PACKAGE_ROOT/"
printf '#!/usr/bin/env bash\n' >"$PACKAGE_ROOT/karnel/bin/karnel"
RELEASE_COMMIT=0123456789abcdef0123456789abcdef01234567
printf '%s\n' "$RELEASE_COMMIT" >"$PACKAGE_ROOT/karnel/RELEASE_COMMIT"

FAKE_BIN="$TEST_ROOT/bin"
PREFIX="$TEST_ROOT/com.termux-prefix"
ARGS_FILE="$TEST_ROOT/bash-args"
mkdir -p "$FAKE_BIN" "$PREFIX/bin"
ln -s "$PACKAGE_ROOT/karnel/bin/karnel" "$PREFIX/bin/karnel"

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
node "$PACKAGE_ROOT/scripts/npm-install.js" >/dev/null

expected_version=$(node -p "require('$ROOT_DIR/package.json').version")
expected=$(printf 'install.sh\n--ref\nv%s\n--commit\n%s' "$expected_version" "$RELEASE_COMMIT")
actual=$(<"$ARGS_FILE")
if [[ "$actual" != "$expected" ]]; then
  printf 'FAIL: npm bin symlink was mistaken for a complete installation\n' >&2
  exit 1
fi

printf 'npm postinstall contract: passed\n'
