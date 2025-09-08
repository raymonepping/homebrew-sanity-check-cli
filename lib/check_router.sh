#!/usr/bin/env bash

route_file_check() {
  local file="$1"
  local mode="${2:-all}"
  local basename ext lower

  basename="$(basename "$file")"
  ext="${file##*.}"
  ext="${ext,,}"
  lower="$(echo "$basename" | tr '[:upper:]' '[:lower:]')"

  # Normalize special cases
  [[ "$basename" == "Dockerfile" ]] && ext="Dockerfile"

  # Shebang-based Bash detection for extensionless files
  if [[ "$basename" != *.* && -z "$ext" ]]; then
    if head -n 1 "$file" | grep -qE '^#! */usr/(bin|env) +(env +)?bash'; then
      ext="sh"
    fi
  fi

  # Compose by filename pattern
  if [[ "$lower" =~ (^|.*[-_.])docker(-)?compose\.ya?ml$ || "$lower" =~ (^|.*[-_.])compose\.ya?ml$ || "$lower" =~ \.compose\.ya?ml$ ]]; then
    # shellcheck disable=SC1091
    source "$LIB_DIR/check_compose.sh"
    check_compose "$file" "$mode"
    return
  fi

  case "$ext" in
    sh)
      # shellcheck disable=SC1091
      source "$LIB_DIR/check_bash.sh"
      check_bash "$file" "$mode"
      return
      ;;
    py)
      # shellcheck disable=SC1091
      source "$LIB_DIR/check_python.sh"
      check_python "$file" "$mode"
      return
      ;;
    js|ts)
      # shellcheck disable=SC1091
      source "$LIB_DIR/check_node.sh"
      check_node "$file" "$mode"
      return
      ;;
    tf|hcl)
      # shellcheck disable=SC1091
      source "$LIB_DIR/check_terraform.sh"
      check_terraform "$file" "$mode"
      return
      ;;
    json)
      # shellcheck disable=SC1091
      source "$LIB_DIR/check_json.sh"
      check_json "$file" "$mode"
      return
      ;;
    Dockerfile)
      # shellcheck disable=SC1091
      source "$LIB_DIR/check_docker.sh"
      check_docker "$file" "$mode"
      return
      ;;
    yml|yaml)
      # Treat YAML with top-level 'services:' as Compose (Compose v2+ does not require 'version:')
      if grep -qE '^[[:space:]]*services:' "$file"; then
        # shellcheck disable=SC1091
        source "$LIB_DIR/check_compose.sh"
        check_compose "$file" "$mode"
        return
      fi
      # Optional: generic YAML checker (only if you have one)
      if [[ -f "$LIB_DIR/check_yaml.sh" ]]; then
        # shellcheck disable=SC1091
        source "$LIB_DIR/check_yaml.sh"
        check_yaml "$file" "$mode"
        return
      fi
      ;;
    md)
      # shellcheck disable=SC1091
      source "$LIB_DIR/check_markdown.sh"
      check_markdown "$file" "$mode"
      return
      ;;
  esac

  # Final fallback, detect Bash by shebang
  if head -n 1 "$file" | grep -qE '^#!.*/(env )?bash'; then
    # shellcheck disable=SC1091
    source "$LIB_DIR/check_bash.sh"
    check_bash "$file" "$mode"
    return
  fi

  [[ "$QUIET" == false ]] && echo "⚠️  Skipping unsupported file: $file"
}
