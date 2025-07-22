#!/usr/bin/env bash

# Locate and source sanity_utils.sh if not already loaded
if ! command -v tool_enabled_for &>/dev/null; then
  # Try the usual locations; adapt as needed
  for f in \
    "./sanity_utils.sh" \
    "../lib/sanity_utils.sh" \
    "./lib/sanity_utils.sh" \
    "/opt/homebrew/share/sanity-check-cli/lib/sanity_utils.sh" \
    "/usr/local/share/sanity-check-cli/lib/sanity_utils.sh" \
    "$HOME/.sanity_check/lib/sanity_utils.sh"
  do
    [[ -f "$f" ]] && source "$f" && break
  done
fi

fix_md041_first_heading() {
  local file="$1"
  # Only rewrite if first line is not a single # heading
  local firstline
  firstline="$(head -n1 "$file")"
  if [[ "$firstline" =~ ^\#{2,}\  ]]; then
    # Replace ##... with #
    awk 'NR==1{sub(/^#+ /, "# ")} 1' "$file" > "$file.tmp" && mv "$file.tmp" "$file"
    echo "🔧 Fixed: First line changed to a top-level heading (# ...)"
  elif [[ ! "$firstline" =~ ^#\  ]]; then
    # If not a heading at all, insert a dummy title
    awk 'NR==1{print "# Auto-generated Title"; print $0; next} 1' "$file" > "$file.tmp" && mv "$file.tmp" "$file"
    echo "🔧 Inserted: # Auto-generated Title as first heading"
  fi
}

check_markdown() {
  local file="$1"
  local mode="${2:-all}"

  # Optionally fix first line to be # heading for MD041
  if [[ "$mode" =~ ^(fix|all)$ ]]; then
    fix_md041_first_heading "$file"
  fi

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

# CLI wrapper if script is run directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  file="$1"
  mode="${2:-all}"
  check_markdown "$file" "$mode"
fi