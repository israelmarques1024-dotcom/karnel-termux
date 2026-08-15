#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
TEST_ROOT=$(mktemp -d)
trap 'rm -rf "$TEST_ROOT"' EXIT

export KARNEL_CACHE="$TEST_ROOT/cache"
export LOG_FILE="$KARNEL_CACHE/pinned-git.log"
mkdir -p "$KARNEL_CACHE"
log_error() { printf '%s\n' "$*" >>"$LOG_FILE"; }
source "$ROOT_DIR/karnel/utils/install.sh"

assert_static_contracts() {
  local file
  local files=(
    karnel/tools/shell/powerlevel10k/install.sh
    karnel/tools/shell/zsh-defer/install.sh
    karnel/tools/shell/zsh-autosuggestions/install.sh
    karnel/tools/shell/zsh-syntax-highlighting/install.sh
    karnel/tools/shell/history-substring/install.sh
    karnel/tools/shell/zsh-completions/install.sh
    karnel/tools/shell/fzf-tab/install.sh
    karnel/tools/shell/you-should-use/install.sh
    karnel/tools/shell/zsh-autopair/install.sh
    karnel/tools/shell/better-npm/install.sh
    karnel/tools/ai/hermes-agent/install.sh
    karnel/tools/ai/gga/install.sh
    karnel/tools/ai/engram/install.sh
    karnel/tools/ai/gentle-ai/install.sh
    karnel/tools/ai/odysseus/install.sh
    karnel/tools/editor/nvchad/install.sh
    karnel/tools/security/whatweb/install.sh
    karnel/tools/security/sqlmap/install.sh
    karnel/tools/security/nikto/install.sh
    karnel/tools/security/theharvester/install.sh
    karnel/tools/security/enum4linux/install.sh
    karnel/tools/security/dnsrecon/install.sh
    karnel/tools/security/masscan/install.sh
    karnel/tools/security/metasploit/install.sh
  )

  for file in "${files[@]}"; do
    grep -Eq 'COMMIT="[0-9a-f]{40}"' "$ROOT_DIR/$file"
    grep -qF 'install_pinned_git_repo' "$ROOT_DIR/$file"
    if grep -Eq 'git[[:space:]]+(clone|pull)' "$ROOT_DIR/$file"; then
      printf 'mutable Git operation remains in %s\n' "$file" >&2
      return 1
    fi
  done
  grep -qF 'fetch --quiet --depth=1 origin "$commit"' "$ROOT_DIR/karnel/utils/install.sh"
  grep -qF 'rev-parse HEAD' "$ROOT_DIR/karnel/utils/install.sh"
}

assert_pinned_install_and_update() {
  local source="$TEST_ROOT/source" destination="$TEST_ROOT/managed/repo"
  local first second before
  mkdir -p "$source"
  git init --quiet "$source"
  git -C "$source" config user.name test
  git -C "$source" config user.email test@example.invalid
  printf 'first\n' >"$source/value"
  git -C "$source" add value
  git -C "$source" commit --quiet -m first
  first=$(git -C "$source" rev-parse HEAD)

  install_pinned_git_repo "file://$source" "$first" "$destination"
  [[ "$(git -C "$destination" rev-parse HEAD)" == "$first" ]]
  [[ "$(git -C "$destination" rev-parse --is-shallow-repository)" == true ]]

  printf 'second\n' >"$source/value"
  git -C "$source" add value
  git -C "$source" commit --quiet -m second
  second=$(git -C "$source" rev-parse HEAD)
  install_pinned_git_repo "file://$source" "$second" "$destination"
  [[ "$(git -C "$destination" rev-parse HEAD)" == "$second" ]]
  [[ "$(<"$destination/value")" == second ]]

  before=$(git -C "$destination" rev-parse HEAD)
  if install_pinned_git_repo "file://$source" "0000000000000000000000000000000000000000" "$destination"; then
    printf 'nonexistent pin unexpectedly installed\n' >&2
    return 1
  fi
  [[ "$(git -C "$destination" rev-parse HEAD)" == "$before" ]]
}

assert_unowned_destination_is_preserved() {
  local source="$TEST_ROOT/source" destination="$TEST_ROOT/unowned" commit
  mkdir -p "$destination"
  printf 'user data\n' >"$destination/value"
  commit=$(git -C "$source" rev-parse HEAD)
  if install_pinned_git_repo "file://$source" "$commit" "$destination"; then
    printf 'unowned destination unexpectedly replaced\n' >&2
    return 1
  fi
  [[ "$(<"$destination/value")" == 'user data' ]]
}

assert_static_contracts
assert_pinned_install_and_update
assert_unowned_destination_is_preserved
printf 'Pinned Git repository contracts: 3 passed\n'
