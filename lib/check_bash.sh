#!/usr/bin/env bash
set -euo pipefail

check_bash() {
  local file="$1"
  local mode="${2:-all}"
  local lint_status="" # Will contain status symbol and message
  local fmt_status=""  # Will contain formatting status

  [[ "${QUIET:-false}" == false ]] && echo "🧪 [bash] Checking $file"

  # --- shellcheck (linting) ---
  if tool_enabled_for "bash" "shellcheck"; then
    if check_tool_or_prompt "shellcheck" "brew install shellcheck"; then
      if [[ "$mode" == "lint" || "$mode" == "all" ]]; then
        shellcheck --color=always "$file"
        sc_exit=$?
        if [[ $sc_exit -ne 0 ]]; then
          lint_status="⚠️  shellcheck issues found"
        else
          lint_status="✔️  No shellcheck issues"
        fi
      fi
    fi
  fi

  # --- shfmt (formatting, only reports “changed” if actually changed) ---
  if tool_enabled_for "bash" "shfmt"; then
    if check_tool_or_prompt "shfmt" "brew install shfmt"; then
      if [[ "$mode" == "fix" || "$mode" == "all" ]]; then
        local tmpfile
        tmpfile="$(mktemp)"
        cp "$file" "$tmpfile"
        shfmt -w -i 2 "$file"
        if cmp -s "$file" "$tmpfile"; then
          fmt_status="🎨 Already formatted (no changes): $file"
        else
          fmt_status="🎨 Formatted with shfmt (2 spaces): $file"
        fi
        rm -f "$tmpfile"
      fi
    fi
  fi

  # --- Print concise summary per file ---
  if [[ -n "$lint_status" || -n "$fmt_status" ]]; then
    echo "${lint_status}${lint_status:+ | }${fmt_status}"
  fi
}
