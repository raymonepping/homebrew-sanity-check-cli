#!/usr/bin/env bash

check_markdown() {
  local file="$1"
  local mode="${2:-all}"

  if tool_enabled_for markdown prettier && [[ "$mode" =~ ^(fix|all)$ ]]; then
    check_tool_or_prompt prettier "npm install -g prettier" || return
    echo "🎨 Formatting $(basename "$file") with prettier"
    prettier --write "$file"
  fi

  if tool_enabled_for markdown markdownlint && [[ "$mode" =~ ^(lint|all)$ ]]; then
    check_tool_or_prompt markdownlint "npm install -g markdownlint-cli" || return
    echo "🔍 Linting $(basename "$file") with markdownlint"
    markdownlint "$file"
  fi
}
