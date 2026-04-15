#!/bin/bash
# capture-evidence.sh -- atomic evidence capture pipeline
#
# Captures a URL to an EV-NNNN evidence folder with full chain of custody.
# Submits to Wayback + archive.today, renders PDF + PNG via Chrome headless,
# computes SHA-256, writes source.json + chain-of-custody.md.
#
# Any single failure marks the item INCOMPLETE and blocks report inclusion.
#
# Usage:
#   capture-evidence.sh <url> <slug> [--case <case-folder>] [--account <@handle>]
#                                    [--platform <name>] [--note "text"]
#   capture-evidence.sh --batch <file> [--case <case-folder>]
#
# Batch file format (one item per line, tab-separated):
#   <url>\t<slug>\t[platform]\t[account]\t[note]
#   Lines starting with # and blank lines are ignored.
#   In batch mode the script iterates items and fail-stops on the first
#   INCOMPLETE capture (consistent with evidence-capture-protocol.md).
#
# Examples:
#   capture-evidence.sh "https://x.com/DataRepublican/status/123" "datarepublican-origin-thread"
#   capture-evidence.sh --batch /tmp/osint-.../urls.tsv
#
# Requires: curl, jq, shasum, Google Chrome (macOS)

set -euo pipefail

# ---------- Resolve workspace and active case ----------

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
WORKSPACE="$(cd "$SCRIPT_DIR/../../.." && pwd)"

# ---------- Batch dispatcher ----------
#
# If invoked as `--batch <file>`, iterate the file and re-invoke this script
# per line. Fail-stop on first INCOMPLETE (exit 2 from single-URL path).

if [ "${1:-}" = "--batch" ]; then
  BATCH_FILE="${2:-}"
  if [ -z "$BATCH_FILE" ] || [ ! -f "$BATCH_FILE" ]; then
    echo "ERROR: --batch requires a readable file path" >&2
    exit 1
  fi
  shift 2
  BATCH_EXTRA=("$@")

  COUNT=0
  COMPLETE=0
  while IFS=$'\t' read -r b_url b_slug b_platform b_account b_note || [ -n "${b_url:-}" ]; do
    case "$b_url" in
      '' | \#*) continue ;;
    esac
    if [ -z "${b_slug:-}" ]; then
      echo "ERROR: batch line missing slug for url=$b_url" >&2
      exit 1
    fi
    COUNT=$((COUNT + 1))
    extra=()
    [ -n "${b_platform:-}" ] && extra+=(--platform "$b_platform")
    [ -n "${b_account:-}" ] && extra+=(--account "$b_account")
    [ -n "${b_note:-}" ] && extra+=(--note "$b_note")

    echo "--- batch item $COUNT: $b_url ---"
    if "$0" "$b_url" "$b_slug" "${BATCH_EXTRA[@]}" "${extra[@]}"; then
      COMPLETE=$((COMPLETE + 1))
    else
      rc=$?
      echo "FAIL-STOP: batch item $COUNT returned exit $rc; remaining items skipped." >&2
      echo "batch summary: $COMPLETE/$COUNT complete before failure" >&2
      exit "$rc"
    fi
  done < "$BATCH_FILE"

  echo "batch summary: $COMPLETE/$COUNT complete"
  exit 0
fi

# ---------- Parse args (single-URL path) ----------

URL="${1:-}"
SLUG="${2:-}"
if [ -z "$URL" ] || [ -z "$SLUG" ]; then
  echo "Usage: capture-evidence.sh <url> <slug> [--case <case-folder>] [--account <@handle>] [--platform <name>] [--note \"text\"]" >&2
  echo "       capture-evidence.sh --batch <file> [--case <case-folder>]" >&2
  exit 1
fi
shift 2

