#!/usr/bin/env bash

# Shared npm shebang repair for Termux.
# Rewrites `#!/usr/bin/env <interp>` shebangs of npm-installed bins to the
# absolute Termux interpreter path. Safe to call on any bin name.

_fix_npm_shebang() {
  local bin_name="$1"
  local bin_path="$PREFIX/bin/$bin_name"
  [ ! -f "$bin_path" ] && [ ! -L "$bin_path" ] && return 0

  local real_path
  real_path=$(readlink -f "$bin_path" 2>/dev/null || echo "$bin_path")
  [ ! -f "$real_path" ] && return 0

  local shebang
  shebang=$(head -1 "$real_path")

  case "$shebang" in
    "#!/usr/bin/env node"|"#!/data/data/com.termux/files/usr/bin/env node"|"#!$PREFIX/bin/env node")
      sed -i "1s|.*|#!$PREFIX/bin/node|" "$real_path" || return 1
      log_info "Fixed shebang for $bin_name: $shebang → $PREFIX/bin/node"
      ;;
    "#!/usr/bin/env bash"|"#!/data/data/com.termux/files/usr/bin/env bash"|"#!$PREFIX/bin/env bash")
      sed -i "1s|.*|#!$PREFIX/bin/bash|" "$real_path" || return 1
      log_info "Fixed shebang for $bin_name: $shebang → $PREFIX/bin/bash"
      ;;
  esac
  return 0
}
