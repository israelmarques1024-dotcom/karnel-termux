#!/usr/bin/env bash

import "@/utils/log"
import "@/utils/colors"
import "@/utils/version"

: "${KARNEL_DATA:=${XDG_DATA_HOME:-$HOME/.local/share}/karnel-data}"
CACTUS_VERSION="2.0.1"
CACTUS_DATA_DIR="$KARNEL_DATA/cactus"
CACTUS_CONTAINER_DIR="/opt/karnel/cactus"
CACTUS_WRAPPER="$PREFIX/bin/cactus"
CACTUS_EMULATE=0

CACTUS_CLI_LOG_FILE="$KARNEL_CACHE/install_ai.log"
CACTUS_CLI_GLIBC_PYTHON="$PREFIX/glibc/bin/python"

_cactus_data_owned() {
  [[ -f "$CACTUS_DATA_DIR/.karnel-managed" ]]
}

_cactus_wrapper_owned() {
  local marker="$CACTUS_DATA_DIR/.karnel-wrapper-cactus"
  [[ -f "$marker" && -f "$CACTUS_WRAPPER" ]] || return 1
  [[ "$(sha256sum "$CACTUS_WRAPPER" 2>/dev/null)" == "$(<"$marker")" ]]
}

_cactus_proot() {
  proot-distro login --shared-tmp ubuntu -- "$@"
}

_cactus_container_owned() {
  command -v proot-distro &>/dev/null || return 1
  _cactus_proot test -f "$CACTUS_CONTAINER_DIR/.karnel-managed" &>/dev/null
}

_cactus_verify_ownership() {
  if [[ -e "$CACTUS_DATA_DIR" ]] && ! _cactus_data_owned; then
    log_error "Refusing to replace unowned Cactus data: $CACTUS_DATA_DIR"
    return 1
  fi
  if [[ -e "$CACTUS_WRAPPER" ]] && ! _cactus_wrapper_owned; then
    log_error "Refusing to replace unowned command: $CACTUS_WRAPPER"
    return 1
  fi
  if command -v cactus &>/dev/null && ! _cactus_wrapper_owned; then
    log_error "Refusing to shadow the existing cactus command: $(command -v cactus)"
    return 1
  fi
  if command -v proot-distro &>/dev/null &&
    _cactus_proot test -e "$CACTUS_CONTAINER_DIR" &>/dev/null &&
    ! _cactus_container_owned; then
    log_error "Refusing to replace unowned Cactus data in Ubuntu: $CACTUS_CONTAINER_DIR"
    return 1
  fi
}

_cactus_cpu_supported() {
  local features
  features="$(grep -m1 '^Features' /proc/cpuinfo 2>/dev/null || true)"
  [[ "$features" == *atomics* || "$features" == *lse* ]] &&
    [[ "$features" == *fp16* || "$features" == *asimdhp* ]] &&
    [[ "$features" == *dotprod* || "$features" == *asimddp* ]]
}

_cactus_set_emulation() {
  if _cactus_cpu_supported; then
    CACTUS_EMULATE=0
  else
    CACTUS_EMULATE=1
  fi
}

_cactus_wrapper_matches_emulation() {
  if [[ "$CACTUS_EMULATE" == 1 ]]; then
    grep -q "CACTUS_EMULATE=1" "$CACTUS_WRAPPER" 2>/dev/null
  else
    ! grep -q "CACTUS_EMULATE=1" "$CACTUS_WRAPPER" 2>/dev/null
  fi
}

_cactus_ensure_ubuntu() {
  _cactus_set_emulation
  if [[ "$CACTUS_EMULATE" == 1 ]]; then
    log_warn "This CPU lacks ARMv8.1+ features (LSE/fp16/dotprod); Cactus inference will run under qemu-aarch64 emulation and will be very slow"
  fi
  case "$(uname -m)" in
    aarch64|arm64) ;;
    *)
      log_error "Cactus currently provides a Linux wheel only for ARM64"
      return 1
      ;;
  esac
  if ! command -v proot-distro &>/dev/null; then
    pkg install proot-distro -y || return 1
  fi
  if ! proot-distro login ubuntu -- true &>/dev/null; then
    proot-distro install ubuntu:24.04 || return 1
  fi
}