CASE=""
ACCOUNT=""
PLATFORM=""
NOTE=""
while [ $# -gt 0 ]; do
  case "$1" in
    --case) CASE="$2"; shift 2 ;;
    --account) ACCOUNT="$2"; shift 2 ;;
    --platform) PLATFORM="$2"; shift 2 ;;
    --note) NOTE="$2"; shift 2 ;;
    *) echo "ERROR: unknown argument: $1" >&2; exit 1 ;;
  esac
done

if [ -z "$CASE" ]; then
  if [ -f "$WORKSPACE/.active-case" ]; then
    CASE=$(head -1 "$WORKSPACE/.active-case" | tr -d '[:space:]')
  else
    echo "ERROR: no active case set and --case not given" >&2
    exit 1
  fi
fi

CASE_DIR="$WORKSPACE/investigations/$CASE"
if [ ! -d "$CASE_DIR" ]; then
  echo "ERROR: case directory not found: $CASE_DIR" >&2
  exit 1
fi

# ---------- Assign EV-NNNN ID ----------

EV_ID=$("$SCRIPT_DIR/next-ev-id.sh" "$CASE")
ITEM_DIR="$CASE_DIR/investigation/evidence/items/${EV_ID}-${SLUG}"
mkdir -p "$ITEM_DIR"

echo "=== $EV_ID ==="
echo "URL:  $URL"
echo "Case: $CASE"
echo "Dir:  $ITEM_DIR"
echo ""

# ---------- Track status ----------

STATUS_WAYBACK="PENDING"
STATUS_ARCHIVE_TODAY="PENDING"
STATUS_PDF="PENDING"
STATUS_PNG="PENDING"
WAYBACK_URL=""
ARCHIVE_TODAY_URL=""
PDF_SHA=""
CAPTURE_TS=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

# ---------- Step 1: Wayback Machine submission ----------

echo "[1/4] Wayback Machine..."
WAYBACK_RESP=$(curl -sSL -o /dev/null -w "%{http_code}|%{url_effective}" \
  "https://web.archive.org/save/$URL" 2>&1 || echo "000|")
WAYBACK_CODE="${WAYBACK_RESP%%|*}"
WAYBACK_LOC="${WAYBACK_RESP#*|}"
if [ "$WAYBACK_CODE" = "200" ] || [ "$WAYBACK_CODE" = "302" ]; then
  WAYBACK_URL="$WAYBACK_LOC"
  STATUS_WAYBACK="OK"
  echo "      OK: $WAYBACK_URL"
else
  STATUS_WAYBACK="FAIL (http $WAYBACK_CODE)"
  echo "      FAIL: http $WAYBACK_CODE"
fi

# ---------- Step 2: archive.today submission ----------

echo "[2/4] archive.today..."
# archive.today returns a Refresh header pointing at the archived page on success
AT_RESP=$(curl -sSL -I -X POST "https://archive.ph/submit/?url=$(printf '%s' "$URL" | jq -sRr @uri)" \
  -H "User-Agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) huntkit/0.2" 2>&1 || echo "")
AT_REFRESH=$(echo "$AT_RESP" | grep -i '^refresh:' | sed 's/.*url=//I' | tr -d '\r\n' || true)
AT_LOC=$(echo "$AT_RESP" | grep -i '^location:' | awk '{print $2}' | tr -d '\r\n' || true)
ARCHIVE_TODAY_URL="${AT_REFRESH:-$AT_LOC}"
if [ -n "$ARCHIVE_TODAY_URL" ]; then
  STATUS_ARCHIVE_TODAY="OK"
  echo "      OK: $ARCHIVE_TODAY_URL"
else
  STATUS_ARCHIVE_TODAY="FAIL (no archive url returned)"
  echo "      FAIL: no archive url returned"
fi

# ---------- Step 3: Chrome headless PDF ----------

CHROME="/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"
CHROME_TIMEOUT_SEC="${CHROME_TIMEOUT_SEC:-45}"

