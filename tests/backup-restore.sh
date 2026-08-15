#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
TEST_ROOT=$(mktemp -d)
MAIN_BASHPID=$BASHPID
trap '[[ $BASHPID != $MAIN_BASHPID ]] || rm -rf "$TEST_ROOT"' EXIT
PASSED=0

setup_commands() {
  import() { :; }
  box() { :; }
  separator_section() { :; }
  log_info() { :; }
  log_warn() { :; }
  log_error() { :; }
  log_success() { :; }
  termux-reload-settings() { :; }
  loading() { shift; "$@"; }
  dpkg() {
    if [[ ${1:-} == "--get-selections" ]]; then
      printf 'bash\tinstall\n'
    else
      command cat >/dev/null
    fi
  }
  apt-get() { :; }
  read_confirm() { printf -v "$2" y; }
}

setup_environment() {
  local root="$1"
  export HOME="$root/home"
  export PREFIX="$root/prefix"
  export KARNEL_PATH="$root/karnel"
  export KARNEL_DATA="$root/data"
  export KARNEL_CACHE="$root/cache"
  export ROBIN_CONFIG_DIR="$HOME/.config/karnel/robin"
  mkdir -p "$HOME/.ssh" "$HOME/.config/app" "$PREFIX/etc/apt" "$KARNEL_DATA" "$KARNEL_CACHE" \
    "$KARNEL_PATH/tools/demo/tool" "$KARNEL_PATH/bin"
  printf '#!/usr/bin/env bash\n' >"$KARNEL_PATH/tools/demo/tool/install.sh"
  printf '#!/usr/bin/env bash\n' >"$KARNEL_PATH/bin/karnel"
}

load_commands() {
  source "$ROOT_DIR/karnel/utils/backup.sh"
  source "$ROOT_DIR/karnel/cli/commands/backup.sh"
  source "$ROOT_DIR/karnel/cli/commands/restore.sh"
}

new_archive() {
  backup_run false >/dev/null
  _backup_latest "$BACKUP_DIR" 'termux-*.tar.gz'
}

assert_checksum_and_archive_validation() (
  local root="$TEST_ROOT/validation"
  mkdir -p "$root/safe/metadata"
  source "$ROOT_DIR/karnel/utils/backup.sh"
  printf 'pkg install\n' >"$root/safe/metadata/packages.list"
  tar -czf "$root/safe.tar.gz" -C "$root/safe" .
  sha256sum "$root/safe.tar.gz" >"$root/safe.tar.gz.sha256"
  _backup_verify_checksum "$root/safe.tar.gz"
  _backup_archive_safe "$root/safe.tar.gz"
  printf 'bad\n' >"$root/safe.tar.gz.sha256"
  if _backup_verify_checksum "$root/safe.tar.gz"; then return 1; fi
)

