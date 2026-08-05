#!/usr/bin/env bash

set -euo pipefail

readonly INSTALL_URL="https://raw.githubusercontent.com/israelmarques1024-dotcom/karnel-termux/main/install.sh"
readonly KARNEL_CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/karnel"

if [[ -z "${PREFIX:-}" || "$PREFIX" != *"com.termux"* ]]; then
  echo "Karnel sponsored installer requires Termux." >&2
  exit 1
fi

if ! command -v curl >/dev/null 2>&1; then
  echo "curl is required. Install it with: pkg install curl" >&2
  exit 1
fi

cat <<'NOTICE'

  ◈ KARNEL — INDEPENDENT SPONSORED DISTRIBUTION

  This installer enables one clearly labeled sponsor message at most once
  every 24 hours. Sponsor messages do not collect commands, files, history,
  device identifiers, or personal data.

  Disable at any time with: karnel sponsor off

NOTICE

tmp="$(mktemp "${TMPDIR:-$PREFIX/tmp}/karnel-install.XXXXXX")"
trap 'rm -f "$tmp"' EXIT

curl -fsSL --connect-timeout 5 --max-time 30 "$INSTALL_URL" -o "$tmp"
bash "$tmp"

mkdir -p "$KARNEL_CONFIG_DIR"
printf '%s\n' "direct" >"$KARNEL_CONFIG_DIR/install-source"
printf '%s\n' "${KARNEL_SPONSORS_DEFAULT:-on}" >"$KARNEL_CONFIG_DIR/sponsors"
chmod 600 "$KARNEL_CONFIG_DIR/install-source" "$KARNEL_CONFIG_DIR/sponsors" 2>/dev/null || true

echo
echo "Sponsored distribution enabled. Run 'karnel sponsor status' to inspect it."
