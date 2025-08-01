#!/usr/bin/env bash

# Helper: Get absolute path
abspath() {
  [[ $1 = /* ]] && echo "$1" || echo "$PWD/${1#./}"
}

warn() { echo -e "⚠️  $*" >&2; }

check_json() {
  local file="$1" mode="${2:-all}"
  local absfile
  absfile="$(abspath "$file")"

  [[ "${QUIET:-false}" == false ]] && echo "🧪 [json] Checking $file"

  # Prettier – Format for 'fix', Check for 'lint' or 'all'
  if tool_enabled_for json prettier; then
    check_tool_or_prompt prettier "npm install -g prettier" || return
    if [[ "$mode" == "fix" ]]; then
      [[ "$QUIET" == false ]] && echo "🎨 Formatting $file with Prettier"
      prettier --write "$file"
    elif [[ "$mode" =~ ^(lint|all)$ ]]; then
      [[ "$QUIET" == false ]] && echo "🎨 Checking format of $file with Prettier"
      if ! prettier --check "$file"; then
        PROBLEM_FILES+=("$file (prettier)")
      fi
    fi
  fi

  # JSONLint – strict syntax check
  if tool_enabled_for json jsonlint && [[ "$mode" =~ ^(lint|all)$ ]]; then
    check_tool_or_prompt jsonlint "npm install -g jsonlint" || return
    [[ "$QUIET" == false ]] && echo "🔍 Validating syntax of $file with jsonlint"
    if ! jsonlint -q "$file"; then
      PROBLEM_FILES+=("$file (jsonlint)")
    fi
  fi

  # jq – structure check
  if tool_enabled_for json jq && [[ "$mode" =~ ^(lint|all)$ ]]; then
    check_tool_or_prompt jq "brew install jq" || return
    [[ "$QUIET" == false ]] && echo "🔍 Validating structure of $file with jq"
    if ! jq empty "$file" 2>/dev/null; then
      PROBLEM_FILES+=("$file (jq)")
    fi
  fi
}
