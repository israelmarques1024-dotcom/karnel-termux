#!/usr/bin/env bash
# shellcheck disable=SC1091,SC2030,SC2031,SC2251,SC2329
set -euo pipefail

ROOT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
TEST_ROOT=$(mktemp -d)
trap 'rm -rf "$TEST_ROOT"' EXIT

log_info() { :; }
log_success() { :; }
log_warn() { :; }
log_error() { :; }
import() { :; }
export LOG_FILE="$TEST_ROOT/install.log"

# shellcheck source=../karnel/utils/install.sh
source "$ROOT_DIR/karnel/utils/install.sh"

assert_helper_rejects_bad_inputs() (
  local payload="$TEST_ROOT/payload" archive="$TEST_ROOT/traversal.tar" fixture="$TEST_ROOT/fixture"
  local link_archive="$TEST_ROOT/link.tar"
  printf 'payload\n' >"$payload"
  ! verify_sha256 "$payload" "$(printf '%064d' 0)"

  mkdir -p "$fixture"
  printf 'escape\n' >"$fixture/escape"
  tar -cf "$archive" -C "$fixture" --transform='s|escape|../escape|' escape
  ! safe_extract_tar "$archive" "$TEST_ROOT/extracted"
  [[ ! -e "$TEST_ROOT/escape" ]]

  rm -rf "$fixture"
  mkdir -p "$fixture/root/bin"
  ln -s ../../../outside "$fixture/root/bin/escape"
  tar -cf "$link_archive" -C "$fixture" root
  ! safe_extract_tar "$link_archive" "$TEST_ROOT/link-extracted"
)

assert_activation_rolls_back() (
  local target="$TEST_ROOT/bin/tool" marker="$TEST_ROOT/markers/tool"
  mkdir -p "$(dirname "$target")" "$(dirname "$marker")"
  printf 'working version\n' >"$target"
  sha256sum "$target" >"$marker"
  ! activate_installer_file "$TEST_ROOT/missing-stage" "$target" "$marker" >/dev/null 2>&1
  grep -qF 'working version' "$target"
  installer_file_owned "$target" "$marker"
)

assert_bad_download_preserves_install() (
  local tool="$1" installer="$2" update_function="$3" marker data_dir
  export PREFIX="$TEST_ROOT/$tool-prefix"
  export TMPDIR="$TEST_ROOT/$tool-tmp"
  export PATH="$PREFIX/bin:$PATH"
  mkdir -p "$PREFIX/bin" "$TMPDIR"
  marker="$PREFIX/share/karnel-installers/$tool"
  data_dir=""
  case "$tool" in
    zap) data_dir="$PREFIX/share/zap"; marker="$data_dir/.karnel-wrapper" ;;
    burpsuite) data_dir="$PREFIX/share/burpsuite"; marker="$data_dir/.karnel-wrapper" ;;
  esac
  mkdir -p "$(dirname "$marker")"
  printf '#!/usr/bin/env bash\nprintf "working version\\n"\n' >"$PREFIX/bin/$tool"
  chmod 755 "$PREFIX/bin/$tool"
  sha256sum "$PREFIX/bin/$tool" >"$marker"
  if [[ "$tool" == burpsuite ]]; then
    printf 'working jar\n' >"$data_dir/burpsuite_community.jar"
  elif [[ "$tool" == zap ]]; then
    mkdir -p "$data_dir/ZAP_2.16.1"
    printf 'working zap\n' >"$data_dir/ZAP_2.16.1/zap.sh"
    chmod 755 "$data_dir/ZAP_2.16.1/zap.sh"
  fi

  pkg() { return 1; }
  apt() { return 1; }
  uname() { printf 'aarch64\n'; }
  curl() {
    local previous="" arg output=""
    for arg in "$@"; do
      [[ "$previous" == -o ]] && output="$arg"
      previous="$arg"
    done
    printf 'tampered bytes\n' >"$output"
  }
  # shellcheck source=/dev/null
  source "$ROOT_DIR/$installer"
  ! "$update_function"
  grep -qF 'working version' "$PREFIX/bin/$tool"
  installer_file_owned "$PREFIX/bin/$tool" "$marker"
  [[ -z "$data_dir" || -d "$data_dir" ]]
)

assert_node_requires_shasums() (
  export KARNEL_CACHE="$TEST_ROOT/node-cache"
  export KARNEL_DATA="$TEST_ROOT/node-data"
  export KARNEL_PATH="$ROOT_DIR/karnel"
  export PREFIX="$TEST_ROOT/node-prefix"
  mkdir -p "$KARNEL_CACHE" "$KARNEL_DATA" "$PREFIX/bin" "$TEST_ROOT/node-stage"
  # shellcheck source=../karnel/tools/npm/turbopack/install.sh
  source "$ROOT_DIR/karnel/tools/npm/turbopack/install.sh"
  curl() {
    local output="${!#}"
    if [[ "$output" == *SHASUMS256.txt ]]; then
      printf '%064d  node-v%s-linux-arm64.tar.xz\n' 0 "$NODE_VERSION" >"$output"
    else
      printf 'tampered node\n' >"$output"
    fi
  }
  extracted=0
  safe_extract_tar() { extracted=1; }
  ! _download "$TEST_ROOT/node-stage"
  [[ $extracted -eq 0 ]]
)

assert_source_contracts() {
  local file function
  for file in ffuf amass subfinder gobuster zap burpsuite; do
    ! grep -q '/releases/latest' "$ROOT_DIR/karnel/tools/security/$file/install.sh"
    grep -qE 'SHA256|checksum=' "$ROOT_DIR/karnel/tools/security/$file/install.sh"
    function="update_${file}"
    [[ "$file" == burpsuite ]] && function=update_burpsuite
    ! grep -A3 "^${function}()" "$ROOT_DIR/karnel/tools/security/$file/install.sh" | grep -q 'uninstall_'
  done
  grep -qF 'SHASUMS256.txt' "$ROOT_DIR/karnel/tools/npm/turbopack/install.sh"
  grep -qF 'NODE_SHA256=' "$ROOT_DIR/karnel/tools/npm/turbopack/install.sh"
}

assert_helper_rejects_bad_inputs
assert_activation_rolls_back
assert_bad_download_preserves_install ffuf karnel/tools/security/ffuf/install.sh update_ffuf
assert_bad_download_preserves_install amass karnel/tools/security/amass/install.sh update_amass
assert_bad_download_preserves_install subfinder karnel/tools/security/subfinder/install.sh update_subfinder
assert_bad_download_preserves_install gobuster karnel/tools/security/gobuster/install.sh update_gobuster
assert_bad_download_preserves_install zap karnel/tools/security/zap/install.sh update_zap
assert_bad_download_preserves_install burpsuite karnel/tools/security/burpsuite/install.sh update_burpsuite
assert_node_requires_shasums
assert_source_contracts
printf 'Security installer integrity: 10 passed\n'