_cactus_validate() {
  _cactus_proot "$CACTUS_CONTAINER_DIR/venv/bin/cactus" --help &>/dev/null
}

_cactus_apply_emulation_patch() {
  [[ "$CACTUS_EMULATE" == 1 ]] || return 0
  local patch_path patch_name rc
  patch_path="$(mktemp "$PREFIX/tmp/.cactus-emu-patch.XXXXXX")" || return 1
  patch_name="$(basename "$patch_path")"
  cat >"$patch_path" <<'PY'
import pathlib
import cactus.cli.common as m
p = pathlib.Path(m.__file__)
src = p.read_text()
if "CACTUS_EMULATE" in src:
    raise SystemExit(0)
old = "    return subprocess.run([str(binary), *(str(a) for a in args)]).returncode"
new = (
    "    cmd = [str(binary), *(str(a) for a in args)]\n"
    '    if os.environ.get("CACTUS_EMULATE") == "1":\n'
    '        cmd = ["/usr/bin/qemu-aarch64", "-cpu", "max", "-L", "/", *cmd]\n'
    "    return subprocess.run(cmd).returncode"
)
if old not in src:
    raise SystemExit(2)
p.write_text(src.replace(old, new))
PY
  _cactus_proot "$CACTUS_CONTAINER_DIR/venv/bin/python" "/tmp/$patch_name"
  rc=$?
  rm -f "$patch_path"
  return $rc
}

_install_cactus_inside_ubuntu() {
  _cactus_proot /bin/bash -c '
    set -e
    export DEBIAN_FRONTEND=noninteractive
    if [ -f /etc/apt/sources.list.d/ubuntu.sources ]; then
      official_source=/etc/apt/sources.list.d/ubuntu.sources
    else
      official_source=/etc/apt/sources.list
    fi
    apt_options=(-o "Dir::Etc::sourcelist=$official_source" -o "Dir::Etc::sourceparts=-")
    features="$(grep -m1 -E "^Features" /proc/cpuinfo || true)"
    emulate=0
    case "$features" in
      *atomics*|*lse*) ;;
      *) emulate=1 ;;
    esac
    if [ "$emulate" = 0 ]; then
      case "$features" in *fp16*|*asimdhp*) ;; *) emulate=1 ;; esac
    fi
    if [ "$emulate" = 0 ]; then
      case "$features" in *dotprod*|*asimddp*) ;; *) emulate=1 ;; esac
    fi
    apt-get "${apt_options[@]}" update -qq
    apt-get "${apt_options[@]}" install -y -qq ca-certificates python3 python3-pip python3-venv
    if [ "$emulate" = 1 ]; then
      apt-get "${apt_options[@]}" install -y -qq qemu-user
    fi
    if [ -e /opt/karnel/cactus ] && [ ! -f /opt/karnel/cactus/.karnel-managed ]; then
      echo "Refusing to replace unowned /opt/karnel/cactus" >&2
      exit 1
    fi
    rm -rf /opt/karnel/cactus
    mkdir -p /opt/karnel/cactus
    : > /opt/karnel/cactus/.karnel-managed
    if python3 -c "import sys; raise SystemExit(sys.version_info >= (3, 14))"; then
      python3 -m venv /opt/karnel/cactus/venv
    else
      python3 -m venv /opt/karnel/cactus/bootstrap
      /opt/karnel/cactus/bootstrap/bin/python -m pip install --upgrade uv
      export UV_PYTHON_INSTALL_DIR=/opt/karnel/cactus/python
      /opt/karnel/cactus/bootstrap/bin/uv python install 3.13
      /opt/karnel/cactus/bootstrap/bin/uv venv --seed --python 3.13 /opt/karnel/cactus/venv
    fi
    /opt/karnel/cactus/venv/bin/python -m pip install --upgrade "cactus-compute==2.0.1"
    /opt/karnel/cactus/venv/bin/cactus --help >/dev/null
  '
}