assert_backup_and_snapshot_filter_secrets() (
  local root="$TEST_ROOT/filter"
  setup_commands
  setup_environment "$root"
  export OPENAI_API_KEY=must-not-be-backed-up
  printf 'shell\n' >"$HOME/.bashrc"
  printf 'private-key-must-not-be-backed-up\n' >"$HOME/.ssh/id_test"
  printf 'ssh-ed25519 public\n' >"$HOME/.ssh/id_test.pub"
  printf 'env-secret-must-not-be-backed-up\n' >"$HOME/.config/app/.env.local"
  printf 'credential-must-not-be-backed-up\n' >"$HOME/.config/app/credentials.json"
  printf 'safe\n' >"$HOME/.config/app/settings"
  load_commands

  backup_run false >/dev/null
  backup_snapshot safe-name >/dev/null
  local archive contents listing count=0
  for archive in "$BACKUP_DIR"/*.tar.gz; do
    contents=$(tar -xOzf "$archive" 2>/dev/null)
    listing=$(tar -tzf "$archive")
    [[ "$contents" != *must-not-be-backed-up* ]]
    [[ "$listing" == *'./metadata/packages.list'* ]]
    [[ "$listing" == *'./metadata/tool-catalog.list'* ]]
    [[ "$listing" == *'./config/ssh/id_test.pub'* ]]
    [[ "$listing" == *'./config/config/app/settings'* ]]
    _backup_verify_checksum "$archive"
    ((count += 1))
  done
  [[ $count -eq 2 ]]
)

assert_invalid_snapshot_name_and_collection_failure() (
  local root="$TEST_ROOT/failure"
  setup_commands
  setup_environment "$root"
  printf 'shell\n' >"$HOME/.bashrc"
  load_commands
  if backup_snapshot '../escape' >/dev/null; then return 1; fi
  [[ ! -e "$KARNEL_DATA/escape.tar.gz" ]]

  cp() { return 1; }
  if backup_run false >/dev/null; then return 1; fi
  ! compgen -G "$BACKUP_DIR/*.tar.gz" >/dev/null
)

assert_backup_rejects_symlink_source_ancestors() (
  local root="$TEST_ROOT/source-symlink" outside="$TEST_ROOT/source-symlink-outside"
  setup_commands
  setup_environment "$root"
  mkdir -p "$outside/app"
  printf 'must-not-be-read\n' >"$outside/app/settings"
  rmdir "$HOME/.config/app" "$HOME/.config"
  ln -s "$outside" "$HOME/.config"
  load_commands

  if backup_run false >/dev/null; then return 1; fi
  ! compgen -G "$BACKUP_DIR/*.tar.gz" >/dev/null
)

assert_concurrent_backups_get_distinct_names() (
  local root="$TEST_ROOT/concurrent"
  setup_commands
  setup_environment "$root"
  load_commands
  date() {
    if [[ ${1:-} == '+%Y%m%d_%H%M%S' ]]; then
      printf '20260101_010101\n'
    else
      command date "$@"
    fi
  }
  printf 'existing-backup\n' >"$BACKUP_DIR/termux-20260101_010101.tar.gz"
  printf 'existing-checksum\n' >"$BACKUP_DIR/termux-20260101_010101.tar.gz.sha256"
  backup_run false >/dev/null & local first=$!
  backup_run false >/dev/null & local second=$!
  wait "$first"
  wait "$second"
  local archives=("$BACKUP_DIR"/termux-20260101_010101*.tar.gz)
  [[ ${#archives[@]} -eq 3 ]]
  grep -qFx existing-backup "$BACKUP_DIR/termux-20260101_010101.tar.gz"
  local archive verified=0
  for archive in "${archives[@]}"; do
    [[ "$archive" == "$BACKUP_DIR/termux-20260101_010101.tar.gz" ]] && continue
    _backup_verify_checksum "$archive"
    ((verified += 1))
  done
  [[ $verified -eq 2 ]]
)

assert_restore_merges_and_restores_dotfiles() (
  local root="$TEST_ROOT/restore"
  setup_commands
  setup_environment "$root"
  printf 'from-backup\n' >"$HOME/.bashrc"
  printf 'archived-setting\n' >"$HOME/.config/app/settings"
  load_commands
  local archive
  archive=$(new_archive)
  printf 'current\n' >"$HOME/.bashrc"
  printf 'external-data\n' >"$HOME/.config/app/external"

  restore_main "$archive" >/dev/null
  grep -qFx from-backup "$HOME/.bashrc"
  grep -qFx archived-setting "$HOME/.config/app/settings"
  grep -qFx external-data "$HOME/.config/app/external"
  ! compgen -G "$HOME/.karnel-restore.*" >/dev/null
)

assert_restore_copy_failure_changes_nothing() (
  local root="$TEST_ROOT/copy-rollback"
  setup_commands
  setup_environment "$root"
  printf 'from-backup\n' >"$HOME/.bashrc"
  printf 'archived\n' >"$HOME/.config/app/settings"
  load_commands
  local archive
  archive=$(new_archive)
  printf 'current\n' >"$HOME/.bashrc"
  printf 'external\n' >"$HOME/.config/app/external"
  cp() {
    local argument
    for argument in "$@"; do
      [[ "$argument" == */config/config/app/. ]] && return 1
    done
    command cp "$@"
  }

  if restore_main "$archive" >/dev/null; then return 1; fi
  grep -qFx current "$HOME/.bashrc"
  grep -qFx external "$HOME/.config/app/external"
)

