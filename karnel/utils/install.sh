#!/usr/bin/env bash

LOG_FILE="${LOG_FILE:-$KARNEL_CACHE/install_ai.log}"

# ── Dependency installation ────────────────────────────────────

declare -gA _INSTALL_DEPS_CACHE

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
  local tmpfile
  tmpfile="$outdir/$(basename "$asset")"
  mkdir -p "$outdir"
  if ! curl --fail --silent --show-error --location "$url" -o "$tmpfile" &>>"$LOG_FILE"; then
    log_error "Failed to download $asset from $repo"
    return 1
  fi
  echo "$tmpfile"
}

verify_sha256() {
  local file="$1" expected="$2" actual
  [[ "$expected" =~ ^[0-9a-f]{64}$ ]] || {
    log_error "Refusing invalid SHA-256 for $(basename "$file")"
    return 1
  }
  actual=$(sha256sum "$file" 2>>"$LOG_FILE") || return 1
  actual=${actual%% *}
  if [[ "$actual" != "$expected" ]]; then
    log_error "Checksum verification failed for $(basename "$file")"
    return 1
  fi
}

_archive_member_is_safe() {
  local member="$1"
  [[ -n "$member" && "$member" != /* && "$member" != *\\* ]] || return 1
  case "/$member/" in
    */../*) return 1 ;;
  esac
}

_archive_link_is_safe() {
  local member="$1" target="$2" part depth=0
  local -a _archive_parts
  [[ -n "$target" && "$target" != /* && "$target" != *\\* ]] || return 1
  IFS=/ read -r -a _archive_parts <<<"$(dirname "$member")/$target"
  for part in "${_archive_parts[@]}"; do
    case "$part" in
      ''|.) ;;
      ..) ((depth > 0)) || return 1; ((depth -= 1)) ;;
      *) ((depth += 1)) ;;
    esac
  done
}

safe_extract_tar() {
  local archive="$1" outdir="$2" strip_components="${3:-0}"
  local member listing verbose mode line target
  listing=$(tar -tf "$archive" 2>>"$LOG_FILE") || {
    log_error "Failed to inspect $archive"
    return 1
  }
  while IFS= read -r member; do
    _archive_member_is_safe "$member" || {
      log_error "Refusing unsafe archive member: $member"
      return 1
    }
  done <<<"$listing"
  verbose=$(tar -tvf "$archive" 2>>"$LOG_FILE") || return 1
  while IFS= read -r line; do
    mode=${line%% *}
    case "${mode:0:1}" in
      l)
        member=${line%% -> *}
        member=${member##* }
        target=${line#* -> }
        _archive_link_is_safe "$member" "$target" || {
          log_error "Refusing unsafe archive symlink: $member"
          return 1
        }
        ;;
      h)
        member=${line%% link to *}
        member=${member##* }
        target=${line#* link to }
        _archive_link_is_safe "$member" "$target" || {
          log_error "Refusing unsafe archive hard link: $member"
          return 1
        }
        ;;
      b|c|p) log_error "Refusing unsafe archive entry type: $mode"; return 1 ;;
    esac
  done <<<"$verbose"
  mkdir -p "$outdir" || return 1
  tar -xf "$archive" -C "$outdir" --strip-components="$strip_components" \
    --no-same-owner --no-same-permissions &>>"$LOG_FILE"
}

safe_extract_zip() {
  local archive="$1" outdir="$2" member listing verbose mode
  listing=$(unzip -Z1 "$archive" 2>>"$LOG_FILE") || {
    log_error "Failed to inspect $archive"
    return 1
  }
  while IFS= read -r member; do
    _archive_member_is_safe "$member" || {
      log_error "Refusing unsafe archive member: $member"
      return 1
    }
  done <<<"$listing"
  if command -v zipinfo &>/dev/null; then
    verbose=$(zipinfo -l "$archive" 2>>"$LOG_FILE") || return 1
    while IFS= read -r mode _; do
      [[ "$mode" == l????????? ]] || continue
      log_error "Refusing symlink in zip archive"
      return 1
    done <<<"$verbose"
  else
    log_error "zipinfo is required for safe zip extraction"
    return 1
  fi
  mkdir -p "$outdir" || return 1
  unzip -q "$archive" -d "$outdir" >>"$LOG_FILE" 2>&1
}

installer_file_owned() {
  local target="$1" marker="$2"
  [[ -f "$target" && ! -L "$target" && -f "$marker" ]] || return 1
  [[ "$(sha256sum "$target" 2>/dev/null)" == "$(<"$marker")" ]]
}

activate_installer_file() {
  local staged="$1" target="$2" marker="$3"
  local target_dir marker_dir backup="" marker_tmp
  target_dir=$(dirname "$target")
  marker_dir=$(dirname "$marker")
  mkdir -p "$target_dir" "$marker_dir" || return 1
  if [[ -e "$target" || -L "$target" ]]; then
    installer_file_owned "$target" "$marker" || {
      log_error "Refusing to replace unowned file: $target"
      return 1
    }
    backup=$(mktemp "$target_dir/.karnel-backup.XXXXXX") || return 1
    mv -f "$target" "$backup" || { rm -f "$backup"; return 1; }
  fi
  marker_tmp=$(mktemp "$marker_dir/.karnel-marker.XXXXXX") || {
    [[ -z "$backup" ]] || mv -f "$backup" "$target"
    return 1
  }
  if ! chmod 755 "$staged" || ! mv -f "$staged" "$target" ||
    ! sha256sum "$target" >"$marker_tmp" || ! mv -f "$marker_tmp" "$marker"; then
    rm -f "$marker_tmp" "$target"
    [[ -z "$backup" ]] || mv -f "$backup" "$target"
    return 1
  fi
  [[ -z "$backup" ]] || rm -f "$backup"
}

github_release_asset_sha256() {
  local repo="$1" version="$2" asset="$3" digest=""
  # GitHub's release API does not expose per-asset digests, so fetch the
  # companion checksum file published alongside the asset (common convention).
  digest=$(curl -fsSL --connect-timeout 10 --max-time 30 \
    "https://github.com/$repo/releases/download/$version/$asset.sha256" 2>/dev/null \
    | awk '{print $1; exit}' | tr -d '\r')
  if [[ "$digest" =~ ^[0-9a-f]{64}$ ]]; then
    echo "$digest"
    return 0
  fi
  # Fallback: a checksums.txt / SHA256SUMS asset listing every released file.
  # Match the filename field exactly (it is the LAST field) so a substring or
  # regex-metacharacter in $asset cannot select the wrong line's digest.
  digest=$(curl -fsSL --connect-timeout 10 --max-time 30 \
    "https://github.com/$repo/releases/download/$version/checksums.txt" 2>/dev/null \
    | awk -v a="$asset" '{ f=$NF; if (f == a) { sub(/^\*/, "", $1); print $1; exit } }' | tr -d '\r')
  if [[ "$digest" =~ ^[0-9a-f]{64}$ ]]; then
    echo "$digest"
    return 0
  fi
  return 1
}

