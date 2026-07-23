#!/usr/bin/env bash

LOG_FILE="${LOG_FILE:-$KARNEL_CACHE/install_ai.log}"

# ── Dependency installation ────────────────────────────────────

declare -A _INSTALL_DEPS_CACHE

install_deps() {
  local -n deps=$1
  local pkg_name bin_name
  for pkg_name in "${!deps[@]}"; do
    bin_name="${deps[$pkg_name]}"
    if ! command -v "$bin_name" &>/dev/null; then
      if ! pkg install "$pkg_name" -y &>>"$LOG_FILE"; then
        log_error "Failed to install $pkg_name"
        return 1
      fi
    fi
  done
  return 0
}

# ── Glibc installation ─────────────────────────────────────────

install_glibc() {
  if [[ ! -f $PREFIX/etc/apt/sources.list.d/glibc.list ]]; then
    if ! pkg install glibc-repo -y &>>"$LOG_FILE"; then
      log_error "Failed to install glibc-repo"
      return 1
    fi
  fi
  if [[ ! -f $PREFIX/glibc/lib/libc.so.6 ]]; then
    if ! pkg install glibc -y &>>"$LOG_FILE"; then
      log_error "Failed to install glibc"
      return 1
    fi
  fi
  return 0
}

# ── GitHub release helpers ─────────────────────────────────────

github_latest_tag() {
  local repo="$1"
  curl -fsSL "https://api.github.com/repos/$repo/releases/latest" |
    grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/'
}

github_download_release() {
  local repo="$1" version="$2" asset="$3" outdir="$4"
  local url="https://github.com/$repo/releases/download/$version/$asset"
  local tmpfile="$outdir/$(basename "$asset")"
  mkdir -p "$outdir"
  if ! curl -fsSL "$url" -o "$tmpfile" &>>"$LOG_FILE"; then
    log_error "Failed to download $asset from $repo"
    return 1
  fi
  echo "$tmpfile"
}

extract_tarball() {
  local tarball="$1" outdir="$2"
  if ! tar -zxf "$tarball" -C "$outdir" &>>"$LOG_FILE"; then
    log_error "Failed to extract $tarball"
    return 1
  fi
  rm -f "$tarball"
  return 0
}

github_download_and_extract() {
  local repo="$1" version="$2" asset="$3" outdir="$4"
  local tarball
  tarball=$(github_download_release "$repo" "$version" "$asset" "$outdir") || return 1
  extract_tarball "$tarball" "$outdir" || return 1
  return 0
}

# ── C helper compilation ───────────────────────────────────────

compile_helper() {
  local src="$1" out="$2"
  if [ ! -f "$src" ]; then
    log_error "Helper source not found at $src"
    return 1
  fi
  if ! cc -O2 -o "$out" "$src" &>>"$LOG_FILE"; then
    log_error "Failed to compile $src"
    return 1
  fi
  chmod +x "$out"
  return 0
}

# ── Wrapper generator ─────────────────────────────────────────

generate_wrapper() {
  local template="$1" ubuntu_root="$2" output="$3"
  if [ ! -f "$template" ]; then
    log_error "Wrapper template not found at $template"
    return 1
  fi
  sed "s|__UBUNTU_ROOTFS__|$ubuntu_root|g" "$template" >"$output"
  chmod +x "$output"
  return 0
}
