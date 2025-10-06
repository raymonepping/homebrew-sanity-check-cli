#!/usr/bin/env bash
set -euo pipefail

# Homebrew Formula checker using a short-lived tap created by `brew tap-new`.
#
# Modes:
#   all  = ruby syntax + brew style + brew audit
#   lint = ruby syntax + brew style + brew audit
#   fix  = ruby syntax + brew style --fix + brew audit
#
# Env:
#   SANITY_BREW_ONLINE=true  -> add --online to brew audit
#   SANITY_BREW_VERBOSE=true -> extra debug echo
#   SANITY_BREW_WRITEBACK=true -> copy style-fixed file from temp tap back to source (only in --fix)

is_brew_formula_file() {
  local file="$1"
  grep -qE 'class[[:space:]]+[A-Za-z0-9_]+[[:space:]]*<+[[:space:]]*Formula' "$file"
}

_formula_name_from_path() {
  local file="$1"
  basename "$file" .rb
}

_repo_root() {
  brew --repository 2>/dev/null
}

_tap_path() {
  local repo_root="$1" user="$2" repo="$3"
  echo "${repo_root}/Library/Taps/${user}/homebrew-${repo}"
}

_ensure_git() {
  if ! command -v git >/dev/null 2>&1; then
    echo "⚠️  git is required for brew tap-new workflows" >&2
    return 1
  fi
}

_create_fresh_tap() {
  export TAP_USER="sanity"
  export TAP_REPO="local"
  export TAP_NAME="$TAP_USER/$TAP_REPO"

  local repo_root tap_dir
  repo_root="$(_repo_root)"
  [[ -z "$repo_root" ]] && { echo "⚠️  Unable to find brew repository root"; return 1; }

  tap_dir="$(_tap_path "$repo_root" "$TAP_USER" "$TAP_REPO")"

  # If an old run left artifacts, nuke them cleanly.
  if brew tap | grep -q "^${TAP_NAME}\$"; then
    brew untap "$TAP_NAME" >/dev/null 2>&1 || true
  fi
  rm -rf "$tap_dir"

  # Create a clean git-backed tap.
  brew tap-new "$TAP_NAME" >/dev/null

  [[ -d "$tap_dir" ]] || { echo "⚠️  tap-new did not create $tap_dir"; return 1; }

  export TAP_DIR="$tap_dir"
  return 0
}

_cleanup_tap() {
  brew untap "$TAP_NAME" >/dev/null 2>&1 || true
  rm -rf "$TAP_DIR" || true
}

_stage_formula_into_tap() {
  local src_file="$1" dest_name="$2"
  cp "$src_file" "$TAP_DIR/Formula/${dest_name}.rb"
  (
    cd "$TAP_DIR"
    git add "Formula/${dest_name}.rb" >/dev/null
    git commit -q -m "add ${dest_name}"
  )
}

_tap_formula_path() {
  local dest_name="$1"
  echo "$TAP_DIR/Formula/${dest_name}.rb"
}

_writeback_if_changed() {
  local src_path="$1" tap_path="$2"
  if ! cmp -s "$src_path" "$tap_path"; then
    cp "$tap_path" "$src_path"
    [[ "${QUIET:-false}" == false ]] && echo "💾 Wrote back brew style fixes to source: $src_path"
  else
    [[ "${QUIET:-false}" == false ]] && echo "🆗 No write-back needed, source already matches"
  fi
}

check_brew_formula() {
  local file="$1"
  local mode="${2:-all}"

  if ! is_brew_formula_file "$file"; then
    [[ "${QUIET:-false}" == false ]] && echo "⏭️  [brew] Skipping non-formula: $file"
    return 0
  fi

  [[ "${QUIET:-false}" == false ]] && echo "🧪 [brew] Checking Homebrew Formula: $file"

  local name had_issue=false
  name="$(_formula_name_from_path "$file")"

  # --- Ruby syntax (no tap needed) ---
  if tool_enabled_for "brew" "ruby"; then
    if check_tool_or_prompt "ruby" "brew install ruby"; then
      if ! ruby -c "$file" >/dev/null 2>&1; then
        echo "⚠️  ruby -c failed: $file"
        had_issue=true
        PROBLEM_FILES+=("$file (brew ruby syntax)")
      else
        [[ "${QUIET:-false}" == false ]] && echo "✔️  ruby syntax OK"
      fi
    else
      MISSING_TOOL_WARNINGS+=("ruby needed for formula syntax check")
    fi
  fi

  # Decide if we need brew style/audit
  local need_style=false need_audit=false
  tool_enabled_for "brew" "brew_style" && need_style=true
  tool_enabled_for "brew" "brew_audit" && need_audit=true
  if [[ "$need_style" == false && "$need_audit" == false ]]; then
    [[ "${QUIET:-false}" == false ]] && echo "⏭️  [brew] style/audit disabled by config"
    return 0
  fi

  # --- Prepare tap and stage the formula ---
  if ! check_tool_or_prompt "brew" "echo 'Install Homebrew: https://brew.sh'"; then
    MISSING_TOOL_WARNINGS+=("brew needed for style/audit")
    return 0
  fi

  _ensure_git || return 0

  if ! _create_fresh_tap; then
    echo "⚠️  Could not create temp tap; skipping brew style/audit"
    return 0
  fi

  trap _cleanup_tap EXIT

  _stage_formula_into_tap "$file" "$name"

  local fq_name tap_fixed
  fq_name="$TAP_NAME/$name"
  tap_fixed="$(_tap_formula_path "$name")"
  [[ "${SANITY_BREW_VERBOSE:-false}" == "true" ]] && echo "🧪 [brew] Staged as $fq_name in $TAP_DIR"

  # --- brew style ---
  if [[ "$need_style" == true ]]; then
    if [[ "$mode" == "fix" ]]; then
      if ! brew style --display-cop-names --formula --fix "$fq_name"; then
        echo "⚠️  brew style --fix found issues"
        had_issue=true
        PROBLEM_FILES+=("$file (brew style)")
      else
        [[ "${QUIET:-false}" == false ]] && echo "🎨 brew style fixed or confirmed clean"
      fi

      # Optional write-back of style changes from temp tap to source
      if [[ "${SANITY_BREW_WRITEBACK:-false}" == "true" ]]; then
        _writeback_if_changed "$file" "$tap_fixed"
      fi
    else
      if ! brew style --display-cop-names --formula "$fq_name"; then
        echo "⚠️  brew style found issues"
        had_issue=true
        PROBLEM_FILES+=("$file (brew style)")
      else
        [[ "${QUIET:-false}" == false ]] && echo "✔️  brew style OK"
      fi
    fi
  fi

  # --- brew audit ---
  if [[ "$need_audit" == true ]]; then
    local audit_flags=(--strict)
    [[ "${SANITY_BREW_ONLINE:-false}" == "true" ]] && audit_flags+=(--online)
    if ! brew audit "${audit_flags[@]}" "$fq_name"; then
      echo "⚠️  brew audit reported issues"
      had_issue=true
      PROBLEM_FILES+=("$file (brew audit)")
    else
      [[ "${QUIET:-false}" == false ]] && echo "✔️  brew audit OK"
    fi
  fi

  # No generic PROBLEM_FILES append here; we tag per check above.
}
# ---------------------------