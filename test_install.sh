#!/usr/bin/env bash
module_target=""
tool_flags=()
for arg in "ai" "--opencode"; do
    if [[ "$arg" == --* ]]; then
      # Remove -- prefix and convert to lowercase
      local flag="${arg#--}"
      tool_flags+=("$flag")
    elif [[ -z "$module_target" ]]; then
      module_target="$arg"
    fi
done
echo "Module: $module_target"
echo "Flags: ${tool_flags[@]}"
