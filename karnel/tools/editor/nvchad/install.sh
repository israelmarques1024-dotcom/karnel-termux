#!/usr/bin/env bash

import "@/utils/log"
import "@/utils/install"
import "@/utils/uninstall"
import "@/utils/version"

LOG_FILE="$KARNEL_CACHE/install_editor.log"
NVCHAD_REPO="https://github.com/DevCoreXOfficial/nvchad-termux.git"
NVCHAD_COMMIT="374710cfb4514719f53f4efc5a772547dbfe71d2"
NVCHAD_DIR="$KARNEL_DATA/nvchad-termux"
NVCHAD_MARKER=".karnel-nvchad"

_nvchad_owned_path() {
  local path="$1" kind="$2"
  [[ -d "$path" && -f "$path/$NVCHAD_MARKER" && "$(<"$path/$NVCHAD_MARKER")" == "karnel-nvchad-$kind-v1" ]]
}

_nvchad_owned_source() {
  { _nvchad_owned_path "$NVCHAD_DIR" source ||
    { declare -F _pinned_git_repo_owned &>/dev/null && _pinned_git_repo_owned "$NVCHAD_DIR" "$NVCHAD_REPO"; }; } &&
    [[ -d "$NVCHAD_DIR/.git" && -d "$NVCHAD_DIR/nvim" ]]
}

_nvchad_installed() {
  _nvchad_owned_source && _nvchad_owned_path "$HOME/.config/nvim" config &&
    [[ -f "$NVCHAD_DIR/.karnel-complete" && "$(<"$NVCHAD_DIR/.karnel-complete")" == "karnel-nvchad-complete-v1" ]]
}

_nvchad_dependencies() {
  declare -A DEPS=(
    ["git"]="git"
    ["neovim"]="nvim"
    ["nodejs-lts"]="node"
    ["python"]="python"
    ["perl"]="perl"
    ["curl"]="curl"
    ["wget"]="wget"
    ["lua-language-server"]="lua-language-server"
    ["ripgrep"]="rg"
    ["stylua"]="stylua"
    ["tree-sitter"]="tree-sitter"
  )

  local pkg_name bin_name
  for pkg_name in "${!DEPS[@]}"; do
    bin_name="${DEPS[$pkg_name]}"
    if ! command -v "$bin_name" &>/dev/null; then
      if ! yes | pkg install "$pkg_name" &>>"$LOG_FILE"; then
        log_error "Failed to install $pkg_name"
        return 1
      fi
    fi
  done

  log_success "NvChad dependencies installed"
  return 0
}

