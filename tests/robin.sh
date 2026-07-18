#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
TEST_ROOT=$(mktemp -d)
trap 'rm -rf "$TEST_ROOT"' EXIT

export KARNEL_PATH="$ROOT_DIR/karnel"
export KARNEL_CONFIG="$TEST_ROOT/config"
export KARNEL_CACHE="$TEST_ROOT/cache"
export KARNEL_DATA="$TEST_ROOT/data"
export KARNEL_TOOLS="$KARNEL_DATA/tools"
export KARNEL_RUN="$KARNEL_CACHE/run"
export KARNEL_LOGS="$KARNEL_CACHE/logs"
export ROBIN_ROOT="$KARNEL_TOOLS/osint/robin"
export ROBIN_CONFIG_DIR="$KARNEL_CONFIG/robin"
export ROBIN_DATA_DIR="$KARNEL_DATA/robin"
export ROBIN_PID_FILE="$KARNEL_RUN/robin.pid"
export ROBIN_LOCK_DIR="$KARNEL_RUN/robin.lock"
export ROBIN_LOG="$KARNEL_LOGS/robin.log"
export ROBIN_PROC_ROOT="$TEST_ROOT/proc"
export ROBIN_PORT=18591

mkdir -p "$KARNEL_TOOLS/osint" "$KARNEL_RUN" "$KARNEL_LOGS"

log_error() { :; }
log_warn() { :; }
log_info() { :; }
log_success() { :; }
box() { :; }
list_item() { :; }

import() {
  case "$1" in
    "@/tools/osint/robin/common")
      # shellcheck source=../karnel/tools/osint/robin/common.sh
      source "$KARNEL_PATH/tools/osint/robin/common.sh"
      ;;
    *) : ;;
  esac
}

# shellcheck source=../karnel/tools/osint/robin/common.sh
source "$KARNEL_PATH/tools/osint/robin/common.sh"
# shellcheck source=../karnel/cli/commands/robin.sh
source "$KARNEL_PATH/cli/commands/robin.sh"
# shellcheck source=../karnel/tools/osint/robin/install.sh
source "$KARNEL_PATH/tools/osint/robin/install.sh"

pass=0
assert() {
  local description="$1"
  shift
  if "$@"; then
    ((pass += 1))
  else
    printf 'FAIL: %s\n' "$description" >&2
    exit 1
  fi
}

# Versioned non-interactive acknowledgement.
assert "explicit responsible-use acknowledgement" _robin_require_acknowledgement true
assert "acknowledgement version is recorded" grep -qx "notice_version=$ROBIN_NOTICE_VERSION" "$ROBIN_ACK_FILE"
assert "acknowledgement file is private" test "$(stat -c '%a' "$ROBIN_ACK_FILE")" = "600"

# Provider detection ignores placeholders and never prints values.
cat > "$TEST_ROOT/providers.env" <<'EOF'
OPENAI_API_KEY=your_openai_key
ANTHROPIC_API_KEY="real-test-value"
OLLAMA_BASE_URL=http://127.0.0.1:11434
EMPTY=
EOF
assert "configured providers are counted" test "$(_robin_configured_provider_count "$TEST_ROOT/providers.env")" = "2"

# PID identity validates start time, command line, cwd, and rejects reuse.
pid="$$"
mkdir -p "$ROBIN_PROC_ROOT/$pid" "$ROBIN_MANAGED_APP_DIR"
cp "/proc/$pid/stat" "$ROBIN_PROC_ROOT/$pid/stat"
printf 'python\0-m\0streamlit\0run\0ui.py\0' > "$ROBIN_PROC_ROOT/$pid/cmdline"
ln -s "$ROBIN_MANAGED_APP_DIR" "$ROBIN_PROC_ROOT/$pid/cwd"
_robin_refresh_layout
start_time=$(_robin_proc_start_time "$pid")
assert "managed PID identity matches" _robin_process_matches "$pid" "$start_time"
assert "unmanaged Robin process can be identified safely" test "$(_robin_find_matching_processes)" = "$pid"
if _robin_process_matches "$pid" "${start_time}9"; then
  printf 'FAIL: reused PID start time was accepted\n' >&2
  exit 1
