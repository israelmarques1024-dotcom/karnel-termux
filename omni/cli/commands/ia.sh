#!/usr/bin/env bash

import "@/utils/log"
import "@/utils/colors"

# AI Manager (omni ia) — router for all AI agents and sessions
IA_SESSIONS_DIR="$HOME/.local/share/omni-data/ia/sessions"
IA_DATA_DIR="$HOME/.local/share/omni-data/ia"

ia_help() {
	echo
	box "OMNI IA — AI Agent Manager"
	echo
	log_info "Usage: omni ia <command> [options]"
	echo
	separator_section "Commands"
	echo
	printf "    ${D_CYAN}%-12s${NC} %s\n" "sessions" "List all AI conversation sessions"
	printf "    ${D_CYAN}%-12s${NC} %s\n" "install" "Install AI tools (odysseus, opencode, claude, etc)"
	printf "    ${D_CYAN}%-12s${NC} %s\n" "list" "List all installed AI tools"
	printf "    ${D_CYAN}%-12s${NC} %s\n" "routes" "Show available AI CLI methods/launchers"
	echo
	separator_section "Examples"
	echo
	printf "    ${D_CYAN}omni ia sessions${NC}         # Show all AI sessions\n"
	printf "    ${D_CYAN}omni ia sessions --all${NC}   # Include agent names\n"
	printf "    ${D_CYAN}omni ia install odysseus${NC}  # Install Odysseus web UI\n"
	printf "    ${D_CYAN}omni ia list${NC}             # List installed AI tools\n"
	echo
}

