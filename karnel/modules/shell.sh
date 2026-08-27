#!/usr/bin/env bash

import "@/utils/log"
import "@/utils/colors"
import "@/utils/uninstall"

ZSH_PLUGINS_DIR="$HOME/.zsh-plugins"
OH_MY_ZSH_DIR="$HOME/.oh-my-zsh"
LOG_FILE="$KARNEL_CACHE/install_shell.log"
OH_MY_ZSH_REF="b54a71977574cfcf659cc2f15a5e6422f17a8da7"

install_termux_packages() {
	log_info "Installing dependencies..."

	if pkg install -y zsh lsd bat fzf zoxide &>>"$LOG_FILE"; then
		log_success "Dependencies installed successfully"
		return 0
	else
		log_error "Failed to install dependencies"
		return 1
	fi
}

install_oh_my_zsh() (
	if [[ -d "$OH_MY_ZSH_DIR" ]]; then
		log_warn "Oh My Zsh already installed"
		return 0
	fi

	log_info "Downloading Oh My Zsh..."
	log_info "When prompted, enter (Y/n) to set ZSH as your default shell"
	echo

	local temp_base temp_dir temp_file
	temp_base="${TMPDIR:-${KARNEL_CACHE:-$HOME/.cache/karnel}}"
	mkdir -p "$temp_base" || return 1
	temp_dir=$(mktemp -d "$temp_base/karnel-omz.XXXXXX") || {
		log_error "Failed to create private Oh My Zsh temporary directory"
		return 1
	}
	trap 'rm -rf "$temp_dir"' EXIT
	temp_file="$temp_dir/install.sh"

	if curl -fsSL "https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/$OH_MY_ZSH_REF/tools/install.sh" -o "$temp_file" &>>"$LOG_FILE"; then
		# Keep the reviewed installer behavior, but fetch and check out the reviewed commit.
		local omz_ref_esc
omz_ref_esc=$(printf '%s\n' "$OH_MY_ZSH_REF" | sed 's/[][\/.&*?^$|]/\\&/g')
sed -i "s|git fetch --depth=1 origin|git fetch --depth=1 origin $omz_ref_esc|" "$temp_file"
		# shellcheck disable=SC2016
		sed -i 's|git checkout -b "$BRANCH" "origin/$BRANCH"|git checkout --detach FETCH_HEAD|' "$temp_file"
		if ! grep -qF "git fetch --depth=1 origin $OH_MY_ZSH_REF" "$temp_file" ||
			! grep -qF 'git checkout --detach FETCH_HEAD' "$temp_file"; then
			log_error "Unable to pin the Oh My Zsh clone"
			return 1
		fi
		if ! CHSH=no RUNZSH=no BRANCH="master" sh "$temp_file" &>>"$LOG_FILE"; then
			log_error "Failed to install Oh My Zsh"
			return 1
		fi
		# Record Karnel ownership so uninstall only removes a Karnel-managed install.
		: >"$OH_MY_ZSH_DIR/.karnel-managed"
		log_success "Oh My Zsh installed successfully"
		return 0
	else
		log_error "Failed to download Oh My Zsh"
		return 1
	fi
)

add_to_zshrc() {
	local line="$1"
	if ! grep -qxF "$line" ~/.zshrc 2>/dev/null; then
		echo "$line" >>~/.zshrc
	fi
}

setup_zsh_aliases() {
	log_info "Setting up ZSH aliases..."

	# Wrap in a marker block so it can be cleanly removed on uninstall, and
	# only alias to tools that are actually installed (otherwise ls/cat break).
	local block_start="# >>> karnel shell aliases >>>"
	local block_end="# <<< karnel shell aliases <<<"
	[[ -f ~/.zshrc ]] && sed -i "/$block_start/,/$block_end/d" ~/.zshrc 2>/dev/null
	{
		echo "$block_start"
		command -v lsd >/dev/null && echo 'alias ls="lsd"'
		command -v bat >/dev/null && echo 'alias cat="bat --theme=Dracula --style=plain --paging=never"'
		command -v zoxide >/dev/null && echo 'eval "$(zoxide init zsh)"'
		echo "$block_end"
	} >>~/.zshrc

	log_success "ZSH aliases configured"
}

setup_shell_env() {
	log_info "Setting up shell environment..."

	add_to_zshrc "unalias gga 2>/dev/null"
	add_to_zshrc "export GOPATH=\"\$HOME/.local/go\""
	add_to_zshrc "export GOCACHE=\"\$HOME/.cache/go\""
	add_to_zshrc "export GOMODCACHE=\"\$GOPATH/pkg/mod\""
	add_to_zshrc "export PATH=\$PATH:\$HOME/go/bin"
	add_to_zshrc "export OPENCLAW_DISABLE_BONJOUR=1"

	log_success "Shell environment configured"
}

