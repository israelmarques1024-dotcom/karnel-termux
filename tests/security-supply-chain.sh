#!/usr/bin/env bash
# shellcheck disable=SC2329
set -euo pipefail

ROOT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
TEST_ROOT=$(mktemp -d)
trap 'rm -rf "$TEST_ROOT"' EXIT

if grep -REq 'raw\.githubusercontent\.com/.*/(main|master)/' "$ROOT_DIR/karnel/tools" --include='install.sh'; then
  printf 'mutable raw GitHub URL found in an installer\n' >&2
  exit 1
fi
grep -qF 'Bind package to release commit' "$ROOT_DIR/.github/workflows/release.yml"
grep -qF 'karnel/RELEASE_COMMIT' "$ROOT_DIR/.github/workflows/release.yml"
grep -qF 'steps.publication.outputs.npm_exists' "$ROOT_DIR/.github/workflows/release.yml"
grep -qF 'concurrency:' "$ROOT_DIR/.github/workflows/release.yml"
if grep -q -- '--clobber' "$ROOT_DIR/.github/workflows/release.yml"; then
  printf 'release workflow uses unsafe asset clobbering\n' >&2
  exit 1
fi
grep -q -- '--ref "v$version"' "$ROOT_DIR/README.md"

assert_source_contracts() {
  local mode asset
  if grep -qF 'https://cli.kiro.dev/install' "$ROOT_DIR/karnel/tools/ai/kiro/install.sh"; then
    return 1
  fi
  grep -qF 'package.get("sha256", "")' "$ROOT_DIR/karnel/tools/ai/kiro/install.sh"
  grep -qF 'OH_MY_ZSH_REF="b54a71977574cfcf659cc2f15a5e6422f17a8da7"' "$ROOT_DIR/karnel/modules/shell.sh"
  grep -qF 'mktemp -d' "$ROOT_DIR/karnel/modules/shell.sh"
  grep -qF 'actions/checkout@11bd71901bbe5b1630ceea73d27597364c9af683' "$ROOT_DIR/.github/workflows/ci.yml"
  grep -qF 'actions/setup-node@49933ea5288caeca8642d1e84afbd3f7d6820020' "$ROOT_DIR/.github/workflows/ci.yml"
  for asset in assets/images/karnel-2x.png assets/images/karnel-4x.png assets/images/karnel-logo.png karnel/tools/ai/gentle-ai/termux-patches.go; do
    mode=$(stat -c '%a' "$ROOT_DIR/$asset")
    # Non-executable mode (no execute bit anywhere). Accepts 644, 660, 664,
    # etc. so filesystems that cannot preserve exact modes (Android shared
    # storage, vfat) still pass the security intent.
    [[ "$mode" =~ ^[0246][0246][0246]$ ]]
  done
}

assert_supabase_rejects_bad_checksum() (
  export PREFIX="$TEST_ROOT/supabase-prefix"
  export TMPDIR="$TEST_ROOT/tmp"
  mkdir -p "$PREFIX/bin" "$TMPDIR"
  import() { :; }
  log_info() { :; }
  log_success() { :; }
  log_warn() { :; }
  log_error() { :; }
  loading() { shift; "$@"; }
  command() { [[ "$1" == -v && "$2" == supabase ]] && return 1; builtin command "$@"; }
  uname() { printf 'aarch64\n'; }
  curl() {
    local output="" previous="" arg
    for arg in "$@"; do
      [[ "$previous" == -o ]] && output="$arg"
      previous="$arg"
    done
    if [[ "$output" == *checksums.txt ]]; then
      printf '%064d  supabase_linux_arm64.tar.gz\n' 0 >"$output"
    else
      printf 'not the expected archive' >"$output"
    fi
  }
  source "$ROOT_DIR/karnel/tools/deploy/supabase/install.sh"
  if install_supabase; then
    printf 'FAIL: Supabase accepted a checksum mismatch\n' >&2
    return 1
  fi
  [[ ! -e "$PREFIX/bin/supabase" ]]
)

