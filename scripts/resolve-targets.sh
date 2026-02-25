#!/usr/bin/env bash
# Maps changed files against distribution.yaml to build per-repo target lists.
# Usage: resolve_targets "$changed_files" "$config_path" RESULT_ARRAY_NAME

resolve_targets() {
  local changed_files="$1"
  local config="$2"
  local -n result="$3"

  # Single yq pass: emit every entry as key|repo|path|pr
  local entries
  entries=$(yq -r '
    to_entries[] | .key as $k | .value[] |
    "\($k)|\(.repo)|\(.path)|\(.pr // true)"
  ' "$config")

  while IFS= read -r changed_file; do
    [ -z "$changed_file" ] && continue

    while IFS='|' read -r key repo dest pr; do
      [ -z "$key" ] && continue
      if [[ "$changed_file" == "$key" || "$changed_file" == "$key"* ]]; then
        result["$repo"]+="${changed_file}|${dest}|${pr}"$'\n'
      fi
    done <<< "$entries"
  done <<< "$changed_files"
}
