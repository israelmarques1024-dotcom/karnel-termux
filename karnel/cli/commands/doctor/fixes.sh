#!/usr/bin/env bash
# shellcheck disable=SC1091

import "@/utils/log"
import "@/utils/colors"

_fix_storage() {
  termux-setup-storage 2>/dev/null
  return $?
}

_fix_mkdir() {
  local rc=0
  for dir in "$KARNEL_CONFIG" "$KARNEL_CACHE" "$KARNEL_DATA"; do
    mkdir -p "$dir" && chmod 755 "$dir" 2>/dev/null || { rc=1; log_warn "Failed to create $dir"; }
  done
  return $rc
}

_fix_pkg_install() {
  local pkg_to_install=""
  case "$1" in
    pkg) pkg_to_install="$2" ;;
    *) pkg_to_install="${fix_commands[$i]:-}" ;;
  esac
  local pkg_name=""
  if [[ "$pkg_to_install" =~ pkg\ install\ -y\ (.+) ]]; then
    pkg_name="${BASH_REMATCH[1]}"
  fi
  if [[ -n "$pkg_name" ]]; then
    pkg install -y "$pkg_name" 2>/dev/null
    return $?
  fi
  return 1
}

_fix_dpkg() {
  dpkg --configure -a 2>/dev/null
  apt-get -f install -y 2>/dev/null
  return $?
}

_fix_apt_update() {
  pkg update -y 2>/dev/null
  return $?
}

_fix_npm_prefix() {
  mkdir -p "$HOME/.npm-global"
  npm config set prefix "$HOME/.npm-global" 2>/dev/null
  return $?
}

_fix_pip() {
  local py_cmd=""
  for py in python3.12 python3.11 python3.10 python3.9 python3 python; do
    if command -v "$py" &>/dev/null; then py_cmd="$py"; break; fi
  done
  if [[ -n "$py_cmd" ]]; then
    "$py_cmd" -m ensurepip 2>/dev/null
    "$py_cmd" -m pip install --upgrade pip 2>/dev/null
    return $?
  fi
  return 1
}

_fix_pg_init() {
  source "$KARNEL_PATH/utils/env.sh" 2>/dev/null
  import "@/modules/db" 2>/dev/null
  if type pg_init &>/dev/null; then
    pg_init 2>/dev/null
    pg_start 2>/dev/null
    return $?
  fi
  local pg_data="$HOME/.local/share/postgresql/data"
  mkdir -p "$pg_data" 2>/dev/null
  if command -v initdb &>/dev/null; then
    initdb -D "$pg_data" 2>/dev/null
    pg_ctl -D "$pg_data" -l "$HOME/.cache/karnel/postgresql.log" start 2>/dev/null
    return $?
  fi
  return 1
}

_fix_pg_start() {
  local pg_data=""
  for dir in "$PREFIX/var/lib/postgresql/data" "$PREFIX/var/lib/postgresql" "$HOME/.termux/postgresql/data" "$HOME/.termux/postgresql" "$HOME/.local/share/postgresql/data"; do
    if [[ -d "$dir" ]] && [[ -f "$dir/PG_VERSION" ]]; then
      pg_data="$dir"
      break
    fi
  done
  if [[ -n "$pg_data" ]] && command -v pg_ctl &>/dev/null; then
    pg_ctl -D "$pg_data" -l "$HOME/.cache/karnel/postgresql.log" start 2>/dev/null
    return $?
  fi
  return 1
}

_fix_pg_install() {
  if ! command -v pg_ctl &>/dev/null; then
    pkg install -y postgresql 2>/dev/null || return 1
  fi
  if ! command -v initdb &>/dev/null; then
    return 1
  fi
  local pg_data="$PREFIX/var/lib/postgresql"
  mkdir -p "$pg_data" 2>/dev/null
  if [[ ! -f "$pg_data/PG_VERSION" ]]; then
    initdb -D "$pg_data" 2>/dev/null || return 1
  fi
  return 0
}

