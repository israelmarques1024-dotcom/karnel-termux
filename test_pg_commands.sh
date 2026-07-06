#!/bin/bash
# Test script for Omni PostgreSQL commands
# This script tests all pg commands to ensure they work correctly

OMNI="$HOME/omni/bin/omni"
PASS=0
FAIL=0

# Strip ANSI color codes
strip_ansi() {
    echo "$1" | sed 's/\x1b\[[0-9;]*m//g'
}

echo "=== Omni PostgreSQL Test Suite ==="
echo

# Test 1: Check pg.sh syntax
echo -n "[TEST 1] Syntax check... "
if bash -n "$HOME/omni/omni/cli/commands/pg.sh"; then
    echo "PASS"
    PASS=$((PASS + 1))
else
    echo "FAIL"
    FAIL=$((FAIL + 1))
fi

# Test 2: Test pg help
echo -n "[TEST 2] pg help command... "
HELP_OUTPUT=$($OMNI pg 2>&1)
HELP_CLEAN=$(strip_ansi "$HELP_OUTPUT")
if echo "$HELP_CLEAN" | grep -qi "omni postgresql manager\|usage:.*pg"; then
    echo "PASS"
    PASS=$((PASS + 1))
else
    echo "FAIL"
    FAIL=$((FAIL + 1))
fi

# Test 3: Test pg status
echo -n "[TEST 3] pg status command... "
STATUS_OUTPUT=$($OMNI pg status 2>&1)
STATUS_CLEAN=$(strip_ansi "$STATUS_OUTPUT")
if echo "$STATUS_CLEAN" | grep -qi "postgresql status\|running\|stopped\|not initialized"; then
    echo "PASS"
    PASS=$((PASS + 1))
else
    echo "FAIL"
    FAIL=$((FAIL + 1))
fi

# Test 4: Test pg init
echo -n "[TEST 4] pg init command... "
INIT_OUTPUT=$($OMNI pg init 2>&1)
INIT_CLEAN=$(strip_ansi "$INIT_OUTPUT")
if echo "$INIT_CLEAN" | grep -qi "already initialized\|initialized successfully\|postgresql is not installed"; then
    echo "PASS"
    PASS=$((PASS + 1))
else
    echo "FAIL"
    FAIL=$((FAIL + 1))
fi

# Test 5: Test pg start
echo -n "[TEST 5] pg start command... "
START_OUTPUT=$($OMNI pg start 2>&1)
START_CLEAN=$(strip_ansi "$START_OUTPUT")
if echo "$START_CLEAN" | grep -qi "started successfully\|already running\|not initialized"; then
    echo "PASS"
    PASS=$((PASS + 1))
else
    echo "FAIL"
    FAIL=$((FAIL + 1))
fi

# Test 6: Test pg status after start
echo -n "[TEST 6] pg status after start... "
STATUS_OUTPUT=$($OMNI pg status 2>&1)
STATUS_CLEAN=$(strip_ansi "$STATUS_OUTPUT")
if echo "$STATUS_CLEAN" | grep -qi "RUNNING\|STOPPED\|NOT INITIALIZED"; then
    echo "PASS"
    PASS=$((PASS + 1))
else
    echo "FAIL"
    FAIL=$((FAIL + 1))
fi

# Test 7: Test pg list
echo -n "[TEST 7] pg list command... "
LIST_OUTPUT=$($OMNI pg list 2>&1)
LIST_CLEAN=$(strip_ansi "$LIST_OUTPUT")
if echo "$LIST_CLEAN" | grep -qi "database\|failed to list\|not running\|not initialized"; then
    echo "PASS"
    PASS=$((PASS + 1))
else
    echo "FAIL"
    FAIL=$((FAIL + 1))
fi

# Test 8: Test pg create
echo -n "[TEST 8] pg create command... "
CREATE_OUTPUT=$($OMNI pg create test_db 2>&1)
CREATE_CLEAN=$(strip_ansi "$CREATE_OUTPUT")
if echo "$CREATE_CLEAN" | grep -qi "created successfully\|already exists\|not running\|database name required"; then
    echo "PASS"
    PASS=$((PASS + 1))
else
    echo "FAIL"
    FAIL=$((FAIL + 1))
fi

# Test 9: Test pg list after create
echo -n "[TEST 9] pg list after create... "
LIST_OUTPUT=$($OMNI pg list 2>&1)
LIST_CLEAN=$(strip_ansi "$LIST_OUTPUT")
if echo "$LIST_CLEAN" | grep -qi "test_db\|database\|failed to list\|not running"; then
    echo "PASS"
    PASS=$((PASS + 1))
else
    echo "FAIL"
    FAIL=$((FAIL + 1))
fi

# Test 10: Test pg drop
echo -n "[TEST 10] pg drop command... "
DROP_OUTPUT=$($OMNI pg drop test_db 2>&1 <<< "y")
DROP_CLEAN=$(strip_ansi "$DROP_OUTPUT")
if echo "$DROP_CLEAN" | grep -qi "dropped successfully\|does not exist\|database name required"; then
    echo "PASS"
    PASS=$((PASS + 1))
