#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
TEST_ROOT=$(mktemp -d)
trap 'rm -rf "$TEST_ROOT"' EXIT

export PREFIX="$TEST_ROOT/prefix"
export KARNEL_CACHE="$TEST_ROOT/cache"
export KARNEL_DATA="$TEST_ROOT/data"
export KARNEL_PATH="$ROOT_DIR/karnel"
export PATH="$PREFIX/bin:$PATH"
mkdir -p "$PREFIX/bin" "$KARNEL_CACHE"
import() { :; }
log_info() { :; }
log_success() { :; }
log_error() { :; }
pkg() { :; }
curl_failure=0
curl() {
  local output="" previous="" arg
  (( curl_failure == 0 )) || return 1
  for arg in "$@"; do
    [[ "$previous" == "-o" ]] && output="$arg"
    previous="$arg"
  done
  printf '#!/usr/bin/env python3\nprint("runtime payload")\n' >"$output"
}
# shellcheck source=../karnel/utils/downloaded-python.sh
source "$ROOT_DIR/karnel/utils/downloaded-python.sh"

for spec in \
  'buzz:karnel/tools/games/buzz/install.sh' \
  'arcade:karnel/tools/games/arcade/install.sh' \
  'ctfgod:karnel/tools/games/ctfgod/install.sh' \
  'detective:karnel/tools/games/detective/install.sh' \
  'pet-friends:karnel/tools/games/pet-friends/install.sh' \
  'tamagotchi:karnel/tools/games/tamagotchi/install.sh' \
  'dark:karnel/tools/network/dark/install.sh' \
  'dedsec-network:karnel/tools/network/dedsec-network/install.sh' \
  'applaunch:karnel/tools/utils/applaunch/install.sh' \
  'fconv:karnel/tools/utils/fconv/install.sh' \
  'filecheck:karnel/tools/utils/filecheck/install.sh' \
  'notes:karnel/tools/utils/notes/install.sh' \
  'passman:karnel/tools/utils/passman/install.sh' \
  'qrcode:karnel/tools/utils/qrcode/install.sh' \
  'splash:karnel/tools/utils/splash/install.sh' \
  'treex:karnel/tools/utils/treex/install.sh' \
  'websites:karnel/tools/utils/websites/install.sh'; do
  tool=${spec%%:*}
  installer=${spec#*:}
  install_function="install_${tool//-/_}"
  update_function="update_${tool//-/_}"
  uninstall_function="uninstall_${tool//-/_}"
  runtime_payload="$KARNEL_DATA/${installer#karnel/tools/}"
  runtime_payload="${runtime_payload%/install.sh}/$tool.py"
  source_payload="$KARNEL_PATH/tools/${installer#karnel/tools/}"
  source_payload="${source_payload%/install.sh}/$tool.py"
  # shellcheck source=/dev/null
  source "$ROOT_DIR/$installer"

  printf 'external wrapper\n' >"$PREFIX/bin/$tool"
  if "$install_function"; then exit 1; fi
  grep -qF 'external wrapper' "$PREFIX/bin/$tool"
  rm -f "$PREFIX/bin/$tool"

  "$install_function"
  [[ -L "$PREFIX/bin/$tool" && "$(readlink "$PREFIX/bin/$tool")" == "$runtime_payload" ]]
  [[ -f "$runtime_payload" ]]
  [[ "$installer" == karnel/tools/utils/* || ! -e "$source_payload" ]]
  payload_before=$(<"$runtime_payload")
  curl_failure=1
  if [[ -f "$source_payload" ]]; then
    "$update_function"
  else
    if "$update_function"; then exit 1; fi
    [[ "$payload_before" == "$(<"$runtime_payload")" ]]
  fi
  curl_failure=0
  "$uninstall_function"
  [[ ! -e "$PREFIX/bin/$tool" && ! -e "${runtime_payload%/*}" ]]

  "$install_function"
  rm -f "$PREFIX/bin/$tool"
  printf 'external wrapper\n' >"$PREFIX/bin/$tool"
  "$uninstall_function" || [[ $? -eq 2 ]]
  [[ -f "$PREFIX/bin/$tool" && -f "$runtime_payload" ]]
  rm -rf "$PREFIX/bin/$tool" "${runtime_payload%/*}"
done

atomic_dir="$KARNEL_DATA/atomic/tool"
curl_failure=0
_downloaded_python_install atomic "$atomic_dir" https://example.invalid/atomic.py
atomic_before=$(<"$atomic_dir/atomic.py")
mv() {
  if [[ "${1:-}" == *'/atomic' && "${2:-}" == "$PREFIX/bin/atomic" ]]; then return 1; fi
  command mv "$@"
}
if _downloaded_python_install atomic "$atomic_dir" https://example.invalid/atomic.py force; then exit 1; fi
unset -f mv
[[ "$atomic_before" == "$(<"$atomic_dir/atomic.py")" ]]
_downloaded_python_owned atomic "$atomic_dir"

printf 'Downloaded Python installer contracts: 18 passed\n'