_fix_symlinks() {
  ln -sf "$KARNEL_PATH/bin/karnel" "$PREFIX/bin/karnel" 2>/dev/null
  [[ -L "$PREFIX/bin/karnel" ]]
}

_fix_banner() {
  local shell_config=""
  if [[ -f "$HOME/.zshrc" ]]; then
    shell_config="$HOME/.zshrc"
  elif [[ -f "$HOME/.bashrc" ]]; then
    shell_config="$HOME/.bashrc"
  fi
  if [[ -z "$shell_config" ]]; then
    shell_config="$HOME/.zshrc"
    touch "$shell_config"
  fi
  local marker="# ===== Karnel Banner ====="
  if ! grep -qF "$marker" "$shell_config" 2>/dev/null; then
    cat >>"$shell_config" <<EOF

$marker
source "$KARNEL_UTILS/banner.sh"
EOF
    return 0
  fi
  return 0
}

_fix_ai_install() {
  log_info "Installing AI tools (this may take a while)..."
  source "$KARNEL_PATH/utils/env.sh" 2>/dev/null
  import "@/modules/ai" 2>/dev/null
  if type install_ai &>/dev/null; then
    install_ai 2>/dev/null
    return $?
  fi
  return 1
}

_fix_shell_syntax() {
  local config=""
  if [[ -f "$HOME/.zshrc" ]]; then
    config="$HOME/.zshrc"
    if ! command -v zsh &>/dev/null; then
      log_warn "zsh not installed — cannot validate .zshrc syntax"
      return 1
    fi
  elif [[ -f "$HOME/.bashrc" ]]; then
    config="$HOME/.bashrc"
  else
    return 1
  fi
  local bak="${config}.bak.$(date +%s)"
  cp "$config" "$bak" 2>/dev/null || return 1
  sed -i '/^# syntax error/d' "$config" 2>/dev/null
  local validator="bash"
  [[ "$config" == *.zshrc ]] && validator="zsh"
  if "$validator" -n "$config" 2>/dev/null; then
    return 0
  fi
  cp "$bak" "$config" 2>/dev/null
  return 1
}

_fix_ssh_key() {
  mkdir -p "$HOME/.ssh"
  chmod 700 "$HOME/.ssh"
  ssh-keygen -t ed25519 -f "$HOME/.ssh/id_ed25519" -N '' 2>/dev/null
  return $?
}

_fix_disk_cleanup() {
  rm -rf ~/.cache/karnel/install_*.log 2>/dev/null
  if command -v pkg &>/dev/null; then
    pkg clean -y 2>/dev/null
  fi
  return $?
}

_fix_mkdir_single() {
  local rc=0
  for dir in "$KARNEL_CONFIG" "$KARNEL_CACHE" "$KARNEL_DATA"; do
    [[ -d "$dir" ]] || mkdir -p "$dir" 2>/dev/null || { rc=1; log_warn "Failed to create $dir"; }
  done
  return $rc
}

# ===== NEW FIX CALLBACKS =====

_fix_psutil() {
  local tmp="$PREFIX/tmp/psutil_patch"
  mkdir -p "$tmp"
  pip download psutil==7.2.2 --no-binary :all: --no-deps -d "$tmp" 2>/dev/null || return 1
  tar xzf "$tmp/psutil-7.2.2.tar.gz" -C "$tmp"
  sed -i 's/LINUX = sys.platform.startswith("linux")/LINUX = sys.platform.startswith(("linux", "android"))/' "$tmp/psutil-7.2.2/psutil/_common.py"
  pip install "$tmp/psutil-7.2.2" 2>/dev/null
  local rc=$?
  rm -rf "$tmp"
  return $rc
}

