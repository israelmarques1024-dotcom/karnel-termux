#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
TEST_ROOT=$(mktemp -d)
trap 'rm -rf "$TEST_ROOT"' EXIT

assert_font_uninstall_preserves_custom_font() (
  export HOME="$TEST_ROOT/font-home"
  export KARNEL_CACHE="$TEST_ROOT/font-cache"
  export KARNEL_PATH="$TEST_ROOT/karnel"
  mkdir -p "$HOME/.termux" "$KARNEL_CACHE" "$TEST_ROOT/assets/fonts"
  printf 'karnel font' >"$TEST_ROOT/assets/fonts/font.ttf"
  printf 'custom font' >"$HOME/.termux/font.ttf"
  import() { :; }
  log_info() { :; }
  log_success() { :; }
  log_warn() { :; }
  loading() { "$2"; }
  # shellcheck source=../karnel/tools/ui/font/install.sh
  source "$ROOT_DIR/karnel/tools/ui/font/install.sh"

  install_font
  [[ "$(<"$HOME/.termux/font.ttf")" == "custom font" ]]
  uninstall_font
  [[ "$(<"$HOME/.termux/font.ttf")" == "custom font" ]]
  cp "$TEST_ROOT/assets/fonts/font.ttf" "$HOME/.termux/font.ttf"
  uninstall_font
  [[ ! -e "$HOME/.termux/font.ttf" ]]
)

assert_ui_and_editor_status_are_karnel_owned() (
  export HOME="$TEST_ROOT/status-home"
  export KARNEL_DATA="$TEST_ROOT/status-data"
  export KARNEL_PATH="$TEST_ROOT/karnel"
  mkdir -p "$HOME/.termux" "$HOME/.config/nvim" "$KARNEL_DATA" "$TEST_ROOT/assets/fonts"
  printf 'karnel font' >"$TEST_ROOT/assets/fonts/font.ttf"
  printf 'custom font' >"$HOME/.termux/font.ttf"
  printf 'cursor=#123456\n' >"$HOME/.termux/colors.properties"
  import() { :; }
  D_GREEN='' D_RED='' NC=''
  # shellcheck source=../karnel/cli/commands/list.sh
  source "$ROOT_DIR/karnel/cli/commands/list.sh"

  [[ "$(_check_font)" == 'not installed' ]]
  [[ "$(_check_cursor)" == 'not installed' ]]
  [[ "$(_check_nvchad)" == 'not installed' ]]
  cp "$TEST_ROOT/assets/fonts/font.ttf" "$HOME/.termux/font.ttf"
  printf '\n# Karnel cursor begin\ncursor=#00FF00\n# Karnel cursor end\n' >>"$HOME/.termux/colors.properties"
  mkdir -p "$KARNEL_DATA/nvchad-termux/.git"
  [[ "$(_check_font)" == installed ]]
  [[ "$(_check_cursor)" == installed ]]
  [[ "$(_check_nvchad)" == installed ]]
)

assert_ui_uninstall_preserves_malformed_blocks() (
  export HOME="$TEST_ROOT/ui-home"
  export KARNEL_CACHE="$TEST_ROOT/ui-cache"
  mkdir -p "$HOME/.termux" "$KARNEL_CACHE"
  import() { :; }
  log_info() { :; }
  log_success() { :; }
  log_warn() { :; }
  loading() { "$2"; }
  source "$ROOT_DIR/karnel/utils/uninstall.sh"
  source "$ROOT_DIR/karnel/tools/ui/cursor/install.sh"
  source "$ROOT_DIR/karnel/tools/ui/extra-keys/install.sh"

  printf '%s\nuser setting' "$CURSOR_BEGIN" >"$HOME/.termux/colors.properties"
  uninstall_cursor
  grep -qF 'user setting' "$HOME/.termux/colors.properties"
  printf '%s\nuser setting' "$EXTRA_KEYS_BEGIN" >"$HOME/.termux/termux.properties"
  uninstall_extra_keys
  grep -qF 'user setting' "$HOME/.termux/termux.properties"
)