verify_github_release_asset() {
  local repo="$1" version="$2" asset="$3" file="$4" expected actual
  expected=$(github_release_asset_sha256 "$repo" "$version" "$asset") || expected=""
  if [[ ! "$expected" =~ ^[0-9a-f]{64}$ ]]; then
    log_error "No verifiable SHA-256 digest published for $repo/$asset; refusing install"
    return 1
  fi
  actual=$(sha256sum "$file" 2>>"$LOG_FILE") || return 1
  actual=${actual%% *}
  if [[ "$actual" != "$expected" ]]; then
    log_error "SHA-256 mismatch for $asset"
    return 1
  fi
}

extract_tarball() {
  local tarball="$1" outdir="$2"
  if ! safe_extract_tar "$tarball" "$outdir"; then
    log_error "Failed to extract $tarball"
    return 1
  fi
  rm -f "$tarball"
  return 0
}

replace_managed_directory() {
  local staging="$1" destination="$2" marker="$3"
  local backup_dir backup_target=""
  if [[ -e "$destination" && ! -f "$destination/$marker" ]]; then
    log_error "Refusing to replace unowned installation: $destination"
    return 1
  fi
  printf '%s\n' 'karnel-managed-v1' >"$staging/$marker" || return 1
  backup_dir="$(mktemp -d "$(dirname "$destination")/.karnel-managed.XXXXXX")" || return 1
  if [[ -e "$destination" ]]; then
    backup_target="$backup_dir/$(basename "$destination")"
    if ! mv "$destination" "$backup_target"; then
      rm -rf "$backup_dir"
      return 1
    fi
  fi
  if ! mv "$staging" "$destination"; then
    [[ -n "$backup_target" ]] && mv "$backup_target" "$destination" 2>/dev/null
    rm -rf "$backup_dir"
    return 1
  fi
  rm -rf "$backup_dir"
}

