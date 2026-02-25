#!/usr/bin/env bash

set -euo pipefail

CHANGED_FILES="$1"

source "$(dirname "$0")/resolve-targets.sh"
declare -A REPO_TARGETS
resolve_targets \
  "$CHANGED_FILES" \
  shared/distribution.yaml \
  REPO_TARGETS

JSON="[]"

for repo in "${!REPO_TARGETS[@]}"; do
  mappings="${REPO_TARGETS[$repo]}"
  use_pr=true

  while IFS='|' read -r src dest pr; do
    [ -z "$src" ] && continue
    [ "$pr" = "false" ] && use_pr=false
  done <<< "$mappings"

  JSON=$(jq -c \
    --arg repo "$repo" \
    --arg mappings "$mappings" \
    --argjson use_pr "$use_pr" \
    '. += [{repo: $repo, mappings: $mappings, use_pr: $use_pr}]' \
    <<< "$JSON")
done

echo "targets=${JSON}" >> "$GITHUB_OUTPUT"
