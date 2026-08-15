#!/usr/bin/env bash
# shellcheck disable=SC1091,SC2329
set -euo pipefail

ROOT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
TEST_ROOT=$(mktemp -d)
trap 'rm -rf "$TEST_ROOT"' EXIT

assert_secure_download_install() (
  local tool="$1" installer="$2"
  export PREFIX="$TEST_ROOT/$tool-prefix"
  export TMPDIR="$TEST_ROOT/$tool-tmp"
  export KARNEL_CACHE="$TEST_ROOT/$tool-cache"
  export LOG_FILE="$KARNEL_CACHE/install.log"
  export PATH="$PREFIX/bin:$PATH"
  mkdir -p "$PREFIX/bin" "$TMPDIR" "$KARNEL_CACHE"

  log_info() { :; }
  log_success() { :; }
  log_error() { :; }
  pkg() {
    case "$3" in
      zaproxy|subfinder|gobuster|ffuf|amass) return 1 ;;
      *) return 0 ;;
    esac
  }
  apt() { return 1; }
  command() {
    [[ "$1" == "-v" ]] && return 1
    builtin command "$@"
  }
  # shellcheck source=../karnel/utils/install.sh
  source "$ROOT_DIR/karnel/utils/install.sh"
  curl() {
    local arg output="" previous=""
    for arg in "$@"; do
      [[ "$previous" == "-o" ]] && output="$arg"
      previous="$arg"
    done
    if [[ -n "$output" ]]; then
      : >"$output"
    else
      printf '%s' '{"tag_name":"v1.0.0"}'
    fi
  }
  verify_sha256() { :; }
  safe_extract_tar() {
    local destination="$2"
    mkdir -p "$destination"
    case "$tool" in
      zap) mkdir -p "$destination/ZAP_2.16.1"; printf '#!/usr/bin/env bash\n' >"$destination/ZAP_2.16.1/zap.sh"; chmod +x "$destination/ZAP_2.16.1/zap.sh" ;;
      *) printf '#!/usr/bin/env bash\n' >"$destination/$tool" ;;
    esac
  }
  safe_extract_zip() {
    local destination="$2"
    mkdir -p "$destination"
    if [[ "$tool" == "amass" ]]; then
      mkdir -p "$destination/release"
      printf '#!/usr/bin/env bash\n' >"$destination/release/amass"
    else
      printf '#!/usr/bin/env bash\n' >"$destination/subfinder"
    fi
  }

  # shellcheck source=/dev/null
  source "$ROOT_DIR/$installer"
  "install_$tool"
  [[ -x "$PREFIX/bin/$tool" ]]
  shopt -s nullglob
  local leftovers=("$TMPDIR"/*)
  [[ ${#leftovers[@]} -eq 0 ]]
)

assert_secure_download_install zap karnel/tools/security/zap/install.sh
assert_secure_download_install subfinder karnel/tools/security/subfinder/install.sh
assert_secure_download_install gobuster karnel/tools/security/gobuster/install.sh
assert_secure_download_install ffuf karnel/tools/security/ffuf/install.sh
assert_secure_download_install amass karnel/tools/security/amass/install.sh
printf 'Security temporary installer contracts: 5 passed\n'