_cactus_write_wrapper() {
  mkdir -p "$CACTUS_DATA_DIR" "$PREFIX/bin" || return 1
  : >"$CACTUS_DATA_DIR/.karnel-managed" || return 1
  local temporary
  temporary="$(mktemp "$PREFIX/bin/.cactus.XXXXXX")" || return 1
  if [[ "$CACTUS_EMULATE" == 1 ]]; then
    cat >"$temporary" <<EOF
#!$PREFIX/bin/bash
# Karnel-managed Cactus wrapper (qemu-aarch64 emulation)
exec proot-distro login --shared-tmp ubuntu -- env CACTUS_EMULATE=1 $CACTUS_CONTAINER_DIR/venv/bin/cactus "\$@"
EOF
  else
    cat >"$temporary" <<EOF
#!$PREFIX/bin/bash
# Karnel-managed Cactus wrapper
exec proot-distro login --shared-tmp ubuntu -- $CACTUS_CONTAINER_DIR/venv/bin/cactus "\$@"
EOF
  fi
  chmod 755 "$temporary" || { rm -f "$temporary"; return 1; }
  mv -f "$temporary" "$CACTUS_WRAPPER" || return 1
  sha256sum "$CACTUS_WRAPPER" >"$CACTUS_DATA_DIR/.karnel-wrapper-cactus" || return 1
}

# ── Método nativo: glibc termux (recomendado) ──────────────────────────

_cactus_cli_glibc_run() {
  glibc-runner -s "$CACTUS_CLI_GLIBC_PYTHON" "$@"
}

_cactus_cli_install_deps_native_impl() {
  if [[ ! -f $PREFIX/etc/apt/sources.list.d/glibc.list ]]; then
    if ! yes | pkg install glibc-repo &>>"$CACTUS_CLI_LOG_FILE"; then
      log_error "Failed to install glibc-repo"
      return 1
    fi
  fi

  if [[ ! -f $PREFIX/glibc/lib/libc.so.6 ]]; then
    if ! yes | pkg install glibc &>>"$CACTUS_CLI_LOG_FILE"; then
      log_error "Failed to install glibc"
      return 1
    fi
  fi

  if [[ ! -f $CACTUS_CLI_GLIBC_PYTHON ]]; then
    if ! yes | pkg install python-glibc &>>"$CACTUS_CLI_LOG_FILE"; then
      log_error "Failed to install python-glibc"
      return 1
    fi
  fi

  if [[ ! -f $PREFIX/glibc/bin/pip ]]; then
    if ! yes | pkg install python-pip-glibc &>>"$CACTUS_CLI_LOG_FILE"; then
      log_error "Failed to install python-pip-glibc"
      return 1
    fi
  fi

  return 0
}

_cactus_cli_install_deps_native() {
  loading "Installing glibc and Python dependencies" _cactus_cli_install_deps_native_impl
}

_cactus_cli_install_pip_glibc_impl() {
  local pkg_spec="cactus-compute==${CACTUS_VERSION}"
  local install_args=""
  if [ "${1:-install}" = "update" ]; then
    pkg_spec='cactus-compute>=2,<3'
    install_args="--upgrade"
  fi

  _cactus_cli_glibc_run -m pip install $install_args "$pkg_spec" 2>&1 | tee -a "$CACTUS_CLI_LOG_FILE"
  local pip_rc=${PIPESTATUS[0]}
  if (( pip_rc != 0 )); then
    log_error "Failed to install Cactus Engine CLI"
    return 1
  fi

  _cactus_cli_post_install_glibc || return 1

  return 0
}

_cactus_cli_install_pip_glibc() {
  log_info "This downloads the Cactus Engine wheel (~26 MB) plus dependencies (torch, numpy, fastapi...) — it can take several minutes; progress is shown below"
  log_info "Full log: ${D_CYAN}$CACTUS_CLI_LOG_FILE${D_NC}"
  echo
  _cactus_cli_install_pip_glibc_impl "$@"
}

