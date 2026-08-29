#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
TEST_ROOT=$(mktemp -d)
trap 'rm -rf "$TEST_ROOT"' EXIT

assert_bun_download_stages_replacement() (
  export PREFIX="$TEST_ROOT/staged-prefix"
  export KARNEL_CACHE="$TEST_ROOT/staged-cache"
  export KARNEL_DATA="$TEST_ROOT/staged-data"
  mkdir -p "$PREFIX/bin" "$PREFIX/lib" "$KARNEL_CACHE" "$KARNEL_DATA/bun"
  printf 'old bun' >"$KARNEL_DATA/bun/bun.real"
  : >"$KARNEL_DATA/bun/.karnel-managed"
  import() { :; }
  log_error() { :; }
  loading() { "$2"; }
  uname() { printf 'aarch64\n'; }
  curl() {
    local output="" previous="" arg
    for arg in "$@"; do
      [[ "$previous" == '-o' ]] && output="$arg"
      previous="$arg"
    done
    : >"$output"
  }
  # The installer (since 4.17.14) refuses extraction without the integrity
  # helpers from utils/install.sh, which this unit test does not source.
  # Stub them with the same contract: a valid digest, a pass-through verify,
  # and an extractor that materializes the bun binary.
  github_release_asset_sha256() { printf '%064d\n' 0; }
  verify_sha256() { return 0; }
  safe_extract_zip() {
    local archive="$1" outdir="$2"
    mkdir -p "$outdir/bun-linux-aarch64"
    printf 'new bun' >"$outdir/bun-linux-aarch64/bun"
  }
  # shellcheck source=../karnel/tools/lang/bun/install.sh
  source "$ROOT_DIR/karnel/tools/lang/bun/install.sh"
  _bun_fetch_version() { printf '1.2.3\n'; }

  _download_bun_binary_native_impl
  [[ "$(<"$BUN_DATA_DIR/bun.real")" == 'new bun' ]]
  [[ -f "$BUN_DATA_DIR/.karnel-managed" ]]
  [[ ! -e "${BUN_DATA_DIR}.previous.$$" ]]
)

assert_bun_download_failure_preserves_existing_data() (
  export PREFIX="$TEST_ROOT/failure-prefix"
  export KARNEL_CACHE="$TEST_ROOT/failure-cache"
  export KARNEL_DATA="$TEST_ROOT/failure-data"
  mkdir -p "$PREFIX/bin" "$PREFIX/lib" "$KARNEL_CACHE" "$KARNEL_DATA/bun"
  printf 'old bun' >"$KARNEL_DATA/bun/bun.real"
  : >"$KARNEL_DATA/bun/.karnel-managed"
  import() { :; }
  log_error() { :; }
  loading() { "$2"; }
  uname() { printf 'aarch64\n'; }
  curl() { return 1; }
  # shellcheck source=../karnel/tools/lang/bun/install.sh
  source "$ROOT_DIR/karnel/tools/lang/bun/install.sh"
  _bun_fetch_version() { printf '1.2.3\n'; }

  if _download_bun_binary_native_impl; then
    return 1
  fi
  [[ "$(<"$BUN_DATA_DIR/bun.real")" == 'old bun' ]]
)

assert_bun_uninstall_preserves_unowned_prefix_files() (
  export PREFIX="$TEST_ROOT/ownership-prefix"
  export KARNEL_CACHE="$TEST_ROOT/ownership-cache"
  export KARNEL_DATA="$TEST_ROOT/ownership-data"
  mkdir -p "$PREFIX/bin" "$PREFIX/lib" "$KARNEL_CACHE" "$KARNEL_DATA/bun"
  : >"$KARNEL_DATA/bun/.karnel-managed"
  printf 'user replacement' >"$PREFIX/bin/bun"
  printf 'user replacement' >"$PREFIX/bin/bunx"
  printf 'user replacement' >"$PREFIX/lib/bun-shim.so"
  printf 'different checksum\n' >"$KARNEL_DATA/bun/.karnel-wrapper-bun"
  printf 'bun\n' >"$KARNEL_DATA/bun/.karnel-wrapper-bunx"
  printf 'different checksum\n' >"$KARNEL_DATA/bun/.karnel-shim"
  import() { :; }
  log_error() { :; }
  log_success() { :; }
  # shellcheck source=../karnel/tools/lang/bun/install.sh
  source "$ROOT_DIR/karnel/tools/lang/bun/install.sh"

  if _bun_verify_native_ownership; then
    return 1
  fi
  _uninstall_bun_native
  [[ "$(<"$PREFIX/bin/bun")" == 'user replacement' ]]
  [[ "$(<"$PREFIX/bin/bunx")" == 'user replacement' ]]
  [[ "$(<"$PREFIX/lib/bun-shim.so")" == 'user replacement' ]]
  [[ ! -e "$BUN_DATA_DIR" ]]
)

assert_bun_download_stages_replacement
assert_bun_download_failure_preserves_existing_data
assert_bun_uninstall_preserves_unowned_prefix_files
printf 'Bun installer contracts: 3 passed\n'
