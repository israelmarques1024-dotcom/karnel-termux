#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
BASH_COMPLETION="$ROOT_DIR/scripts/completion.bash"
ZSH_COMPLETION="$ROOT_DIR/scripts/completion.zsh"

fail() {
  printf 'Completion catalog mismatch: %s\n' "$1" >&2
  exit 1
}

sorted_words() {
  local words="$1"
  # Intentional word splitting: completion catalogs are space-delimited identifiers.
  # shellcheck disable=SC2086
  printf '%s\n' $words | sort
}

assert_same_words() {
  local label="$1"
  local expected="$2"
  local actual="$3"
  local expected_sorted actual_sorted

  expected_sorted=$(sorted_words "$expected")
  actual_sorted=$(sorted_words "$actual")
  [[ "$expected_sorted" == "$actual_sorted" ]] || {
    printf 'Expected %s:\n%s\nActual %s:\n%s\n' "$label" "$expected_sorted" "$label" "$actual_sorted" >&2
    fail "$label"
  }
}

expected_commands=""
for command_file in "$ROOT_DIR"/karnel/cli/commands/*.sh; do
  command_name=${command_file##*/}
  expected_commands+=" ${command_name%.sh}"
done

bash_commands=$(sed -n 's/^  local commands="\([^"]*\)"/\1/p' "$BASH_COMPLETION")
zsh_commands=$(sed -n '/^_karnel_commands()/,/^}/s/^    '\''\([^:]*\):.*$/\1/p' "$ZSH_COMPLETION" | tr '\n' ' ')
assert_same_words "Bash top-level commands" "$expected_commands" "$bash_commands"
assert_same_words "Zsh top-level commands" "$expected_commands" "$zsh_commands"

expected_modules=""
for module_file in "$ROOT_DIR"/karnel/modules/*.sh; do
  module_name=${module_file##*/}
  expected_modules+=" ${module_name%.sh}"
done

bash_modules=$(sed -n 's/^  local modules="\([^"]*\)"/\1/p' "$BASH_COMPLETION")
zsh_modules=$(sed -n '/^_karnel_modules()/,/^}/s/^    '\''\([^:]*\):.*$/\1/p' "$ZSH_COMPLETION" | tr '\n' ' ')
assert_same_words "Bash modules" "$expected_modules" "$bash_modules"
assert_same_words "Zsh modules" "$expected_modules" "$zsh_modules"
grep -qF 'local install_targets="$modules supabase"' "$BASH_COMPLETION"
grep -qF 'local update_targets="$modules supabase karnel core"' "$BASH_COMPLETION"
grep -qF 'compadd -- supabase karnel core' "$ZSH_COMPLETION"

ai_ids=$(awk '
  /^AI_TOOLS_REGISTRY=\(/ { registry = 1; next }
  registry && /^\)/ { exit }
  registry && /"/ {
    line = $0
    sub(/^[[:space:]]*"/, "", line)
    sub(/:.*/, "", line)
    print line
  }
' "$ROOT_DIR/karnel/tools/ai/all.sh")

bash_ai_ids=$(sed -n 's/^  local ai_tools="\([^"]*\)"/\1/p' "$BASH_COMPLETION" | sed -n '1p')
zsh_ai_ids=$(sed -n 's/^  local ai_tools="\([^"]*\)"/\1/p' "$ZSH_COMPLETION" | sed -n '1p')
assert_same_words "Bash AI tools" "$ai_ids" "$bash_ai_ids"
assert_same_words "Zsh AI tools" "$ai_ids" "$zsh_ai_ids"

catalog_has_id() {
  local id="$1"
  local catalog="$2"
  [[ " $catalog " == *" $id "* ]]
}

installer_count=0
for installer in "$ROOT_DIR"/karnel/tools/*/*/install.sh; do
  [[ -f "$installer" ]] || continue
  tool_dir=${installer%/install.sh}
  tool_id=${tool_dir##*/}
  module_dir=${tool_dir%/*}
  module_id=${module_dir##*/}
  if [[ "$module_id" != "ai" ]]; then
    bash_tool_ids=$(sed -n "s/^    ${module_id}) tools=\"\([^\"]*\)\".*/\1/p" "$BASH_COMPLETION")
    zsh_tool_ids=$(sed -n "s/^    ${module_id}) tools=\"\([^\"]*\)\".*/\1/p" "$ZSH_COMPLETION")
    catalog_has_id "$tool_id" "$bash_tool_ids" || fail "Bash $module_id flag --$tool_id"
    catalog_has_id "$tool_id" "$zsh_tool_ids" || fail "Zsh $module_id flag --$tool_id"
  fi
  installer_count=$((installer_count + 1))
done

command_count=$(sorted_words "$expected_commands" | wc -l)
module_count=$(sorted_words "$expected_modules" | wc -l)
ai_count=$(printf '%s\n' "$ai_ids" | sed '/^$/d' | wc -l)
printf 'Completion catalogs: %d commands, %d modules, %d AI tools, %d installers verified\n' \
  "$command_count" "$module_count" "$ai_count" "$installer_count"
