#!/usr/bin/env bash

METASPLOIT_DIR="$PREFIX/opt/metasploit-framework"

install_metasploit() {
  if command -v msfconsole &>/dev/null; then
    log_info "metasploit já está instalado"
    return 2
  fi
  log_info "Instalando Metasploit Framework..."

  if pkg install -y metasploit 2>/dev/null || apt install -y metasploit 2>/dev/null; then
    log_success "metasploit instalado"
    return 0
  fi

  pkg install -y ruby git curl autoconf bison flex openssl libxml2 libxslt libyaml ncurses zlib 2>/dev/null

  if [ ! -d "$METASPLOIT_DIR" ]; then
    git clone --depth 1 https://github.com/rapid7/metasploit-framework "$METASPLOIT_DIR" 2>/dev/null || {
      log_error "Falha ao clonar Metasploit"
      return 1
    }
  fi

  cd "$METASPLOIT_DIR"
  gem install bundler 2>/dev/null
  bundle install --jobs 4 2>/dev/null

  for bin in msfconsole msfvenom msfrpc msfrpcd msfdb; do
    cat > "$PREFIX/bin/$bin" << BINEOF
#!/usr/bin/env bash
cd "$METASPLOIT_DIR"
bundle exec ruby \$0 "\$@"
BINEOF
    chmod +x "$PREFIX/bin/$bin"
  done

  log_success "metasploit instalado"
  return 0
}

uninstall_metasploit() {
  log_info "Removendo Metasploit..."
  for bin in msfconsole msfvenom msfrpc msfrpcd msfdb; do
    rm -f "$PREFIX/bin/$bin"
  done
  rm -rf "$METASPLOIT_DIR"
  log_success "metasploit removido"
}

update_metasploit() {
  if [ -d "$METASPLOIT_DIR" ]; then
    git -C "$METASPLOIT_DIR" pull
    cd "$METASPLOIT_DIR" && bundle install --jobs 4 2>/dev/null
    log_success "metasploit atualizado"
    return 0
  fi
  log_warn "metasploit não encontrado"
  return 1
}

reinstall_metasploit() {
  uninstall_metasploit
  install_metasploit
}
