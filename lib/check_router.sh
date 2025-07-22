#!/usr/bin/env bash

route_file_check() {
  local file="$1"
  local mode="${2:-all}"
  local ext="${file##*.}"
  local basename

  basename="$(basename "$file")"
  ext="${file##*.}"
  ext="${ext,,}"

  [[ "$basename" == "Dockerfile" ]] && ext="Dockerfile"

  # Fallback: detect bash script via shebang if no extension
  if [[ "$basename" != *.* && -z "$ext" ]]; then
    if head -n 1 "$file" | grep -qE '^#! */usr/(bin|env) +(env +)?bash'; then
      ext="sh"
    fi
  fi

  # Normalize special cases
  [[ "$basename" == "Dockerfile" ]] && ext="Dockerfile"

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
  js | ts)
    # shellcheck disable=SC1091
    source "$LIB_DIR/check_node.sh"
    check_node "$file" "$mode"
    return
    ;;
  tf | hcl)
    # shellcheck disable=SC1091
    source "$LIB_DIR/check_terraform.sh"
    check_terraform "$file" "$mode"
    return
    ;;
  Dockerfile)
    # shellcheck disable=SC1091
    source "$LIB_DIR/check_docker.sh"
    check_docker "$file" "$mode"
    return
    ;;
  yml | yaml)
    if grep -qE '^\s*version:\s*["]?[23]' "$file" 2>/dev/null; then
      # shellcheck disable=SC1091
      source "$LIB_DIR/check_compose.sh"
      check_compose "$file" "$mode"
      return
    fi
    ;;
  esac

  # 💡 Fallback: detect Bash script by shebang
  if head -n 1 "$file" | grep -qE '^#!.*/(env )?bash'; then
    # shellcheck disable=SC1091
    source "$LIB_DIR/check_bash.sh"
    check_bash "$file" "$mode"
    return
  fi

  [[ "$QUIET" == false ]] && echo "⚠️  Skipping unsupported file: $file"
}
