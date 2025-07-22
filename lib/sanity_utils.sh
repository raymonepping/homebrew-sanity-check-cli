#!/usr/bin/env bash
set -euo pipefail

# Global: Always resolve config to absolute path
CONFIG_FILE="${CONFIG_FILE:-.sanity.config.json}"

# Find the .sanity.config.json config file, set $CONFIG_FILE (absolute path if possible)
find_config_file() {
  local candidates=(
    "./.sanity.config.json"
    "$HOME/.sanity.config.json"
    "$HOME/.config/sanity_check/.sanity.config.json"
    "/usr/local/share/sanity-check-cli/.sanity.config.json"
    "/opt/homebrew/share/sanity-check-cli/.sanity.config.json"
  )
  for f in "${candidates[@]}"; do
    if [[ -f "$f" ]]; then
      CONFIG_FILE="$(cd "$(dirname "$f")" && pwd)/$(basename "$f")"
      return 0
    fi
  done
  warn "⚠️  No .sanity.config.json found. All tools will be considered enabled."
  CONFIG_FILE=""
  return 1
}

# Check if a tool is enabled for a language (or globally enabled if config is missing)
tool_enabled_for() {
  local lang="$1"
  local tool="$2"

  find_config_file

  # If config file is missing, consider everything enabled.
  if [[ -z "${CONFIG_FILE:-}" ]]; then
    [[ "${DEBUG_SANITY:-false}" == true ]] && echo "[DEBUG] No config file, defaulting tool '$tool' for '$lang' to enabled."
    return 0
  fi

  # jq will fail if the tool is not enabled in config
  if jq -e --arg lang "$lang" --arg tool "$tool" '
    .tools[$lang]? 
    | select(.enabled == true)
    | [(.linters[]? // empty), (.formatters[]? // empty), (.scanners[]? // empty), (.audit[]? // empty)]
    | any(. == $tool)
  ' "$CONFIG_FILE" >/dev/null 2>&1; then
    [[ "${DEBUG_SANITY:-false}" == true ]] && echo "[DEBUG] tool_enabled_for $lang $tool: YES"
    return 0
  else
    [[ "${DEBUG_SANITY:-false}" == true ]] && echo "[DEBUG] tool_enabled_for $lang $tool: NO"
    return 1
  fi
}

# Prompt for tool install if missing. Respects CI envs.
check_tool_or_prompt() {
  local tool="$1"
  local install="$2"

  if ! command -v "$tool" >/dev/null 2>&1; then
    warn "Tool '$tool' not found."
    if [[ "${CI:-}" == "true" ]]; then
      warn "Skipping install prompt in CI mode."
      return 1
    fi
    read -rp "❓ Install $tool via: $install ? [y/N] " confirm
    if [[ "$confirm" =~ ^[Yy]$ ]]; then
      eval "$install"
      command -v "$tool" >/dev/null 2>&1 || { warn "Install command did not provide $tool. Please install manually."; return 1; }
    else
      warn "⏭️  Skipping $tool"
      return 1
    fi
  fi
  return 0
}

# Consistent logging
log() {
  [[ "${QUIET:-false}" == false ]] && echo -e "🧪 $*"
}

warn() {
  echo -e "⚠️  $*" >&2
}

# Optionally: tool_version (if you want per-tool version info for debugging)
tool_version() {
  local tool="$1"
  if command -v "$tool" >/dev/null 2>&1; then
    "$tool" --version 2>&1 | head -n 1
  else
    echo "not installed"
  fi
}

render_markdown_report() {
  local report_file="$1"
  local timestamp
  timestamp="$(date '+%Y-%m-%d %H:%M:%S')"
  local tpl_file="$TPL_DIR/report.tpl"

  {
    sed "s/{{TIMESTAMP}}/$timestamp/" "$tpl_file" |
    awk -v processed="${FILES[*]}" \
        -v missing="${MISSING_TOOL_WARNINGS[*]:-}" \
        -v issues="${PROBLEM_FILES[*]:-}" '
      BEGIN {
        split(processed, files_arr, " ");
        split(missing, missing_arr, " ");
        split(issues, issues_arr, " ");

        PROCESSED_FILES = length(files_arr) > 0;
        MISSING_TOOLS = length(missing_arr) > 0;
        LINT_ISSUES = length(issues_arr) > 0;
      }

      /{{#PROCESSED_FILES}}/,/{{\/PROCESSED_FILES}}/ {
        if (/{{#files}}/) {
          for (i = 1; i <= length(files_arr); i++) print "- `" files_arr[i] "`";
          next;
        }
        if (!PROCESSED_FILES) next;
      }

      /{{#MISSING_TOOLS}}/,/{{\/MISSING_TOOLS}}/ {
        if (/{{#tools}}/) {
          for (i = 1; i <= length(missing_arr); i++) print "- " missing_arr[i];
          next;
        }
        if (!MISSING_TOOLS) next;
      }

      /{{#LINT_ISSUES}}/,/{{\/LINT_ISSUES}}/ {
        if (/{{#issues}}/) {
          for (i = 1; i <= length(issues_arr); i++) print "- `" issues_arr[i] "`";
          next;
        }
        if (!LINT_ISSUES) next;
      }

      /{{\^LINT_ISSUES}}/,/{{\/LINT_ISSUES}}/ {
        if (LINT_ISSUES) next;
      }

      !/{{[#\/^].*}}/ {print}
    '
  } >>"$report_file"

  echo -e "\n📄 Markdown report saved to \033[1;36m$report_file\033[0m"
}

