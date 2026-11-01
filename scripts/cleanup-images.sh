#!/usr/bin/env bash

set -euo pipefail

OWNER="${OWNER:-kloudkit}"
REGISTRY="${REGISTRY:-ghcr.io}"
PACKAGES="${PACKAGES:-ws-server:ws-server ws-server/testbench:ws-server ws-server/cache:ws-server workspace:workspace}"
DRY_RUN="${DRY_RUN:-true}"
BUILD_MAX_AGE_DAYS="${BUILD_MAX_AGE_DAYS:-30}"
UNTAGGED_MAX_AGE_DAYS="${UNTAGGED_MAX_AGE_DAYS:-7}"
NOW="${NOW:-$(date -u +%s)}"

[ "${DRY_RUN}" = "false" ] || DRY_RUN=true

work="$(mktemp -d)"
trap 'rm -rf "${work}"' EXIT

fail() {
  echo "::error::$*" >&2
  echo "::error::Protected set incomplete; nothing was deleted" >&2
  exit 1
}

versions_url() {
  printf '/orgs/%s/packages/container/%s/versions' "${OWNER}" "${1//\//%2F}"
}

echo "${PACKAGES}" | tr ' ' '\n' | sed '/^$/d' > "${work}/packages"

: > "${work}/versions.jsonl"
while IFS=: read -r package repo; do
  [ -n "${repo}" ] || fail "PACKAGES entry '${package}' needs the form package:repo"

  gh api --paginate --slurp "$(versions_url "${package}")?per_page=100" \
    > "${work}/page.json" || fail "Listing ${package} failed"

  jq -c --arg package "${package}" --arg repo "${repo}" '
    if type != "array" or any(.[]; type != "array") then error("not a list of pages") else . end
    | add // []
    | .[]
    | {
        package: $package,
        repo: $repo,
        id: .id,
        digest: .name,
        updated: (.updated_at | fromdateiso8601),
        tags: (.metadata.container.tags // [])
      }
  ' "${work}/page.json" >> "${work}/versions.jsonl" || fail "Parsing ${package} versions failed"

  echo "Listed ${package}: $(jq -s --arg p "${package}" 'map(select(.package == $p)) | length' "${work}/versions.jsonl") versions"
done < "${work}/packages"

jq -s '.' "${work}/versions.jsonl" > "${work}/versions.json"

jq -r '.[] | .repo as $r | .tags[] | select(test("^pr-[0-9]+$")) | "\($r) \(ltrimstr("pr-"))"' \
  "${work}/versions.json" | sort -u > "${work}/prs"

: > "${work}/prs.jsonl"
while read -r repo number; do
  state="$(gh pr view "${number}" --repo "${OWNER}/${repo}" --json state --jq .state < /dev/null)" \
    || fail "PR lookup ${OWNER}/${repo}#${number} failed"
  case "${state}" in
    OPEN|CLOSED|MERGED) ;;
    *) fail "PR ${OWNER}/${repo}#${number} has unexpected state '${state}'" ;;
  esac
  jq -nc --arg k "${repo}#${number}" --arg s "${state}" '{($k): $s}' >> "${work}/prs.jsonl"
done < "${work}/prs"
jq -s 'add // {}' "${work}/prs.jsonl" > "${work}/prs.json"

jq -r '.[] | select(.tags | length > 0) | "\(.package) \(.digest)"' "${work}/versions.json" \
  > "${work}/queue"

: > "${work}/children"
: > "${work}/seen"
while [ -s "${work}/queue" ]; do
  : > "${work}/next"
  while read -r package digest; do
    grep -qxF "${package} ${digest}" "${work}/seen" && continue
    echo "${package} ${digest}" >> "${work}/seen"

    docker buildx imagetools inspect --raw "${REGISTRY}/${OWNER}/${package}@${digest}" \
      < /dev/null > "${work}/manifest.json" || fail "Fetching ${package}@${digest} failed"

    jq -r '.manifests // [] | .[] | "\(.digest) \(.mediaType // "")"' "${work}/manifest.json" \
      > "${work}/entries" || fail "Parsing ${package}@${digest} failed"

    while read -r child media; do
      echo "${child}" >> "${work}/children"
      case "${media}" in
        *manifest.list*|*image.index*) echo "${package} ${child}" >> "${work}/next" ;;
      esac
    done < "${work}/entries"
  done < "${work}/queue"
  mv "${work}/next" "${work}/queue"
done
sort -u "${work}/children" | jq -Rn '[inputs | select(length > 0)]' > "${work}/children.json"

