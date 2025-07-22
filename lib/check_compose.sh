#!/usr/bin/env bash

check_compose() {
  local file="$1"
  local mode="${2:-all}"

  [[ "$QUIET" == false ]] && echo "🧪 [compose] Checking $file"

  if tool_enabled_for docker yamllint && [[ "$mode" =~ ^(lint|all)$ ]]; then
    check_tool_or_prompt yamllint "brew install yamllint" || return
    [[ "$QUIET" == false ]] && echo "🔍 Linting $file with yamllint"
    if ! yamllint -c .yamllint "$file"; then
      PROBLEM_FILES+=("$file")
    fi
  fi

  if grep -qE '^\\s*services:' "$file" && grep -qE '^\\s*version:' "$file"; then
    local VALID_CMD=()
    if command -v docker &>/dev/null && docker compose version &>/dev/null; then
      VALID_CMD=(docker compose -f "$file" config)
    elif command -v docker-compose &>/dev/null; then
      VALID_CMD=(docker-compose -f "$file" config)
    fi

    if [[ ${#VALID_CMD[@]} -eq 0 ]]; then
      MISSING_TOOL_WARNINGS+=("docker-compose or docker compose (required for Compose validation in $file)")
      return
    fi

    [[ "$QUIET" == false ]] && echo "🐳 Validating Compose file with: ${VALID_CMD[*]}"
    if ! "${VALID_CMD[@]}" >/dev/null 2>&1; then
      PROBLEM_FILES+=("$file (Compose config failed)")
    fi
  else
    [[ "$QUIET" == false ]] && echo "ℹ️  Not a Compose file: $file (no services/version key)"
  fi
}