fi
((pass += 1))
printf '%s\n' "$pid" > "$ROBIN_PID_FILE"
if _robin_read_pid; then
  printf 'FAIL: truncated PID metadata was accepted\n' >&2
  exit 1
fi
((pass += 1))
rm -f "$ROBIN_PID_FILE"

# Legacy migration preserves configuration and investigations outside source.
rm -rf "$ROBIN_MANAGED_APP_DIR" "$ROBIN_PROC_ROOT"
mkdir -p "$ROBIN_ROOT/.git" "$ROBIN_ROOT/.venv/bin" "$ROBIN_ROOT/investigations"
printf '#!/usr/bin/env bash\nexec python3 "$@"\n' > "$ROBIN_ROOT/.venv/bin/python"
chmod +x "$ROBIN_ROOT/.venv/bin/python"
printf 'SECRET=preserved\n' > "$ROBIN_ROOT/.env"
printf '{"query":"preserved"}\n' > "$ROBIN_ROOT/investigations/investigation_test.json"
_robin_refresh_layout
assert "legacy layout detected" test "$ROBIN_LAYOUT" = "legacy"
assert "legacy migration succeeds" _robin_migrate_legacy_layout
assert "managed layout activated" test "$ROBIN_LAYOUT" = "managed"
assert "configuration preserved" grep -qx 'SECRET=preserved' "$ROBIN_ENV_FILE"
assert "investigation preserved" test -f "$ROBIN_INVESTIGATIONS_DIR/investigation_test.json"
assert "source env is a persistent symlink" test -L "$ROBIN_APP_DIR/.env"
assert "source investigations are a persistent symlink" test -L "$ROBIN_APP_DIR/investigations"

# Candidate virtualenv scripts remain executable after an atomic directory swap.
old_venv="$TEST_ROOT/venv-candidate"
new_venv="$TEST_ROOT/venv-active"
mkdir -p "$new_venv/bin"
ln -s "$(command -v python3)" "$new_venv/bin/python"
printf '#!%s/bin/python\nprint("ok")\n' "$old_venv" > "$new_venv/bin/tool"
assert "virtualenv relocation succeeds" _robin_relocate_venv "$old_venv" "$new_venv"
assert "virtualenv shebang is rewritten" grep -qx "#!$new_venv/bin/python" "$new_venv/bin/tool"

# Purging a legacy layout migrates first, then removes every secret copy.
rm -rf "$ROBIN_ROOT" "$ROBIN_CONFIG_DIR" "$ROBIN_DATA_DIR"
mkdir -p "$ROBIN_ROOT/.git" "$ROBIN_ROOT/.venv/bin" "$ROBIN_ROOT/investigations"
printf '#!/usr/bin/env bash\nexec python3 "$@"\n' > "$ROBIN_ROOT/.venv/bin/python"
chmod +x "$ROBIN_ROOT/.venv/bin/python"
printf 'SECRET=must-be-deleted\n' > "$ROBIN_ROOT/.env"
printf '{"query":"delete-me"}\n' > "$ROBIN_ROOT/investigations/investigation_purge.json"
_robin_refresh_layout
assert "legacy purge succeeds" _robin_purge_data --yes
if grep -R -q 'must-be-deleted\|delete-me' "$ROBIN_CONFIG_DIR" "$ROBIN_DATA_DIR" 2>/dev/null; then
  printf 'FAIL: purge preserved legacy Robin data\n' >&2
  exit 1
fi
((pass += 1))

# Real command dispatch reaches the shared batch helper and rejects unknown tools.
cli_home="$TEST_ROOT/cli-home"
mkdir -p "$cli_home/cache/karnel"
date +%s > "$cli_home/cache/karnel/last_version_check"
for command in install reinstall; do
  output="$TEST_ROOT/$command.out"
  if HOME="$cli_home" XDG_CONFIG_HOME="$cli_home/config" \
    XDG_CACHE_HOME="$cli_home/cache" XDG_DATA_HOME="$cli_home/data" \
    bash "$KARNEL_PATH/bin/karnel" "$command" osint --unknown >"$output" 2>&1; then
    printf 'FAIL: %s accepted an unknown OSINT tool\n' "$command" >&2
    exit 1
  fi
  assert "$command dispatch uses batch tool action" grep -q 'Unknown osint tool: unknown' "$output"
done

printf 'Robin contracts: %d passed\n' "$pass"