_fix_pip_check() {
  local -a broken_pkgs=()
  while IFS= read -r line; do
    broken_pkgs+=("$line")
  done < <(pip check 2>&1 | grep -oP '^\S+' | head -3)
  if [[ ${#broken_pkgs[@]} -gt 0 ]]; then
    pip install --upgrade --force-reinstall "${broken_pkgs[@]}" 2>/dev/null
  fi
  return 0
}

_fix_npm_shebangs() {
  local fixed=0
  for f in "$PREFIX/bin/"*; do
    [[ -f "$f" ]] || continue
    local shebang
    shebang=$(head -1 "$f" 2>/dev/null | tr -d '\0')
    if [[ "$shebang" == "#!/usr/bin/env node" ]]; then
      sed -i "1s|^.*$|#!$PREFIX/bin/node|" "$f" && ((fixed++))
    elif [[ "$shebang" == "#!/usr/bin/env bash" ]] || [[ "$shebang" == "#!/usr/bin/env sh" ]]; then
      sed -i "1s|^.*$|#!$PREFIX/bin/bash|" "$f" && ((fixed++))
    elif [[ "$shebang" == "#!/usr/bin/env python3" ]] || [[ "$shebang" == "#!/usr/bin/env python" ]]; then
      sed -i "1s|^.*$|#!$PREFIX/bin/python3|" "$f" && ((fixed++))
    fi
  done
  return 0
}

_fix_broken_symlinks() {
  find "$PREFIX/bin" -type l ! -exec test -e {} \; -delete 2>/dev/null
  return 0
}

_fix_npm_cache() {
  npm cache clean --force 2>/dev/null
  return $?
}

_fix_pip_cache() {
  pip cache purge 2>/dev/null
  return $?
}

_fix_pycache() {
  local python_dir
  for python_dir in "$PREFIX"/lib/python3.*; do
    [[ -d "$python_dir" ]] || continue
    find "$python_dir" -name "__pycache__" -type d -exec rm -rf {} + 2>/dev/null
  done
  return 0
}

_fix_proot_ubuntu() {
  if command -v proot-distro &>/dev/null; then
    proot-distro install ubuntu 2>/dev/null
    return $?
  fi
  return 1
}

_fix_dns() {
  if command -v nslookup &>/dev/null && nslookup github.com &>/dev/null; then
    return 0
  fi
  local resolv_conf="$PREFIX/etc/resolv.conf"
  if [[ -w "$resolv_conf" ]] || [[ -w "$PREFIX/etc" ]]; then
    cp "$resolv_conf" "${resolv_conf}.bak" 2>/dev/null
    echo 'nameserver 8.8.8.8' > "$resolv_conf" 2>/dev/null && return 0
    echo 'nameserver 8.8.4.4' >> "$resolv_conf" 2>/dev/null || true
  fi
  return 1
}

_fix_mirror() {
  if command -v termux-change-repo &>/dev/null; then
    termux-change-repo 2>/dev/null
    return $?
  fi
  return 1
}

_fix_locale() {
  local config="$HOME/.zshrc"
  if [[ ! -f "$config" ]] && [[ -f "$HOME/.bashrc" ]]; then
    config="$HOME/.bashrc"
  fi
  echo 'export LANG=en_US.UTF-8' >> "$config" 2>/dev/null
}


_fix_zombies() {
  local zombies
  zombies=$(ps aux 2>/dev/null | awk '$8 ~ /^Z/ {print $2}')
  if [[ -n "$zombies" ]]; then
    log_warn "Zombie processes (PID: $zombies) cannot be killed — the parent process must reap them"
    log_info "Run 'ps aux | grep Z' to see zombie parent PIDs"
  fi
  return 0
}

_fix_url_quote_magic() {
  local uqm_file="$PREFIX/share/zsh/functions/Zle/url-quote-magic"
  if [[ ! -f "$uqm_file" ]]; then
    return 1
  fi
  # Fix double-paren case patterns: (( -> ( for localschema and otherschema
  sed -i \
    -e 's/((${~localschema})/(${~localschema})/g' \
    -e 's/((${~otherschema})/(${~otherschema})/g' \
    "$uqm_file" 2>/dev/null
  return $?
}
