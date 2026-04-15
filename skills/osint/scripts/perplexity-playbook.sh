#!/bin/bash
# perplexity-playbook.sh -- target-type-driven Perplexity research pass
#
# Runs a hardcoded set of sub-queries per target type in parallel via
# `JSON_MODE=1 perplexity.sh sonar`, merges citations with URL normalization +
# exact dedupe, and writes a reproducible run directory.
#
# Usage:
#   perplexity-playbook.sh <type> <slug> <target> [--capture] [--case <case>]
#
#   type   -- person | company | domain | incident
#   slug   -- short filesystem-safe id for the run (e.g., "jane-doe")
#   target -- the subject string injected into queries (e.g., "Jane Doe, CEO Acme")
#
#   --capture        after merge, run capture-evidence.sh --batch over urls.tsv
#   --case <case>    also copy run dir to
#                    investigations/<case>/investigation/evidence/raw-collections/
#
# Output (run directory: /tmp/osint-<slug>-<ISO8601>):
#   raw-NN.json         one file per sub-query (full sonar API response)
#   evidence.json       merged {queries, citations[], by_url{}}
#   urls.txt            deduped citation URLs, one per line
#   urls.tsv            TSV for capture-evidence.sh --batch (url\tslug-NN)
#   report.md           human-readable digest
#   run_manifest.json   run metadata (target, type, timestamp, query count)
#
# Requires: perplexity.sh (in the same dir), python3, jq. PERPLEXITY_API_KEY set.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
WORKSPACE="$(cd "$SCRIPT_DIR/../../.." && pwd)"

TYPE="${1:-}"
SLUG="${2:-}"
TARGET="${3:-}"
if [ -z "$TYPE" ] || [ -z "$SLUG" ] || [ -z "$TARGET" ]; then
  echo "Usage: perplexity-playbook.sh <person|company|domain|incident> <slug> <target> [--capture] [--case <case>]" >&2
  exit 1
fi
shift 3

CAPTURE=0
CASE=""
while [ $# -gt 0 ]; do
  case "$1" in
    --capture) CAPTURE=1; shift ;;
    --case) CASE="$2"; shift 2 ;;
    *) echo "ERROR: unknown argument: $1" >&2; exit 1 ;;
  esac
done

: "${PERPLEXITY_API_KEY:?Set PERPLEXITY_API_KEY}"
command -v python3 >/dev/null || { echo "ERROR: python3 required" >&2; exit 1; }
command -v jq >/dev/null || { echo "ERROR: jq required" >&2; exit 1; }

# ---------- Target-type query doctrine ----------

build_queries() {
  case "$TYPE" in
    person)
      QUERIES=(
        "Who is $TARGET? Give biographical facts, current affiliations, and verifiable sources only."
        "What public controversies, lawsuits, sanctions, or regulatory actions involve $TARGET? Cite primary sources."
        "List verified social media accounts, personal domains, and public contact addresses for $TARGET."
        "What companies, boards, nonprofits, or political organizations is $TARGET currently or formerly affiliated with?"
      )
      ;;
    company)
      QUERIES=(
        "What does $TARGET do, who owns it, and where is it incorporated? Cite primary sources only."
        "List $TARGET's officers, directors, key employees, and significant investors with sources."
        "What lawsuits, regulatory actions, enforcement orders, or sanctions involve $TARGET?"
        "What subsidiaries, affiliates, parent companies, and acquisition history does $TARGET have?"
        "What is $TARGET's domain footprint, brand portfolio, and public social media presence?"
      )
      ;;
    domain)
      QUERIES=(
        "Who owns and operates the website $TARGET? What is its stated purpose and funding source?"
        "What entities, people, or brands are publicly linked to $TARGET (ownership, authors, staff)?"
        "Is $TARGET associated with any reported disinformation, fraud, scams, or content violations?"
        "What other domains, sites, or social accounts are operated by the same owner as $TARGET?"
      )
      ;;
    incident)
      QUERIES=(
        "Describe the incident: $TARGET. Who, what, when, where, primary sources only."
        "What legal, regulatory, or law-enforcement response followed the incident: $TARGET?"
        "What are the named parties, suspects, victims, and witnesses in: $TARGET?"
        "What conflicting accounts or unresolved facts exist about: $TARGET?"
      )
      ;;
    *)
      echo "ERROR: unknown type '$TYPE' (use person|company|domain|incident)" >&2
      exit 1
      ;;
  esac
}