assert_supabase_tracks_binary_ownership() (
  export PREFIX="$TEST_ROOT/supabase-owned-prefix"
  export TMPDIR="$TEST_ROOT/owned-tmp"
  export HOME="$TEST_ROOT/home"
  mkdir -p "$PREFIX/bin" "$TMPDIR" "$HOME"
  import() { :; }
  log_info() { :; }
  log_success() { :; }
  log_warn() { :; }
  log_error() { :; }
  loading() { shift; "$@"; }
  command() { [[ "$1" == -v && "$2" == supabase ]] && return 1; builtin command "$@"; }
  uname() { printf 'aarch64\n'; }
  curl() {
    local output="" previous="" arg archive payload_dir
    for arg in "$@"; do
      [[ "$previous" == -o ]] && output="$arg"
      previous="$arg"
    done
    if [[ "$output" == *checksums.txt ]]; then
      archive="$(dirname "$output")/supabase_linux_arm64.tar.gz"
      printf '%s  supabase_linux_arm64.tar.gz\n' "$(sha256sum "$archive" | awk '{print $1}')" >"$output"
    else
      payload_dir="$TEST_ROOT/supabase-payload"
      mkdir -p "$payload_dir"
      printf '#!/usr/bin/env bash\nprintf "2.20.8\\n"\n' >"$payload_dir/supabase"
      chmod +x "$payload_dir/supabase"
      builtin command tar -czf "$output" -C "$payload_dir" supabase
    fi
  }
  source "$ROOT_DIR/karnel/tools/deploy/supabase/install.sh"
  install_supabase
  _supabase_is_owned
  mkdir -p "$HOME/.supabase"
  printf 'user configuration\n' >"$HOME/.supabase/config"
  uninstall_supabase
  grep -qF 'user configuration' "$HOME/.supabase/config"
  install_supabase
  printf 'user replacement\n' >"$PREFIX/bin/supabase"
  if uninstall_supabase; then
    printf 'FAIL: Supabase removed a user replacement\n' >&2
    return 1
  fi
  grep -qF 'user replacement' "$PREFIX/bin/supabase"
)

assert_package_checker_rejects_secrets() (
  local fixture forbidden
  fixture="$TEST_ROOT/package-fixture"
  mkdir -p "$fixture/assets/fonts" "$fixture/karnel/cli/commands" "$fixture/karnel/modules" "$fixture/karnel/tools/osint/robin"
  printf '{"name":"karnel-package-test","version":"1.0.0","files":["assets/","karnel/"]}\n' >"$fixture/package.json"
  printf 'font\n' >"$fixture/assets/fonts/font.ttf"
  for required in \
    karnel/cli/commands/robin.sh \
    karnel/modules/osint.sh \
    karnel/tools/osint/robin/common.sh \
    karnel/tools/osint/robin/install.sh \
    karnel/tools/osint/robin/README.md \
    karnel/tools/osint/robin/requirements-termux.txt; do
    printf 'fixture\n' >"$fixture/$required"
  done
  chmod 0644 "$fixture/assets/fonts/font.ttf" "$fixture/karnel/tools/osint/robin/README.md"
  mkdir -p "$fixture/karnel/tools/ai/gentle-ai"
  printf 'fixture\n' >"$fixture/karnel/tools/ai/gentle-ai/termux-patches.go"
  chmod 0644 "$fixture/karnel/tools/ai/gentle-ai/termux-patches.go"
  git -C "$fixture" init -q
  git -C "$fixture" -c user.name=Test -c user.email=test@example.invalid add .
  git -C "$fixture" -c user.name=Test -c user.email=test@example.invalid commit -qm fixture
  node "$ROOT_DIR/scripts/check-package.js" "$fixture" >/dev/null
  [[ ! -e "$fixture/karnel/RELEASE_COMMIT" ]]
  for forbidden in karnel/.env.production karnel/signing.key karnel/release-secret.txt; do
    printf 'secret\n' >"$fixture/$forbidden"
    if node "$ROOT_DIR/scripts/check-package.js" "$fixture" >/dev/null 2>&1; then
      printf 'FAIL: package checker accepted %s\n' "$forbidden" >&2
      return 1
    fi
    rm "$fixture/$forbidden"
  done
)

assert_source_contracts
assert_supabase_rejects_bad_checksum
assert_supabase_tracks_binary_ownership
assert_package_checker_rejects_secrets
printf 'Supply-chain security contracts: 4 passed\n'
