#!/bin/bash
# security-stack-ats.sh -- profile a company's security tool stack via public
# ATS (Applicant Tracking System) job board JSON APIs. No Apify required.
#
# Cascade order (stops at first hit with >0 jobs):
#   1. Greenhouse     boards-api.greenhouse.io/v1/boards/<slug>/jobs?content=true
#   2. Lever          api.lever.co/v0/postings/<slug>?mode=json
#   3. Ashby          api.ashbyhq.com/posting-api/job-board/<slug>
#   4. Workable       apply.workable.com/api/v3/accounts/<slug>/jobs
#   5. SmartRecruiters api.smartrecruiters.com/v1/companies/<slug>/postings
#   6. Recruitee      <slug>.recruitee.com/api/offers/
#
# Also supports Workday via explicit URL (Workday requires tenant+region+site
# not a simple slug, so it's not in the auto-cascade):
#   security-stack-ats.sh --company "Acme" --workday-url "https://acme.wd12.myworkdayjobs.com/AcmeCareers"
#
# Usage:
#   security-stack-ats.sh --company "Acme Corp" --slug acme [--ats greenhouse|lever|ashby|workable|smartrecruiters|recruitee] [--output-dir ./out]
#   security-stack-ats.sh --company "Acme Corp" --workday-url "https://acme.wd12.myworkdayjobs.com/AcmeCareers" [--output-dir ./out]
#
# Examples:
#   # Auto-detect (try all ATS in order):
#   security-stack-ats.sh --company "Vercel" --slug vercel
#
#   # Force a specific ATS:
#   security-stack-ats.sh --company "GitLab" --slug gitlab --ats greenhouse
#
# Requires: curl, jq. No Apify token needed.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

COMPANY=""
SLUG=""
FORCE_ATS=""
WORKDAY_URL=""
OUTPUT_DIR="./security-stack-output"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --company) COMPANY="$2"; shift 2 ;;
    --slug) SLUG="$2"; shift 2 ;;
    --ats) FORCE_ATS="$2"; shift 2 ;;
    --workday-url) WORKDAY_URL="$2"; shift 2 ;;
    --output-dir) OUTPUT_DIR="$2"; shift 2 ;;
    -h|--help) sed -n '2,22p' "$0"; exit 0 ;;
    *) echo "ERROR: unknown arg $1" >&2; exit 1 ;;
  esac
done

if [ -z "$COMPANY" ]; then
  echo "ERROR: --company required" >&2
  exit 1
fi
if [ -z "$SLUG" ] && [ -z "$WORKDAY_URL" ]; then
  echo "ERROR: either --slug (for cascade ATS) or --workday-url required" >&2
  echo "  Try --help for usage." >&2
  exit 1
fi

command -v curl >/dev/null 2>&1 || { echo "ERROR: curl not installed" >&2; exit 1; }
command -v jq >/dev/null 2>&1 || { echo "ERROR: jq not installed (brew install jq)" >&2; exit 1; }

mkdir -p "$OUTPUT_DIR"
TS=$(date -u +"%Y%m%dT%H%M%SZ")
WORK_DIR="$OUTPUT_DIR/.ats-$SLUG-$TS"
mkdir -p "$WORK_DIR"

echo "=== ATS cascade for: $COMPANY (slug: $SLUG) ==="
echo ""

# ---- helpers ------------------------------------------------------------------

strip_html() {
  # Some ATS (Greenhouse) return HTML-entity-encoded content.
  # Decode entities FIRST so the tag stripper can match them; THEN strip tags;
  # THEN collapse whitespace.
  sed -E 's/&lt;/</g; s/&gt;/>/g; s/&quot;/"/g; s/&#39;/'\''/g; s/&nbsp;/ /g; s/&amp;/\&/g' | \
    sed -E 's/<[^>]+>/ /g' | \
    tr -s '[:space:]' ' '
}

fetch_json() {
  # Args: URL. Returns body on stdout, exits non-zero if HTTP >=400.
  local url="$1"
  local tmp_body
  tmp_body=$(mktemp)
  local http_code
  http_code=$(curl -s -o "$tmp_body" -w "%{http_code}" \
    --connect-timeout 10 --max-time 30 \
    -H "Accept: application/json" \
    -H "User-Agent: q-osint/1.0" \
    "$url" || echo "000")
  if [ "$http_code" -ge 400 ] || [ "$http_code" = "000" ]; then
    rm -f "$tmp_body"
    return 1
  fi
  cat "$tmp_body"
  rm -f "$tmp_body"
}

# ---- ATS probe functions ------------------------------------------------------
# Each returns 0 (success) on finding >=1 job and writes extracted text to $2 (output file).
# Returns non-zero on ATS miss, invalid response, or zero jobs.

