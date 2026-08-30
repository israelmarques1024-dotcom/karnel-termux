#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)

fail() {
  printf 'FAIL: %s\n' "$1" >&2
  exit 1
}

import() { :; }
log_error() { :; }
log_warn() { :; }
log_info() { :; }
log_success() { :; }
box() { :; }
separator_section() { :; }
D_CYAN= D_GREEN= D_DIM= NC=
# shellcheck source=../karnel/cli/commands/open.sh
source "$ROOT_DIR/karnel/cli/commands/open.sh"

opened=""
termux-open-url() { opened="$1"; }

open_main cleanup
[[ "$opened" == "https://karneltermux.vercel.app/karnel/cleanup" ]] ||
  fail "cleanup opened '$opened'"

open_main supabase
[[ "$opened" == "https://karneltermux.vercel.app/karnel/supabase" ]] ||
  fail "supabase opened '$opened'"

open_main karnel
[[ "$opened" == "https://karneltermux.vercel.app/" ]] ||
  fail "overview opened '$opened'"

printf 'Open documentation routes: 3 passed\n'
