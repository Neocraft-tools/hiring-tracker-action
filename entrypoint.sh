#!/usr/bin/env bash
# Open jobs of companies (Greenhouse, Lever, Ashby, Workable...) and new/closed jobs since the previous run.
set -euo pipefail
. "$(dirname "$0")/apify.sh"
check_prereqs

COMPANIES="$(split_list "${INPUT_COMPANIES:-}")"
[ "$(jq length <<<"$COMPANIES")" -gt 0 ] || fail "Input 'companies' is required (names, domains or job-board URLs)"
MODE="${INPUT_MODE:-changes}"
STATE="${INPUT_STATE_KEY:-}"
[ -z "$STATE" ] && STATE="$(printf '%s' "${GITHUB_REPOSITORY:-github-action}" | tr -c 'A-Za-z0-9._\n-' '-')"

BASE="$(jq -c -n --argjson c "$COMPANIES" --arg mode "$MODE" --arg state "$STATE" \
  --argjson ti "$(split_list "${INPUT_TITLE_INCLUDE:-}")" --argjson te "$(split_list "${INPUT_TITLE_EXCLUDE:-}")" \
  --argjson co "$(split_list "${INPUT_COUNTRIES:-}")" --argjson remote "$(bool "${INPUT_REMOTE_ONLY:-}" false)" \
  --argjson max "${INPUT_MAX_JOBS_PER_COMPANY:-0}" \
  '{companies: $c, mode: $mode, stateKey: $state, remoteOnly: $remote, maxJobsPerCompany: $max}
   + (if ($ti | length) > 0 then {titleInclude: $ti} else {} end)
   + (if ($te | length) > 0 then {titleExclude: $te} else {} end)
   + (if ($co | length) > 0 then {countries: $co} else {} end)')"
INPUT="$(merge_extra "$BASE" "${INPUT_EXTRA_INPUT:-}")"

CAP="${INPUT_MAX_TOTAL_CHARGE_USD:-0.25}"
OUT="${INPUT_OUTPUT_FILE:-hiring.json}"
apify_run "neocraft~company-hiring-tracker" "$INPUT" "$CAP" "${INPUT_TIMEOUT_SECS:-900}" "$OUT"

JOBS="$(jq -c '[.[] | select(.type == "job")]' "$OUT")"
NJ="$(jq length <<<"$JOBS")"
NEW="$(jq '[.[] | select(.changeType == "new" or .changeType == "reopened")] | length' <<<"$JOBS")"
CLOSED="$(jq '[.[] | select(.changeType == "closed")] | length' <<<"$JOBS")"
{
  echo "## Hiring tracker (${MODE} mode)"
  echo
  echo "| Company | Open jobs | Net change 30d | Summary |"
  echo "|---|---:|---:|---|"
  jq -r '.[] | select(.type == "company") | "| \(.company) | \(.openJobs // "") | \(.netChange30d // "") | \((.summary // "") | gsub("\\|"; "/") | .[0:200]) |"' "$OUT"
  jq -r '[.[] | select(.type == "coverage" and .covered == false)] | if length > 0 then "\nNot covered (free): " + (map(.query | tostring) | join(", ")) else empty end' "$OUT"
  if [ "$NJ" -gt 0 ]; then
    echo
    echo "### Jobs (${NJ}, first 50)"
    jq -r '.[:50][] | "- \(if .changeType then "**" + .changeType + "** " else "" end)[\(.title)](\(.url // "")) · \(.company) · \((.locations // []) | if type == "array" then join(", ") else tostring end)"' <<<"$JOBS"
  fi
  true
} | summary
footer "$CAP"

set_output job-count "$NJ"
set_output new-count "$NEW"
set_output closed-count "$CLOSED"
set_output jobs "$(jq -c 'map({company, title, changeType, department, country, remote, url})' <<<"$JOBS" | head -c 60000)"

if [ "$NEW" -gt 0 ] && [ "$(bool "${INPUT_FAIL_ON_NEW_JOBS:-}" false)" = "true" ]; then
  echo "::error::${NEW} new or reopened job(s)"
  exit 1
fi
echo "Done: ${NJ} job row(s), ${NEW} new/reopened, ${CLOSED} closed"
