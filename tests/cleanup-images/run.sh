#!/usr/bin/env bash
# shellcheck disable=SC2016,SC2034

set -euo pipefail

here="$(cd "$(dirname "$0")" && pwd)"
script="${here}/../../scripts/cleanup-images.sh"
work="$(mktemp -d)"
trap 'rm -rf "${work}"' EXIT

python3 "${here}/gen.py" "${work}/fx"

export PATH="${here}/bin:${PATH}"
export MOCK_FX="${work}/fx"
export MOCK_LOG="${work}/deleted.log"
export NOW=1800000000
unset GITHUB_STEP_SUMMARY

failures=0

check() {
  if eval "$2"; then
    echo "ok   $1"
  else
    echo "FAIL $1"
    failures=$((failures + 1))
  fi
}

run() {
  rm -f "${MOCK_LOG}" "${MOCK_LOG}".*.lists
  touch "${MOCK_LOG}"
  set +e
  env "$@" "${script}" > "${work}/out" 2>&1
  status=$?
  set -e
}

verdict() {
  grep -qE "^$1 +$2 +$3 " "${work}/out"
}

run DRY_RUN=true
check "dry run exits 0" '[ "${status}" -eq 0 ]'
check "plan is 82 DELETE / 95 KEEP" 'grep -qxF "Plan: 82 to delete, 95 kept (dry run: true)" "${work}/out"'
check "dry run deletes nothing" '[ ! -s "${MOCK_LOG}" ]'
check "pagination reads both pages" 'grep -qxF "Listed workspace: 157 versions" "${work}/out" && verdict DELETE workspace 1171 && verdict KEEP workspace 1172'
check "latest kept" 'verdict KEEP ws-server 1001'
check "old build-* child of a tagged index kept" 'verdict KEEP ws-server 1002 && verdict KEEP ws-server 1003'
check "untagged index children kept" 'verdict KEEP ws-server 1004 && verdict KEEP workspace 1018'
check "open PR kept" 'verdict KEEP ws-server 1005 && verdict KEEP workspace 1022'
check "closed PR deleted" 'verdict DELETE ws-server 1006 && verdict DELETE ws-server/testbench 1177'
check "merged PR deleted" 'verdict DELETE workspace 1021'
check "merged PR with a young build-* kept" 'verdict KEEP ws-server 1007'
check "build-* older than 30 days deleted" 'verdict DELETE ws-server 1008'
check "build-* at 29 days kept" 'verdict KEEP ws-server 1009'
check "untagged 3 days kept" 'verdict KEEP ws-server 1010'
check "untagged 10 days deleted" 'verdict DELETE ws-server 1011 && verdict DELETE ws-server/cache 1175'
check "closed PR index deleted, children kept" 'verdict DELETE ws-server 1012 && verdict KEEP ws-server 1013 && verdict KEEP ws-server 1014'
check "cross-package protected digest kept" 'verdict KEEP ws-server 1015'
check "dev plus old build-* kept" 'verdict KEEP workspace 1016'
check "release tags kept" 'verdict KEEP workspace 1017'
check "cache and testbench dev kept" 'verdict KEEP ws-server/cache 1173 && verdict KEEP ws-server/cache 1174 && verdict KEEP ws-server/testbench 1176'

run DRY_RUN=true UNTAGGED_MAX_AGE_DAYS=10
check "untagged exactly at the limit kept" 'verdict KEEP ws-server 1011'
run DRY_RUN=true UNTAGGED_MAX_AGE_DAYS=9
check "untagged one day past the limit deleted" 'verdict DELETE ws-server 1011'

run DRY_RUN=false
check "real run deletes the plan" '[ "${status}" -eq 0 ] && [ "$(wc -l < "${MOCK_LOG}")" -eq 82 ]'

run DRY_RUN=false MOCK_GONE=1006 MOCK_RETAG=1008
check "gone version is a no-op" 'grep -q "^GONE   ws-server 1006 " "${work}/out"'
check "retagged version is skipped" 'grep -q "^SKIP   ws-server 1008 .*tags changed" "${work}/out"'
check "mid-run cases delete the rest" '[ "${status}" -eq 0 ] && [ "$(wc -l < "${MOCK_LOG}")" -eq 80 ]'

run DRY_RUN=false MOCK_DELETE_FAIL=1006
check "a refused delete fails the run" '[ "${status}" -eq 1 ] && [ ! -s "${MOCK_LOG}" ] && grep -q "Deleting ws-server 1006 failed" "${work}/out" && ! grep -q "^GONE" "${work}/out"'

run DRY_RUN=false MOCK_FAIL_RELIST=ws-server
check "a failed re-list fails the run" '[ "${status}" -eq 1 ] && [ ! -s "${MOCK_LOG}" ] && grep -q "Re-listing ws-server failed" "${work}/out"'

run DRY_RUN=false MAX_DELETES=1
check "MAX_DELETES=1 deletes exactly one" '[ "${status}" -eq 0 ] && [ "$(wc -l < "${MOCK_LOG}")" -eq 1 ] && grep -qxF "Stopping at MAX_DELETES=1" "${work}/out"'

run DRY_RUN=false MAX_DELETES=abc
check "a non-numeric MAX_DELETES is refused" '[ "${status}" -eq 1 ] && [ ! -s "${MOCK_LOG}" ]'

for failure in MOCK_FAIL_PR=801 MOCK_FAIL_LIST=workspace "MOCK_FAIL_INSPECT=sha256:$(printf '%064x' 60)"; do
  run DRY_RUN=false "${failure}"
  check "${failure%%=*} fails closed" '[ "${status}" -eq 1 ] && [ ! -s "${MOCK_LOG}" ] && grep -q "nothing was deleted" "${work}/out"'
done

[ "${failures}" -eq 0 ] || { echo "${failures} check(s) failed"; exit 1; }
