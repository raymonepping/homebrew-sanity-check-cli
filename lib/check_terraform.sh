#!/usr/bin/env bash

check_terraform() {
  local file="$1"
  local mode="${2:-all}"
  local ext="${file##*.}"
  local dir

  qecho "🧪 [terraform] Checking $file"

  dir="$(dirname "$file")"

  # --- Formatting (.tf and .hcl) ---
  if [[ "$mode" =~ ^(fix|all)$ ]]; then
    if [[ "$ext" == "tf" ]] && tool_enabled_for terraform terraform-fmt; then
      check_tool_or_prompt terraform "brew install terraform" || return
      qecho "🎨 Formatting $(basename "$file") with terraform fmt"
      terraform fmt -write=true "$file" || PROBLEM_FILES+=("$file (terraform fmt)")
    fi
    if [[ "$ext" == "hcl" ]] && tool_enabled_for terraform hclfmt; then
      check_tool_or_prompt hclfmt "brew install hclfmt" || return
      qecho "🎨 Formatting $(basename "$file") with hclfmt"
      hclfmt -w "$file" || PROBLEM_FILES+=("$file (hclfmt)")
    fi
  fi

  # --- Linting (.tf and .hcl) ---
  if [[ "$mode" =~ ^(lint|all)$ ]]; then
    if tool_enabled_for terraform tflint; then
      check_tool_or_prompt tflint "brew install tflint" || return
      qecho "🔍 Linting $(basename "$file") with tflint"
      tflint --filter="$file" || PROBLEM_FILES+=("$file (tflint)")
    fi
    if tool_enabled_for terraform terrascan && [[ "$mode" =~ ^(lint|all)$ ]]; then
      check_tool_or_prompt terrascan "brew install terrascan" || return
      qecho "🔐 Running terrascan in $dir"
      local ts_out
      ts_out="$(terrascan scan -d "$dir" 2>/dev/null | grep -v '\[DEBUG\]')"
      if [[ -n "$ts_out" ]]; then
        echo "$ts_out"
        PROBLEM_FILES+=("$file (terrascan)")
      fi
    fi
  fi
}