assert_kiro_install_rejects_unusable_binary() (
  export PREFIX="$TEST_ROOT/kiro-prefix"
  export KARNEL_CACHE="$TEST_ROOT/kiro-cache"
  export PATH="$PREFIX/bin:$PATH"
  mkdir -p "$PREFIX/bin" "$KARNEL_CACHE"
  import() { :; }
  log_info() { :; }
  log_success() { :; }
  log_warn() { :; }
  log_error() { :; }
  D_CYAN=""
  NC=""
  curl() {
    if [[ "$*" == *manifest.json* ]]; then
      printf '%s' '{"packages":[{"architecture":"aarch64","os":"linux","fileType":"tar","download":"kiro.tar.gz"}]}'
    elif [[ "$*" == *' -o '* ]]; then
      return 0
    else
      return 1
    fi
  }
  tar() {
    printf '#!/usr/bin/env bash\nexit 127\n' >"$4/kiro-cli"
    chmod +x "$4/kiro-cli"
  }
  pkg() { return 0; }
  # shellcheck source=../karnel/tools/ai/kiro/install.sh
  source "$ROOT_DIR/karnel/tools/ai/kiro/install.sh"

  if install_kiro; then
    printf 'FAIL: Kiro installer accepted an unusable binary\n' >&2
    return 1
  fi
)

assert_code_server_install_preserves_configuration() (
  export HOME="$TEST_ROOT/code-server-home"
  export PREFIX="$TEST_ROOT/code-server-prefix"
  export PATH="$PREFIX/bin:$PATH"
  mkdir -p "$HOME/.config/code-server" "$PREFIX/bin"
  printf 'password: existing-secret\n' >"$HOME/.config/code-server/config.yaml"
  import() { :; }
  log_info() { :; }
  log_success() { :; }
  log_error() { :; }
  pkg() {
    if [[ "$1" == "install" && "$3" == "code-server" ]]; then
      printf '#!/usr/bin/env bash\nexit 0\n' >"$PREFIX/bin/code-server"
      chmod +x "$PREFIX/bin/code-server"
    fi
  }
  # shellcheck source=../karnel/tools/editor/code-server/install.sh
  source "$ROOT_DIR/karnel/tools/editor/code-server/install.sh"

  install_code_server
  [[ "$(<"$HOME/.config/code-server/config.yaml")" == "password: existing-secret" ]]
)

assert_zork_update_preserves_existing_data_on_download_failure() (
  export HOME="$TEST_ROOT/zork-home"
  export PREFIX="$TEST_ROOT/zork-prefix"
  export KARNEL_CACHE="$TEST_ROOT/zork-cache"
  mkdir -p "$HOME/.local/share/karnel-data/zork/DATA" "$PREFIX/bin" "$KARNEL_CACHE"
  printf 'existing zork data' >"$HOME/.local/share/karnel-data/zork/DATA/ZORK1.DAT"
  import() { :; }
  log_info() { :; }
  log_error() { :; }
  loading() { "$2"; }
  curl() { return 1; }
  # shellcheck source=../karnel/tools/utils/zork/install.sh
  source "$ROOT_DIR/karnel/tools/utils/zork/install.sh"

  if update_zork; then
    return 1
  fi
  [[ "$(<"$ZORK_DATA_DIR/DATA/ZORK1.DAT")" == 'existing zork data' ]]
)

assert_zork_preserves_unowned_install() (
  export HOME="$TEST_ROOT/zork-owned-home"
  export PREFIX="$TEST_ROOT/zork-owned-prefix"
  export KARNEL_CACHE="$TEST_ROOT/zork-owned-cache"
  mkdir -p "$HOME/.local/share/karnel-data/zork/DATA" "$PREFIX/bin" "$KARNEL_CACHE"
  printf 'external zork data' >"$HOME/.local/share/karnel-data/zork/DATA/ZORK1.DAT"
  printf '#!/usr/bin/env bash\nexit 99\n' >"$PREFIX/bin/zork"
  chmod +x "$PREFIX/bin/zork"
  import() { :; }
  log_info() { :; }
  log_error() { :; }
  log_success() { :; }
  loading() { "$2"; }
  source "$ROOT_DIR/karnel/tools/utils/zork/install.sh"

  uninstall_zork || [[ $? -eq 2 ]]
  grep -qF 'exit 99' "$PREFIX/bin/zork"
  update_zork || [[ $? -eq 1 ]]
  [[ "$(<"$ZORK_DATA_DIR/DATA/ZORK1.DAT")" == 'external zork data' ]]
)