setupPersistentSession() {
	log_info "Configuring persistent session..."

	mkdir -p "$KARNEL_CACHE" 2>/dev/null || mkdir -p ~/.cache/karnel

	echo "$HOME" > "$KARNEL_CACHE/last_dir"

	if grep -q "# ===== Persistent Directory =====" ~/.zshrc 2>/dev/null; then
		log_warn "Persistent session already configured"
		return 0
	fi

	cat >>~/.zshrc <<'EOF'

# ===== Persistent Directory =====
LAST_DIR_FILE="$HOME/.cache/karnel/last_dir"
SESSION_TIMESTAMP="$HOME/.cache/karnel/.session_time"
SESSION_TIMEOUT=5

save_dir() {
  mkdir -p ~/.cache/karnel 2>/dev/null
  pwd > "$LAST_DIR_FILE"
  date +%s > "$SESSION_TIMESTAMP"
}

restore_dir() {
  if [[ -f "$SESSION_TIMESTAMP" ]] && [[ -f "$LAST_DIR_FILE" ]]; then
    local current_time
    local last_time
    current_time=$(date +%s)
    last_time=$(cat "$SESSION_TIMESTAMP" 2>/dev/null || echo 0)
    local diff=$((current_time - last_time))

    if [[ $diff -lt $SESSION_TIMEOUT ]]; then
      local dir
      dir=$(cat "$LAST_DIR_FILE" 2>/dev/null)
      if [[ -d "$dir" ]] && [[ "$dir" != "$HOME" ]]; then
        cd "$dir" 2>/dev/null
      fi
    fi
  fi
  date +%s > "$SESSION_TIMESTAMP"
}

if typeset -f add-zsh-hook &>/dev/null; then
  add-zsh-hook precmd save_dir
  restore_dir
else
  restore_dir
  trap 'save_dir' EXIT
fi
echo
EOF

	log_success "Persistent session configured"
	log_info "New sessions within Termux will restore last directory"
}

install_shell() {
	separator
	box "Installing ZSH Shell Environment"
	separator
	echo

	mkdir -p "$(dirname "$LOG_FILE")"

	local rc=0
	if ! loading "Installing base packages" install_termux_packages; then
		log_error "Base package installation failed"
		rc=1
	fi
	echo

	if ! install_oh_my_zsh; then
		log_error "Oh My Zsh installation failed"
		rc=1
	fi
	echo

	_install_shell_plugins_wrapper || rc=$?
	if (( rc == 0 )); then
		log_success "ZSH plugins installed"
	else
		log_warn "ZSH plugin(s) failed to install"
	fi
	echo

	setup_zsh_aliases
	echo

	setup_shell_env
	echo

	setupPersistentSession
	echo

	separator
	if [ "$rc" -eq 0 ]; then
		log_success "ZSH shell environment setup completed"
	else
		log_warn "$rc ZSH plugin(s) failed to install"
	fi
	separator
	echo
	log_warn "Please restart Termux or run: exec zsh"
	echo
	return "$rc"
}

_install_shell_plugins_wrapper() {
	import "@/tools/shell/all"
	install_all_shell_plugins
	local plugin_rc=$?

	if [[ -d "$ZSH_PLUGINS_DIR/powerlevel10k" ]]; then
		add_to_zshrc 'source ~/.zsh-plugins/powerlevel10k/powerlevel10k.zsh-theme'
	fi
	if [[ -d "$ZSH_PLUGINS_DIR/zsh-defer" ]]; then
		add_to_zshrc 'source ~/.zsh-plugins/zsh-defer/zsh-defer.plugin.zsh'
	fi
	if [[ -d "$ZSH_PLUGINS_DIR/zsh-autosuggestions" ]]; then
		add_to_zshrc 'source ~/.zsh-plugins/zsh-autosuggestions/zsh-autosuggestions.zsh'
	fi
	if [[ -d "$ZSH_PLUGINS_DIR/zsh-syntax-highlighting" ]]; then
		add_to_zshrc 'source ~/.zsh-plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh'
	fi
	if [[ -d "$ZSH_PLUGINS_DIR/zsh-history-substring-search" ]]; then
		add_to_zshrc 'source ~/.zsh-plugins/zsh-history-substring-search/zsh-history-substring-search.zsh'
		add_to_zshrc "bindkey '^[[A' history-substring-search-up"
		add_to_zshrc "bindkey '^[[B' history-substring-search-down"
	fi
	if [[ -d "$ZSH_PLUGINS_DIR/zsh-completions" ]]; then
		add_to_zshrc 'fpath+=~/.zsh-plugins/zsh-completions'
	fi
	if [[ -d "$ZSH_PLUGINS_DIR/fzf-tab" ]]; then
		add_to_zshrc 'source ~/.zsh-plugins/fzf-tab/fzf-tab.plugin.zsh'
		add_to_zshrc "zstyle ':completion:*' menu-select yes"
		add_to_zshrc "zstyle ':fzf-tab:*' switch-word yes"
	fi
	if [[ -d "$ZSH_PLUGINS_DIR/zsh-you-should-use" ]]; then
		add_to_zshrc 'source ~/.zsh-plugins/zsh-you-should-use/you-should-use.plugin.zsh'
	fi
	if [[ -d "$ZSH_PLUGINS_DIR/zsh-autopair" ]]; then
		add_to_zshrc 'source ~/.zsh-plugins/zsh-autopair/autopair.zsh'
	fi
	if [[ -d "$ZSH_PLUGINS_DIR/zsh-better-npm-completion" ]]; then
		add_to_zshrc 'source ~/.zsh-plugins/zsh-better-npm-completion/zsh-better-npm-completion.plugin.zsh'
	fi

	return $plugin_rc
}

