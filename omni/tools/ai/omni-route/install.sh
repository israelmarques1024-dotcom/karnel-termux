#!/usr/bin/env bash

import "@/utils/log"

LOG_FILE="$OMNI_CACHE/install_ai.log"

# Patch playwright-core for Termux/Android compatibility
# playwright-core throws "Unsupported platform: android" which crashes the server
_patch_playwright_core() {
  local bundle_path="$HOME/.omni/packages/omniroute/node_modules/omniroute/dist/node_modules/playwright-core/lib/coreBundle.js"
  [ -f "$bundle_path" ] || return 0

  # Replace 3x "throw new Error(...)" with "return HOME/.cache"
  python3 -c "
import sys
path = '$bundle_path'
with open(path, 'r') as f:
    c = f.read()
old = 'throw new Error(\"Unsupported platform: \" + process.platform);'
if old in c:
    c = c.replace(old, 'return process.env.HOME + \"/.cache\";')
    with open(path, 'w') as f:
        f.write(c)
    print('Playwright-core patched for Termux')
    sys.exit(0)
print('Playwright-core already patched')
" 2>&1 || true
}

_install_omni_route_impl() {
  mkdir -p "$PREFIX/bin"

  # Smart wrapper: local install first, fallback to npm install, last resort npx
  cat > "$PREFIX/bin/omni-route" <<'WRAPPER'
#!/data/data/com.termux/files/usr/bin/env bash
set -euo pipefail

OMNIROUTE_DIR="$HOME/.omni/packages/omniroute/node_modules/omniroute"
OMNIROUTE_BIN="$OMNIROUTE_DIR/bin/omniroute.mjs"

# Try local install first (fast, no download)
if [ -f "$OMNIROUTE_BIN" ]; then
  # Re-patch playwright-core after every npm update
  BUNDLE="$OMNIROUTE_DIR/dist/node_modules/playwright-core/lib/coreBundle.js"
  if [ -f "$BUNDLE" ] && grep -q 'throw new Error.*Unsupported platform' "$BUNDLE" 2>/dev/null; then
    python3 -c "
import sys
with open('$BUNDLE', 'r') as f:
    c = f.read()
c = c.replace('throw new Error(\"Unsupported platform: \" + process.platform);', 'return process.env.HOME + \"/.cache\";')
with open('$BUNDLE', 'w') as f:
    f.write(c)
" 2>/dev/null || true
  fi
  exec node "$OMNIROUTE_BIN" "$@"
fi

# Fallback: install locally then run
echo "Installing omniroute locally (first run)..." >&2
mkdir -p "$HOME/.omni/packages/omniroute"
cd "$HOME/.omni/packages/omniroute"
npm init -y >/dev/null 2>&1
npm install omniroute --ignore-scripts >/dev/null 2>&1

if [ -f "$OMNIROUTE_BIN" ]; then
  # Fix shebang for Termux
  sed -i '1s|^#!/usr/bin/env node|#!/data/data/com.termux/files/usr/bin/node|' "$OMNIROUTE_BIN"
  # Patch playwright-core for Termux
  BUNDLE="$OMNIROUTE_DIR/dist/node_modules/playwright-core/lib/coreBundle.js"
  if [ -f "$BUNDLE" ] && grep -q 'throw new Error.*Unsupported platform' "$BUNDLE" 2>/dev/null; then
    python3 -c "
import sys
with open('$BUNDLE', 'r') as f:
    c = f.read()
c = c.replace('throw new Error(\"Unsupported platform: \" + process.platform);', 'return process.env.HOME + \"/.cache\";')
with open('$BUNDLE', 'w') as f:
    f.write(c)
" 2>/dev/null || true
  fi
  echo "omniRoute installed successfully!" >&2
  exec node "$OMNIROUTE_BIN" "$@"
fi

# Last resort: npx (slow, downloads each time)
exec npx omniroute "$@"
WRAPPER

  chmod +x "$PREFIX/bin/omni-route"
  log_success "omniRoute installed"
}

install_omni_route() {
  if command -v omni-route &>/dev/null; then
    log_info "omniRoute already installed"
    return 2
  fi
  log_info "Installing omniRoute..."
  _install_omni_route_impl
}

uninstall_omni_route() {
  rm -f "$PREFIX/bin/omni-route"
  log_success "omniRoute uninstalled"
}

update_omni_route() {
  log_info "Updating omniroute..."
  mkdir -p "$HOME/.omni/packages/omniroute"
  cd "$HOME/.omni/packages/omniroute"
  npm update omniroute --ignore-scripts 2>&1 || true

  # Re-patch playwright-core after npm update (npm overwrites node_modules)
  _patch_playwright_core

  # Reinstall wrapper in case PREFIX changed
  _install_omni_route_impl
  log_success "omniRoute updated"
}

reinstall_omni_route() {
  uninstall_omni_route
  install_omni_route
}

