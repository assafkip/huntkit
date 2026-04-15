#!/bin/bash
set -euo pipefail
# Tool call counter for token discipline
# Tracks tool calls per session and warns at thresholds

COUNTER_FILE="/tmp/q-tool-counter-$(date +%Y%m%d).txt"
ANALYZE_FLAG="/tmp/claude-analyze-active-$(date +%Y%m%d).flag"

# Read current count (or start at 0)
if [ -f "$COUNTER_FILE" ]; then
    COUNT=$(cat "$COUNTER_FILE")
else
    COUNT=0
fi

# Increment
COUNT=$((COUNT + 1))
echo "$COUNT" > "$COUNTER_FILE"

# Skip all warnings during /analyze (the orchestrator protocol IS the plan)
if [ -f "$ANALYZE_FLAG" ]; then
    exit 0
fi

# Warn at thresholds
if [ $((COUNT % 10)) -eq 0 ]; then
    echo "TOKEN CHECK: $COUNT tool calls this session. Pause and ask: Am I closer to the goal than 10 calls ago?"
fi

if [ "$COUNT" -eq 30 ]; then
    echo "WARNING: 30 tool calls. Consider /q-client-questions before continuing collection."
fi

if [ "$COUNT" -eq 50 ]; then
    echo "WARNING: 50 tool calls. Run /q-challenge to check assumptions before burning more tokens."
fi
