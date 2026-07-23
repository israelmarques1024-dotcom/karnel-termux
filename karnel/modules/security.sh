install_security() {
  separator
  box "Installing Security Tools"
  separator
  import "@/tools/security/all"
  install_all_security
}

uninstall_security() {
  import "@/tools/security/all"
  uninstall_all_security
}

update_security() {
  import "@/tools/security/all"
  update_all_security
}

reinstall_security() {
  import "@/tools/security/all"
  reinstall_all_security
}
