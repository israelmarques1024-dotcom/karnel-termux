#!/usr/bin/env bash
set -eo pipefail

ROOT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
TEST_ROOT=$(mktemp -d)
TESTS_RUN=0
TESTS_FAILED=0

cleanup() {
  rm -rf -- "$TEST_ROOT"
}
trap cleanup EXIT

export HOME="$TEST_ROOT/home"
export XDG_DATA_HOME="$TEST_ROOT/data"
export KARNEL_PATH="$ROOT_DIR/karnel"
mkdir -p "$HOME" "$XDG_DATA_HOME"

source "$KARNEL_PATH/utils/bootstrap.sh"
source "$KARNEL_PATH/utils/env.sh"
source "$KARNEL_PATH/utils/colors.sh"
source "$KARNEL_PATH/utils/log.sh"
source "$KARNEL_PATH/cli/karnel.sh"
source "$KARNEL_PATH/cli/commands/brain.sh"

pass() {
  ((TESTS_RUN += 1))
  printf '  ok:    %s\n' "$1" >&2
}

fail() {
  ((TESTS_FAILED += 1))
  printf '  FAIL:  %s\n' "$1" >&2
}

# ── init: cria o brain local sem gh ────────────────────────────
brain_init >/dev/null 2>&1
if [[ -d "$BRAIN_DIR" ]]; then pass "brain_init cria o diretorio do brain"; else fail "brain_init nao criou $BRAIN_DIR"; fi

# ── brain_save em modo nao-interativo aponta para add ──────────
out=$(brain_save 2>&1 </dev/null || true)
if [[ "$out" == *"karnel brain add"* ]]; then pass "brain_save nao-interativo sugere 'brain add'"; else fail "brain_save nao-interativo nao sugere add"; fi

# ── add: cria memoria em general (padrao) ──────────────────────
brain_add "Fix: o comando brain add foi adicionado" >/dev/null 2>&1
file=$(find "$BRAIN_DIR" -name "*.md" | head -1)
if [[ -n "$file" ]] && grep -q "o comando brain add foi adicionado" "$file"; then pass "brain add salva o texto na memoria"; else fail "brain add nao salvou o texto"; fi

# ── add: categoria e tags via flags ─────────────────────────────
brain_add "Memoria com tags sobre react hooks" --tags react,hooks --category dev >/dev/null 2>&1
devfile=$(find "$BRAIN_DIR/dev" -name "*.md" | head -1)
if [[ -n "$devfile" ]] && grep -q "react, hooks" "$devfile"; then pass "brain add respeita --category/--tags"; else fail "brain add ignora --category/--tags"; fi

# ── slug curto resolve mesmo com prefixo de data ────────────────
short_slug=$(basename "$file" .md | sed 's/^[0-9-]*_//')
if _brain_find_memory "$short_slug" >/dev/null; then pass "_brain_find_memory resolve slug curto"; else fail "_brain_find_memory nao resolve slug curto"; fi

if brain_show "$short_slug" >/dev/null 2>&1; then pass "brain show aceita slug curto"; else fail "brain show rejeitou slug curto"; fi

second_short=$(basename "$devfile" .md | sed 's/^[0-9-]*_//')
if brain_relate "$short_slug" "$second_short" >/dev/null 2>&1; then pass "brain relate aceita slug curto"; else fail "brain relate rejeitou slug curto"; fi

related_both=$(grep -l "related:" "$file" "$devfile" 2>/dev/null | wc -l)
if [[ "$related_both" -eq 2 ]]; then pass "relate grava relacionamentos reciprocos"; else fail "relate nao gravou ambos relacionamentos"; fi

# ── same-day title collisions must never overwrite an existing memory ─────────
brain_add "primeiro conteudo" --title collision >/dev/null 2>&1
collision_file=$(find "$BRAIN_DIR" -name "*_collision.md" | head -1)
if brain_add "segundo conteudo" --title collision >/dev/null 2>&1; then
  fail "brain add sobrescreveu memoria com titulo repetido"
elif [[ -n "$collision_file" ]] && grep -q "primeiro conteudo" "$collision_file"; then
  pass "brain add preserva memoria com titulo repetido"
else
  fail "brain add nao preservou memoria original"
fi

if brain_ls >/dev/null 2>&1; then pass "brain ls lista memorias"; else fail "brain ls falhou"; fi
if brain_search "react" >/dev/null 2>&1; then pass "brain search encontra memorias"; else fail "brain search falhou"; fi

echo
echo "brain: $TESTS_RUN passed, $TESTS_FAILED failed"
[[ "$TESTS_FAILED" -eq 0 ]]
