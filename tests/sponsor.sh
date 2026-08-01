#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
TMP_ROOT=$(mktemp -d)
trap 'rm -rf "$TMP_ROOT"' EXIT

export KARNEL_CONFIG="$TMP_ROOT/config"
export KARNEL_CACHE="$TMP_ROOT/cache"
export KARNEL_SPONSOR_NO_REFRESH=1
export KARNEL_SPONSOR_INTERVAL=0
export CI=""
mkdir -p "$KARNEL_CONFIG" "$KARNEL_CACHE"

# shellcheck source=/dev/null
source "$ROOT_DIR/karnel/utils/sponsor.sh"

printf '%s\n' "direct" >"$KARNEL_CONFIG/install-source"
printf '%s\n' "on" >"$KARNEL_CONFIG/sponsors"
printf 'demo\tExample Cloud\tFast hosting for Termux developers.\thttps://example.com/karnel\n' >"$KARNEL_CACHE/sponsors.tsv"

sponsor_is_enabled
output=$(sponsor_render_cached)
grep -Fq "Patrocinado por Example Cloud" <<<"$output"
grep -Fq "https://example.com/karnel" <<<"$output"

export CI="1"
if sponsor_is_enabled; then
  echo "CI unexpectedly enabled sponsors" >&2
  exit 1
fi
export CI=""

sponsor_set_enabled off
if sponsor_is_enabled; then
  echo "sponsor_is_enabled ignored the off state" >&2
  exit 1
fi

printf '%s\n' "npm" >"$KARNEL_CONFIG/install-source"
printf '%s\n' "on" >"$KARNEL_CONFIG/sponsors"
if sponsor_is_enabled; then
  echo "npm installation unexpectedly enabled sponsors" >&2
  exit 1
fi

set +e
sponsor_set_enabled on
status=$?
set -e
if [[ "$status" != "2" ]]; then
  echo "npm installation was allowed to enable sponsors" >&2
  exit 1
fi

printf '%s\n' "direct" >"$KARNEL_CONFIG/install-source"
printf '%s\n' "on" >"$KARNEL_CONFIG/sponsors"
printf 'bad\tUnsafe\tInvalid URL\thttp://example.com\n' >"$KARNEL_CACHE/sponsors.tsv"
if sponsor_render_cached >/dev/null 2>&1; then
  echo "invalid sponsor URL was rendered" >&2
  exit 1
fi

echo "sponsor tests passed"
