#!/usr/bin/env bash

detect_ubuntu_root() {
  local root
  root="$(find /data/data/com.termux -maxdepth 10 -type d \
    -name "rootfs" -path "*/containers/ubuntu/*" 2>/dev/null | head -1)"
  if [ -z "$root" ]; then
    root="$(find /data/data/com.termux -maxdepth 10 -type d \
      -name "ubuntu" -path "*/installed-rootfs/*" 2>/dev/null | head -1)"
  fi
  echo "$root"
}

proot_ubuntu() {
  proot-distro login --shared-tmp ubuntu -- "$@"
}

proot_install_ubuntu() {
  local dist="${1:-ubuntu:24.04}"
  if ! command -v proot-distro &>/dev/null; then
    pkg install proot-distro -y &>>"$LOG_FILE"
  fi
  if [ ! -d "$(detect_ubuntu_root)" ]; then
    proot-distro install "$dist" &>>"$LOG_FILE"
  fi
}