_install_nvchad_impl() {
  local config="$HOME/.config/nvim" state="$HOME/.local/state/nvim" data="$HOME/.local/share/nvim"
  local source_staging config_staging state_preexisting=0 data_preexisting=0
  if [[ -e "$config" || -L "$config" ]]; then
    if _nvchad_owned_path "$config" config && _nvchad_owned_source; then
      if _nvchad_installed; then log_info "NvChad already installed"; return 2; fi
      nvim --headless "+Lazy! sync" +qa &>>"$LOG_FILE" || return 1
      nvim --headless "+Lazy! clean nvim-treesitter" +qa &>>"$LOG_FILE" || return 1
      nvim --headless "+Lazy! install nvim-treesitter" +qa &>>"$LOG_FILE" || return 1
      printf '%s\n' 'karnel-nvchad-source-v1' >"$NVCHAD_DIR/$NVCHAD_MARKER" || return 1
      printf '%s\n' 'karnel-nvchad-complete-v1' >"$NVCHAD_DIR/.karnel-complete" || return 1
      log_success "NvChad installed"
      return 0
    fi
    log_error "Neovim configuration is not owned by Karnel; refusing to overwrite it"
    return 1
  fi
  [[ ! -e "$state" ]] || state_preexisting=1
  [[ ! -e "$data" ]] || data_preexisting=1
  if [[ -e "$NVCHAD_DIR" ]] && ! _nvchad_owned_source; then
    log_error "NvChad source directory is not owned by Karnel"
    return 1
  fi

  mkdir -p "$(dirname "$LOG_FILE")" "$HOME/.config" "$(dirname "$NVCHAD_DIR")" || return 1
  _nvchad_dependencies || return 1
  source_staging=$(mktemp -d "$(dirname "$NVCHAD_DIR")/.nvchad-source.XXXXXX") || return 1
  config_staging=$(mktemp -d "$HOME/.config/.nvchad-config.XXXXXX") || { rm -rf "$source_staging"; return 1; }

  if ! install_pinned_git_repo "$NVCHAD_REPO" "$NVCHAD_COMMIT" "$source_staging/repo" ||
    ! cp -R "$source_staging/repo/nvim/." "$config_staging/" &>>"$LOG_FILE"; then
    rm -rf "$source_staging" "$config_staging"
    log_error "Failed to install NvChad"
    return 1
  fi
  printf '%s\n' 'karnel-nvchad-source-v1' >"$source_staging/repo/$NVCHAD_MARKER" || { rm -rf "$source_staging" "$config_staging"; return 1; }
  printf '%s\n' 'karnel-nvchad-config-v1' >"$config_staging/$NVCHAD_MARKER" || { rm -rf "$source_staging" "$config_staging"; return 1; }
  [[ ! -e "$NVCHAD_DIR" ]] || rm -rf "$NVCHAD_DIR" || return 1
  mv "$source_staging/repo" "$NVCHAD_DIR" || { rm -rf "$source_staging" "$config_staging"; return 1; }
  rmdir "$source_staging" || return 1
  mv "$config_staging" "$config" || return 1
  nvim --headless "+Lazy! sync" +qa &>>"$LOG_FILE" || return 1
  nvim --headless "+Lazy! clean nvim-treesitter" +qa &>>"$LOG_FILE" || return 1
  nvim --headless "+Lazy! install nvim-treesitter" +qa &>>"$LOG_FILE" || return 1
  if (( state_preexisting == 0 )) && [[ -d "$state" ]]; then printf '%s\n' 'karnel-nvchad-state-v1' >"$state/$NVCHAD_MARKER" || return 1; fi
  if (( data_preexisting == 0 )) && [[ -d "$data" ]]; then printf '%s\n' 'karnel-nvchad-data-v1' >"$data/$NVCHAD_MARKER" || return 1; fi
  printf '%s\n' 'karnel-nvchad-complete-v1' >"$NVCHAD_DIR/.karnel-complete" || return 1
  log_success "NvChad installed"
}

install_nvchad() {
  if _nvchad_installed; then
    log_info "NvChad already installed"
    return 0
  fi
  log_info "Installing NvChad..."
  loading "Installing NvChad" _install_nvchad_impl
}

_uninstall_nvchad_impl() {
  local path kind removed=0
  for path in "$HOME/.config/nvim" "$HOME/.local/state/nvim" "$HOME/.local/share/nvim"; do
    case "$path" in
      */.config/nvim) kind=config ;;
      */state/nvim) kind=state ;;
      *) kind=data ;;
    esac
    if _nvchad_owned_path "$path" "$kind"; then rm -rf "$path" || return 1; removed=1; fi
  done
  if _nvchad_owned_source; then rm -rf "$NVCHAD_DIR" || return 1; removed=1; fi
  (( removed != 0 )) || return 2
  log_success "NvChad uninstalled"
}

uninstall_nvchad() {
  if ! _nvchad_owned_source && ! _nvchad_owned_path "$HOME/.config/nvim" config &&
    ! _nvchad_owned_path "$HOME/.local/state/nvim" state && ! _nvchad_owned_path "$HOME/.local/share/nvim" data; then
    log_info "NvChad is not installed"
    return 2
  fi
  log_info "Uninstalling NvChad..."
  loading "Uninstalling NvChad" _uninstall_nvchad_impl || return $?
}

_update_nvchad() {
  loading "Updating NvChad" _do_nvchad_update
}

_do_nvchad_update() {
  if ! _nvchad_owned_source; then
    log_error "NvChad source is not managed by Karnel; refusing to replace Neovim configuration"
    return 1
  fi
  if ! _pinned_git_repo_owned "$NVCHAD_DIR" "$NVCHAD_REPO"; then
    _adopt_pinned_git_repo "$NVCHAD_DIR" "$NVCHAD_REPO" || return 1
  fi
  install_pinned_git_repo "$NVCHAD_REPO" "$NVCHAD_COMMIT" "$NVCHAD_DIR" || return 1
  printf '%s\n' 'karnel-nvchad-source-v1' >"$NVCHAD_DIR/$NVCHAD_MARKER" || return 1
  printf '%s\n' 'karnel-nvchad-complete-v1' >"$NVCHAD_DIR/.karnel-complete" || return 1
  log_success "NvChad source updated; existing Neovim configuration was preserved"
}

update_nvchad() {
  _do_nvchad_update
}

reinstall_nvchad() {
  uninstall_nvchad || return $?
  install_nvchad
}
