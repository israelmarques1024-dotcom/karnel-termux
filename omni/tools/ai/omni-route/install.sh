#!/usr/bin/env bash

import "@/utils/log"

LOG_FILE="$OMNI_CACHE/install_ai.log"

_install_omni_route_impl() {
  mkdir -p "$PREFIX/bin"
  cat > "$PREFIX/bin/omni-route" <<'EOS'
#!/data/data/com.termux/files/usr/bin/env bash
set -euo pipefail

OMNIROUTE_PORT="${OMNIROUTE_PORT:-7331}"

usage() {
  cat <<'USAGE'
omniRoute - AI CLI routes manager

Usage:
  omni-route list          List installed AI CLIs
  omni-route start         Start web interface (localhost:7331)
  omni-route stop          Stop web interface
  omni-route status        Check interface status
  omni-route --help        Show this help
USAGE
}

get_installed_clis() {
  IFS=$'\n'
  for bin in $(command -v opencode claude codex qwen vibe hermes kimi ollama odysseus openclaw freebuff pi agy mmx gentle-ai gga engram codegraph kilow command-code kimchi 2>/dev/null || true); do
    [ -n "$bin" ] && echo "$bin"
  done | sort
}

start_server() {
  if pgrep -f "server.py" > /dev/null 2>&1; then
    echo "omniRoute already running at http://localhost:${OMNIROUTE_PORT}"
    return 0
  fi
  
  OMNI_WEB_DIR="${OMNI_WEB_DIR:-${HOME}/.local/share/omni-route/web}"
  
  if [ -d "$OMNI_WEB_DIR" ]; then
    cd "$OMNI_WEB_DIR"
    nohup python3 server.py > /dev/null 2>&1 &
    sleep 1
    echo "omniRoute started at http://localhost:${OMNIROUTE_PORT}"
  else
    echo "Web UI files missing. Reinstall with 'omni install ai --omni-route'."
    return 1
  fi
}

stop_server() {
  pkill -f "server.py" 2>/dev/null || true
  echo "omniRoute stopped"
}

status_server() {
  if pgrep -f "server.py" > /dev/null 2>&1; then
    echo "omniRoute is running"
    echo "Interface: http://localhost:${OMNIROUTE_PORT}"
  else
    echo "omniRoute is not running"
  fi
}

cmd="${1:-}"
shift || true

case "$cmd" in
  list)
    get_installed_clis
    ;;
  start)
    start_server
    ;;
  stop)
    stop_server
    ;;
  status)
    status_server
    ;;
  -h|--help|help|"")
    usage
    ;;
  *)
    echo "Unknown command: $cmd"
    usage
    return 1
    ;;
esac
EOS
  chmod +x "$PREFIX/bin/omni-route"
  
  # Create web interface directory
  mkdir -p "${HOME}/.local/share/omni-route/web"
  cat > "${HOME}/.local/share/omni-route/web/server.py" << 'PYEOF'
#!/usr/bin/env python3
import subprocess, os, http.server, socketserver
from urllib.parse import urlparse

PORT = int(os.environ.get('OMNIROUTE_PORT', 7331))

CLIS = [
    ("opencode", "OpenCode", "💻", "Multi-provider AI"),
    ("claude", "Claude", "🔷", "Anthropic AI"),
    ("codex", "OpenAI Codex", "🌐", "OpenAI CLI"),
    ("qwen", "Qwen Code", "🖥", "Alibaba AI"),
    ("hermes", "Hermes", "🦅", "Persistent agent"),
    ("odysseus", "Odysseus", "⚡", "AI workspace"),
    ("ollama", "Ollama", "🦙", "Local LLM"),
    ("gemini", "Gemini", "💎", "Google AI"),
]

def get_installed():
    result = {}
    for cli in CLIS:
        result[cli[0]] = subprocess.run(['which', cli[0]], capture_output=True).returncode == 0
    return result

HTML_HEAD = '''<!DOCTYPE html><html lang="en"><head>
<meta charset="UTF-8"><meta name="viewport" content="width=device-width, initial-scale=1">
<title>omniRoute</title>
<style>
*{{margin:0;padding:0;box-sizing:border-box}}
body{{font-family:monospace;background:linear-gradient(135deg,#0a0a0f,#1a1a2e);color:#fff;min-height:100vh;padding:40px}}
.container{{max-width:800px;margin:0 auto}}
h1{{text-align:center;margin-bottom:40px}}
.grid{{display:grid;gap:12px}}
.card{{background:rgba(255,255,255,0.05);border:1px solid rgba(255,255,255,0.1);border-radius:12px;padding:16px;display:flex;align-items:center;gap:12px}}
.info{{flex:1}}
.name{{font-weight:bold}}
.desc{{color:#888;font-size:0.85rem}}
.installed{{background:#00c853;color:#000;padding:3px 10px;border-radius:12px;font-size:0.75rem}}
.not{{background:#666;padding:3px 10px;border-radius:12px;font-size:0.75rem}}
.run{{padding:6px 12px;background:#00d4ff;border:none;border-radius:6px;color:#000;font-weight:bold;cursor:pointer}}
.run[disabled]{{background:#444;cursor:not-allowed}}
</style>
</head><body><div class="container"><h1><span style="color:#00d4ff">omni</span>Route</h1>
<div class="grid">'''

def generate_cards():
    installed = get_installed()
    cards_html = ''
    for cli, name, icon, desc in CLIS:
        st_class = "installed" if installed[cli] else "not"
        st_text = "Installed" if installed[cli] else "Not Installed"
        disabled = ' disabled' if not installed[cli] else ''
        cards_html += '<div class="card"><div style="font-size:1.5rem">' + icon + '</div><div class="info"><div class="name">' + name + ' <code>' + cli + '</code></div><div class="desc">' + desc + '</div></div><span class="' + st_class + '">' + st_text + '</span><button class="run"' + disabled + ' onclick="runCli(\'' + cli + '\')">Run</button></div>'
    return cards_html

class H(http.server.SimpleHTTPRequestHandler):
    def do_GET(self):
        p = urlparse(self.path).path
        if p == '/':
            self.send_response(200); self.send_header('Content-type', 'text/html'); self.end_headers()
            self.wfile.write((HTML_HEAD + generate_cards() + '</div></body></html>').encode())
        elif p.startswith('/run/'):
            subprocess.Popen([p[5:]], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, stdin=subprocess.DEVNULL)
            self.send_response(200); self.end_headers()
        else: self.send_response(404); self.end_headers()
    def log_message(self, *a): pass

if __name__ == '__main__':
    print(f"omniRoute: http://localhost:{PORT}")
    with socketserver.TCPServer(("", PORT), H) as httpd: httpd.serve_forever()
PYEOF
  chmod +x "${HOME}/.local/share/omni-route/web/server.py"
  
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
  rm -rf "${HOME}/.local/share/omni-route"
  pkill -f "server.py" 2>/dev/null || true
  log_success "omniRoute uninstalled"
}

update_omni_route() {
  log_info "omniRoute updated"
}

reinstall_omni_route() {
  uninstall_omni_route
  install_omni_route
}