#!/bin/bash
set +e

OMNI="$HOME/omni/bin/omni"
PASS=0
FAIL=0
TOTAL=0
RESULTS=()

record() {
  local status="$1"
  local msg="$2"
  TOTAL=$((TOTAL+1))
  if [[ "$status" == "PASS" ]]; then
    PASS=$((PASS+1))
    RESULTS+=("PASS|$msg")
  else
    FAIL=$((FAIL+1))
    RESULTS+=("FAIL|$msg")
  fi
}

ai_tools=(
  opencode:opencode
  claude:claude
  codex:codex
  qwen:qwen
  vibe:vibe
  mimo:mimo
  hermes:hermes
  kimi:kimi
  ollama:ollama
  odysseus:odysseus
  openclaw:openclaw
  freebuff:freebuff
  pi:pi
  agy:agy
  mmx:mmx
  gentle-ai:gentle-ai
  gga:gga
  engram:engram
  codegraph:codegraph
  kilow:kilow
  command-code:command-code
  kimchi:kimchi
  omni-route:omni-route
)

for tool in "${ai_tools[@]}"; do
  name="${tool%%:*}"
  bin="${tool##*:}"
  printf '=== %s (%s) ===\n' "$name" "$bin"

  # 1) omni list ai
  list_clean=$(omni list ai 2>&1 | sed 's/\x1b\[[0-9;]*m//g')
  if printf '%s' "$list_clean" | grep -qi "$bin"; then
    record PASS "$name listed in omni list ai"
  else
    record FAIL "$name missing in omni list ai"
  fi

  # 2) omni ia routes
  routes_clean=$(omni ia routes 2>&1 | sed 's/\x1b\[[0-9;]*m//g')
  if printf '%s' "$routes_clean" | grep -qi "$bin"; then
    record PASS "$name present in omni ia routes"
  else
    record FAIL "$name missing in omni ia routes"
  fi

  # 3) binary in PATH
  if command -v "$bin" >/dev/null 2>&1; then
    record PASS "$name binary present"
  else
    record FAIL "$name binary not found"
  fi

  # 4) interface/help smoke test (no TUI open)
  help_out=$(timeout 4 "$bin" --help 2>&1 || timeout 4 "$bin" -h 2>&1 || true)
  if [[ -n "$help_out" ]]; then
    record PASS "$name help/interface responds"
  else
    record FAIL "$name help/interface empty"
  fi
done

# Extra: omni-route dedicated interfaces
if command -v omni-route >/dev/null 2>&1; then
  printf '=== omni-route interfaces ===\n'
  out=$(timeout 4 omni-route list 2>&1 || true)
  if printf '%s' "$out" | grep -qi opencode; then
    record PASS "omni-route list works"
  else
    record FAIL "omni-route list empty"
  fi

  out=$(timeout 4 omni-route show opencode 2>&1 || true)
  if printf '%s' "$out" | grep -qi opencode; then
    record PASS "omni-route show works"
  else
    record FAIL "omni-route show empty"
  fi
else
  record FAIL "omni-route not installed"
fi

printf '\n=== RESULTS ===\n'
for r in "${RESULTS[@]}"; do
  printf '%s\n' "$r"
done
printf '\nPassed: %d/%d\n' "$PASS" "$TOTAL"
printf 'Failed: %d\n' "$FAIL"
exit $(( FAIL > 0 ? 1 : 0 ))