#!/usr/bin/env bash

_BURP_DIR="$PREFIX/share/burpsuite"
_BURP_JAR="burpsuite_community.jar"

install_burpsuite() {
  if command -v burpsuite &>/dev/null; then
    log_info "burpsuite já está instalado"
    return 2
  fi
  log_info "Instalando Burp Suite..."

  if pkg install -y burpsuite 2>/dev/null || apt install -y burpsuite 2>/dev/null; then
    log_success "burpsuite instalado"
    return 0
  fi

  pkg install -y curl openjdk-17 2>/dev/null

  mkdir -p "$_BURP_DIR"

  local url
  url=$(curl -fsSL "https://portswigger.net/burp/releases/data/latest" 2>/dev/null | \
    grep -oP '"communityDownloadUrl"\s*:\s*"[^"]+"' | head -1 | sed 's/.*"communityDownloadUrl"\s*:\s*"//;s/"//' 2>/dev/null)

  if [ -n "$url" ]; then
    curl -fsSL "$url" -o "$_BURP_DIR/$_BURP_JAR"
  fi

  if [ -f "$_BURP_DIR/$_BURP_JAR" ]; then
    cat > "$PREFIX/bin/burpsuite" << 'SCRIPT'
#!/usr/bin/env bash
exec java -jar "$PREFIX/share/burpsuite/burpsuite_community.jar" "$@"
SCRIPT
    chmod +x "$PREFIX/bin/burpsuite"
    log_success "burpsuite instalado"
    return 0
  fi

  log_error "Falha ao instalar burpsuite"
  return 1
}

uninstall_burpsuite() {
  log_info "Removendo Burp Suite..."
  rm -f "$PREFIX/bin/burpsuite"
  rm -rf "$_BURP_DIR"
  log_success "burpsuite removido"
}

update_burpsuite() {
  uninstall_burpsuite
  install_burpsuite
}

reinstall_burpsuite() {
  uninstall_burpsuite
  install_burpsuite
}
