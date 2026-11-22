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
  JSON=$(jq -c \
    --arg repo "$repo" \
    --arg mappings "${REPO_TARGETS[$repo]}" \
    '. += [{repo: $repo, mappings: $mappings}]' \
    <<< "$JSON")
done

echo "targets=${JSON}" >> "$GITHUB_OUTPUT"
