#!/usr/bin/env bash

# Helper: Get absolute path
abspath() {
  [[ $1 = /* ]] && echo "$1" || echo "$PWD/${1#./}"
}

warn() { echo -e "⚠️  $*" >&2; }

# Find nearest eslint flat config upwards (js, mjs, cjs only)
find_eslint_config() {
  local dir="$1"
  while [[ "$dir" != "/" && -n "$dir" ]]; do
    for f in "$dir"/eslint.config.js "$dir"/eslint.config.mjs "$dir"/eslint.config.cjs; do
      [[ -f "$f" ]] && echo "$f" && return 0
    done
    dir="$(dirname "$dir")"
  done
  return 1
}

# Find nearest package.json upwards
find_package_root() {
  local dir
  dir="$(dirname "$1")"
  while [[ "$dir" != "/" && -n "$dir" && ! -f "$dir/package.json" ]]; do
    dir="$(dirname "$dir")"
  done
  [[ -f "$dir/package.json" ]] && echo "$dir" || return 1
}

check_node() {
  local file="$1" mode="${2:-all}"
  local absfile pkg_root esconfig_file did_pushd=false

  [[ "${QUIET:-false}" == false ]] && echo "🧪 [node] Checking $file"

  absfile="$(abspath "$file")"
  pkg_root="$(find_package_root "$file" || true)"
  esconfig_file="$(find_eslint_config "$(dirname "$absfile")" || true)"

  if [[ -n "$pkg_root" ]]; then
    pushd "$pkg_root" >/dev/null || return 1
    did_pushd=true
  fi

  # Prettier (always runs if enabled)
  if tool_enabled_for node prettier && [[ "$mode" =~ ^(fix|all)$ ]]; then
    check_tool_or_prompt prettier "npm install -g prettier" || {
      $did_pushd && popd >/dev/null || return
      return
    }
    [[ "${QUIET:-false}" == false ]] && echo "🎨 Formatting $(basename "$absfile") with prettier"
    prettier --write "$absfile"
  fi

  # ESLint (flat config only!)
  if tool_enabled_for node eslint && [[ "$mode" =~ ^(lint|all)$ ]]; then
    check_tool_or_prompt eslint "npm install -g eslint" || {
      $did_pushd && popd >/dev/null || return
      return
    }
    if [[ -n "$esconfig_file" ]]; then
      [[ "${QUIET:-false}" == false ]] && echo "🔍 Linting $(basename "$absfile") with flat ESLint config $(basename "$esconfig_file")"
      if ! eslint "$absfile"; then
        PROBLEM_FILES+=("$absfile (eslint)")
      fi
    else
      warn "No flat ESLint config (eslint.config.js|mjs|cjs) found near $(dirname "$absfile"). Skipping ESLint."
    fi
  fi

  # TypeScript check
  if [[ "$file" == *.ts ]] && tool_enabled_for node tsc && [[ "$mode" =~ ^(lint|all)$ ]]; then
    check_tool_or_prompt tsc "npm install -g typescript" || {
      $did_pushd && popd >/dev/null || return
      return
    }
    [[ "${QUIET:-false}" == false ]] && echo "📐 Type-checking $absfile with tsc"
    if ! tsc --noEmit "$absfile"; then
      PROBLEM_FILES+=("$absfile (tsc)")
    fi
  fi

  # depcheck
  if tool_enabled_for node depcheck && [[ "$mode" =~ ^(lint|all)$ ]]; then
    check_tool_or_prompt depcheck "npm install -g depcheck" || {
      $did_pushd && popd >/dev/null || return
      return
    }
    if [[ -f "$pkg_root/package.json" ]]; then
      [[ "${QUIET:-false}" == false ]] && echo "📦 Running depcheck in $pkg_root"
      depcheck "$pkg_root" || PROBLEM_FILES+=("$pkg_root (depcheck)")
    else
      warn "No package.json found at $pkg_root; skipping depcheck."
    fi
  fi

  # npm audit
  if tool_enabled_for node npm-audit && [[ "$mode" =~ ^(lint|all)$ ]]; then
    if command -v npm &>/dev/null; then
      if [[ -f "$pkg_root/package-lock.json" ]]; then
        [[ "${QUIET:-false}" == false ]] && echo "🔐 Running npm audit in $pkg_root"
        npm audit --prefix "$pkg_root" || PROBLEM_FILES+=("$pkg_root (npm audit)")
      else
        warn "No package-lock.json found in $pkg_root; skipping npm audit."
      fi
    else
      MISSING_TOOL_WARNINGS+=("npm (required for npm audit)")
    fi
  fi

  if $did_pushd; then
    popd >/dev/null || return
  fi
}
