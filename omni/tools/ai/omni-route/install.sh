#!/usr/bin/env bash

import "@/utils/log"
import "@/utils/colors"

LOG_FILE="$OMNI_CACHE/install_ai.log"
OMNIROUTE_HOME="$HOME/.local/share/omni-route"

_install_omni_route_impl() {
  mkdir -p "$OMNIROUTE_HOME"
  mkdir -p "$PREFIX/bin"

  # Create Python web interface
  cat > "$OMNIROUTE_HOME/omni_route.py" << 'PYEOF'
#!/usr/bin/env python3
import subprocess
import json
import os
from flask import Flask, render_template_string

app = Flask(__name__)
PORT = 7331

CLIS = [
    ("opencode", "OpenCode", "💻", "Multi-provider AI coding assistant"),
    ("claude", "Claude", "� orange", "Anthropic Claude AI"),
    ("codex", "OpenAI Codex", "🌐", "OpenAI coding assistant"),
    ("qwen", "Qwen Code", "🖥", "Alibaba Qwen AI"),
    ("hermes", "Hermes Agent", "🦅", "Persistent AI agent"),
    ("odysseus", "Odysseus", "⚡", "Self-hosted AI workspace"),
    ("openclaw", "OpenClaw", "🐾", "Persistent AI assistant"),
    ("freebuff", "Freebuff", "🆓", "Free AI with ads"),
    ("ollama", "Ollama", "🦙", "Local LLM runner"),
    ("gemini", "Gemini CLI", "💎", "Google Gemini AI"),
    ("kilow", "KiloW", "🔷", "Kilo Code CLI"),
]

HTML = '''
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>omniRoute - AI CLI Manager</title>
  <style>
    * { margin: 0; padding: 0; box-sizing: border-box; }
    body { 
      font-family: 'JetBrains Mono', monospace; 
      background: linear-gradient(135deg, #0a0a0f, #1a1a2e);
      color: #fff; min-height: 100vh; padding: 40px 20px;
    }
    .container { max-width: 800px; margin: 0 auto; }
    h1 { text-align: center; margin-bottom: 40px; font-size: 2.5rem; }
    h1 span { color: #00d4ff; }
    .grid { display: grid; gap: 16px; }
    .card {
      background: rgba(255,255,255,0.05); border: 1px solid rgba(255,255,255,0.1);
      border-radius: 12px; padding: 20px; display: flex; align-items: center; gap: 16px;
    }
    .icon { font-size: 2rem; }
    .info { flex: 1; }
    .name { font-weight: bold; font-size: 1.1rem; }
    .desc { color: #888; font-size: 0.9rem; }
    .status { padding: 4px 12px; border-radius: 20px; font-size: 0.8rem; }
    .installed { background: #00c853; }
    .not-installed { background: #666; }
    .run-btn { 
      padding: 8px 16px; background: #00d4ff; border: none; border-radius: 6px;
      color: #000; font-weight: bold; cursor: pointer;
    }
    .run-btn:disabled { background: #444; cursor: not-allowed; }
  </style>
</head>
<body>
  <div class="container">
    <h1><span>omni</span>Route - AI CLI Manager</h1>
    <div class="grid">
    {% for cli, name, icon, desc in clis %}
      <div class="card">
        <div class="icon">{{ icon }}</div>
        <div class="info">
          <div class="name">{{ name }} <code>{{ cli }}</code></div>
          <div class="desc">{{ desc }}</div>
        </div>
        <span class="status {{ 'installed' if installed[cli] else 'not-installed' }}">{{ 'Installed' if installed[cli] else 'Not Installed' }}</span>
        <button class="run-btn" {% if not installed[cli] %}disabled{% endif %} onclick="runCli('{{ cli }}')">Run</button>
      </div>
    {% endfor %}
    </div>
  </div>
  <script>
    function runCli(cli) {
      fetch('/run/' + cli).then(() => location.reload());
    }
  </script>
</body>
</html>
'''

def get_installed():
    installed = {}
    for cli, _, _, _ in CLIS:
        installed[cli] = subprocess.run(['which', cli], capture_output=True).returncode == 0
    return installed

@app.route('/')
def index():
    return render_template_string(HTML, clis=CLIS, installed=get_installed())

@app.route('/run/<cli>')
def run_cli(cli):
    subprocess.Popen([cli], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, stdin=subprocess.DEVNULL)
    return '', 204

if __name__ == '__main__':
    print(f"omniRoute running at http://localhost:{PORT}")
    app.run(host='0.0.0.0', port=PORT)
PYEOF

  # Create wrapper script
  cat > "$PREFIX/bin/omni-route" << 'EOS'
#!/data/data/com.termux/files/usr/bin/bash
set -e

OMNIROUTE_PORT="${OMNIROUTE_PORT:-7331}"
OMNIROUTE_HOME="${HOME}/.local/share/omni-route"

start() {
  if pgrep -f "python.*omni_route.py" > /dev/null 2>&1; then
    echo "omniRoute already running"
    echo "Interface: http://localhost:${OMNIROUTE_PORT}"
    return 0
  fi
  
  cd "$OMNIROUTE_HOME"
  nohup python3 omni_route.py > /dev/null 2>&1 &
  
  sleep 2
  echo "omniRoute started"
  echo "Interface: http://localhost:${OMNIROUTE_PORT}"
}

stop() {
  pkill -f "python.*omni_route.py" 2>/dev/null || true
  echo "omniRoute stopped"
}

status() {
  if pgrep -f "python.*omni_route.py" > /dev/null 2>&1; then
    echo "omniRoute is running"
    echo "Interface: http://localhost:${OMNIROUTE_PORT}"
  else
    echo "omniRoute is not running"
  fi
}

case "${1:-}" in
  start) start ;;
  stop) stop ;;
  status) status ;;
  -h|--help|help|"")
    echo "omniRoute - AI CLI Manager"
    echo "Usage: omni-route [start|stop|status]"
    echo "Interface: http://localhost:${OMNIROUTE_PORT}"
    ;;
  *)
    echo "Unknown command: $1"
    echo "Usage: omni-route [start|stop|status]"
    return 1
    ;;
esac
EOS
  chmod +x "$PREFIX/bin/omni-route"
  log_success "omniRoute installed"
}

install_omni_route() {
  if command -v omni-route &>/dev/null; then
    log_info "omniRoute already installed"
    return 2
  fi
  log_info "Installing omniRoute..."
  
  # Check dependencies
  for dep in python flask; do
    if ! command -v "$dep" &>/dev/null && ! python3 -c "import flask" 2>/dev/null; then
      log_info "Installing Python Flask..."
      pip install flask --break-system-packages 2>&1 | tail -3
    fi
  done
  
  _install_omni_route_impl
}

uninstall_omni_route() {
  rm -f "$PREFIX/bin/omni-route"
  rm -rf "$OMNIROUTE_HOME"
  pkill -f "omni_route.py" 2>/dev/null || true
  log_success "omniRoute uninstalled"
}

update_omni_route() {
  log_info "omniRoute is up to date"
}

reinstall_omni_route() {
  uninstall_omni_route
  install_omni_route
}