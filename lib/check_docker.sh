#!/usr/bin/env bash

check_docker() {
  local file="$1"
  local mode="${2:-all}"

  qecho "🧪 [docker] Checking $file"

  if tool_enabled_for docker dockerfmt && [[ "$mode" =~ ^(fix|all)$ ]]; then
    check_tool_or_prompt dockerfmt "go install github.com/lucasepe/dockerfmt@latest" || return
    qecho "🎨 Formatting $file with dockerfmt"
    dockerfmt -w "$file"
  fi

  if tool_enabled_for docker hadolint && [[ "$mode" =~ ^(lint|all)$ ]]; then
    check_tool_or_prompt hadolint "brew install hadolint" || return
    qecho "🔍 Linting $file with hadolint"
    if ! hadolint "$file"; then
      PROBLEM_FILES+=("$file")
    fi
  fi

  if tool_enabled_for docker dockle; then
    check_tool_or_prompt dockle "brew install dockle" || return
    qecho "🔐 Security (dockle): scanning image from $file"
    IMAGE=$(grep -i "^FROM " "$file" | awk '{print $2}' | head -n 1)
    [[ -n "$IMAGE" ]] && dockle "$IMAGE" || echo "⚠️  No FROM image found to scan with dockle"
  fi

  if tool_enabled_for docker trivy; then
    check_tool_or_prompt trivy "brew install trivy" || return
    qecho "🛡️ Security (trivy): scanning image from $file"
    IMAGE=$(grep -i "^FROM " "$file" | awk '{print $2}' | head -n 1)
    [[ -n "$IMAGE" ]] && trivy image --quiet "$IMAGE" || echo "⚠️  No FROM image found to scan with trivy"
  fi

  if tool_enabled_for docker grype; then
    check_tool_or_prompt grype "brew install grype" || return
    qecho "🔎 Vulnerabilities (grype): scanning image from $file"
    IMAGE=$(grep -i "^FROM " "$file" | awk '{print $2}' | head -n 1)
    [[ -n "$IMAGE" ]] && grype "$IMAGE" || echo "⚠️  No FROM image found to scan with grype"
  fi
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  check_markdown "$@"
fi
