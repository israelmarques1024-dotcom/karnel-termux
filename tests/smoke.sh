#!/usr/bin/env bash
# shellcheck disable=SC1091
set -eo pipefail

PASS=0
FAIL=0

pass() { PASS=$((PASS + 1)); }
fail() { FAIL=$((FAIL + 1)); echo "  FAIL: $1"; }

echo "=== Karnel Smoke Tests ==="
echo

# 1. version.sh parses correctly
echo "1) version.sh loads without error"
if KARNEL_PATH="$PWD/karnel" source karnel/utils/env.sh 2>/dev/null; then
  if [[ -n "$KARNEL_VERSION" ]]; then
    pass
  else
    fail "KARNEL_VERSION is empty"
  fi
else
  fail "env.sh failed to source"
fi

# 2. bootstrap.sh loads without error
echo "2) bootstrap.sh loads without error"
if source karnel/utils/bootstrap.sh 2>/dev/null; then
  pass
else
  fail "bootstrap.sh failed to source"
fi

# 3. log.sh loads without error
echo "3) log.sh loads without error"
if KARNEL_PATH="$PWD/karnel" source karnel/utils/log.sh 2>/dev/null; then
  pass
else
  fail "log.sh failed to source"
fi

# 4. colors.sh loads without error
echo "4) colors.sh loads without error"
if source karnel/utils/colors.sh 2>/dev/null; then
  pass
else
  fail "colors.sh failed to source"
fi

# 5. AI tools registry loads without error (syntax check)
echo "5) AI tools registry syntax check"
if bash -n karnel/tools/ai/all.sh 2>/dev/null; then
  pass
else
  fail "ai/all.sh has syntax errors"
fi

# 6. All module files have valid syntax
echo "6) All module files syntax check"
for mod in karnel/modules/*.sh; do
  if ! bash -n "$mod" 2>/dev/null; then
    fail "$mod has syntax errors"
    continue 2
  fi
done
pass

# 7. All CLI command files have valid syntax
echo "7) All CLI command files syntax check"
for cmd in karnel/cli/commands/*.sh; do
  if ! bash -n "$cmd" 2>/dev/null; then
    fail "$cmd has syntax errors"
    continue 2
  fi
done
pass

# 8. install.sh syntax check
echo "8) install.sh syntax check"
if bash -n install.sh 2>/dev/null; then
  pass
else
  fail "install.sh has syntax errors"
fi

# 9. All tool all.sh orchestrators syntax check
echo "9) Tool orchestrators syntax check"
for all in karnel/tools/*/all.sh; do
  if ! bash -n "$all" 2>/dev/null; then
    fail "$all has syntax errors"
    continue 2
  fi
done
pass

# 10. Version consistency check
echo "10) Version consistency check"
PKG_VERSION=$(grep '"version"' package.json | head -1 | cut -d'"' -f4)
ENV_VERSION=$(grep '^KARNEL_VERSION=' karnel/utils/env.sh | cut -d'"' -f2)
if [[ "$PKG_VERSION" == "$ENV_VERSION" ]]; then
  pass
else
  fail "package.json version ($PKG_VERSION) != env.sh version ($ENV_VERSION)"
fi

# 11. Doctor modules have valid syntax
echo "11) Doctor module syntax check"
doctor_syntax_ok=true
for cmd in karnel/cli/commands/doctor/*.sh; do
  if ! bash -n "$cmd" 2>/dev/null; then
    fail "$cmd has syntax errors"
    doctor_syntax_ok=false
  fi
done
$doctor_syntax_ok && pass

# 12. Doctor registry preserves commands containing pipes
echo "12) Doctor tool registry parser"
source karnel/cli/commands/doctor/code_langs.sh
_init_lang_tools
entry="${LANG_TOOLS["Rust:cargo_check"]}"
_parse_lang_tool "$entry"
if [[ ${#LANG_TOOLS[@]} -eq 76 && "${PARSED_LANG_TOOL[0]}" == "cargo" && "${PARSED_LANG_TOOL[1]}" == "syntax" && "${PARSED_LANG_TOOL[2]}" == *"| tail -5"* && -z "${PARSED_LANG_TOOL[3]}" && "${PARSED_LANG_TOOL[5]}" == "official" ]]; then
  pass
else
  fail "doctor registry parsing is inconsistent"
fi

# 13. Doctor modes select the expected registry definitions
echo "13) Doctor mode registry counts"
count_mode() {
  local mode="$1" count=0 registry_entry registry_category
  for registry_entry in "${LANG_TOOLS[@]}"; do
    _parse_lang_tool "$registry_entry"
    registry_category="${PARSED_LANG_TOOL[1]}"
    case "$mode:$registry_category" in
      quick:syntax|quick:format|quick:lint|quick:lint+format|quick:type-check|quick:test|\
      standard:syntax|standard:format|standard:lint|standard:lint+format|standard:type-check|standard:test|\
      standard:security|standard:deps|standard:coverage|standard:dead-code|standard:complexity|deep:*)
        count=$((count + 1)) ;;
    esac
  done
  printf '%d' "$count"
}
if [[ "$(count_mode quick)" == "64" && "$(count_mode standard)" == "74" && "$(count_mode deep)" == "76" ]]; then
  pass
else
  fail "doctor mode registry counts changed unexpectedly"
fi

# 14. Hidden GitHub workflows and scoped frameworks are detected
echo "14) Doctor project detection"
fixture=$(mktemp -d)
mkdir -p "$fixture/.github/workflows"
printf '%s\n' '{"dependencies":{"@nestjs/core":"latest","typescript":"latest"}}' > "$fixture/package.json"
printf '%s\n' 'name: ci' > "$fixture/.github/workflows/ci.yml"
printf '%s\n' 'pytest' > "$fixture/requirements-dev.txt"
source karnel/cli/commands/doctor/code_detect.sh
_detect_project "$fixture"
langs=" ${PROJECT_LANGS[*]} "
frameworks=" ${PROJECT_FRAMEWORKS[*]} "
rm -rf "$fixture"
if [[ "$langs" == *" JavaScript "* && "$langs" == *" TypeScript "* && "$langs" == *" Python "* && "$langs" == *" GitHub Actions "* && "$frameworks" == *" JavaScript:NestJS "* ]]; then
  pass
else
  fail "doctor project detection missed a supported ecosystem"
fi

echo
echo "=== Results: $PASS passed, $FAIL failed ==="
[[ $FAIL -eq 0 ]] || exit 1