build_queries

# ---------- Prepare run dir ----------

RUN_TS=$(date -u +"%Y-%m-%dT%H-%M-%SZ")
RUN_DIR="/tmp/osint-${SLUG}-${RUN_TS}"
mkdir -p "$RUN_DIR"

echo "=== perplexity-playbook: $TYPE / $SLUG ==="
echo "Target: $TARGET"
echo "Run:    $RUN_DIR"
echo "Queries: ${#QUERIES[@]}"
echo ""

# ---------- Dispatch parallel sonar calls ----------

i=0
for q in "${QUERIES[@]}"; do
  i=$((i + 1))
  idx=$(printf "%02d" "$i")
  (
    set +e
    JSON_MODE=1 "$SCRIPT_DIR/perplexity.sh" sonar "$q" > "$RUN_DIR/raw-${idx}.json" 2> "$RUN_DIR/raw-${idx}.err"
    echo "$?" > "$RUN_DIR/raw-${idx}.exit"
  ) &
done
wait

# ---------- Report per-query status ----------

FAIL=0
for idx_file in "$RUN_DIR"/raw-*.exit; do
  rc=$(cat "$idx_file")
  idx=$(basename "$idx_file" .exit)
  if [ "$rc" != "0" ]; then
    echo "  $idx: FAIL (exit $rc)"
    FAIL=$((FAIL + 1))
  else
    echo "  $idx: OK"
  fi
done
if [ "$FAIL" -gt 0 ]; then
  echo "WARNING: $FAIL sub-queries failed; partial merge will proceed" >&2
fi

# ---------- Merge + dedupe via python ----------

python3 - "$RUN_DIR" "$TYPE" "$SLUG" "$TARGET" <<'PY'
import json, os, re, sys
from urllib.parse import urlsplit, urlunsplit, parse_qsl, urlencode

run_dir, target_type, slug, target = sys.argv[1:5]

def normalize(url: str) -> str:
    try:
        s = urlsplit(url.strip())
    except Exception:
        return url
    if not s.scheme or not s.netloc:
        return url
    host = s.netloc.lower()
    if host.startswith("www."):
        host = host[4:]
    # strip common tracking params
    drop_exact = {"fbclid", "gclid", "mc_cid", "mc_eid", "igshid", "ref", "ref_src", "ref_url"}
    q = [(k, v) for k, v in parse_qsl(s.query, keep_blank_values=False)
         if not k.lower().startswith("utm_") and k.lower() not in drop_exact]
    path = s.path
    if len(path) > 1 and path.endswith("/"):
        path = path.rstrip("/")
    return urlunsplit((s.scheme.lower(), host, path, urlencode(q), ""))

queries = []
by_url = {}

for fname in sorted(os.listdir(run_dir)):
    if not (fname.startswith("raw-") and fname.endswith(".json")):
        continue
    path = os.path.join(run_dir, fname)
    try:
        with open(path) as f:
            data = json.load(f)
    except (json.JSONDecodeError, OSError) as e:
        queries.append({"file": fname, "status": "parse_error", "error": str(e)})
        continue
    if "error" in data:
        queries.append({"file": fname, "status": "api_error", "error": data["error"]})
        continue
    msg = (data.get("choices") or [{}])[0].get("message", {})
    content = msg.get("content", "")
    cits = data.get("citations") or msg.get("citations") or []
    prompt = ""
    # reconstruct prompt from the request isn't preserved; capture snippet
    queries.append({
        "file": fname,
        "status": "ok",
        "answer_preview": content[:400],
        "citation_count": len(cits),
    })
    for c in cits:
        u = c if isinstance(c, str) else c.get("url", "")
        if not u:
            continue
        n = normalize(u)
        entry = by_url.setdefault(n, {"url": n, "original_urls": [], "from_queries": []})
        if u not in entry["original_urls"]:
            entry["original_urls"].append(u)
        if fname not in entry["from_queries"]:
            entry["from_queries"].append(fname)

