check_json() {
  local file="$1" mode="${2:-all}"
  local absfile
  absfile="$(abspath "$file")"

  [[ "${QUIET:-false}" == false ]] && echo "🧪 [json] Checking $file"

  # Prettier – format (fix) or always in all mode
  if tool_enabled_for json prettier && [[ "$mode" =~ ^(fix|all)$ ]]; then
    check_tool_or_prompt prettier "npm install -g prettier" || return
    [[ "${QUIET:-false}" == false ]] && echo "🎨 Formatting $(basename "$file") with Prettier"
    prettier --write "$file"
  fi

  # JSONLint – strict syntax check
  if tool_enabled_for json jsonlint && [[ "$mode" =~ ^(lint|all)$ ]]; then
    check_tool_or_prompt jsonlint "npm install -g jsonlint" || return
    [[ "${QUIET:-false}" == false ]] && echo "🔍 Validating syntax of $(basename "$file") with jsonlint"
    if ! jsonlint -q "$file"; then
      PROBLEM_FILES+=("$file (jsonlint)")
    fi
  fi

  # jq – structure check (noop unless invalid structure)
  if tool_enabled_for json jq && [[ "$mode" =~ ^(lint|all)$ ]]; then
    check_tool_or_prompt jq "brew install jq" || return
    [[ "${QUIET:-false}" == false ]] && echo "🔍 Validating structure of $(basename "$file") with jq"
    if ! jq empty "$file" 2>/dev/null; then
      PROBLEM_FILES+=("$file (jq)")
    fi
  fi

  # spectral – for OpenAPI/AsyncAPI-style JSON files
  if [[ "$file" =~ (openapi|asyncapi|spec|swagger)[._-].*\.json$ ]] && tool_enabled_for json spectral; then
    check_tool_or_prompt spectral "brew install spectral-cli" || return
    [[ "${QUIET:-false}" == false ]] && echo "📘 Running Spectral on $(basename "$file")"
    if ! spectral lint "$file"; then
      PROBLEM_FILES+=("$file (spectral)")
    fi
  fi
}