record_managed_file() {
  local file="$1" marker="$2"
  mkdir -p "$(dirname "$marker")" || return 1
  sha256sum "$file" >"$marker"
}

managed_file_matches() {
  local file="$1" marker="$2"
  [[ -f "$file" && -f "$marker" && "$(sha256sum "$file" 2>/dev/null)" == "$(<"$marker")" ]]
}

github_download_and_extract() {
  local repo="$1" version="$2" asset="$3" outdir="$4"
  local tarball expected
  tarball=$(github_download_release "$repo" "$version" "$asset" "$outdir") || return 1
  expected=$(github_release_asset_sha256 "$repo" "$version" "$asset") || expected=""
  if [[ "$expected" =~ ^[0-9a-f]{64}$ ]]; then
    verify_sha256 "$tarball" "$expected" || return 1
  else
    log_warn "No published SHA-256 digest for $repo/$asset; skipping integrity verification"
  fi
  extract_tarball "$tarball" "$outdir" || return 1
  return 0
}

# ── Pinned Git repository helpers ──────────────────────────────

_pinned_git_repo_owned() {
  local destination="$1" repository="$2"
  local marker="$destination/.karnel-pinned-git"
  [[ -d "$destination" && ! -L "$destination" && -f "$marker" &&
    "$(<"$marker")" == $'karnel-pinned-git-v1\n'"$repository" ]]
}

_adopt_pinned_git_repo() {
  local destination="$1" repository="$2" remote
  [[ -d "$destination/.git" ]] || return 1
  remote=$(git -C "$destination" remote get-url origin 2>/dev/null) || return 1
  [[ "${remote%.git}" == "${repository%.git}" ]] || {
    log_error "Refusing Git repository with unexpected origin: $destination"
    return 1
  }
  printf '%s\n%s\n' 'karnel-pinned-git-v1' "$repository" >"$destination/.karnel-pinned-git"
}

_stage_pinned_git_repo() {
  local repository="$1" commit="$2" staging="$3"

  [[ "$commit" =~ ^[0-9a-f]{40}$ ]] || {
    log_error "Refusing non-immutable Git commit: $commit"
    return 1
  }
  git init --quiet "$staging" &>>"$LOG_FILE" || return 1
  git -C "$staging" remote add origin "$repository" &>>"$LOG_FILE" || return 1
  git -C "$staging" fetch --quiet --depth=1 origin "$commit" &>>"$LOG_FILE" || return 1
  git -C "$staging" checkout --quiet --detach FETCH_HEAD &>>"$LOG_FILE" || return 1
  [[ "$(git -C "$staging" rev-parse HEAD 2>>"$LOG_FILE")" == "$commit" ]] || {
    log_error "Fetched Git commit does not match pin for $repository"
    return 1
  }
  printf '%s\n%s\n' 'karnel-pinned-git-v1' "$repository" >"$staging/.karnel-pinned-git"
}

install_pinned_git_repo() {
  local repository="$1" commit="$2" destination="$3"
  local parent staging backup=""

  parent=$(dirname "$destination")
  mkdir -p "$parent" || return 1
  if [[ -e "$destination" || -L "$destination" ]]; then
    if ! _pinned_git_repo_owned "$destination" "$repository"; then
      log_error "Refusing to replace unowned Git repository: $destination"
      return 1
    fi
    if [[ -d "$destination/.git" ]] &&
      [[ "$(git -C "$destination" rev-parse HEAD 2>/dev/null)" == "$commit" ]]; then
      return 0
    fi
  fi

  staging=$(mktemp -d "$parent/.karnel-git-stage.XXXXXX") || return 1
  if ! _stage_pinned_git_repo "$repository" "$commit" "$staging"; then
    rm -rf "$staging"
    log_error "Failed to fetch pinned repository: $repository@$commit"
    return 1
  fi

  if [[ -e "$destination" || -L "$destination" ]]; then
    backup=$(mktemp -d "$parent/.karnel-git-backup.XXXXXX") || { rm -rf "$staging"; return 1; }
    rmdir "$backup" || { rm -rf "$staging" "$backup"; return 1; }
    mv "$destination" "$backup" || { rm -rf "$staging"; return 1; }
  fi
  if ! mv "$staging" "$destination"; then
    [[ -z "$backup" ]] || mv "$backup" "$destination"
    rm -rf "$staging"
    return 1
  fi
  [[ -z "$backup" ]] || rm -rf "$backup"
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