assert_goose_update_preserves_existing_binary_on_download_failure() (
  export HOME="$TEST_ROOT/goose-home"
  export PREFIX="$TEST_ROOT/goose-prefix"
  export KARNEL_CACHE="$TEST_ROOT/goose-cache"
  mkdir -p "$HOME/.local/share/karnel-data/goose" "$PREFIX/bin" "$KARNEL_CACHE"
  printf 'existing goose data' >"$HOME/.local/share/karnel-data/goose/marker"
  printf '#!/usr/bin/env bash\n' >"$PREFIX/bin/goose"
  chmod +x "$PREFIX/bin/goose"
  import() { :; }
  log_error() { :; }
  curl() { return 1; }
  # shellcheck source=../karnel/tools/ai/goose/install.sh
  source "$ROOT_DIR/karnel/tools/ai/goose/install.sh"

  if _goose_download_binary_impl force; then
    return 1
  fi
  [[ "$(<"$GOOSE_DATA_DIR/marker")" == 'existing goose data' ]]
  [[ -x "$GOOSE_BIN_PATH" ]]
)

assert_omp_native_update_preserves_existing_install_on_download_failure() (
  export HOME="$TEST_ROOT/omp-home"
  export PREFIX="$TEST_ROOT/omp-prefix"
  export KARNEL_CACHE="$TEST_ROOT/omp-cache"
  export KARNEL_PATH="$ROOT_DIR/karnel"
  mkdir -p "$HOME/.local/share/karnel-data/oh-my-pi" "$PREFIX/bin" "$KARNEL_CACHE"
  printf 'existing omp data' >"$HOME/.local/share/karnel-data/oh-my-pi/marker"
  printf '#!/usr/bin/env bash\n' >"$PREFIX/bin/omp"
  chmod +x "$PREFIX/bin/omp"
  import() { :; }
  log_error() { :; }
  loading() { "$2"; }
  _omp_install_deps_native() { :; }
  _get_latest_omp_version_silent() { return 1; }
  # shellcheck source=../karnel/tools/ai/oh-my-pi/install.sh
  source "$ROOT_DIR/karnel/tools/ai/oh-my-pi/install.sh"
  _omp_install_deps_native() { :; }
  _get_latest_omp_version_silent() { return 1; }

  if _update_omp_native_impl; then
    return 1
  fi
  [[ "$(<"$OMP_DATA_DIR/marker")" == 'existing omp data' ]]
  [[ -x "$PREFIX/bin/omp" ]]
)

assert_codegraph_update_preserves_existing_payload_on_download_failure() (
  export HOME="$TEST_ROOT/codegraph-home"
  export PREFIX="$TEST_ROOT/codegraph-prefix"
  export KARNEL_CACHE="$TEST_ROOT/codegraph-cache"
  export KARNEL_DATA="$HOME/.local/share/karnel-data"
  mkdir -p "$KARNEL_DATA/codegraph-linux-arm64" "$PREFIX/bin" "$KARNEL_CACHE"
  printf 'existing codegraph data' >"$KARNEL_DATA/codegraph-linux-arm64/marker"
  import() { :; }
  log_error() { :; }
  curl() { return 1; }
  # shellcheck source=../karnel/tools/ai/codegraph/install.sh
  source "$ROOT_DIR/karnel/tools/ai/codegraph/install.sh"

  if _download_codegraph_impl; then
    return 1
  fi
  [[ "$(<"$KARNEL_DATA/codegraph-linux-arm64/marker")" == 'existing codegraph data' ]]
)

assert_font_uninstall_preserves_custom_font
assert_kiro_install_rejects_unusable_binary
assert_code_server_install_preserves_configuration
assert_zork_update_preserves_existing_data_on_download_failure
assert_zork_preserves_unowned_install
assert_goose_update_preserves_existing_binary_on_download_failure
assert_omp_native_update_preserves_existing_install_on_download_failure
assert_codegraph_update_preserves_existing_payload_on_download_failure
assert_ui_and_editor_status_are_karnel_owned
assert_ui_uninstall_preserves_malformed_blocks
printf 'Installer data-safety contracts: 10 passed\n'
