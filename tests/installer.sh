#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
TEST_ROOT=$(mktemp -d)
trap 'rm -rf "$TEST_ROOT"' EXIT

ORIGIN="$TEST_ROOT/origin"
mkdir -p "$ORIGIN/karnel/bin" "$ORIGIN/scripts"
git -C "$ORIGIN" init -q
printf '#!/usr/bin/env bash\nprintf "v1\\n"\n' >"$ORIGIN/karnel/bin/karnel"
printf 'complete v1\n' >"$ORIGIN/scripts/completion.bash"
printf 'complete v1\n' >"$ORIGIN/scripts/completion.zsh"
chmod +x "$ORIGIN/karnel/bin/karnel"
git -C "$ORIGIN" add .
git -C "$ORIGIN" -c user.name=Test -c user.email=test@example.invalid commit -qm v1
V1_COMMIT=$(git -C "$ORIGIN" rev-parse HEAD)
git -C "$ORIGIN" tag v4.14.0

printf '#!/usr/bin/env bash\nprintf "v2\\n"\n' >"$ORIGIN/karnel/bin/karnel"
git -C "$ORIGIN" add .
git -C "$ORIGIN" -c user.name=Test -c user.email=test@example.invalid commit -qm v2
SECOND_COMMIT=$(git -C "$ORIGIN" rev-parse HEAD)
git -C "$ORIGIN" tag v4.14.1

prepare_installer() {
  # shellcheck source=../install.sh
  source "$ROOT_DIR/install.sh"
  progress_bar() { :; }
  log_step() { :; }
  log_ok() { :; }
  log_fail() { :; }
  log_info() { :; }
  INSTALL_SCRIPT_DIR="$TEST_ROOT/not-a-checkout"
  REPO="$ORIGIN"
  mkdir -p "$INSTALL_SCRIPT_DIR"
}

assert_release_installs_from_staging() (
  prepare_installer
  KARNEL_REPO="$TEST_ROOT/release-repo"
  PREFIX="$TEST_ROOT/release-prefix"
  BRANCH=v4.14.0
  RELEASE_REF=$BRANCH
  RELEASE_COMMIT=$V1_COMMIT
  mkdir -p "$PREFIX/bin" "$PREFIX/share/zsh/site-functions"
  local source_hash
  source_hash=$(sha256sum "$ORIGIN/karnel/bin/karnel")

  clone_repo
  create_symlink
  _finish_install

  [[ "$(git -C "$KARNEL_REPO" rev-parse HEAD)" == "$V1_COMMIT" ]]
  [[ -z "$(git -C "$KARNEL_REPO" status --porcelain --untracked-files=all)" ]]
  [[ "$(readlink "$PREFIX/bin/karnel")" == "$KARNEL_REPO/karnel/bin/karnel" ]]
  [[ "$(sha256sum "$ORIGIN/karnel/bin/karnel")" == "$source_hash" ]]
  ! compgen -G "$TEST_ROOT/.karnel-staging.*" >/dev/null
)

assert_dirty_release_is_preserved() (
  prepare_installer
  KARNEL_REPO="$TEST_ROOT/dirty-repo"
  PREFIX="$TEST_ROOT/dirty-prefix"
  BRANCH=v4.14.1
  RELEASE_REF=$BRANCH
  RELEASE_COMMIT=$SECOND_COMMIT
  git -c advice.detachedHead=false clone -q --branch v4.14.0 "$ORIGIN" "$KARNEL_REPO"
  printf 'local change\n' >>"$KARNEL_REPO/karnel/bin/karnel"

  if clone_repo; then
    return 1
  fi
  grep -qF 'local change' "$KARNEL_REPO/karnel/bin/karnel"
  [[ "$(git -C "$KARNEL_REPO" rev-parse HEAD)" == "$(git -C "$ORIGIN" rev-list -n 1 v4.14.0)" ]]
)

assert_preexisting_directory_is_preserved() (
  prepare_installer
  KARNEL_REPO="$TEST_ROOT/preexisting"
  PREFIX="$TEST_ROOT/preexisting-prefix"
  mkdir -p "$KARNEL_REPO"
  printf 'user data\n' >"$KARNEL_REPO/keep"

  if clone_repo; then
    return 1
  fi
  [[ "$(<"$KARNEL_REPO/keep")" == 'user data' ]]
)

assert_mismatched_release_is_not_activated() (
  prepare_installer
  KARNEL_REPO="$TEST_ROOT/mismatch-repo"
  PREFIX="$TEST_ROOT/mismatch-prefix"
  BRANCH=v4.14.0
  RELEASE_REF=$BRANCH
  RELEASE_COMMIT=0123456789abcdef0123456789abcdef01234567

  if clone_repo; then
    return 1
  fi
  [[ ! -e "$KARNEL_REPO" ]]
)

assert_failure_rolls_back_repo_and_symlink() {
  local repo="$TEST_ROOT/rollback-repo"
  local prefix="$TEST_ROOT/rollback-prefix"
  local old_target="$TEST_ROOT/original-karnel"
  git -c advice.detachedHead=false clone -q --branch v4.14.0 "$ORIGIN" "$repo"
  mkdir -p "$prefix/bin" "$prefix/share/zsh/site-functions"
  printf '#!/usr/bin/env bash\n' >"$old_target"
  ln -s "$old_target" "$prefix/bin/karnel"

  if (
    prepare_installer
    KARNEL_REPO="$repo"
    PREFIX="$prefix"
    BRANCH=v4.14.1
    RELEASE_REF=$BRANCH
    RELEASE_COMMIT=$SECOND_COMMIT
    clone_repo
    create_symlink
    _cleanup_failed
  ) >/dev/null 2>&1; then
    return 1
  fi
  [[ "$(git -C "$repo" rev-parse HEAD)" == "$V1_COMMIT" ]]
  [[ "$(readlink "$prefix/bin/karnel")" == "$old_target" ]]
}

assert_bootstrap_stops_on_dependency_failure() (
  source "$ROOT_DIR/install.sh"
  command() {
    if [[ "$1" == "-v" && "$2" == "git" ]]; then return 1; fi
    builtin command "$@"
  }
  pkg() { return 1; }
  if bootstrap_dependencies; then return 1; fi
)

assert_release_installs_from_staging
assert_dirty_release_is_preserved
assert_preexisting_directory_is_preserved
assert_mismatched_release_is_not_activated
assert_failure_rolls_back_repo_and_symlink
assert_bootstrap_stops_on_dependency_failure

if bash "$ROOT_DIR/install.sh" --ref main >/dev/null 2>&1; then
  printf 'FAIL: mutable release ref was accepted\n' >&2
  exit 1
fi

printf 'Installer contracts: 7 passed\n'