_cactus_cli_post_install_glibc() {
  local launcher_src="$KARNEL_PATH/tools/ai/cactus/bin/cactus.launcher.py"
  local launcher_dst="$PREFIX/libexec/cactus.launcher.py"
  local bin_dir cactus_bin engine_lib loader

  if [ ! -f "$launcher_src" ]; then
    log_error "Launcher template not found at $launcher_src"
    return 1
  fi
  mkdir -p "$PREFIX/libexec"
  cp "$launcher_src" "$launcher_dst"
  chmod 644 "$launcher_dst"

  if ! command -v patchelf &>/dev/null; then
    if ! yes | pkg install patchelf &>>"$CACTUS_CLI_LOG_FILE"; then
      log_error "Failed to install patchelf (needed to fix cactus engine binaries)"
      return 1
    fi
  fi

  cactus_bin="$PREFIX/glibc/bin/cactus"
  bin_dir="$({ printf 'import cactus, os; print(os.path.join(os.path.dirname(cactus.__file__), "bin"))\n' | "$CACTUS_CLI_GLIBC_PYTHON" - 2>/dev/null; } | tail -1)"
  if [ -z "$bin_dir" ] || [ ! -d "$bin_dir" ]; then
    bin_dir="$PREFIX/glibc/lib/python3.12/site-packages/cactus/bin"
  fi
  loader="$PREFIX/glibc/lib/ld-linux-aarch64.so.1"
  engine_lib="$PREFIX/glibc/lib"

  for engine in run transcribe; do
    if [ ! -f "$bin_dir/$engine" ]; then
      log_warn "Engine binary not found: $bin_dir/$engine"
      continue
    fi
    chmod 755 "$bin_dir/$engine" 2>/dev/null || true
    if readelf -l "$bin_dir/$engine" 2>/dev/null | grep -q "interpreter: /lib/ld-linux"; then
      if ! patchelf --set-interpreter "$loader" --set-rpath "\$ORIGIN/../../cactus_compute.libs:$engine_lib" "$bin_dir/$engine" &>>"$CACTUS_CLI_LOG_FILE"; then
        log_error "patchelf failed on $bin_dir/$engine"
        return 1
      fi
    fi
  done

  return 0
}

_cactus_cli_verify_impl() {
  if ! { printf 'import cactus\n' | timeout 300 glibc-runner -s "$CACTUS_CLI_GLIBC_PYTHON" -; } &>>"$CACTUS_CLI_LOG_FILE"; then
    log_error "Cactus Engine CLI installed but the native engine failed to load — your Android kernel or glibc setup cannot run it; use method 2 or 3"
    rm -f "$PREFIX/bin/cactus"
    _cactus_cli_glibc_run -m pip uninstall -y cactus-compute &>>"$CACTUS_CLI_LOG_FILE"
    return 1
  fi
  return 0
}

_cactus_cli_verify_glibc() {
  loading "Verifying Cactus Engine CLI (first engine load, may take a few minutes)" _cactus_cli_verify_impl
}

_cactus_cli_create_glibc_wrapper() {
  local wrapper_src="$KARNEL_PATH/tools/ai/cactus/bin/cactus.glibc"
  if [ ! -f "$wrapper_src" ]; then
    log_error "Wrapper template not found at $wrapper_src"
    return 1
  fi
  sed "1s|^#!.*|#!$PREFIX/bin/bash|" "$wrapper_src" >"$PREFIX/bin/cactus"
  chmod +x "$PREFIX/bin/cactus"
  return 0
}

_cactus_cli_install_native() {
  if ! _cactus_cpu_supported; then
    log_error "This CPU lacks ARMv8.1 features (LSE/fp16/dotprod) required by the native Cactus engine — it would crash with Illegal instruction"
    list_item "Re-run ${D_CYAN}karnel install ai --cactus${D_NC} and choose ${D_CYAN}proot-distro (ubuntu container)${D_NC}"
    list_item "That method runs under qemu-aarch64 emulation: functional but very slow on this CPU"
    return 1
  fi
  _cactus_cli_install_deps_native || return 1
  _cactus_cli_install_pip_glibc || return 1
  _cactus_cli_verify_glibc || return 1
  loading "Creating wrapper" _cactus_cli_create_glibc_wrapper || return 1

  mkdir -p "$CACTUS_DATA_DIR"
  : >"$CACTUS_DATA_DIR/.karnel-managed"
  printf 'native' >"$CACTUS_DATA_DIR/.install-method"
  log_success "Cactus Engine CLI installed natively"
  return 0
}

