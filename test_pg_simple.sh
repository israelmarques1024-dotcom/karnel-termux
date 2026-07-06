#!/bin/bash
# Minimal test script for Omni PostgreSQL commands

OMNI="$HOME/omni/bin/omni"
PASS=0
FAIL=0

strip_ansi() {
    echo "$1" | sed 's/\x1b\[[0-9;]*m//g'
}

echo "=== Omni PostgreSQL Test Suite ==="
echo

for test_name in "help" "status" "init" "start" "stop" "restart" "list" "shell" "list-backups" "create" "drop" "backup"; do
    echo -n "[TEST] omni pg $test_name ... "
    OUTPUT=$($OMNI pg "$test_name" 2>&1 || true)
    CLEAN=$(strip_ansi "$OUTPUT")
    if [[ -n "$CLEAN" ]]; then
        echo "OK"
        PASS=$((PASS + 1))
    else
        echo "FAIL (empty output)"
        FAIL=$((FAIL + 1))
    fi
done

echo
echo "=== Results ==="
echo "Passed: $PASS"
echo "Failed: $FAIL"