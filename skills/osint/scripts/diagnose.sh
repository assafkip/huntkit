#!/bin/bash
set -euo pipefail
# OSINT Toolkit Self-Diagnostic
# Run before starting any research to check available tools
# Usage: ./diagnose.sh

SKILL_DIR="$(cd "$(dirname "$0")/.." && pwd)"
WORKSPACE="$(cd "$SKILL_DIR/../.." && pwd)"

echo "=== OSINT TOOLKIT DIAGNOSTIC ==="
echo ""

# 1. API Tokens (env or file)
echo "📡 API Tokens:"
if [ -n "${APIFY_API_TOKEN:-}" ]; then
  echo "  ✅ APIFY_API_TOKEN (env)"
elif [ -f "$WORKSPACE/scripts/apify-api-token.txt" ]; then
  echo "  ✅ APIFY_API_TOKEN (file: scripts/apify-api-token.txt)"
else
  echo "  ❌ APIFY_API_TOKEN"
fi

if [ -n "${JINA_API_KEY:-}" ]; then
  echo "  ✅ JINA_API_KEY (env)"
elif [ -f "$WORKSPACE/scripts/jina-api-key.txt" ]; then
  echo "  ✅ JINA_API_KEY (file: scripts/jina-api-key.txt)"
else
  echo "  ❌ JINA_API_KEY"
fi

if [ -n "${PERPLEXITY_API_KEY:-}" ]; then
  echo "  ✅ PERPLEXITY_API_KEY (env)"
else
  echo "  ❌ PERPLEXITY_API_KEY"
fi

if [ -n "${PARALLEL_API_KEY:-}" ]; then
  echo "  ✅ PARALLEL_API_KEY (env)"
elif [ -f "$WORKSPACE/scripts/parallel-api-key.txt" ]; then
  echo "  ✅ PARALLEL_API_KEY (file: scripts/parallel-api-key.txt)"
else
  echo "  ❌ PARALLEL_API_KEY"
fi

if [ -n "${EXA_API_KEY:-}" ]; then
  echo "  ✅ EXA_API_KEY (env)"
else
  echo "  ⚠️  EXA_API_KEY (not set — exa.sh won't work)"
fi

if [ -n "${TAVILY_API_KEY:-}" ]; then
  echo "  ✅ TAVILY_API_KEY (env)"
else
  echo "  ❌ TAVILY_API_KEY"
fi

if [ -n "${BRIGHTDATA_MCP_URL:-}" ]; then
  echo "  ✅ BRIGHTDATA_MCP_URL (env)"
elif [ -f "$WORKSPACE/scripts/brightdata-mcp-url.txt" ]; then
  echo "  ✅ BRIGHTDATA_MCP_URL (file: scripts/brightdata-mcp-url.txt)"
else
  echo "  ❌ BRIGHTDATA_MCP_URL"
fi
echo ""

# 2. CLI tools
echo "🔧 CLI Tools:"
command -v mcporter &>/dev/null && echo "  ✅ mcporter" || echo "  ❌ mcporter"
[ -f ~/.local/node_modules/.bin/mcpc ] && echo "  ✅ mcpc (Apify actor discovery)" || echo "  ❌ mcpc (npm i @apify/mcpc)"
command -v jq &>/dev/null && echo "  ✅ jq" || echo "  ❌ jq"
command -v curl &>/dev/null && echo "  ✅ curl" || echo "  ❌ curl"
if command -v node &>/dev/null; then
  NODE_V=$(node -v 2>/dev/null)
  NODE_MAJOR=$(echo "$NODE_V" | sed 's/v//' | cut -d. -f1)
  if [ "$NODE_MAJOR" -ge 18 ]; then
    echo "  ✅ node $NODE_V (run_actor.js compatible)"
  else
    echo "  ⚠️  node $NODE_V (need 18+ for run_actor.js)"
  fi
else
  echo "  ❌ node (required for run_actor.js)"
fi
[ -f "$SKILL_DIR/scripts/run_actor.js" ] && echo "  ✅ run_actor.js (embedded, 55+ actors)" || echo "  ❌ run_actor.js (missing from skill)"
[ -f "$SKILL_DIR/scripts/run-actor.sh" ] && echo "  ✅ run-actor.sh (bash wrapper)" || echo "  ❌ run-actor.sh"
echo ""

# 3. Internal Intelligence Tools (optional)
echo "📱 Internal Intelligence (optional):"
if command -v tgspyder &>/dev/null; then
  echo "  ✅ tgspyder (Telegram recon CLI)"
else
  echo "  ⚪ tgspyder not installed (optional — https://github.com/Darksight-Analytics/tgspyder)"
fi

if command -v himalaya &>/dev/null || command -v mutt &>/dev/null || command -v notmuch &>/dev/null; then
  echo "  ✅ local email CLI detected"
else
  echo "  ⚪ no local email CLI detected (optional)"
fi

