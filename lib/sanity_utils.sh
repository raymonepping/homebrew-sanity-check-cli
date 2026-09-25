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
  if [[ "${QUIET:-false}" == false ]]; then
    echo -e "🧪 $*"
  fi
  return 0
}

# Prints its arguments unless QUIET is true. Always returns 0, regardless of
# whether QUIET is true or false, and regardless of which branch of the `if`
# below actually runs.
#
# This exists because the bare idiom `[[ "$QUIET" == false ]] && echo "..."`
# is unsafe under `set -e` (bin/sanity_check's own top-level setting,
# inherited by every lib/*.sh sourced into that same process): when QUIET is
# true, the `[[ ... ]]` test is false, so the whole `A && B` line's exit
# status is the test's own failure (1), not the echo's. If that line is the
# last statement executed in its enclosing function/block — exactly what
# happens for the last enabled tool checked on a given file — `set -e` treats
# it as a real command failure and kills the entire script right there,
# before it ever reaches the final "Sanity check complete" + exit 0.
#
# A first attempt at this fix wrote `[[ ... ]] && echo "$@"` followed by a
# separate `return 0` line, which does NOT work: `set -e` kills the function
# at the failing `[[ ]] && echo` statement itself, before that later
# `return 0` is ever reached — confirmed live, the exact same failure
# persisted after that "fix." An explicit `if/fi` is the only form that
# avoids the ambiguous exit status entirely; there is no statement left
# whose own failure could trigger `set -e`.
#
# Confirmed live: `sanity_check --fix --quiet` on an already-clean Python
# file printed "All done! ... 1 file left unchanged." (autoflake's own
# success message) and still exited 1 — bash -x traced it dying silently
# immediately after the autoflake call, exactly on the
# `[[ "${QUIET:-false}" == false ]] && echo "..."` line that used to follow
# it. Every check_*.sh file had the same pattern, ~40 call sites total; all
# converted to call this helper instead.
qecho() {
  if [[ "${QUIET:-false}" == false ]]; then
    echo "$@"
  fi
  return 0
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
    # Replace timestamp placeholder up front
    sed "s/{{TIMESTAMP}}/$timestamp/" "$tpl_file" |
    awk -v processed="${FILES[*]}" \
        -v missing="${MISSING_TOOL_WARNINGS[*]:-}" \
        -v issues="${PROBLEM_FILES[*]:-}" '
      BEGIN {
        # Convert Bash arrays into awk arrays
        n_files = split(processed, files_arr, " ")
        n_missing = split(missing, missing_arr, " ")
        n_issues = split(issues, issues_arr, " ")
        PROCESSED_FILES = n_files > 0
        MISSING_TOOLS = n_missing > 0
        LINT_ISSUES = n_issues > 0
      }

      # Processed Files block
      /{{#PROCESSED_FILES}}/,/{{\/PROCESSED_FILES}}/ {
        if (/{{#files}}/) {
          for (i = 1; i <= n_files; i++) print "- `" files_arr[i] "`";
          next;
        }
        if (/{{.}}/) next;    # Skip literal Mustache lines
        if (!PROCESSED_FILES) next;
      }

      # Missing Tools block
      /{{#MISSING_TOOLS}}/,/{{\/MISSING_TOOLS}}/ {
        if (/{{#tools}}/) {
          for (i = 1; i <= n_missing; i++) print "- " missing_arr[i];
          next;
        }
        if (!MISSING_TOOLS) next;
      }

      # Lint Issues block
      /{{#LINT_ISSUES}}/,/{{\/LINT_ISSUES}}/ {
        if (/{{#issues}}/) {
          for (i = 1; i <= n_issues; i++) print "- `" issues_arr[i] "`";
          next;
        }
        if (!LINT_ISSUES) next;
      }

      # No Lint Issues block (invert: only print if none)
      /{{\^LINT_ISSUES}}/,/{{\/LINT_ISSUES}}/ {
        if (LINT_ISSUES) next;
      }

      # Default: print any other lines not handled above, and skip Mustache
      !/{{[#\/^].*}}/ { print }
    '
  } >>"$report_file"

  echo -e "\n📄 Markdown report saved to \033[1;36m$report_file\033[0m"
}