_cactus_cli_install_proot_pkg() {
  if ! command -v proot &>/dev/null; then
    if ! yes | pkg install proot &>>"$CACTUS_CLI_LOG_FILE"; then
      log_error "Failed to install proot"
      return 1
    fi
  fi
  return 0
}

_cactus_cli_create_proot_wrapper() {
  local wrapper_src="$KARNEL_PATH/tools/ai/cactus/bin/cactus.proot"
  if [ ! -f "$wrapper_src" ]; then
    log_error "Wrapper template not found at $wrapper_src"
    return 1
  fi
  sed "1s|^#!.*|#!$PREFIX/bin/bash|" "$wrapper_src" >"$PREFIX/bin/cactus"
  chmod +x "$PREFIX/bin/cactus"
  return 0
}

_cactus_cli_install_proot_glibc() {
  _cactus_cli_install_deps_native || return 1
  loading "Installing proot" _cactus_cli_install_proot_pkg || return 1
  _cactus_cli_install_pip_glibc || return 1
  _cactus_cli_verify_glibc || return 1
  loading "Creating proot wrapper" _cactus_cli_create_proot_wrapper || return 1

  mkdir -p "$CACTUS_DATA_DIR"
  : >"$CACTUS_DATA_DIR/.karnel-managed"
  printf 'proot-glibc' >"$CACTUS_DATA_DIR/.install-method"
  log_success "Cactus Engine CLI installed with glibc + proot"
  return 0
}

_cactus_cli_installed_version() {
  local method="native"
  if [ -f "$CACTUS_DATA_DIR/.install-method" ]; then
    method="$(cat "$CACTUS_DATA_DIR/.install-method")"
  fi

  if [ "$method" = "proot" ]; then
    _spin_capture "Detecting version" bash -c 'proot-distro login --shared-tmp ubuntu -- python3 -c "from importlib.metadata import version; print(version(\"cactus-compute\"))" 2>/dev/null'
  else
    _spin_capture "Detecting version" bash -c 'printf "%s\n" "from importlib.metadata import version; print(version(\"cactus-compute\"))" | glibc-runner -s "$PREFIX/glibc/bin/python" - 2>/dev/null'
  fi
}

_cactus_update_native() {
  local method="native"
  if [ -f "$CACTUS_DATA_DIR/.install-method" ]; then
    method="$(cat "$CACTUS_DATA_DIR/.install-method")"
  fi

  if [ "$method" = "proot" ]; then
    if ! _cactus_proot /bin/bash -c 'python3 -m pip install --break-system-packages --upgrade cactus-compute' &>>"$CACTUS_CLI_LOG_FILE"; then
      log_error "Failed to update Cactus Engine CLI"
      return 1
    fi
    if ! timeout 300 proot-distro login --shared-tmp ubuntu -- python3 -c "import cactus" &>>"$CACTUS_CLI_LOG_FILE"; then
      log_error "Cactus Engine CLI updated but the native engine failed to load"
      return 1
    fi
    log_success "Cactus Engine CLI (proot-distro) updated"
    return 0
  fi

  _cactus_cli_install_pip_glibc update || return 1
  _cactus_cli_verify_glibc || return 1
  log_success "Cactus Engine CLI ($method) updated"
  return 0
}

_cactus_uninstall_native() {
  local method="native"
  if [ -f "$CACTUS_DATA_DIR/.install-method" ]; then
    method="$(cat "$CACTUS_DATA_DIR/.install-method")"
  fi

  if [ "$method" = "proot" ]; then
    _cactus_proot python3 -m pip uninstall -y cactus-compute &>>"$CACTUS_CLI_LOG_FILE"
    rm -f "$PREFIX/bin/cactus"
    rm -rf "$CACTUS_DATA_DIR"
    log_success "Cactus Engine CLI (proot-distro) uninstalled"
    return 0
  fi

  _cactus_cli_glibc_run -m pip uninstall -y cactus-compute &>>"$CACTUS_CLI_LOG_FILE"
  rm -f "$PREFIX/bin/cactus"
  rm -rf "$CACTUS_DATA_DIR"
  log_success "Cactus Engine CLI ($method) uninstalled"
  return 0
}

