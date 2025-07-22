#!/usr/bin/env bash

print_version() {
  local tool="$1"
  if ! command -v "$tool" &>/dev/null; then
    # echo -e "⚠️  $tool: \033[1;33mnot installed\033[0m"
    return
  fi

  local out=""

  # Tool-specific quirks
  case "$tool" in
  dockerfmt)
    out="$("$tool" version 2>&1 | head -n 1)"
    ;;
  hclfmt)
    out="$("$tool" --version 2>&1 | head -n 1)"
    ;;
  terrascan)
    out="$("$tool" version 2>&1 | head -n 1)"
    ;;
  tfsec)
    # tfsec prints a migration message + version at the end
    out="$("$tool" --version 2>&1 | grep -Eo 'v[0-9]+\.[0-9]+\.[0-9]+' | head -n 1)"
    [[ -z "$out" ]] && out="$("$tool" --version 2>&1 | tail -n 1)"
    ;;
  *)
    for flag in --version version -v "-V"; do
      out="$("$tool" $flag 2>&1 | grep -iE 'version|[0-9]+\.[0-9]+' | head -n 1)" && [[ -n "$out" ]] && break
    done
    ;;
  esac

  if [[ -z "$out" ]]; then
    echo -e "⚠️  $tool: \033[1;33mversion unknown (tool present, flag not recognized)\033[0m"
  else
    # Extract only the first version-like pattern (e.g. 1.2.3)
    if [[ "$out" =~ ([0-9]+\.[0-9]+\.[0-9]+) ]]; then
      echo "$tool: ${BASH_REMATCH[1]}"
    else
      # Fallback: strip anything after 'version' or 'v'
      v=$(echo "$out" | grep -oE 'v?[0-9]+\.[0-9]+(\.[0-9]+)?' | head -n1)
      if [[ -n "$v" ]]; then
        echo "$tool: $v"
      else
        # If nothing matches, print raw out
        echo "$tool: $out"
      fi
    fi
  fi

}

print_all_tool_versions() {
  echo "🧪 Tool Versions:"

  declare -A TOOL_GROUPS=(
    [Bash]="shfmt shellcheck"
    [Python]="black pylint flake8 bandit"
    [Node]="prettier eslint tsc depcheck"
    [Terraform]="terraform tflint tfsec terrascan hclfmt"
    [Docker]="dockerfmt hadolint dockle"
    [ContainerSecurity]="trivy grype syft"
    [Compose]="docker docker-compose yamllint"
    [Markdown]="prettier markdownlint"
  )

  for GROUP in "${!TOOL_GROUPS[@]}"; do
    echo -e "\n🔹 \033[1;36m$GROUP\033[0m"
    for tool in ${TOOL_GROUPS[$GROUP]}; do
      print_version "$tool"
    done
  done
}

# Only run if script is called directly, not sourced
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  print_all_tool_versions
fi