jq -r \
  --argjson now "${NOW}" \
  --argjson build_days "${BUILD_MAX_AGE_DAYS}" \
  --argjson untagged_days "${UNTAGGED_MAX_AGE_DAYS}" \
  --slurpfile prs "${work}/prs.json" \
  --slurpfile children "${work}/children.json" '
  def days: (($now - .updated) / 86400 | floor);
  def verdict($v):
    if test("^pr-[0-9]+$") then
      ($prs[0]["\($v.repo)#\(ltrimstr("pr-"))"]) as $s
      | if $s == "CLOSED" or $s == "MERGED" then {ok: true, why: "\(.) \($s | ascii_downcase) PR"}
        else {ok: false, why: "\(.) \($s // "unknown" | ascii_downcase) PR"} end
    elif startswith("build-") then
      if ($v | days) > $build_days then {ok: true, why: "\(.) \($v | days)d old"}
      else {ok: false, why: "\(.) \($v | days)d old"} end
    else {ok: false, why: "\(.) protected"} end;

  . as $all
  | ($children[0] | map({(.): true}) | add // {}) as $child
  | ([ $all[] as $v | select(any($v.tags[]; verdict($v).ok | not)) | $v.digest ]
     | map({(.): true}) | add // {}) as $protected
  | $all[]
  | . as $v
  | [ .tags[] | verdict($v) ] as $verdicts
  | (if ($v.tags | length) == 0 then
       if $child[$v.digest] then {act: "KEEP", why: "untagged child of a tagged index"}
       elif ($v | days) > $untagged_days then {act: "DELETE", why: "untagged \($v | days)d"}
       else {act: "KEEP", why: "untagged \($v | days)d"} end
     elif ($verdicts | all(.ok)) | not then
       {act: "KEEP", why: ($verdicts | map(.why) | join(", "))}
     elif $protected[$v.digest] then
       {act: "KEEP", why: "digest carries a protected tag elsewhere"}
     elif $child[$v.digest] then
       {act: "KEEP", why: "child of a tagged index; \($verdicts | map(.why) | join(", "))"}
     else
       {act: "DELETE", why: ($verdicts | map(.why) | join(", "))}
     end) as $d
  | [$d.act, $v.package, ($v.id | tostring), $v.digest, ($v.tags | if length == 0 then "-" else join(",") end), $d.why] | @tsv
' "${work}/versions.json" > "${work}/plan.tsv" || fail "Planning failed"

kept=0
planned=0
while IFS=$'\t' read -r act package id digest tags why; do
  printf '%-6s %-20s %-10s %s [%s] %s\n' "${act}" "${package}" "${id}" "${digest}" "${tags}" "${why}"
  if [ "${act}" = DELETE ]; then planned=$((planned + 1)); else kept=$((kept + 1)); fi
done < "${work}/plan.tsv"

echo "Plan: ${planned} to delete, ${kept} kept (dry run: ${DRY_RUN})"

deleted=0
if [ "${DRY_RUN}" = false ]; then
  while IFS=$'\t' read -r act package id digest tags why; do
    [ "${act}" = DELETE ] || continue
    url="$(versions_url "${package}")/${id}"

    if ! current="$(gh api "${url}" --jq '.metadata.container.tags // [] | if length == 0 then "-" else join(",") end' \
      < /dev/null 2> "${work}/err")"; then
      if grep -q "HTTP 404" "${work}/err"; then
        echo "GONE   ${package} ${id} ${digest}"
        continue
      fi
      cat "${work}/err" >&2
      echo "::error::Re-reading ${package} ${id} failed; stopping after ${deleted} deletions" >&2
      exit 1
    fi

    if [ "${current}" != "${tags}" ]; then
      echo "SKIP   ${package} ${id} ${digest}: tags changed from [${tags}] to [${current}]"
      continue
    fi

    if ! gh api --method DELETE "${url}" < /dev/null > /dev/null 2> "${work}/err"; then
      if grep -q "HTTP 404" "${work}/err"; then
        echo "GONE   ${package} ${id} ${digest}"
        continue
      fi
      cat "${work}/err" >&2
      echo "::error::Deleting ${package} ${id} failed; stopping after ${deleted} deletions" >&2
      exit 1
    fi

    echo "DELETED ${package} ${id} ${digest}"
    deleted=$((deleted + 1))
  done < "${work}/plan.tsv"
fi

if [ -n "${GITHUB_STEP_SUMMARY:-}" ]; then
  {
    echo "## 🧹 Image cleanup (dry run: ${DRY_RUN})"
    echo
    echo "- Planned: ${planned}"
    echo "- Deleted: ${deleted}"
    echo "- Kept: ${kept}"
    if [ "${planned}" -gt 0 ]; then
      echo
      echo "| Package | ID | Digest | Tags | Reason |"
      echo "|---|---|---|---|---|"
      while IFS=$'\t' read -r act package id digest tags why; do
        [ "${act}" = DELETE ] || continue
        echo "| ${package} | ${id} | \`${digest}\` | ${tags} | ${why} |"
      done < "${work}/plan.tsv"
    fi
  } >> "${GITHUB_STEP_SUMMARY}"
fi