install_cactus() {
  _cactus_set_emulation
  if [[ -f "$CACTUS_DATA_DIR/.install-method" ]]; then
    _cactus_update_native
    return $?
  fi
  if _cactus_data_owned && _cactus_wrapper_owned && _cactus_container_owned && _cactus_validate; then
    if _cactus_wrapper_matches_emulation; then
      log_info "Cactus is already installed"
      return 2
    fi
    _cactus_verify_ownership || return 1
    _cactus_apply_emulation_patch || return 1
    if ! _cactus_write_wrapper; then
      log_error "Failed to update Cactus wrapper"
      return 1
    fi
    log_info "Cactus installation updated for this CPU"
    return 0
  fi
  _cactus_verify_ownership || return 1

  log_info "Select installation method for Cactus:"

  local SELECTED_METHOD
  read_select "Installation method" SELECTED_METHOD \
    "glibc (recommended)" \
    "proot-distro (ubuntu container)"

  case "$SELECTED_METHOD" in
  *glibc*)
    if _cactus_cli_install_native; then
      log_success "Cactus installed (native glibc)"
    else
      log_error "Native install failed"
      return 1
    fi
    ;;
  *proot-distro*)
    log_info "Installing Cactus $CACTUS_VERSION in Ubuntu (glibc compatibility)..."
    _cactus_ensure_ubuntu || return 1
    if ! _install_cactus_inside_ubuntu || ! _cactus_apply_emulation_patch || ! _cactus_write_wrapper || ! _cactus_validate; then
      _cactus_wrapper_owned && rm -f "$CACTUS_WRAPPER"
      _cactus_data_owned && rm -rf "$CACTUS_DATA_DIR"
      log_error "Failed to install Cactus"
      return 1
    fi
    mkdir -p "$CACTUS_DATA_DIR"
    : >"$CACTUS_DATA_DIR/.karnel-managed"
    printf 'proot' >"$CACTUS_DATA_DIR/.install-method"
    log_success "Cactus installed"
    ;;
  esac
  if [[ "$CACTUS_EMULATE" == 1 ]]; then
    log_warn "Inference runs through qemu-aarch64 emulation on this CPU; expect minutes per token"
  fi
  log_info "Start with: cactus run Cactus-Compute/needle"
}

uninstall_cactus() {
  if [[ -f "$CACTUS_DATA_DIR/.install-method" ]]; then
    _cactus_uninstall_native
    return $?
  fi
  if ! _cactus_data_owned && ! _cactus_wrapper_owned && ! _cactus_container_owned; then
    if [[ -e "$CACTUS_DATA_DIR" || -e "$CACTUS_WRAPPER" ]]; then
      _cactus_verify_ownership
      return $?
    fi
    log_info "Cactus is not installed by Karnel"
    return 2
  fi
  _cactus_verify_ownership || return 1

  _cactus_wrapper_owned && rm -f "$CACTUS_WRAPPER"
  if _cactus_container_owned; then
    _cactus_proot rm -rf "$CACTUS_CONTAINER_DIR" || return 1
  fi
  _cactus_data_owned && rm -rf "$CACTUS_DATA_DIR"
  log_success "Cactus uninstalled; downloaded model data outside its environment was preserved"
}

update_cactus() {
  if [[ -f "$CACTUS_DATA_DIR/.install-method" ]]; then
    _cactus_update_native
    return $?
  fi
  _cactus_set_emulation
  _cactus_data_owned && _cactus_wrapper_owned && _cactus_container_owned || {
    log_error "Cactus is not installed by Karnel"
    return 1
  }
  _cactus_verify_ownership || return 1
  _cactus_proot "$CACTUS_CONTAINER_DIR/venv/bin/python" -m pip install --upgrade 'cactus-compute>=2,<3' || return 1
  _cactus_apply_emulation_patch || return 1
  _cactus_validate || return 1
  log_success "Cactus updated"
}

reinstall_cactus() {
  uninstall_cactus || [[ $? -eq 2 ]] || return 1
  install_cactus
}
