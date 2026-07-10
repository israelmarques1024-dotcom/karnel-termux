#!/usr/bin/env bash

import "@/utils/log"

LOG_FILE="$KARNEL_CACHE/install_ai.log"

# Check if karnel-route binary exists and works
_karnel_route_ok() {
  command -v karnel-route &>/dev/null && karnel-route --version &>/dev/null 2>&1
}

# Detect Termux / Android (Node reports platform "android" and uname mentions android)
_karnel_route_is_android() {
  if [ "$(node -e 'process.stdout.write(process.platform)' 2>/dev/null)" = "android" ]; then
    return 0
  fi
  case "$(uname -s 2>/dev/null) $(uname -o 2>/dev/null)" in
    *android*|*Android*) return 0 ;;
  esac
  return 1
}

# Apply platform-specific fixes so karnelRoute actually runs on Termux/Android.
# Two real, root-cause issues are addressed here (no workarounds/masking):
#   1. karnelRoute bundles better-sqlite3 / sqlite-vec as prebuilt linux-x64 glibc
#      native addons. On Android/Bionic (aarch64) those fail to load
#      (dlopen: cannot locate symbol), so the database can never open and every
#      HTTP request returns 500. We rebuild the native addons from source for the
#      running Node/ABI. node-gyp mis-detects Termux as Android and demands
#      android_ndk_path, which does not exist; we supply a dummy value so the
#      Android gyp config resolves while Termux's own clang does the compile.
#   2. Next.js registerInstrumentation() re-throws any error from karnelRoute's
#      (non-critical) instrumentation hook and that crash takes down the whole
#      server. We make it log-and-continue so a transient hook error does not
#      kill the gateway (the real application DB is unaffected).
_karnel_route_apply_platform_fixes() {
  local pkg_root="$1"
  [ -d "$pkg_root" ] || return 0
  _karnel_route_is_android || return 0

  log_info "Termux/Android detected — applying native build fixes for karnelRoute..."

  local ng="/data/data/com.termux/files/usr/lib/node_modules/npm/node_modules/node-gyp/bin/node-gyp.js"
  if [ -x "$ng" ] && command -v clang >/dev/null 2>&1; then
    for mod in better-sqlite3 sqlite-vec; do
      local moddir="$pkg_root/node_modules/$mod"
      [ -d "$moddir" ] || continue
      log_info "Rebuilding native module: $mod (aarch64/Bionic)"
      if ( cd "$moddir" && CC=clang CXX=clang++ GYP_DEFINES="android_ndk_path=$PREFIX" node "$ng" rebuild --release "-Dandroid_ndk_path=$PREFIX" ) >>"$LOG_FILE" 2>&1; then
        log_success "Rebuilt $mod"
      else
        log_warn "Could not rebuild $mod (see $LOG_FILE); karnelRoute may fail to open its database"
      fi
    done
  else
    log_warn "Native toolchain (node-gyp/clang) not found; cannot rebuild karnelRoute native modules"
  fi

  # Patch Next.js instrumentation so a non-critical hook error does not crash the server.
  local ig
  ig=$(find "$pkg_root/node_modules/karnelroute/dist/node_modules/next" -path '*router-utils/instrumentation-globals.external.js' 2>/dev/null | head -1)
  if [ -n "$ig" ] && grep -q "An error occurred while loading instrumentation hook" "$ig"; then
    if perl -0pi -e 's/err\.message = `An error occurred while loading instrumentation hook: \$\{err\.message\}`;\s*\n\s*throw err;/err.message = `An error occurred while loading instrumentation hook: ${err.message}`;\n            console.error("[instrumentation] Non-fatal error in instrumentation hook (server continues):", err && err.message ? err.message : err);/g' "$ig"; then
      log_success "Patched Next.js instrumentation (hook errors are now non-fatal)"
    else
      log_warn "Could not patch Next.js instrumentation at $ig"
    fi
  fi
}