# run_with_timeout <seconds> <cmd...> -- uses perl alarm since macOS lacks GNU timeout
# Runs cmd in background, kills it (and descendants) if it doesn't exit in time.
run_with_timeout() {
  local t=$1; shift
  ( "$@" ) &
  local pid=$!
  ( sleep "$t"; kill -TERM "$pid" 2>/dev/null; sleep 2; kill -KILL "$pid" 2>/dev/null ) &
  local watcher=$!
  wait "$pid" 2>/dev/null
  local rc=$?
  kill "$watcher" 2>/dev/null
  wait "$watcher" 2>/dev/null || true
  return $rc
}

if [ ! -x "$CHROME" ]; then
  echo "[3/4] ERROR: Chrome not found at $CHROME"
  STATUS_PDF="FAIL (chrome missing)"
  STATUS_PNG="FAIL (chrome missing)"
else
  echo "[3/4] Chrome PDF..."
  PDF_PATH="$ITEM_DIR/capture.pdf"
  # Unique user-data-dir per capture to avoid singleton lock conflicts
  CHROME_DATA="$(mktemp -d -t qchrome-XXXXXX)"

  run_with_timeout "$CHROME_TIMEOUT_SEC" \
    "$CHROME" \
      --headless=new \
      --disable-gpu \
      --no-sandbox \
      --no-first-run \
      --no-default-browser-check \
      --disable-extensions \
      --disable-dev-shm-usage \
      --no-pdf-header-footer \
      --user-data-dir="$CHROME_DATA" \
      --virtual-time-budget=10000 \
      --timeout=20000 \
      --print-to-pdf="$PDF_PATH" \
      "$URL" >/dev/null 2>&1 || true
  # Clean up any straggler Chrome children from this user-data-dir
  pkill -f "user-data-dir=$CHROME_DATA" 2>/dev/null || true

  if [ -s "$PDF_PATH" ]; then
    STATUS_PDF="OK"
    PDF_SHA=$(shasum -a 256 "$PDF_PATH" | awk '{print $1}')
    echo "      OK: capture.pdf ($(wc -c < "$PDF_PATH" | tr -d ' ') bytes, sha256=${PDF_SHA:0:16}...)"
  else
    STATUS_PDF="FAIL"
    echo "      FAIL"
  fi

  # ---------- Step 4: Chrome headless PNG ----------
  echo "[4/4] Chrome PNG..."
  PNG_PATH="$ITEM_DIR/capture.png"
  CHROME_DATA2="$(mktemp -d -t qchrome-XXXXXX)"

  run_with_timeout "$CHROME_TIMEOUT_SEC" \
    "$CHROME" \
      --headless=new \
      --disable-gpu \
      --no-sandbox \
      --no-first-run \
      --no-default-browser-check \
      --disable-extensions \
      --disable-dev-shm-usage \
      --hide-scrollbars \
      --user-data-dir="$CHROME_DATA2" \
      --virtual-time-budget=10000 \
      --timeout=20000 \
      --window-size=1280,2400 \
      --screenshot="$PNG_PATH" \
      "$URL" >/dev/null 2>&1 || true
  pkill -f "user-data-dir=$CHROME_DATA2" 2>/dev/null || true

  if [ -s "$PNG_PATH" ]; then
    STATUS_PNG="OK"
    echo "      OK: capture.png ($(wc -c < "$PNG_PATH" | tr -d ' ') bytes)"
  else
    STATUS_PNG="FAIL"
    echo "      FAIL"
  fi

  rm -rf "$CHROME_DATA" "$CHROME_DATA2"
fi

# ---------- Write source.json ----------

