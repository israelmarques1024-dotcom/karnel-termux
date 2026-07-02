#!/data/data/com.termux/files/usr/bin/bash

# Test script for Omni improvements
set -e

echo "=== Testing Omni Improvements ==="
echo

# Test 1: Colors
echo "1. Testing color definitions..."
source "$(dirname "$0")/core/utils/colors.sh"

# Verify colors are correct ANSI codes
if [[ "$CYAN" == "\e[1;36m" ]]; then
    echo "   ✓ CYAN is correct (light cyan)"
else
    echo "   ✗ CYAN is incorrect: $CYAN"
    exit 1
fi

if [[ "$D_CYAN" == "\e[0;36m" ]]; then
    echo "   ✓ D_CYAN is correct (dark cyan)"
else
    echo "   ✗ D_CYAN is incorrect: $D_CYAN"
    exit 1
fi

# Test 2: Background colors
if [[ "$BG_RED" == "\e[41m" ]]; then
    echo "   ✓ Background colors use ANSI codes"
else
    echo "   ✗ Background colors still use setterm"
    exit 1
fi

echo
echo "2. Testing help output..."
# Capture help output
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
help_output=$(export OMNI_PATH="$SCRIPT_DIR/core" && export OMNI_PATH="$SCRIPT_DIR/core" && source "$SCRIPT_DIR/core/utils/bootstrap.sh" && source "$SCRIPT_DIR/core/utils/env.sh" && source "$SCRIPT_DIR/core/cli/core.sh" && omni_help 2>&1)

if echo "$help_output" | grep -q "OMNI CATALYST"; then
    echo "   ✓ Help shows OMNI CATALYST branding"
else
    echo "   ✗ Help still shows OMNI branding"
    exit 1
fi

if echo "$help_output" | grep -q "core <command>"; then
    echo "   ✓ Help shows core command"
else
    echo "   ✗ Help doesn't show core command"
    exit 1
fi

echo
echo "3. Testing install help..."
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
install_help=$(export OMNI_PATH="$SCRIPT_DIR/core" && export OMNI_PATH="$SCRIPT_DIR/core" && source "$SCRIPT_DIR/core/utils/bootstrap.sh" && source "$SCRIPT_DIR/core/utils/env.sh" && source "$SCRIPT_DIR/core/cli/commands/install.sh" && install_main 2>&1)

if echo "$install_help" | grep -q "Omni Catalyst Install"; then
    echo "   ✓ Install help shows Omni Catalyst"
else
    echo "   ✗ Install help doesn't show Omni Catalyst"
    exit 1
fi

if echo "$install_help" | grep -q "core install"; then
    echo "   ✓ Install help shows core command"
else
    echo "   ✗ Install help doesn't show core command"
    exit 1
fi

echo
echo "=== All tests passed! ==="
echo
echo "Summary of improvements:"
echo "  • Fixed color definitions (CYAN/D_CYAN)"
echo "  • Updated branding to OMNI CATALYST"
echo "  • Added generic install helpers"
echo "  • Updated help to show 'core' command"
echo
echo "Files modified:"
echo "  • core/utils/colors.sh"
echo "  • core/cli/core.sh"
echo "  • core/cli/commands/install.sh"
echo
echo "See IMPROVEMENTS.md for full details."
