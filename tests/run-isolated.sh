#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
TEST_ENV=$(mktemp -d)
trap 'rm -rf "$TEST_ENV"' EXIT

export HOME="$TEST_ENV/home"
export XDG_CONFIG_HOME="$TEST_ENV/xdg/config"
export XDG_CACHE_HOME="$TEST_ENV/xdg/cache"
export XDG_DATA_HOME="$TEST_ENV/xdg/data"
export XDG_STATE_HOME="$TEST_ENV/xdg/state"
export XDG_RUNTIME_DIR="$TEST_ENV/xdg/runtime"
mkdir -p "$HOME" "$XDG_CONFIG_HOME" "$XDG_CACHE_HOME" "$XDG_DATA_HOME" "$XDG_STATE_HOME" "$XDG_RUNTIME_DIR"
chmod 700 "$HOME" "$XDG_CONFIG_HOME" "$XDG_CACHE_HOME" "$XDG_DATA_HOME" "$XDG_STATE_HOME" "$XDG_RUNTIME_DIR"

bash "$ROOT_DIR/tests/run.sh"