jq -n \
  --arg ev_id "$EV_ID" \
  --arg url "$URL" \
  --arg slug "$SLUG" \
  --arg case "$CASE" \
  --arg account "$ACCOUNT" \
  --arg platform "$PLATFORM" \
  --arg note "$NOTE" \
  --arg capture_ts "$CAPTURE_TS" \
  --arg wayback_url "$WAYBACK_URL" \
  --arg archive_today_url "$ARCHIVE_TODAY_URL" \
  --arg status_wayback "$STATUS_WAYBACK" \
  --arg status_archive_today "$STATUS_ARCHIVE_TODAY" \
  --arg status_pdf "$STATUS_PDF" \
  --arg status_png "$STATUS_PNG" \
  --arg pdf_sha256 "$PDF_SHA" \
  '{
    ev_id: $ev_id,
    slug: $slug,
    case: $case,
    source_url: $url,
    account: $account,
    platform: $platform,
    note: $note,
    capture_timestamp_utc: $capture_ts,
    type: "url",
    captures: {
      wayback: { status: $status_wayback, url: $wayback_url },
      archive_today: { status: $status_archive_today, url: $archive_today_url },
      pdf: { status: $status_pdf, path: "capture.pdf", sha256: $pdf_sha256 },
      png: { status: $status_png, path: "capture.png" }
    }
  }' > "$ITEM_DIR/source.json"

# ---------- Overall status ----------
#
# REQUIRED for COMPLETE: Wayback OK, PDF OK, PNG OK.
# BEST-EFFORT: archive.today -- captured when possible, does not block COMPLETE.
# Reason: archive.today captchas new POST submissions; Wayback + local hashed
# PDF is sufficient chain of custody. archive.today is redundancy.

if [ "$STATUS_WAYBACK" = "OK" ] \
   && [ "$STATUS_PDF" = "OK" ] && [ "$STATUS_PNG" = "OK" ]; then
  OVERALL="COMPLETE"
else
  OVERALL="INCOMPLETE"
fi
jq ". + {overall_status: \"$OVERALL\"}" "$ITEM_DIR/source.json" > "$ITEM_DIR/source.json.tmp" \
  && mv "$ITEM_DIR/source.json.tmp" "$ITEM_DIR/source.json"

# ---------- Write chain-of-custody.md ----------

CAPTURER="${USER:-unknown}@$(hostname)"
cat > "$ITEM_DIR/chain-of-custody.md" <<EOF
# Chain of Custody -- $EV_ID

- **Captured by:** $CAPTURER
- **Captured at:** $CAPTURE_TS
- **Source URL:** $URL
- **Case:** $CASE
- **Account:** ${ACCOUNT:-(none)}
- **Platform:** ${PLATFORM:-(none)}
- **Overall status:** $OVERALL

## Captures

| Capture | Status | Reference |
|---------|--------|-----------|
| Wayback Machine | $STATUS_WAYBACK | ${WAYBACK_URL:-(none)} |
| archive.today | $STATUS_ARCHIVE_TODAY | ${ARCHIVE_TODAY_URL:-(none)} |
| Full-page PDF | $STATUS_PDF | capture.pdf (sha256: ${PDF_SHA:-n/a}) |
| PNG (viewport) | $STATUS_PNG | capture.png |

## Notes

${NOTE:-(none)}

## Integrity

- PDF SHA-256: ${PDF_SHA:-n/a}
- To verify: \`shasum -a 256 capture.pdf\` must match above.
- source.json written atomically at capture time and should not be modified.
EOF

# ---------- content.md stub ----------

cat > "$ITEM_DIR/content.md" <<EOF
# Content -- $EV_ID

> Transcription and OCR notes for this evidence item.
> Source: $URL
> Captured: $CAPTURE_TS

## Transcribed text

(fill in after capture: direct transcription of post text)

## OCR / extracted text

(fill in: OCR output from capture.png/pdf if needed)

## Observed metadata

- Post timestamp:
- View count:
- Engagement (likes/reposts/replies):
- Author display name:
EOF

echo ""
echo "=== $EV_ID: $OVERALL ==="
echo "Dir: $ITEM_DIR"
if [ "$OVERALL" = "INCOMPLETE" ]; then
  echo "WARNING: this item is INCOMPLETE and must not be cited in reports until resolved." >&2
  exit 2
fi
