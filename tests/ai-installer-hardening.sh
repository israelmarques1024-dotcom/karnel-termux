#!/usr/bin/env bash
# shellcheck disable=SC2329
set -euo pipefail

ROOT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
TEST_ROOT=$(mktemp -d)
trap 'rm -rf "$TEST_ROOT"' EXIT

assert_safe_archive_rejected() (
  export KARNEL_CACHE="$TEST_ROOT/archive-cache"
  LOG_FILE="$KARNEL_CACHE/test.log"
  mkdir -p "$KARNEL_CACHE" "$TEST_ROOT/archive/source" "$TEST_ROOT/archive/out"
  log_error() { :; }
  source "$ROOT_DIR/karnel/utils/install.sh"

  ln -s ../../escaped "$TEST_ROOT/archive/source/link"
  tar -czf "$TEST_ROOT/archive/unsafe.tar.gz" -C "$TEST_ROOT/archive/source" link
  if extract_tarball "$TEST_ROOT/archive/unsafe.tar.gz" "$TEST_ROOT/archive/out"; then
    printf 'FAIL: unsafe archive link was accepted\n' >&2
    return 1
  fi
  [[ ! -e "$TEST_ROOT/escaped" ]]
)

assert_mimocode_fails_before_mutation() (
  export HOME="$TEST_ROOT/mimo-home"
  export PREFIX="$TEST_ROOT/mimo-prefix"
  export KARNEL_CACHE="$TEST_ROOT/mimo-cache"
  export KARNEL_PATH="$ROOT_DIR/karnel"
  mkdir -p "$HOME/.mimocode" "$PREFIX/bin" "$KARNEL_CACHE"
  printf 'secret\n' >"$HOME/.mimocode/credentials.json"
  printf 'external\n' >"$PREFIX/bin/mimo"
  import() { :; }
  log_error() { :; }
  log_info() { :; }
  log_warn() { :; }
  loading() { shift; "$@"; }
  source "$ROOT_DIR/karnel/utils/install.sh"
  source "$ROOT_DIR/karnel/tools/ai/mimocode/install.sh"

  if _install_mimocode_proot_impl; then return 1; fi
  if uninstall_mimocode; then return 1; fi
  [[ "$(<"$HOME/.mimocode/credentials.json")" == secret ]]
  [[ "$(<"$PREFIX/bin/mimo")" == external ]]
)

assert_mimocode_update_preserves_working_install() (
  export HOME="$TEST_ROOT/mimo-update-home"
  export PREFIX="$TEST_ROOT/mimo-update-prefix"
  export KARNEL_CACHE="$TEST_ROOT/mimo-update-cache"
  export KARNEL_PATH="$ROOT_DIR/karnel"
  mkdir -p "$HOME/.local/share/karnel-data/mimocode" "$PREFIX/bin" "$KARNEL_CACHE"
  printf 'old binary\n' >"$HOME/.local/share/karnel-data/mimocode/mimocode"
  printf 'karnel-managed-v1\n' >"$HOME/.local/share/karnel-data/mimocode/.karnel-managed"
  printf '#!/usr/bin/env bash\nexit 0\n' >"$PREFIX/bin/mimo"
  chmod +x "$PREFIX/bin/mimo"
  sha256sum "$PREFIX/bin/mimo" >"$HOME/.local/share/karnel-data/mimocode/.karnel-wrapper"
  import() { :; }
  log_error() { :; }
  log_info() { :; }
  loading() { shift; "$@"; }
  pkg() { :; }
  _get_latest_mimocode_version() { printf 'v9.9.9\n'; }
  curl() { return 1; }
  source "$ROOT_DIR/karnel/utils/install.sh"
  source "$ROOT_DIR/karnel/tools/ai/mimocode/install.sh"
  _mimocode_install_deps() { :; }
  _get_latest_mimocode_version() { printf 'v9.9.9\n'; }

  if _do_update_mimocode; then return 1; fi
  [[ "$(<"$MIMOCODE_DATA_DIR/mimocode")" == 'old binary' ]]
  [[ -x "$PREFIX/bin/mimo" ]]
)

assert_source_contracts() {
  local tool file
  for tool in claude-code kimchi-code qoder codebuff mimocode goose codegraph; do
    file="$ROOT_DIR/karnel/tools/ai/$tool/install.sh"
    grep -qF 'extract_tarball' "$file"
  done
  for tool in claude-code kimchi-code qoder codebuff ampcode mimocode goose codegraph crush opencode; do
    file="$ROOT_DIR/karnel/tools/ai/$tool/install.sh"
    grep -Eq 'SHA-256|sha256|integrity|verify_github_release_asset|github_download_and_extract' "$file"
  done
  grep -qF 'upstream does not publish a verifiable checksum' "$ROOT_DIR/karnel/tools/ai/cursor-cli/install.sh"
  grep -qF 'MiMo Code Proot installation is unavailable' "$ROOT_DIR/karnel/tools/ai/mimocode/install.sh"
  ! grep -qF 'rm -rf /root/.claude' "$ROOT_DIR/karnel/tools/ai/claude-code/install.sh"
  ! grep -qF 'rm -rf /root/.mimocode' "$ROOT_DIR/karnel/tools/ai/mimocode/install.sh"
  if grep -qF "[kimchi-code]='" "$ROOT_DIR/karnel/tools/ai/all.sh"; then return 1; fi
  grep -qF "[goose]='goose --version'" "$ROOT_DIR/karnel/tools/ai/all.sh"
}

assert_safe_archive_rejected
assert_mimocode_fails_before_mutation
assert_mimocode_update_preserves_working_install
assert_source_contracts
printf 'AI installer hardening contracts: 4 passed\n'
