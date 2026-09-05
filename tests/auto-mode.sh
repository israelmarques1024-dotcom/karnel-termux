#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)

import() { :; }
# shellcheck source=../karnel/utils/log.sh
source "$ROOT_DIR/karnel/utils/log.sh"

KARNEL_AUTO=1
read_confirm "Continue?" answer
[[ "$answer" == y ]]
read_confirm_default "Remove managed data?" n answer
[[ "$answer" == y ]]

grep -qF 'export KARNEL_AUTO=1' "$ROOT_DIR/karnel/bin/karnel"
grep -qF 'export KARNEL_NONINTERACTIVE=1' "$ROOT_DIR/karnel/bin/karnel"
grep -qF 'if [[ "${KARNEL_AUTO:-0}" == "1" ]]; then' "$ROOT_DIR/karnel/utils/agent_actions.sh"

printf 'Auto mode contracts: 5 passed\n'
