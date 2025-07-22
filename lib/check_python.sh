#!/usr/bin/env bash

check_python() {
  local file="$1"
  local mode="${2:-all}"

  [[ "$QUIET" == false ]] && echo "🧪 [python] Checking $file"

  if tool_enabled_for python black && [[ "$mode" =~ ^(fix|all)$ ]]; then
    check_tool_or_prompt black "brew install black" || return
    [[ "$QUIET" == false ]] && echo "🎨 Formatting $file with black"
    black "$file" || PROBLEM_FILES+=("$file")
  fi

  if tool_enabled_for python pylint && [[ "$mode" =~ ^(lint|all)$ ]]; then
    check_tool_or_prompt pylint "brew install pylint" || return
    [[ "$QUIET" == false ]] && echo "🔍 Linting $file with pylint"
    pylint "$file" || PROBLEM_FILES+=("$file")
  fi

  if tool_enabled_for python flake8 && [[ "$mode" =~ ^(lint|all)$ ]]; then
    check_tool_or_prompt flake8 "brew install flake8" || return
    [[ "$QUIET" == false ]] && echo "🔍 Linting $file with flake8"
    flake8 "$file" || PROBLEM_FILES+=("$file")
  fi

  if tool_enabled_for python bandit && [[ "$mode" =~ ^(lint|all)$ ]]; then
    check_tool_or_prompt bandit "brew install bandit" || return
    [[ "$QUIET" == false ]] && echo "🔐 Running bandit on $file"
    bandit -q -r "$file" || PROBLEM_FILES+=("$file")
  fi

  # isort (import sorting)
  if tool_enabled_for "python" "isort"; then
    if check_tool_or_prompt "isort" "pip install isort"; then
      if [[ "$mode" == "fix" || "$mode" == "all" ]]; then
        isort "$file"
        [[ "${QUIET:-false}" == false ]] && echo "🎨 [python] Sorted imports with isort: $file"
      fi
    fi
  fi

  # autoflake (remove unused imports)
  if tool_enabled_for "python" "autoflake"; then
    if check_tool_or_prompt "autoflake" "pip install autoflake"; then
      if [[ "$mode" == "fix" || "$mode" == "all" ]]; then
        autoflake --in-place --remove-unused-variables --remove-all-unused-imports "$file"
        [[ "${QUIET:-false}" == false ]] && echo "🎨 [python] Cleaned unused imports/vars with autoflake: $file"
      fi
    fi
  fi

}
