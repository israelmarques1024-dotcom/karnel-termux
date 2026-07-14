#!/usr/bin/env bash
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
  [[ -n "$KARNEL_VERSION" ]] && pass || fail "KARNEL_VERSION is empty"
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

echo
echo "=== Results: $PASS passed, $FAIL failed ==="
[[ $FAIL -eq 0 ]] || exit 1