try_greenhouse() {
  local slug="$1"; local out="$2"
  local url="https://boards-api.greenhouse.io/v1/boards/${slug}/jobs?content=true"
  local body
  body=$(fetch_json "$url") || return 1
  local count
  count=$(echo "$body" | jq '.jobs | length' 2>/dev/null || echo 0)
  [ "$count" -gt 0 ] 2>/dev/null || return 1
  echo "$body" | jq -r '.jobs[] | (.title // "") + " " + (.content // "")' | strip_html > "$out"
  echo "$count"
  return 0
}

try_lever() {
  local slug="$1"; local out="$2"
  local url="https://api.lever.co/v0/postings/${slug}?mode=json"
  local body
  body=$(fetch_json "$url") || return 1
  local count
  count=$(echo "$body" | jq 'length' 2>/dev/null || echo 0)
  [ "$count" -gt 0 ] 2>/dev/null || return 1
  echo "$body" | jq -r '.[] | (.text // "") + " " + (.descriptionPlain // "") + " " + ((.lists // []) | map(.content // "") | join(" ")) + " " + (.additionalPlain // "")' | strip_html > "$out"
  echo "$count"
  return 0
}

try_ashby() {
  local slug="$1"; local out="$2"
  local url="https://api.ashbyhq.com/posting-api/job-board/${slug}"
  local body
  body=$(fetch_json "$url") || return 1
  local count
  count=$(echo "$body" | jq '.jobs | length' 2>/dev/null || echo 0)
  [ "$count" -gt 0 ] 2>/dev/null || return 1
  echo "$body" | jq -r '.jobs[] | (.title // "") + " " + (.departmentName // "") + " " + (.descriptionHtml // "") + " " + (.descriptionPlain // "")' | strip_html > "$out"
  echo "$count"
  return 0
}

try_workable() {
  local slug="$1"; local out="$2"
  local url="https://apply.workable.com/api/v3/accounts/${slug}/jobs"
  local body
  body=$(fetch_json "$url") || return 1
  local count
  count=$(echo "$body" | jq '.jobs | length // (.results | length) // 0' 2>/dev/null || echo 0)
  [ "$count" -gt 0 ] 2>/dev/null || return 1
  echo "$body" | jq -r '(.jobs // .results // []) | .[] | (.title // "") + " " + (.description // "") + " " + (.requirements // "") + " " + (.benefits // "")' | strip_html > "$out"
  echo "$count"
  return 0
}

try_smartrecruiters() {
  local slug="$1"; local out="$2"
  local url="https://api.smartrecruiters.com/v1/companies/${slug}/postings"
  local body
  body=$(fetch_json "$url") || return 1
  local count
  count=$(echo "$body" | jq '.content | length // 0' 2>/dev/null || echo 0)
  [ "$count" -gt 0 ] 2>/dev/null || return 1
  # SmartRecruiters listing only gives metadata -- fetch each posting for full text.
  local ids
  ids=$(echo "$body" | jq -r '.content[].id // empty')
  : > "$out"
  local id detail
  for id in $ids; do
    detail=$(fetch_json "https://api.smartrecruiters.com/v1/companies/${slug}/postings/${id}") || continue
    echo "$detail" | jq -r '(.name // "") + " " + ([.jobAd.sections | to_entries[]? | .value.text // ""] | join(" "))' | strip_html >> "$out"
  done
  echo "$count"
  return 0
}

try_recruitee() {
  local slug="$1"; local out="$2"
  local url="https://${slug}.recruitee.com/api/offers/"
  local body
  body=$(fetch_json "$url") || return 1
  local count
  count=$(echo "$body" | jq '.offers | length' 2>/dev/null || echo 0)
  [ "$count" -gt 0 ] 2>/dev/null || return 1
  echo "$body" | jq -r '.offers[] | (.title // "") + " " + (.description // "") + " " + (.requirements // "")' | strip_html > "$out"
  echo "$count"
  return 0
}

