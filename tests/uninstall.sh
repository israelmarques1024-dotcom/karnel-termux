#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
TEST_ROOT=$(mktemp -d)
trap 'rm -rf "$TEST_ROOT"' EXIT

# shellcheck source=../karnel/utils/uninstall.sh
source "$ROOT_DIR/karnel/utils/uninstall.sh"

log_info() { :; }
log_warn() { :; }

read_confirm_default() {
  local _prompt="$1" _default="$2" var="$3"
  printf -v "$var" '%s' "${CONFIRM_ANSWER:-n}"
  [[ "${CONFIRM_ANSWER:-n}" == "y" ]]
}

# An unmanaged path must be preserved even when the user confirms removal.
CONFIRM_ANSWER=y
mkdir -p "$TEST_ROOT/unmanaged"
if confirm_remove_paths "test data" "$TEST_ROOT/unmanaged"; then
  printf 'FAIL: unmanaged path was removed\n' >&2
  exit 1
fi
test -d "$TEST_ROOT/unmanaged"

# KARNEL_FORCE overrides the ownership gate.
CONFIRM_ANSWER=y
if ! KARNEL_FORCE=1 confirm_remove_paths "test data" "$TEST_ROOT/unmanaged"; then
  printf 'FAIL: forced removal failed\n' >&2
  exit 1
fi
test ! -e "$TEST_ROOT/unmanaged"

# A Karnel-managed path (with a marker) is removed when confirmed.
CONFIRM_ANSWER=y
mkdir -p "$TEST_ROOT/managed"
: >"$TEST_ROOT/managed/.karnel-managed"
if ! confirm_remove_paths "test data" "$TEST_ROOT/managed"; then
  printf 'FAIL: managed path removal failed\n' >&2
  exit 1
fi
test ! -e "$TEST_ROOT/managed"

# A Karnel-managed path is preserved when declined.
CONFIRM_ANSWER=n
mkdir -p "$TEST_ROOT/managed2"
: >"$TEST_ROOT/managed2/.karnel-managed"
if confirm_remove_paths "test data" "$TEST_ROOT/managed2"; then
  printf 'FAIL: declined managed removal succeeded\n' >&2
  exit 1
fi
test -d "$TEST_ROOT/managed2"

test_shell_plugin_uninstall_decline() (
  import() { :; }
  loading() {
    printf 'FAIL: shell plugin uninstall used loading spinner\n' >&2
    return 1
  }
  progress_start() { :; }
  progress_update() { :; }
  progress_done() { :; }
  local -a info_messages=()
  log_info() { info_messages+=("$*"); }

  HOME="$TEST_ROOT/home"
  KARNEL_CACHE="$TEST_ROOT/cache"
  # shellcheck source=../karnel/tools/shell/all.sh
  source "$ROOT_DIR/karnel/tools/shell/all.sh"

  local -a plugin_dirs=(
    powerlevel10k zsh-defer zsh-autosuggestions zsh-syntax-highlighting
    zsh-history-substring-search zsh-completions fzf-tab zsh-you-should-use
    zsh-autopair zsh-better-npm-completion
  )
  local -a uninstall_functions=(
    uninstall_powerlevel10k uninstall_zsh_defer uninstall_zsh_autosuggestions
    uninstall_zsh_syntax_highlighting uninstall_history_substring
    uninstall_zsh_completions uninstall_fzf_tab uninstall_you_should_use
    uninstall_zsh_autopair uninstall_better_npm
  )
  local dir func

  for dir in "${plugin_dirs[@]}"; do
    mkdir -p "$ZSH_PLUGINS_DIR/$dir"
  done
  confirm_remove_paths() { return 2; }

  for func in "${uninstall_functions[@]}"; do
    "$func"
  done
  for dir in "${plugin_dirs[@]}"; do
    test -d "$ZSH_PLUGINS_DIR/$dir"
  done
  [[ "${#info_messages[@]}" -eq "${#plugin_dirs[@]}" ]]

  uninstall_all_shell_plugins
  for dir in "${plugin_dirs[@]}"; do
    test -d "$ZSH_PLUGINS_DIR/$dir"
  done
)

if ! test_shell_plugin_uninstall_decline; then
  exit 1
fi

test_module_uninstall_without_sentinel() (
  local module="$1" uninstall_function="$2"
  local called=0 rc=0

  import() { :; }
  separator() { :; }
  box() { :; }
  log_info() { :; }
  log_success() { :; }
  log_warn() { :; }
  _robin_print_disclaimer() { :; }
  command() {
    [[ "$1" == "-v" ]] && return 1
    builtin command "$@"
  }

  HOME="$TEST_ROOT/home"
  KARNEL_CACHE="$TEST_ROOT/cache"
  KARNEL_TOOLS="$TEST_ROOT/tools"
  KARNEL_PATH="$TEST_ROOT/karnel"
  source "$ROOT_DIR/karnel/modules/$module.sh"

  case "$module" in
    ai) _uninstall_ai_tools_wrapper() { called=1; return 3; } ;;
    auto) _uninstall_auto_wrapper() { called=1; return 3; } ;;
    db) _uninstall_db_tools_wrapper() { called=1; return 3; } ;;
    dev) _uninstall_dev_wrapper() { called=1; return 3; } ;;
    editor) _uninstall_editor_wrapper() { called=1; return 3; } ;;
    lang) _uninstall_lang_wrapper() { called=1; return 3; } ;;
    npm) _uninstall_npm_wrapper() { called=1; return 3; } ;;
    osint) _uninstall_osint_wrapper() { called=1; return 3; } ;;
    ui) _uninstall_ui_wrapper() { called=1; return 3; } ;;
    deploy|games|network|utils)
      import() {
        called=1
        case "$1" in
          @/tools/deploy/all) uninstall_all_deploy_tools() { return 3; } ;;
          @/tools/games/all) uninstall_all_games() { return 3; } ;;
          @/tools/network/all) uninstall_all_network() { return 3; } ;;
          @/tools/utils/all) uninstall_all_utils() { return 3; } ;;
        esac
      }
      ;;
  esac

  if "$uninstall_function"; then
    printf 'FAIL: %s uninstall hid a workflow failure\n' "$module" >&2
    return 1
  else
    rc=$?
  fi
  [[ "$called" -eq 1 && "$rc" -eq 3 ]]
)

for module in ai auto db deploy dev editor games lang network npm osint ui utils; do
  if ! test_module_uninstall_without_sentinel "$module" "uninstall_$module"; then
    exit 1
  fi
done

test_shell_uninstall_without_sentinel() (
  local called=0 rc=0

  import() { :; }
  separator() { :; }
  box() { :; }
  log_info() { :; }
  log_success() { :; }
  log_warn() { :; }
  command() {
    [[ "$1" == "-v" ]] && return 1
    builtin command "$@"
  }

  HOME="$TEST_ROOT/home"
  KARNEL_CACHE="$TEST_ROOT/cache"
  source "$ROOT_DIR/karnel/modules/shell.sh"
  _uninstall_shell_plugins_wrapper() { called=1; return 2; }
  uninstall_oh_my_zsh() { return 1; }

  if uninstall_shell; then
    printf 'FAIL: shell uninstall hid a workflow failure\n' >&2
    return 1
  else
    rc=$?
  fi
  [[ "$called" -eq 1 && "$rc" -eq 3 ]]
)

if ! test_shell_uninstall_without_sentinel; then
  exit 1
fi

printf 'Uninstall contracts: 18 passed\n'
