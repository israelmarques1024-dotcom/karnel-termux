#!/usr/bin/env bash
selections=$(dialog --clear --checklist "Select:" 20 65 12 "opt1" "Option 1" OFF 2>&1 >/dev/null)
echo "SELECTIONS: '$selections'"