try_workday() {
  # Workday URL format: https://{tenant}.{region}.myworkdayjobs.com/{site}
  local workday_url="$1"; local out="$2"
  local stripped="${workday_url#https://}"
  stripped="${stripped#http://}"
  local host="${stripped%%/*}"
  local site="${stripped#*/}"
  site="${site%%/*}"
  site="${site%%\?*}"
  local tenant="${host%%.*}"

  [ -z "$tenant" ] || [ -z "$site" ] || [ -z "$host" ] && return 1

  local base_api="https://${host}/wday/cxs/${tenant}/${site}"
  local offset=0 limit=20 total=0 collected=0
  local tmp_raw="$out.tmp-raw"
  : > "$tmp_raw"

  while true; do
    local resp
    resp=$(curl -s --max-time 30 \
      --connect-timeout 10 \
      -X POST "${base_api}/jobs" \
      -H "Content-Type: application/json" \
      -H "Accept: application/json" \
      -H "User-Agent: q-osint/1.0" \
      -d "{\"appliedFacets\":{},\"limit\":${limit},\"offset\":${offset}}") || { rm -f "$tmp_raw"; return 1; }
    total=$(echo "$resp" | jq '.total // 0' 2>/dev/null || echo 0)
    local page_count
    page_count=$(echo "$resp" | jq '.jobPostings | length // 0' 2>/dev/null || echo 0)
    [ "$page_count" -eq 0 ] && break
    local paths
    paths=$(echo "$resp" | jq -r '.jobPostings[].externalPath' 2>/dev/null || true)
    local p
    for p in $paths; do
      local detail
      detail=$(curl -s --max-time 30 --connect-timeout 10 \
        -H "Accept: application/json" -H "User-Agent: q-osint/1.0" \
        "${base_api}${p}") || continue
      echo "$detail" | jq -r '(.jobPostingInfo.title // "") + " " + (.jobPostingInfo.jobDescription // "")' 2>/dev/null >> "$tmp_raw" || true
    done
    collected=$((collected + page_count))
    offset=$((offset + limit))
    [ "$collected" -ge "$total" ] && break
    [ "$offset" -gt 500 ] && break   # sanity cap
  done

  if [ ! -s "$tmp_raw" ]; then
    rm -f "$tmp_raw"
    return 1
  fi
  strip_html < "$tmp_raw" > "$out"
  rm -f "$tmp_raw"
  echo "$collected"
  return 0
}

# ---- cascade ------------------------------------------------------------------

PROBES=(greenhouse lever ashby workable smartrecruiters recruitee)

if [ -n "$FORCE_ATS" ]; then
  # Validate
  case "$FORCE_ATS" in
    greenhouse|lever|ashby|workable|smartrecruiters|recruitee) PROBES=("$FORCE_ATS") ;;
    workday) echo "ERROR: Workday requires --workday-url, not --ats workday" >&2; exit 1 ;;
    *) echo "ERROR: unsupported --ats $FORCE_ATS" >&2; exit 1 ;;
  esac
fi

JOBS_OUT="$WORK_DIR/jobs.txt"
ATS_HIT=""
JOB_COUNT=0

# Workday path (explicit URL supplied)
if [ -n "$WORKDAY_URL" ]; then
  echo -n "  trying workday (${WORKDAY_URL})... "
  result=$(try_workday "$WORKDAY_URL" "$JOBS_OUT" 2>/dev/null) || result=""
  if [ -n "$result" ]; then
    ATS_HIT="workday"
    JOB_COUNT="$result"
    echo "HIT ($result jobs)"
  else
    echo "miss (check URL format and that the tenant/site exist)"
  fi
fi

# Cascade for slug-based ATSes (skip if workday already succeeded)
if [ -z "$ATS_HIT" ] && [ -n "$SLUG" ]; then
  for probe in "${PROBES[@]}"; do
    echo -n "  trying ${probe}... "
    func="try_${probe}"
    result=$($func "$SLUG" "$JOBS_OUT" 2>/dev/null) || result=""
    if [ -n "$result" ]; then
      ATS_HIT="$probe"
      JOB_COUNT="$result"
      echo "HIT ($result jobs)"
      break
    fi
    echo "miss"
  done
fi

if [ -z "$ATS_HIT" ]; then
  echo ""
  echo "=== No ATS detected ===" >&2
  [ -n "$SLUG" ] && echo "Tried for slug '$SLUG': ${PROBES[*]}" >&2
  [ -n "$WORKDAY_URL" ] && echo "Tried workday URL: $WORKDAY_URL" >&2
  echo "Options:" >&2
  echo "  1. Try a different slug (check the company's careers page URL)" >&2
  echo "  2. Use --ats <name> to force a specific ATS" >&2
  echo "  3. Use --workday-url for Workday-hosted companies" >&2
  echo "  4. Fall back to security-stack.sh with --careers-url (Apify web-scraper)" >&2
  exit 2
fi

echo ""
echo "=== ATS hit: $ATS_HIT ($JOB_COUNT postings) ==="
echo "  text file: $JOBS_OUT"
echo "  size: $(wc -c < "$JOBS_OUT") bytes"
echo ""
echo "=== Running extractor ==="
echo ""

python3 "$SCRIPT_DIR/security-stack-extract.py" \
  --company "$COMPANY" \
  --jobs "$JOBS_OUT" \
  --output-dir "$OUTPUT_DIR"

echo ""
echo "ATS source preserved at: $WORK_DIR/jobs.txt"
echo "ATS detected: $ATS_HIT"
echo "Postings analyzed: $JOB_COUNT"