citations = sorted(by_url.values(), key=lambda e: (-len(e["from_queries"]), e["url"]))

evidence = {
    "type": target_type,
    "slug": slug,
    "target": target,
    "queries": queries,
    "unique_url_count": len(citations),
    "citations": citations,
}

with open(os.path.join(run_dir, "evidence.json"), "w") as f:
    json.dump(evidence, f, indent=2)

with open(os.path.join(run_dir, "urls.txt"), "w") as f:
    for c in citations:
        f.write(c["url"] + "\n")

# TSV batch file for capture-evidence.sh --batch: url\tslug
def slugify(u: str, idx: int) -> str:
    h = re.sub(r"[^a-z0-9]+", "-", urlsplit(u).netloc.lower()).strip("-")
    return f"{slug}-{idx:03d}-{h}"[:80]

with open(os.path.join(run_dir, "urls.tsv"), "w") as f:
    for i, c in enumerate(citations, 1):
        f.write(f"{c['url']}\t{slugify(c['url'], i)}\tperplexity\t\t{target_type}:{slug}\n")

with open(os.path.join(run_dir, "report.md"), "w") as f:
    f.write(f"# Perplexity playbook -- {target_type}: {slug}\n\n")
    f.write(f"**Target:** {target}\n\n")
    f.write(f"**Run dir:** `{run_dir}`\n\n")
    f.write(f"**Unique URLs:** {len(citations)}\n\n")
    f.write("## Query results\n\n")
    for q in queries:
        f.write(f"### {q['file']} -- {q['status']}\n\n")
        if q["status"] == "ok":
            f.write(f"Citations: {q['citation_count']}\n\n")
            f.write(f"Preview:\n\n> {q['answer_preview']}...\n\n")
        else:
            f.write(f"Error: `{q.get('error','')}`\n\n")
    f.write("## Citations (deduped, ranked by cross-query frequency)\n\n")
    for i, c in enumerate(citations, 1):
        f.write(f"{i}. {c['url']}  (from {', '.join(c['from_queries'])})\n")

print(f"merged: {len(citations)} unique URLs from {len(queries)} sub-queries")
PY

# ---------- Run manifest ----------

jq -n \
  --arg type "$TYPE" \
  --arg slug "$SLUG" \
  --arg target "$TARGET" \
  --arg run_ts "$RUN_TS" \
  --arg run_dir "$RUN_DIR" \
  --argjson query_count "${#QUERIES[@]}" \
  --argjson fail_count "$FAIL" \
  '{
    type: $type, slug: $slug, target: $target,
    run_timestamp_utc: $run_ts, run_dir: $run_dir,
    query_count: $query_count, failed_queries: $fail_count,
    tool: "perplexity-playbook.sh", model: "sonar"
  }' > "$RUN_DIR/run_manifest.json"

echo ""
echo "=== playbook complete ==="
echo "Artifacts:"
echo "  $RUN_DIR/evidence.json"
echo "  $RUN_DIR/urls.txt"
echo "  $RUN_DIR/report.md"

# ---------- Optional: capture evidence ----------

if [ "$CAPTURE" = "1" ]; then
  echo ""
  echo "=== --capture: invoking capture-evidence.sh --batch ==="
  CAPTURE_ARGS=(--batch "$RUN_DIR/urls.tsv")
  [ -n "$CASE" ] && CAPTURE_ARGS+=(--case "$CASE")
  "$SCRIPT_DIR/capture-evidence.sh" "${CAPTURE_ARGS[@]}"
fi

# ---------- Optional: persist to case ----------

if [ -n "$CASE" ]; then
  CASE_DIR="$WORKSPACE/investigations/$CASE"
  if [ ! -d "$CASE_DIR" ]; then
    echo "WARNING: --case '$CASE' not found; skipping persist" >&2
  else
    DEST="$CASE_DIR/investigation/evidence/raw-collections/${RUN_TS}-${SLUG}"
    mkdir -p "$DEST"
    cp "$RUN_DIR"/*.json "$RUN_DIR"/*.txt "$RUN_DIR"/*.tsv "$RUN_DIR"/*.md "$DEST/" 2>/dev/null || true
    echo ""
    echo "Persisted to: $DEST"
  fi
fi

echo ""
echo "$RUN_DIR"