# List all AI sessions from known tools
ia_sessions() {
	local show_all="${1:-0}"

	mkdir -p "$IA_SESSIONS_DIR"

	local -a sessions=()

	# OpenCode prompt history
	if [[ -f "$HOME/.local/state/opencode/prompt-history.jsonl" ]]; then
		while IFS= read -r line; do
			local input=""
			input=$(printf '%s' "$line" | jq -r '.input // ""' 2>/dev/null || true)
			if [[ -n "$input" ]]; then
				local ts
				ts=$(date +%Y%m%d_%H%M%S)
				local display="${input:0:60}"
				display="${display//$'\n'/ }"
				sessions+=("[opencode]|$ts|$display")
			fi
		done < <(tail -50 "$HOME/.local/state/opencode/prompt-history.jsonl" 2>/dev/null || true)
	fi

	# Hermes sessions
	if [[ -d "$HOME/.hermes/sessions" ]]; then
		for f in "$HOME/.hermes/sessions"/*.json; do
			[[ -f "$f" ]] || continue
			local basename
			basename=$(basename "$f")
			local ts
			ts=$(echo "$basename" | grep -oE '[0-9]{8}_[0-9]{6}' | head -1 || echo "unknown")
			sessions+=("[hermes]|$ts|$basename")
		done
	fi

	# Kimi-code sessions
	if [[ -d "$HOME/.kimi-code/sessions" ]]; then
		for d in "$HOME/.kimi-code/sessions"/*; do
			[[ -d "$d" ]] || continue
			local basename
			basename=$(basename "$d")
			local ts
			ts=$(stat -c %Y "$d" 2>/dev/null || echo "unknown")
			local readable_ts
			readable_ts=$(date -d "@$ts" +%Y%m%d_%H%M%S 2>/dev/null || echo "unknown")
			sessions+=("[kimi]|$readable_ts|$basename")
		done
	fi

	# Pi agent sessions
	if [[ -d "$HOME/.pi/agent/sessions" ]]; then
		for d in "$HOME/.pi/agent/sessions"/*; do
			[[ -d "$d" ]] || continue
			local basename
			basename=$(basename "$d")
			local ts
			ts=$(stat -c %Y "$d" 2>/dev/null || echo "unknown")
			local readable_ts
			readable_ts=$(date -d "@$ts" +%Y%m%d_%H%M%S 2>/dev/null || echo "unknown")
			sessions+=("[pi]|$readable_ts|$basename")
		done
	fi

	# Codex sessions
	if [[ -d "$HOME/.codex" ]]; then
		for f in "$HOME/.codex"/*.json; do
			[[ -f "$f" ]] || continue
			local basename
			basename=$(basename "$f")
			local ts
			ts=$(stat -c %Y "$f" 2>/dev/null || echo "unknown")
			local readable_ts
			readable_ts=$(date -d "@$ts" +%Y%m%d_%H%M%S 2>/dev/null || echo "unknown")
			sessions+=("[codex]|$readable_ts|$basename")
		done
	fi

	# OpenClaw sessions
	if [[ -d "$HOME/.openclaw/agents/main/sessions" ]]; then
		for f in "$HOME/.openclaw/agents/main/sessions"/*.json; do
			[[ -f "$f" ]] || continue
			local basename
			basename=$(basename "$f")
			local ts
			ts=$(stat -c %Y "$f" 2>/dev/null || echo "unknown")
			local readable_ts
			readable_ts=$(date -d "@$ts" +%Y%m%d_%H%M%S 2>/dev/null || echo "unknown")
			sessions+=("[openclaw]|$readable_ts|$basename")
		done
	fi

	# Odysseus sessions
	if [[ -d "$HOME/.local/share/omni-data/odysseus" ]]; then
		local ody_sessions_dir="$HOME/.local/share/omni-data/odysseus/sessions"
		if [[ -d "$ody_sessions_dir" ]]; then
			for f in "$ody_sessions_dir"/*.json; do
				[[ -f "$f" ]] || continue
				local basename
				basename=$(basename "$f")
				local ts
				ts=$(stat -c %Y "$f" 2>/dev/null || echo "unknown")
				local readable_ts
				readable_ts=$(date -d "@$ts" +%Y%m%d_%H%M%S 2>/dev/null || echo "unknown")
				sessions+=("[odysseus]|$readable_ts|$basename")
			done
		fi
	fi

	# MimoCode sessions
	if [[ -d "$HOME/.local/share/omni-data/mimocode" ]]; then
		local mimo_sessions_dir="$HOME/.local/share/omni-data/mimocode/sessions"
		if [[ -d "$mimo_sessions_dir" ]]; then
			for f in "$mimo_sessions_dir"/*.json; do
				[[ -f "$f" ]] || continue
				local basename
				basename=$(basename "$f")
				local ts
				ts=$(stat -c %Y "$f" 2>/dev/null || echo "unknown")
				local readable_ts
				readable_ts=$(date -d "@$ts" +%Y%m%d_%H%M%S 2>/dev/null || echo "unknown")
				sessions+=("[mimocode]|$readable_ts|$basename")
			done
		fi
	fi

	if [[ ${#sessions[@]} -eq 0 ]]; then
		log_warn "No AI sessions found"
		log_info "Start an AI tool to create your first session"
		return 0
	fi

	separator
	box "AI Sessions (${#sessions[@]})"
	separator
	echo

	# Sort by date (newest first)
	mapfile -t sorted_sessions < <(printf '%s\n' "${sessions[@]}" | sort -t'|' -k2 -r)

	local idx=1
	for session in "${sorted_sessions[@]}"; do
		local tool
		tool=$(echo "$session" | cut -d'|' -f1)
		local ts
		ts=$(echo "$session" | cut -d'|' -f2)
		local name
		name=$(echo "$session" | cut -d'|' -f3-)

		local display_name="$name"
		if [[ ${#name} -gt 50 ]]; then
			display_name="${name:0:47}..."
		fi

		printf "    ${D_CYAN}%3d.${D_NC} %-14s %s  %s\n" "$idx" "$tool" "$ts" "$display_name"
		((idx++))
	done

	echo
	log_info "Total: ${#sessions[@]} sessions across all AI tools"
}

# List available AI CLI launchers/routers
ia_routes() {
	separator
	box "AI CLI Routes / Launchers"
	separator
	echo

	local -a routes=()

	# Collect all available AI CLIs
	for cmd in opencode claude codex qwen vibe mimo hermes kimi ollama odysseus openclaude freebuff pi agy mmx gentle-ai gga engram codegraph kilow command-code kimchi; do
		if command -v "$cmd" &>/dev/null; then
			local path
			path=$(command -v "$cmd")
			routes+=("$cmd|$path|installed")
		else
			routes+=("$cmd|not installed|missing")
		fi
	done

	if [[ ${#routes[@]} -eq 0 ]]; then
		log_warn "No AI CLIs found"
		return 0
	fi

	table_start "CLI" "Path" "Status"
	for route in "${routes[@]}"; do
		local cli
		cli=$(echo "$route" | cut -d'|' -f1)
		local path
		path=$(echo "$route" | cut -d'|' -f2)
		local status
		status=$(echo "$route" | cut -d'|' -f3)

		local display_status
		if [[ "$status" == "installed" ]]; then
			display_status="${D_GREEN}installed${NC}"
		else
			display_status="${D_RED}missing${NC}"
		fi

		table_row "${D_CYAN}${cli}${NC}" "$path" "$display_status"
	done
	table_end
	echo

	log_info "Install missing ones with: ${D_CYAN}omni install ai${NC}"
}

# List installed AI tools
ia_list() {
	local -a installed=()
	for cmd in opencode claude codex qwen vibe mimo hermes kimi ollama odysseus openclaude freebuff pi agy mmx gentle-ai gga engram codegraph kilow command-code kimchi; do
		if command -v "$cmd" &>/dev/null; then
			installed+=("$cmd")
		fi
	done

	if [[ ${#installed[@]} -eq 0 ]]; then
		log_warn "No AI tools installed"
		log_info "Install with: ${D_CYAN}omni install ai${NC}"
		return 0
	fi

	separator
	box "Installed AI Tools (${#installed[@]})"
	separator
	echo

	for tool in "${installed[@]}"; do
		list_item "${D_GREEN}✔${NC} ${D_CYAN}${tool}${NC}"
	done

	echo
	log_info "Run ${D_CYAN}omni ia routes${NC} for full CLI paths"
}

# Install AI tools
ia_install() {
	local tool="${1:-}"

	if [[ -z "$tool" ]]; then
		log_error "Please specify an AI tool to install"
		log_info "Usage: omni ia install <tool>"
		log_info "Example: omni ia install odysseus"
		return 1
	fi

	log_info "Installing AI tool: $tool"
	omni_main "install" "ai" "--$tool"
}

# Main router
ia_main() {
	local cmd="$1"
	shift || true

	case "$cmd" in
	sessions)
		ia_sessions "$@"
		;;
	install)
		ia_install "$@"
		;;
	list | ls)
		ia_list
		;;
	routes | launchers)
		ia_routes
		;;
	"" | --help | -h)
		ia_help
		;;
	*)
		log_error "Unknown command: $cmd"
		ia_help
		return 1
		;;
	esac
}