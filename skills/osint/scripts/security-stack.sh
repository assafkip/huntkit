#!/bin/bash
# security-stack.sh -- profile a company's security tool stack via job postings
# and LinkedIn employee skills.
#
# This is a 2-signal pipeline:
#   1. Careers page (Apify web-scraper) -- captures job descriptions mentioning tools
#   2. LinkedIn company employees (configurable actor) -- captures employee skills
#
# Neither signal is required alone. Run with whichever you have.
#
# Usage:
#   security-stack.sh --company "Acme Corp" \
#       [--careers-url https://acme.com/careers] \
#       [--linkedin-company-url https://linkedin.com/company/acme] \
#       [--job-posts-url https://boards.greenhouse.io/acme] \
#       [--linkedin-actor "harvestapi/linkedin-company-employees"] \
#       [--output-dir ./out/]
#
# Env:
#   APIFY_API_TOKEN or APIFY_TOKEN -- required for Apify calls
#
# Examples:
#   # Just a careers page
#   security-stack.sh --company "Fortitude Law" --careers-url "https://fortitude.law/careers"
#
#   # LinkedIn only (no careers page available)
#   security-stack.sh --company "Acme" --linkedin-company-url "https://linkedin.com/company/acme"

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SKILL_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

COMPANY=""
CAREERS_URL=""
LINKEDIN_URL=""
JOB_POSTS_URL=""
LINKEDIN_ACTOR="harvestapi/linkedin-company-employees"
OUTPUT_DIR="./security-stack-output"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --company) COMPANY="$2"; shift 2 ;;
    --careers-url) CAREERS_URL="$2"; shift 2 ;;
    --linkedin-company-url) LINKEDIN_URL="$2"; shift 2 ;;
    --job-posts-url) JOB_POSTS_URL="$2"; shift 2 ;;
    --linkedin-actor) LINKEDIN_ACTOR="$2"; shift 2 ;;
    --output-dir) OUTPUT_DIR="$2"; shift 2 ;;
    -h|--help)
      sed -n '2,30p' "$0"
      exit 0
      ;;
    *) echo "ERROR: unknown arg $1" >&2; exit 1 ;;
  esac
done

if [ -z "$COMPANY" ]; then
  echo "ERROR: --company required" >&2
  exit 1
fi

if [ -z "$CAREERS_URL" ] && [ -z "$LINKEDIN_URL" ] && [ -z "$JOB_POSTS_URL" ]; then
  echo "ERROR: at least one source URL required (--careers-url / --linkedin-company-url / --job-posts-url)" >&2
  exit 1
fi

mkdir -p "$OUTPUT_DIR"

SLUG=$(echo "$COMPANY" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]\+/-/g; s/^-\+\|-\+$//g')
TS=$(date -u +"%Y%m%dT%H%M%SZ")
WORK_DIR="$OUTPUT_DIR/.raw-$SLUG-$TS"
mkdir -p "$WORK_DIR"

echo "=== Security Stack Profile: $COMPANY ==="
echo "  slug: $SLUG"
echo "  work: $WORK_DIR"
echo ""

CAREERS_OUT=""
LINKEDIN_OUT=""
JOBS_OUT=""

# Signal 1: Careers page via apify/web-scraper
if [ -n "$CAREERS_URL" ]; then
  CAREERS_OUT="$WORK_DIR/careers.json"
  echo "[1/3] Scraping careers page: $CAREERS_URL"
  INPUT=$(printf '{"startUrls":[{"url":"%s"}],"maxRequestsPerCrawl":50,"pageFunction":"async function pageFunction(context) { return { url: context.request.url, title: document.title, text: document.body.innerText }; }"}' "$CAREERS_URL")
  if ! bash "$SCRIPT_DIR/run-actor.sh" "apify/web-scraper" "$INPUT" --output "$CAREERS_OUT" --format json; then
    echo "FAIL: careers scrape failed (exit $?)" >&2
    echo "  skipping this signal, continuing." >&2
    CAREERS_OUT=""
  fi
fi

# Signal 2: LinkedIn company employees via configurable actor
if [ -n "$LINKEDIN_URL" ]; then
  LINKEDIN_OUT="$WORK_DIR/linkedin.json"
  echo "[2/3] Scraping LinkedIn employees (actor: $LINKEDIN_ACTOR): $LINKEDIN_URL"
  INPUT=$(printf '{"companies":["%s"],"maxItems":100}' "$LINKEDIN_URL")
  if ! bash "$SCRIPT_DIR/run-actor.sh" "$LINKEDIN_ACTOR" "$INPUT" --output "$LINKEDIN_OUT" --format json; then
    echo "FAIL: LinkedIn scrape failed (exit $?)" >&2
    echo "  LinkedIn actors vary in input schema; you may need to pass a different" >&2
    echo "  --linkedin-actor or tweak the input JSON. Skipping this signal." >&2
    LINKEDIN_OUT=""
  fi
fi

# Signal 3: Job board URL via apify/web-scraper
if [ -n "$JOB_POSTS_URL" ]; then
  JOBS_OUT="$WORK_DIR/jobs.json"
  echo "[3/3] Scraping job board: $JOB_POSTS_URL"
  INPUT=$(printf '{"startUrls":[{"url":"%s"}],"maxRequestsPerCrawl":100,"pageFunction":"async function pageFunction(context) { return { url: context.request.url, title: document.title, text: document.body.innerText }; }"}' "$JOB_POSTS_URL")
  if ! bash "$SCRIPT_DIR/run-actor.sh" "apify/web-scraper" "$INPUT" --output "$JOBS_OUT" --format json; then
    echo "FAIL: jobs scrape failed (exit $?)" >&2
    JOBS_OUT=""
  fi
fi

echo ""
echo "=== Collection complete. Running extractor. ==="
echo ""

EXTRACT_ARGS=(--company "$COMPANY" --output-dir "$OUTPUT_DIR")
[ -n "$CAREERS_OUT" ] && [ -f "$CAREERS_OUT" ] && EXTRACT_ARGS+=(--careers "$CAREERS_OUT")
[ -n "$LINKEDIN_OUT" ] && [ -f "$LINKEDIN_OUT" ] && EXTRACT_ARGS+=(--linkedin "$LINKEDIN_OUT")
[ -n "$JOBS_OUT" ] && [ -f "$JOBS_OUT" ] && EXTRACT_ARGS+=(--jobs "$JOBS_OUT")

python3 "$SCRIPT_DIR/security-stack-extract.py" "${EXTRACT_ARGS[@]}"

echo ""
echo "Raw scrapes preserved at: $WORK_DIR"
