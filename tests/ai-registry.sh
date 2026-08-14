#!/usr/bin/env bash
set -eo pipefail

ROOT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
export HOME="${HOME:-/tmp}"
export PREFIX="${PREFIX:-/data/data/com.termux/files/usr}"
export KARNEL_PATH="$ROOT_DIR/karnel"
export KARNEL_CACHE="${KARNEL_CACHE:-$HOME/.cache/karnel}"
export KARNEL_DATA="${KARNEL_DATA:-$HOME/.local/share/karnel-data}"

import() { :; }
log_info() { :; }
log_warn() { :; }
log_error() { :; }
log_success() { :; }

# shellcheck source=../karnel/tools/ai/all.sh
source "$ROOT_DIR/karnel/tools/ai/all.sh"

declare -A registered=()
for entry in "${AI_TOOLS_REGISTRY[@]}"; do
  IFS=':' read -r id name binaries <<<"$entry"
  [[ -n "$id" && -n "$name" && -n "$binaries" ]]
  [[ -z "${registered[$id]+duplicate}" ]] || {
    printf 'duplicate AI registry id: %s\n' "$id" >&2
    exit 1
  }
  registered["$id"]=1
  [[ -f "$ROOT_DIR/karnel/tools/ai/$id/install.sh" ]]
  [[ -f "$ROOT_DIR/karnel/tools/ai/$id/README.md" ]]
  for action in install uninstall update reinstall; do
    declare -f "${action}_${id//-/_}" >/dev/null
  done
done

for installer in "$ROOT_DIR"/karnel/tools/ai/*/install.sh; do
  id=${installer%/install.sh}
  id=${id##*/}
  [[ -n "${registered[$id]+registered}" ]] || {
    printf 'unregistered AI installer: %s\n' "$id" >&2
    exit 1
  }
done

[[ ${#AI_TOOLS_REGISTRY[@]} -eq 43 ]]
[[ -n "${registered[cactus]+registered}" ]]
[[ -n "${registered[hugging-face]+registered}" ]]
verified_count=${#AI_TOOLS_REGISTRY[@]}

install_contract_probe() { return 0; }
uninstall_contract_probe() { return 9; }
AI_TOOLS_REGISTRY+=("contract-probe:Contract Probe:contract-probe")
if _run_ai_tool_action reinstall contract-probe; then
  printf 'reinstall continued after uninstall failure\n' >&2
  exit 1
fi

printf 'AI registry contracts: %d tools verified\n' "$verified_count"