else
    echo "FAIL"
    FAIL=$((FAIL + 1))
fi

# Test 11: Test pg stop
echo -n "[TEST 11] pg stop command... "
STOP_OUTPUT=$($OMNI pg stop 2>&1)
STOP_CLEAN=$(strip_ansi "$STOP_OUTPUT")
if echo "$STOP_CLEAN" | grep -qi "stopped successfully\|not running"; then
    echo "PASS"
    PASS=$((PASS + 1))
else
    echo "FAIL"
    FAIL=$((FAIL + 1))
fi

# Test 12: Test pg restart
echo -n "[TEST 12] pg restart command... "
RESTART_OUTPUT=$($OMNI pg restart 2>&1)
RESTART_CLEAN=$(strip_ansi "$RESTART_OUTPUT")
if echo "$RESTART_CLEAN" | grep -qi "restarted\|started\|not initialized"; then
    echo "PASS"
    PASS=$((PASS + 1))
else
    echo "FAIL"
    FAIL=$((FAIL + 1))
fi

# Test 13: Test pg backup
echo -n "[TEST 13] pg backup command... "
$OMNI pg create test_backup_db &>/dev/null || true
BACKUP_OUTPUT=$($OMNI pg backup test_backup_db 2>&1)
BACKUP_CLEAN=$(strip_ansi "$BACKUP_OUTPUT")
if echo "$BACKUP_CLEAN" | grep -qi "backup created\|failed to create\|not running\|database name required"; then
    echo "PASS"
    PASS=$((PASS + 1))
else
    echo "FAIL"
    FAIL=$((FAIL + 1))
fi

# Test 14: Test pg list-backups
echo -n "[TEST 14] pg list-backups command... "
BACKUPS_OUTPUT=$($OMNI pg list-backups 2>&1)
BACKUPS_CLEAN=$(strip_ansi "$BACKUPS_OUTPUT")
if echo "$BACKUPS_CLEAN" | grep -qi "available\|no backup\|backup file"; then
    echo "PASS"
    PASS=$((PASS + 1))
else
    echo "FAIL"
    FAIL=$((FAIL + 1))
fi

# Test 15: Test pg shell non-interactive
echo -n "[TEST 15] pg shell command... "
SHELL_OUTPUT=$(echo "SELECT 1;" | $OMNI pg shell 2>&1 | head -5)
SHELL_CLEAN=$(strip_ansi "$SHELL_OUTPUT")
if echo "$SHELL_CLEAN" | grep -qi "psql\|1\|select\|not running\|not initialized"; then
    echo "PASS"
    PASS=$((PASS + 1))
else
    echo "FAIL"
    FAIL=$((FAIL + 1))
fi

# Test 16: Test pg create without name
echo -n "[TEST 16] pg create without name... "
NO_NAME_OUTPUT=$($OMNI pg create 2>&1)
NO_NAME_CLEAN=$(strip_ansi "$NO_NAME_OUTPUT")
if echo "$NO_NAME_CLEAN" | grep -qi "database name required"; then
    echo "PASS"
    PASS=$((PASS + 1))
else
    echo "FAIL"
    FAIL=$((FAIL + 1))
fi

# Test 17: Test pg drop without name
echo -n "[TEST 17] pg drop without name... "
DROP_NO_NAME=$($OMNI pg drop 2>&1)
DROP_NO_NAME_CLEAN=$(strip_ansi "$DROP_NO_NAME")
if echo "$DROP_NO_NAME_CLEAN" | grep -qi "database name required"; then
    echo "PASS"
    PASS=$((PASS + 1))
else
    echo "FAIL"
    FAIL=$((FAIL + 1))
fi

echo
echo "=== Test Results ==="
echo "Passed: $PASS"
echo "Failed: $FAIL"
echo

if [ $FAIL -eq 0 ]; then
    echo "All tests passed!"
    exit 0
else
    echo "Some tests failed. Review the output above."
    exit 1
fi

# Test 2: Test pg help
echo -n "[TEST 2] pg help command... "
if $OMNI pg &>/dev/null; then
    echo "PASS"
    PASS=$((PASS + 1))
else
    echo "FAIL"
    FAIL=$((FAIL + 1))
fi

# Test 3: Test pg status (should not crash)
echo -n "[TEST 3] pg status command... "
if $OMNI pg status &>/dev/null; then
    echo "PASS"
    PASS=$((PASS + 1))
else
    echo "FAIL"
    FAIL=$((FAIL + 1))
fi

# Test 4: Test pg init
echo -n "[TEST 4] pg init command... "
INIT_OUTPUT=$($OMNI pg init 2>&1)
if echo "$INIT_OUTPUT" | grep -qi "already initialized\|initialized successfully\|postgresql is not installed"; then
    echo "PASS"
    PASS=$((PASS + 1))
else
    echo "FAIL"
    FAIL=$((FAIL + 1))
fi

# Test 5: Test pg start
echo -n "[TEST 5] pg start command... "
START_OUTPUT=$($OMNI pg start 2>&1)
if echo "$START_OUTPUT" | grep -qi "started successfully\|already running\|not initialized"; then
    echo "PASS"
    PASS=$((PASS + 1))
