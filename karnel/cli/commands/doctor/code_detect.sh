#!/usr/bin/env bash

# Project detection engine for karnel doctor code
# Analyzes directory structure and identifies languages/frameworks

_detect_project() {
  local dir="${1:-.}"
  dir="$(cd "$dir" 2>/dev/null && pwd)" || { log_error "Directory not found: $dir"; return 1; }

  PROJECT_LANGS=()
  PROJECT_FRAMEWORKS=()
  PROJECT_MANIFESTS=()
  PROJECT_SUBDIRS=()
  _scan_project "$dir" 0 4 "$dir"
}

_scan_project() {
  local current="$1" depth="$2" max_depth="$3" root_dir="${4:-$1}"
  (( depth > max_depth )) && return

  local dir_langs=()
  local dir_fws=()
  local dir_manifests=()

  for entry in "$current"/* "$current"/.github "$current"/.luacheckrc; do
    [[ -e "$entry" ]] || continue
    local name; name=$(basename "$entry")
    case "$name" in
      node_modules|.git|.venv|venv|__pycache__|target|dist|build|vendor|coverage|.cache|.terraform|.next|.nuxt|.angular|cache|elixir_build|_build|deps|.bundle|.gem|bin|obj|.gradle|.mvn|CMakeFiles|.cargo|.rustup|go/pkg|Godeps)
        continue ;;
    esac

    if [[ -f "$entry" ]]; then
      _check_manifest "$name" "$entry" dir_langs dir_fws dir_manifests
    elif [[ -d "$entry" ]]; then
      _scan_project "$entry" $((depth + 1)) "$max_depth" "$root_dir"
    fi
  done

  if [[ ${#dir_langs[@]} -gt 0 ]]; then
    for lang in "${dir_langs[@]}"; do PROJECT_LANGS+=("$lang"); done
    for fw in "${dir_fws[@]}"; do PROJECT_FRAMEWORKS+=("$fw"); done
    for mf in "${dir_manifests[@]}"; do PROJECT_MANIFESTS+=("$mf"); done

    # Register subproject if deeper than root
    if (( depth > 0 )) && [[ "$current" != "$root_dir" ]]; then
      local rel; rel="${current#"$root_dir"/}"
      PROJECT_SUBDIRS+=("$rel:$current:${dir_langs[*]}:${dir_fws[*]}")
    fi
  fi
}

_check_manifest() {
  local name="$1" path="$2"
  # shellcheck disable=SC2178
  local -n _langs="$3" _fws="$4" _manifests="$5"

  case "$name" in
    # JavaScript/TypeScript
    package.json)
      _langs+=("JavaScript")
      _manifests+=("JavaScript:$path")
      if grep -qE '"typescript"[[:space:]]*:' "$path" 2>/dev/null; then
        _langs+=("TypeScript")
      fi
      if grep -qiE '"next"[[:space:]]*:' "$path" 2>/dev/null; then
        _fws+=("JavaScript:Next.js")
      elif grep -qiE '"nuxt"[[:space:]]*:' "$path" 2>/dev/null; then
        _fws+=("JavaScript:Nuxt")
      elif grep -qiE '"vite"[[:space:]]*:' "$path" 2>/dev/null; then
        _fws+=("JavaScript:Vite")
      elif grep -qiE '"@angular/[^\"]+"[[:space:]]*:' "$path" 2>/dev/null; then
        _fws+=("JavaScript:Angular")
      elif grep -qiE '"react"[[:space:]]*:' "$path" 2>/dev/null; then
        _fws+=("JavaScript:React")
      elif grep -qiE '"vue"[[:space:]]*:' "$path" 2>/dev/null; then
        _fws+=("JavaScript:Vue")
      elif grep -qiE '"svelte"[[:space:]]*:' "$path" 2>/dev/null; then
        _fws+=("JavaScript:Svelte")
      elif grep -qiE '"astro"[[:space:]]*:' "$path" 2>/dev/null; then
        _fws+=("JavaScript:Astro")
      fi
      if grep -qiE '"express"[[:space:]]*:' "$path" 2>/dev/null; then
        _fws+=("JavaScript:Express")
      elif grep -qiE '"fastify"[[:space:]]*:' "$path" 2>/dev/null; then
        _fws+=("JavaScript:Fastify")
      elif grep -qiE '"@nestjs/[^\"]+"[[:space:]]*:' "$path" 2>/dev/null; then
        _fws+=("JavaScript:NestJS")
      elif grep -qiE '"hono"[[:space:]]*:' "$path" 2>/dev/null; then
        _fws+=("JavaScript:Hono")
      fi ;;
    tsconfig.json) _langs+=("TypeScript"); _manifests+=("TypeScript:$path") ;;
    # Python
    pyproject.toml)
      _langs+=("Python"); _manifests+=("Python:$path")
      if grep -qi 'django' "$path" 2>/dev/null; then
        _fws+=("Python:Django")
      elif grep -qi 'fastapi' "$path" 2>/dev/null; then
        _fws+=("Python:FastAPI")
      elif grep -qi 'flask' "$path" 2>/dev/null; then
        _fws+=("Python:Flask")
      elif grep -qi 'pytest' "$path" 2>/dev/null; then
        _fws+=("Python:pytest")
      elif grep -qi 'tox' "$path" 2>/dev/null; then
        _fws+=("Python:tox")
      elif grep -qi 'poetry' "$path" 2>/dev/null; then
        _fws+=("Python:Poetry")
      fi ;;
    requirements.txt|requirements-dev.txt|Pipfile|setup.py|setup.cfg)
      [[ " ${_langs[*]} " == *" Python "* ]] || _langs+=("Python")
      _manifests+=("Python:$path") ;;
    manage.py) _langs+=("Python"); _fws+=("Python:Django"); _manifests+=("Python:$path") ;;
    # Go
    go.mod) _langs+=("Go"); _manifests+=("Go:$path") ;;
    # Rust
    Cargo.toml) _langs+=("Rust"); _manifests+=("Rust:$path") ;;
    # Ruby
    Gemfile) _langs+=("Ruby"); _manifests+=("Ruby:$path") ;;
    # PHP
    composer.json) _langs+=("PHP"); _manifests+=("PHP:$path") ;;
    # Dart/Flutter
    pubspec.yaml) _langs+=("Dart"); _manifests+=("Dart:$path")
      grep -qi "flutter" "$path" 2>/dev/null && _fws+=("Dart:Flutter") ;;
    # C/C++
    CMakeLists.txt) _langs+=("C/C++"); _fws+=("C/C++:CMake"); _manifests+=("C/C++:$path") ;;
    Makefile) [[ -f "$(dirname "$path")/CMakeLists.txt" ]] || _detect_c_makefile "$path" _langs _manifests ;;
    # Java
    pom.xml) _langs+=("Java"); _fws+=("Java:Maven"); _manifests+=("Java:$path") ;;
    build.gradle|build.gradle.kts|settings.gradle*)
      _langs+=("Java"); _fws+=("Java:Gradle"); _manifests+=("Java:$path")
      grep -qi "kotlin" "$path" 2>/dev/null && _langs+=("Kotlin") ;;
    # .NET
    *.csproj|*.fsproj|*.vbproj) _langs+=("C#"); _fws+=("C#:.NET"); _manifests+=("C#:$path") ;;
    # Docker
    Dockerfile|docker-compose.yml|docker-compose.yaml)
      _langs+=("Docker"); _manifests+=("Docker:$path") ;;
    # Terraform
    *.tf) _langs+=("Terraform"); _manifests+=("Terraform:$path") ;;
    # Elixir
    mix.exs) _langs+=("Elixir"); _manifests+=("Elixir:$path") ;;
    # Haskell
    *.cabal|stack.yaml) _langs+=("Haskell"); _manifests+=("Haskell:$path") ;;
    # Lua
    *.rockspec|.luacheckrc|selene.toml|stylua.toml) _langs+=("Lua"); _manifests+=("Lua:$path") ;;
    # Swift
    Package.swift) _langs+=("Swift"); _manifests+=("Swift:$path") ;;
    # Julia
    Project.toml|Manifest.toml) _langs+=("Julia"); _manifests+=("Julia:$path") ;;
    # Zig
    build.zig) _langs+=("Zig"); _manifests+=("Zig:$path") ;;
    # Nix
    *.nix|flake.lock) _langs+=("Nix"); _manifests+=("Nix:$path") ;;
    # YAML ecosystems
    *.yml|*.yaml)
      if [[ "$(dirname "$path")" == *".github/workflows" ]]; then
        _langs+=("GitHub Actions"); _manifests+=("GitHub Actions:$path")
      elif [[ "$name" == "playbook.yml" || "$name" == "site.yml" || "$name" == "site.yaml" ]]; then
        _langs+=("Ansible"); _manifests+=("Ansible:$path")
      fi ;;
    # Shell scripts (detect by extension + shebang)
    *.sh|*.bash|*.zsh)
      [[ " ${_langs[*]} " != *" Shell "* ]] && _langs+=("Shell") ;;
    *.sql) [[ " ${_langs[*]} " != *" SQL "* ]] && _langs+=("SQL") ;;
    *.kt|*.kts) _langs+=("Kotlin"); _manifests+=("Kotlin:$path") ;;
    *.dart) _langs+=("Dart") ;;
    *.rs) _langs+=("Rust") ;;
    *.go) _langs+=("Go") ;;
    *.rb) _langs+=("Ruby") ;;
    *.php) _langs+=("PHP") ;;
    *.py) _langs+=("Python") ;;
    *.swift) _langs+=("Swift") ;;
    *.ex|*.exs) _langs+=("Elixir") ;;
  esac
}

_detect_c_makefile() {
  local path="$1"
  # shellcheck disable=SC2178
  local -n _langs="$2" _manifests="$3"
  if grep -qE '^(CC|CXX|CFLAGS|CXXFLAGS)' "$path" 2>/dev/null; then
    _langs+=("C/C++"); _manifests+=("C/C++:$path")
  fi
}