assert_restore_move_failure_rolls_back() (
  local root="$TEST_ROOT/move-rollback"
  setup_commands
  setup_environment "$root"
  printf 'from-backup\n' >"$HOME/.bashrc"
  printf 'archived\n' >"$HOME/.config/app/settings"
  load_commands
  local archive
  archive=$(new_archive)
  printf 'current\n' >"$HOME/.bashrc"
  printf 'external\n' >"$HOME/.config/app/settings"
  mv() {
    local argument destination=${!#}
    if [[ "$destination" == "$HOME/.config/app" ]]; then
      for argument in "$@"; do
        [[ "$argument" == */staged/* ]] && return 1
      done
    fi
    command mv "$@"
  }

  if restore_main "$archive" >/dev/null; then return 1; fi
  grep -qFx current "$HOME/.bashrc"
  grep -qFx external "$HOME/.config/app/settings"
)

assert_restore_rejects_symlink_destination_ancestors() (
  local root="$TEST_ROOT/destination-symlink" outside="$TEST_ROOT/destination-outside"
  setup_commands
  setup_environment "$root"
  printf 'archived\n' >"$HOME/.config/app/settings"
  load_commands
  local archive
  archive=$(new_archive)
  rm -rf "$HOME/.config"
  mkdir -p "$outside/app"
  printf 'outside\n' >"$outside/app/settings"
  ln -s "$outside" "$HOME/.config"

  if restore_main "$archive" >/dev/null; then return 1; fi
  grep -qFx outside "$outside/app/settings"
)

assert_restore_revalidates_destination_before_commit() (
  local root="$TEST_ROOT/revalidate" outside="$TEST_ROOT/revalidate-outside"
  setup_commands
  setup_environment "$root"
  source "$ROOT_DIR/karnel/utils/backup.sh"
  local source="$root/source" transaction="$root/transaction"
  mkdir -p "$source" "$transaction" "$outside"
  printf 'archived\n' >"$source/settings"
  _backup_restore_reset
  _backup_restore_prepare "$source" "$HOME/.config/app" "$transaction"
  rm -rf "$HOME/.config"
  ln -s "$outside" "$HOME/.config"

  if _backup_restore_commit; then return 1; fi
  [[ ! -e "$outside/app" ]]
)

assert_package_failure_keeps_committed_configuration() (
  local root="$TEST_ROOT/package-failure"
  setup_commands
  setup_environment "$root"
  printf 'archived\n' >"$HOME/.bashrc"
  load_commands
  local archive
  archive=$(new_archive)
  printf 'current\n' >"$HOME/.bashrc"
  apt-get() { return 1; }

  if restore_main "$archive" >/dev/null; then return 1; fi
  grep -qFx archived "$HOME/.bashrc"
  ! compgen -G "$HOME/.karnel-restore.*" >/dev/null
)

assert_cron_uses_executable_and_replaces_bad_entry() (
  local root="$TEST_ROOT/cron" cron_file="$TEST_ROOT/cron/installed"
  setup_commands
  setup_environment "$root"
  load_commands
  # shellcheck disable=SC2030 # intentionally scoped to this test subshell
  local KARNEL_BIN="$ROOT_DIR/karnel/bin"
  crontab() {
    if [[ ${1:-} == -l ]]; then
      printf '0 3 * * * %s backup\n' "$KARNEL_BIN"
    else
      command cat >"$cron_file"
    fi
  }
  backup_cron >/dev/null
  grep -qF "$ROOT_DIR/karnel/bin/karnel backup" "$cron_file"
  if grep -qF "$ROOT_DIR/karnel/bin backup" "$cron_file"; then return 1; fi
)

assert_backup_restore_delegates() (
  local root="$TEST_ROOT/delegation" called=""
  setup_commands
  setup_environment "$root"
  source "$ROOT_DIR/karnel/utils/backup.sh"
  source "$ROOT_DIR/karnel/cli/commands/backup.sh"
  restore_main() { called="$*"; }
  backup_main restore one.tar.gz
  [[ "$called" == one.tar.gz ]]
)

tests=(
  assert_checksum_and_archive_validation
  assert_backup_and_snapshot_filter_secrets
  assert_invalid_snapshot_name_and_collection_failure
  assert_backup_rejects_symlink_source_ancestors
  assert_concurrent_backups_get_distinct_names
  assert_restore_merges_and_restores_dotfiles
  assert_restore_copy_failure_changes_nothing
  assert_restore_move_failure_rolls_back
  assert_restore_rejects_symlink_destination_ancestors
  assert_restore_revalidates_destination_before_commit
  assert_package_failure_keeps_committed_configuration
  assert_cron_uses_executable_and_replaces_bad_entry
  assert_backup_restore_delegates
)

for test_name in "${tests[@]}"; do
  printf '  %s\n' "$test_name"
  "$test_name"
  ((PASSED += 1))
done
printf 'Backup/restore regression contracts: %d passed\n' "$PASSED"