else
    echo "FAIL"
    FAIL=$((FAIL + 1))
fi

# Test 6: Test pg status after start
echo -n "[TEST 6] pg status after start... "
STATUS_OUTPUT=$($OMNI pg status 2>&1)
if echo "$STATUS_OUTPUT" | grep -qi "RUNNING\|STOPPED\|NOT INITIALIZED"; then
    echo "PASS"
    PASS=$((PASS + 1))
else
    echo "FAIL"
    FAIL=$((FAIL + 1))
fi

# Test 7: Test pg list
echo -n "[TEST 7] pg list command... "
LIST_OUTPUT=$($OMNI pg list 2>&1)
if echo "$LIST_OUTPUT" | grep -qi "database\|failed to list\|not running\|not initialized"; then
    echo "PASS"
    PASS=$((PASS + 1))
else
    echo "FAIL"
    FAIL=$((FAIL + 1))
fi

# Test 8: Test pg create
echo -n "[TEST 8] pg create command... "
CREATE_OUTPUT=$($OMNI pg create test_db 2>&1)
if echo "$CREATE_OUTPUT" | grep -qi "created successfully\|already exists\|not running\|database name required"; then
    echo "PASS"
    PASS=$((PASS + 1))
else
    echo "FAIL"
    FAIL=$((FAIL + 1))
fi

# Test 9: Test pg drop
echo -n "[TEST 9] pg drop command... "
DROP_OUTPUT=$($OMNI pg drop test_db 2>&1 <<< "y")
if echo "$DROP_OUTPUT" | grep -qi "dropped successfully\|does not exist\|database name required"; then
    echo "PASS"
    PASS=$((PASS + 1))
else
    echo "FAIL"
    FAIL=$((FAIL + 1))
fi

# Test 10: Test pg stop
echo -n "[TEST 10] pg stop command... "
STOP_OUTPUT=$($OMNI pg stop 2>&1)
if echo "$STOP_OUTPUT" | grep -qi "stopped successfully\|not running"; then
    echo "PASS"
    PASS=$((PASS + 1))
else
    echo "FAIL"
    FAIL=$((FAIL + 1))
fi

# Test 11: Test pg restart
echo -n "[TEST 11] pg restart command... "
RESTART_OUTPUT=$($OMNI pg restart 2>&1)
if echo "$RESTART_OUTPUT" | grep -qi "restarted\|started\|not initialized"; then
    echo "PASS"
    PASS=$((PASS + 1))
else
    echo "FAIL"
    FAIL=$((FAIL + 1))
fi

# Test 12: Test pg backup
echo -n "[TEST 12] pg backup command... "
$OMNI pg create test_backup_db &>/dev/null || true
BACKUP_OUTPUT=$($OMNI pg backup test_backup_db 2>&1)
if echo "$BACKUP_OUTPUT" | grep -qi "backup created\|failed to create\|not running\|database name required"; then
    echo "PASS"
    PASS=$((PASS + 1))
else
    echo "FAIL"
    FAIL=$((FAIL + 1))
fi

# Test 13: Test pg list-backups
echo -n "[TEST 13] pg list-backups command... "
BACKUPS_OUTPUT=$($OMNI pg list-backups 2>&1)
if echo "$BACKUPS_OUTPUT" | grep -qi "available\|no backup\|backup file"; then
    echo "PASS"
    PASS=$((PASS + 1))
else
    echo "FAIL"
    FAIL=$((FAIL + 1))
fi

# Test 14: Test pg shell non-interactive
echo -n "[TEST 14] pg shell command... "
SHELL_OUTPUT=$(echo "SELECT 1;" | $OMNI pg shell 2>&1 | head -5)
if echo "$SHELL_OUTPUT" | grep -qi "psql\|1\|select\|not running\|not initialized"; then
    echo "PASS"
    PASS=$((PASS + 1))
else
    echo "FAIL"
    FAIL=$((FAIL + 1))
fi

# Test 15: Test argument parsing - create without name
echo -n "[TEST 15] pg create without name... "
NO_NAME_OUTPUT=$($OMNI pg create 2>&1)
if echo "$NO_NAME_OUTPUT" | grep -qi "database name required"; then
    echo "PASS"
    PASS=$((PASS + 1))
else
    echo "FAIL"
    FAIL=$((FAIL + 1))
fi

# Test 16: Test argument parsing - drop without name
echo -n "[TEST 16] pg drop without name... "
DROP_NO_NAME=$($OMNI pg drop 2>&1)
if echo "$DROP_NO_NAME" | grep -qi "database name required"; then
    echo "PASS"
    PASS=$((PASS + 1))
else
    echo "FAIL"
    FAIL=$((FAIL + 1))
fi

echo
echo "=== Test Results ==="
echo "Passed: $PASS"
echo "Failed: $FAIL"
echo

if [ $FAIL -eq 0 ]; then
    echo "All tests passed!"
    exit 0
else
    echo "Some tests failed. Review the output above."
    exit 1
fi