uninstall_oh_my_zsh() {
	if [[ ! -d "$OH_MY_ZSH_DIR" ]]; then
		log_warn "Oh My Zsh not installed"
		return 0
	fi

	log_info "Uninstalling Oh My Zsh..."

	local remove_rc=0
	confirm_remove_paths "Oh My Zsh" "$OH_MY_ZSH_DIR" || remove_rc=$?
	if [[ "$remove_rc" -eq 0 ]]; then
		log_success "Oh My Zsh uninstalled"
	elif [[ "$remove_rc" -eq 2 ]]; then
		log_info "Oh My Zsh configuration preserved"
	else
		log_error "Failed to uninstall Oh My Zsh"
		return 1
	fi
}

uninstall_shell() {
	separator
	box "Uninstalling ZSH Shell Environment"
	separator
	echo

	mkdir -p "$(dirname "$LOG_FILE")"

	local rc=0
	_uninstall_shell_plugins_wrapper || rc=$?
	local oh_my_zsh_rc=0
	uninstall_oh_my_zsh || oh_my_zsh_rc=$?
	((rc += oh_my_zsh_rc))

	echo
	separator
	if [ "$rc" -eq 0 ]; then
		log_success "ZSH shell environment uninstalled"
	else
		log_warn "$rc ZSH plugin(s) failed to uninstall"
	fi
	separator
	echo
	return "$rc"
}

_uninstall_shell_plugins_wrapper() {
	import "@/tools/shell/all"
	uninstall_all_shell_plugins
	return $?
}

update_shell() {
	separator
	box "Updating ZSH Shell Environment"
	separator
	echo

	mkdir -p "$(dirname "$LOG_FILE")"

	local rc=0
	_update_shell_plugins_wrapper || rc=$?
	if [ "$rc" -eq 0 ]; then
		log_success "ZSH shell environment updated"
	else
		log_warn "$rc ZSH plugin(s) failed to update"
	fi

	setup_shell_env
	echo

	separator
	log_success "ZSH update completed"
	separator
	echo
	return "$rc"
}

_update_shell_plugins_wrapper() {
  import "@/tools/shell/all"
  update_all_shell_plugins
  return $?
}

reinstall_shell() {
  separator
  box "Reinstalling ZSH Shell Environment"
  separator
  echo

	mkdir -p "$(dirname "$LOG_FILE")"

	# Remove karnel-managed alias block so a missing/broken lsd/bat no longer hijacks ls/cat
	[[ -f ~/.zshrc ]] && sed -i '/# >>> karnel shell aliases >>>/,/# <<< karnel shell aliases <<</d' ~/.zshrc 2>/dev/null

	local rc=0
  _reinstall_shell_plugins_wrapper || rc=$?
  log_success "ZSH plugins reinstalled"
  echo

  setup_zsh_aliases
  echo

  setup_shell_env
  echo

  setupPersistentSession
  echo

  separator
  if [ "$rc" -eq 0 ]; then
		log_success "ZSH shell environment reinstallation completed"
  else
		log_warn "$rc ZSH plugin(s) failed to reinstall"
  fi
  separator
  echo
	log_warn "Please restart Termux or run: exec zsh"
	echo
	return "$rc"
}

_reinstall_shell_plugins_wrapper() {
  import "@/tools/shell/all"
  reinstall_all_shell_plugins
  return $?
}
