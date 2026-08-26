#!/data/data/com.termux/files/usr/bin/env bash
ZORK_DIR="$HOME/.local/share/karnel-data/zork"
if [ ! -f "$ZORK_DIR/zork1.dat" ]; then
  mkdir -p "$ZORK_DIR"
  echo "Baixando Zork I..."
  tmpdir="$(mktemp -d "${TMPDIR:-${KARNEL_CACHE:-$HOME/.cache/karnel}}/zork.XXXXXX")" || exit 1
  curl -fsSL "https://www.infocom-if.org/downloads/zork1.zip" -o "$tmpdir/zork1.zip"
  if unzip -l "$tmpdir/zork1.zip" 2>/dev/null | grep -qE '\.\.[/\\]|^/|[A-Za-z]:\\'; then
    echo "Refusing potentially unsafe Zork archive" >&2
    rm -rf "$tmpdir"; exit 1
  fi
  unzip -o "$tmpdir/zork1.zip" -d "$ZORK_DIR" 2>/dev/null
  rm -rf "$tmpdir"
fi
exec frotz "$ZORK_DIR/zork1.dat" "$@"