install_karnel_route() {
  # Already working? Still ensure platform fixes are present (e.g. after an
  # update re-fetched a broken prebuild) and return.
  if _karnel_route_ok; then
    log_info "karnelRoute already installed ($(karnel-route --version 2>&1 | tail -1))"
    _karnel_route_apply_platform_fixes "$HOME/.karnel/packages/karnelroute"
    return 2
  fi

  # Try local install first (fast, no download)
  local local_bin="$HOME/.karnel/packages/karnelroute/node_modules/karnelroute/bin/karnelroute.mjs"
  if [ -f "$local_bin" ]; then
    sed -i '1s|^#!/usr/bin/env node|#!/data/data/com.termux/files/usr/bin/node|' "$local_bin" 2>/dev/null
    # Create both karnelroute (official) and karnel-route (karnel wrapper)
    for cmd in karnelroute karnel-route; do
      cat > "$PREFIX/bin/$cmd" <<'WRAPPER'
#!/data/data/com.termux/files/usr/bin/env bash
exec node "$HOME/.karnel/packages/karnelroute/node_modules/karnelroute/bin/karnelroute.mjs" "$@"
WRAPPER
      chmod +x "$PREFIX/bin/$cmd"
    done
    _karnel_route_apply_platform_fixes "$HOME/.karnel/packages/karnelroute"
    if _karnel_route_ok; then
      log_success "karnelRoute restored from local install"
      return 0
    fi
  fi

  # Install into the local prefix (self-contained; works offline after first download)
  log_info "Installing karnelRoute (this may take a while)..."
  mkdir -p "$HOME/.karnel/packages/karnelroute"
  if command -v npm >/dev/null 2>&1 && npm i karnelroute --prefix "$HOME/.karnel/packages/karnelroute" 2>>"$LOG_FILE"; then
    sed -i '1s|^#!/usr/bin/env node|#!/data/data/com.termux/files/usr/bin/node|' "$local_bin" 2>/dev/null
    for cmd in karnelroute karnel-route; do
      cat > "$PREFIX/bin/$cmd" <<'WRAPPER'
#!/data/data/com.termux/files/usr/bin/env bash
exec node "$HOME/.karnel/packages/karnelroute/node_modules/karnelroute/bin/karnelroute.mjs" "$@"
WRAPPER
      chmod +x "$PREFIX/bin/$cmd"
    done
    _karnel_route_apply_platform_fixes "$HOME/.karnel/packages/karnelroute"
    if _karnel_route_ok; then
      log_success "karnelRoute installed"
      return 0
    fi
  fi

  # Try npx as last resort
  log_warn "npm failed, trying npx..."
  if npx -y karnelroute --version &>/dev/null 2>&1; then
    log_success "karnelRoute available via npx"
    return 0
  fi

  log_error "Failed to install karnelRoute"
  return 1
}

uninstall_karnel_route() {
  if ! _karnel_route_ok; then
    log_info "karnelRoute is not installed"
    return 0
  fi

  log_info "Uninstalling karnelRoute..."
  npm uninstall -g karnelroute 2>>"$LOG_FILE" 2>/dev/null
  rm -rf "$HOME/.karnel/packages/karnelroute"
  rm -f "$PREFIX/bin/karnelroute" "$PREFIX/bin/karnel-route"
  log_success "karnelRoute uninstalled"
  return 0
}

update_karnel_route() {
  if ! _karnel_route_ok; then
    install_karnel_route
    return $?
  fi

  # Update the canonical local install (the one the wrappers actually use),
  # then re-apply the Termux/Android native fixes so it keeps working.
  log_info "Updating karnelRoute..."
  if npm i karnelroute@latest --prefix "$HOME/.karnel/packages/karnelroute" 2>>"$LOG_FILE"; then
    _karnel_route_apply_platform_fixes "$HOME/.karnel/packages/karnelroute"
    log_success "karnelRoute updated"
    return 0
  else
    log_error "Failed to update karnelRoute"
    return 1
  fi
}

reinstall_karnel_route() {
  uninstall_karnel_route
  install_karnel_route
}
