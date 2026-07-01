#!/usr/bin/env bash
# check-collision.sh -- verify an identifier against the case dataset before attribution
# Paired with: client-claims.md/client-claims.json (iav-001) and findings-verify-hook.py (iav-003)
# Usage: check-collision.sh <identifier> <type> <case-folder>
#        check-collision.sh --self-test
set -euo pipefail

SELF_TEST=0
if [[ "${1:-}" == "--self-test" ]]; then
  SELF_TEST=1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ---- collision check logic (python3 does all CSV parsing) ----

run_check() {
  local identifier="$1" type="$2" case_folder="$3"
  python3 "$SCRIPT_DIR/check-collision.py" "$identifier" "$type" "$case_folder"
}

# ---- self-test ----

if [[ $SELF_TEST -eq 1 ]]; then
  echo "=== check-collision.sh --self-test ==="
  TMP=$(mktemp -d)
  trap 'rm -rf "$TMP"' EXIT

  CASE_DIR="$TMP/case-selftest"
  # Use EV-0042 (not EV-0001) to test discovery
  EV_DIR="$CASE_DIR/investigation/evidence/items/EV-0042-test-dataset"
  mkdir -p "$CASE_DIR/canonical" "$EV_DIR"

  cat > "$CASE_DIR/canonical/client-claims.json" <<JSON
{
  "subject_name": "John Subject",
  "identifiers": [
    {"value": "cleanhandle", "type": "username", "status": "UNVERIFIED", "verified_by": ""},
    {"value": "collidehandle", "type": "username", "status": "UNVERIFIED", "verified_by": ""}
  ]
}
JSON

  cat > "$EV_DIR/original.csv" <<'CSV'
source,email,username,phone,dob,city,Name,platform
test,subject@test.com,cleanhandle,,,,"John Subject",TestSite
test,other@test.com,collidehandle,,,,"Matt Jaymes",OtherSite
CSV

  echo ""
  echo "--- Test 1: clean pass (no collision) ---"
  if bash "$0" cleanhandle username "$CASE_DIR"; then
    echo "PASS: clean pass returned exit 0"
  else
    echo "FAIL: clean pass returned non-zero" >&2; exit 1
  fi

  echo ""
  echo "--- Test 2: VERIFIED written back to JSON ---"
  STATUS=$(python3 -c "import json; d=json.load(open('$CASE_DIR/canonical/client-claims.json')); e=[x for x in d['identifiers'] if x['value']=='cleanhandle'][0]; print(e['status'])")
  if [[ "$STATUS" == "VERIFIED" ]]; then
    echo "PASS: status=VERIFIED confirmed"
  else
    echo "FAIL: expected VERIFIED, got $STATUS" >&2; exit 1
  fi

  echo ""
  echo "--- Test 3: collision detection (different name in dataset) ---"
  set +e
  COLLISION_OUT=$(bash "$0" collidehandle username "$CASE_DIR" 2>&1)
  COLLISION_RC=$?
  set -e
  if echo "$COLLISION_OUT" | grep -q "COLLISION" && [[ $COLLISION_RC -ne 0 ]]; then
    echo "PASS: collision detected, exit non-zero"
  else
    echo "FAIL: expected COLLISION in output and non-zero exit" >&2
    echo "  output: $COLLISION_OUT" >&2
    echo "  exit code: $COLLISION_RC" >&2
    exit 1
  fi

  echo ""
  echo "--- Test 4: EV-* discovery uses non-EV-0001 folder ---"
  echo "PASS: EV-0042 was used in tests above (not hardcoded EV-0001)"

  echo ""
  echo "=== ALL SELF-TESTS PASSED ==="
  exit 0
fi

# ---- normal mode ----

if [[ $# -ne 3 ]]; then
  echo "Usage: $0 <identifier> <type> <case-folder>" >&2
  echo "       $0 --self-test" >&2
  exit 2
fi

run_check "$1" "$2" "$3"
