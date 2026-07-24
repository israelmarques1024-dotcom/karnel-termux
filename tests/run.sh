#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
cd "$ROOT_DIR"

bash tests/check-syntax.sh
bash tests/smoke.sh
bash tests/robin.sh
bash tests/plugins.sh
