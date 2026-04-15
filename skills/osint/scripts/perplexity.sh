#!/bin/bash
# Perplexity API — search + sonar + reason + deep research
# Usage: perplexity.sh search "query"       # Search API (ranked results)
#        perplexity.sh sonar "query"        # Sonar (AI answer + citations)
#        perplexity.sh reason "query"       # Sonar Reasoning (compare leads, reconcile contradictions)
#        perplexity.sh deep "query"         # Deep Research
#
# Env:
#   PERPLEXITY_API_KEY   required.
#   JSON_MODE=1          emit raw Perplexity API response as JSON (for pipelines).
#                        Without JSON_MODE, prints human-readable formatted output.
#
# Exit codes:
#   0  success
#   1  API returned an `error` object (message printed to stderr)
#   2  invalid/empty response from API (network or upstream fault)
set -euo pipefail

API_KEY="${PERPLEXITY_API_KEY:?Set PERPLEXITY_API_KEY}"
CMD="${1:?Usage: perplexity.sh search|sonar|reason|deep <query>}"
QUERY="${2:?Missing query}"
export JSON_MODE="${JSON_MODE:-0}"

case "$CMD" in
  search)
    # Search API — ranked web results
    curl -s "https://api.perplexity.ai/search" \
      -H "Authorization: Bearer $API_KEY" \
      -H "Content-Type: application/json" \
      -d "{\"query\": [\"$QUERY\"]}" | python3 -c "
import json, sys, os
try:
    d = json.load(sys.stdin)
except json.JSONDecodeError as e:
    print(f'ERROR: invalid JSON from Perplexity API: {e}', file=sys.stderr)
    sys.exit(2)
if 'error' in d:
    print(f'ERROR: {json.dumps(d[\"error\"])}', file=sys.stderr)
    sys.exit(1)
if os.environ.get('JSON_MODE') == '1':
    print(json.dumps(d))
    sys.exit(0)
if 'results' in d:
    for r in d['results'][:10]:
        print(f'🔗 {r.get(\"title\",\"\")}')
        print(f'   {r.get(\"url\",\"\")}')
        print(f'   {r.get(\"snippet\",\"\")[:200]}')
        print()
else:
    print(json.dumps(d, indent=2)[:2000])
"
    ;;
  sonar)
    # Sonar API — AI answer with citations
    curl -s "https://api.perplexity.ai/chat/completions" \
      -H "Authorization: Bearer $API_KEY" \
      -H "Content-Type: application/json" \
      -d "{
        \"model\": \"sonar\",
        \"messages\": [{\"role\": \"user\", \"content\": \"$QUERY\"}]
      }" | python3 -c "
import json, sys, os
try:
    d = json.load(sys.stdin)
except json.JSONDecodeError as e:
    print(f'ERROR: invalid JSON from Perplexity API: {e}', file=sys.stderr)
    sys.exit(2)
if 'error' in d:
    print(f'ERROR: {json.dumps(d[\"error\"])}', file=sys.stderr)
    sys.exit(1)
if os.environ.get('JSON_MODE') == '1':
    print(json.dumps(d))
    sys.exit(0)
if 'choices' in d:
    msg = d['choices'][0]['message']
    print(msg.get('content', ''))
    cits = d.get('citations', msg.get('citations', []))
    if cits:
        print('\n--- Sources ---')
        for i, c in enumerate(cits[:10], 1):
            print(f'{i}. {c if isinstance(c, str) else c.get(\"url\", c)}')
else:
    print(json.dumps(d, indent=2)[:2000])
"
    ;;
  reason)
    # Sonar Reasoning — compare leads, reconcile contradictions, infer relationships
    curl -s "https://api.perplexity.ai/chat/completions" \
      -H "Authorization: Bearer $API_KEY" \
      -H "Content-Type: application/json" \
      -d "{
        \"model\": \"sonar-reasoning-pro\",
        \"messages\": [{\"role\": \"user\", \"content\": \"$QUERY\"}]
      }" | python3 -c "
import json, sys, os
try:
    d = json.load(sys.stdin)
except json.JSONDecodeError as e:
    print(f'ERROR: invalid JSON from Perplexity API: {e}', file=sys.stderr)
    sys.exit(2)
if 'error' in d:
    print(f'ERROR: {json.dumps(d[\"error\"])}', file=sys.stderr)
    sys.exit(1)
if os.environ.get('JSON_MODE') == '1':
    print(json.dumps(d))
    sys.exit(0)
if 'choices' in d:
    msg = d['choices'][0]['message']
    print(msg.get('content', ''))
    cits = d.get('citations', msg.get('citations', []))
    if cits:
        print('\n--- Sources ---')
        for i, c in enumerate(cits[:15], 1):
            print(f'{i}. {c if isinstance(c, str) else c.get(\"url\", c)}')
else:
    print(json.dumps(d, indent=2)[:2000])
"
    ;;
  deep)
    # Deep Research via sonar-deep-research
    curl -s "https://api.perplexity.ai/chat/completions" \
      -H "Authorization: Bearer $API_KEY" \
      -H "Content-Type: application/json" \
      -d "{
        \"model\": \"sonar-deep-research\",
        \"messages\": [{\"role\": \"user\", \"content\": \"$QUERY\"}]
      }" | python3 -c "
import json, sys, os
try:
    d = json.load(sys.stdin)
except json.JSONDecodeError as e:
    print(f'ERROR: invalid JSON from Perplexity API: {e}', file=sys.stderr)
    sys.exit(2)
if 'error' in d:
    print(f'ERROR: {json.dumps(d[\"error\"])}', file=sys.stderr)
    sys.exit(1)
if os.environ.get('JSON_MODE') == '1':
    print(json.dumps(d))
    sys.exit(0)
if 'choices' in d:
    msg = d['choices'][0]['message']
    print(msg.get('content', ''))
    cits = d.get('citations', msg.get('citations', []))
    if cits:
        print('\n--- Sources ---')
        for i, c in enumerate(cits[:15], 1):
            print(f'{i}. {c if isinstance(c, str) else c.get(\"url\", c)}')
else:
    print(json.dumps(d, indent=2)[:2000])
"
    ;;
  *)
    echo "Unknown command: $CMD (use search|sonar|reason|deep)" >&2; exit 1
    ;;
esac