if [ -n "${INTERNAL_NOTES_DIR:-}" ] && [ -d "$INTERNAL_NOTES_DIR" ]; then
  NOTES_COUNT=$(find "$INTERNAL_NOTES_DIR" -name "*.md" 2>/dev/null | wc -l)
  echo "  ✅ internal notes dir ($NOTES_COUNT files at \$INTERNAL_NOTES_DIR)"
else
  echo "  ⚪ INTERNAL_NOTES_DIR not set (optional — point at a local CRM/vault dir)"
fi
echo ""

# 4. MCP servers
echo "🔌 MCP Servers:"
if command -v mcporter &>/dev/null; then
  MCPORTER_CONFIG="${MCPORTER_CONFIG:-./config/mcporter.json}"
  if [ -f "$MCPORTER_CONFIG" ]; then
    MCPORTER_CONFIG="$MCPORTER_CONFIG" mcporter list 2>/dev/null | grep -E "^[a-z]" | while read -r server; do
      echo "  ✅ $server"
    done
  else
    echo "  ⚠️  mcporter config not found at $MCPORTER_CONFIG"
  fi
else
  echo "  ⚠️  mcporter not installed (npm i -g mcporter)"
fi
echo ""

# 5. Capability summary
echo "📊 Capabilities:"
([ -n "${APIFY_API_TOKEN:-}" ] || [ -f "$WORKSPACE/scripts/apify-api-token.txt" ]) && echo "  LinkedIn scraping (Apify): ✅" || echo "  LinkedIn scraping (Apify): ❌"
([ -n "${APIFY_API_TOKEN:-}" ] || [ -f "$WORKSPACE/scripts/apify-api-token.txt" ]) && echo "  Instagram scraping (Apify): ✅" || echo "  Instagram scraping (Apify): ❌"
([ -n "${APIFY_API_TOKEN:-}" ] || [ -f "$WORKSPACE/scripts/apify-api-token.txt" ]) && echo "  TikTok scraping (Apify clockworks): ✅" || echo "  TikTok scraping: ❌"
([ -n "${APIFY_API_TOKEN:-}" ] || [ -f "$WORKSPACE/scripts/apify-api-token.txt" ]) && echo "  YouTube scraping (Apify streamers): ✅" || echo "  YouTube scraping: ❌"
([ -n "${APIFY_API_TOKEN:-}" ] || [ -f "$WORKSPACE/scripts/apify-api-token.txt" ]) && echo "  Contact enrichment (Apify): ✅" || echo "  Contact enrichment: ❌"
([ -n "${APIFY_API_TOKEN:-}" ] || [ -f "$WORKSPACE/scripts/apify-api-token.txt" ]) && echo "  Google Maps (Apify): ✅" || echo "  Google Maps: ❌"
([ -n "${BRIGHTDATA_MCP_URL:-}" ] || [ -f "$WORKSPACE/scripts/brightdata-mcp-url.txt" ]) && echo "  Facebook scraping (Bright Data): ✅" || echo "  Facebook scraping: ❌"
([ -n "${BRIGHTDATA_MCP_URL:-}" ] || [ -f "$WORKSPACE/scripts/brightdata-mcp-url.txt" ]) && echo "  CAPTCHA bypass (Bright Data): ✅" || echo "  CAPTCHA bypass: ❌"
([ -n "${JINA_API_KEY:-}" ] || [ -f "$WORKSPACE/scripts/jina-api-key.txt" ]) && echo "  Deep search (Jina): ✅" || echo "  Deep search (Jina): ❌"
[ -n "${PERPLEXITY_API_KEY:-}" ] && echo "  Quick answers (Perplexity Sonar): ✅" || echo "  Quick answers (Perplexity): ❌"
[ -n "${PERPLEXITY_API_KEY:-}" ] && echo "  Deep research (Perplexity Deep): ✅" || echo "  Deep research (Perplexity): ❌"
[ -n "${TAVILY_API_KEY:-}" ] && echo "  Agent search (Tavily): ✅" || echo "  Agent search (Tavily): ❌"
[ -n "${EXA_API_KEY:-}" ] && echo "  Semantic search (Exa): ✅" || echo "  Semantic search (Exa): ❌"
[ -n "${EXA_API_KEY:-}" ] && echo "  People/Company search (Exa): ✅" || echo "  People/Company search (Exa): ❌"
([ -n "${PARALLEL_API_KEY:-}" ] || [ -f "$WORKSPACE/scripts/parallel-api-key.txt" ]) && echo "  AI search (Parallel): ✅" || echo "  AI search (Parallel): ❌"
command -v tgspyder &>/dev/null && echo "  Telegram intel (tgspyder): ✅" || echo "  Telegram intel (tgspyder): ⚪ optional"
(command -v himalaya &>/dev/null || command -v mutt &>/dev/null || command -v notmuch &>/dev/null) && echo "  Email intel (local CLI): ✅" || echo "  Email intel: ⚪ optional"
echo ""
echo "=== END DIAGNOSTIC ==="
