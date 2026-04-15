Generate a structured investigation brief summarizing current state.

Execute the /q-brief steps from `.q-system/commands.md`.

1. Read `canonical/scope.md`, all targets, all findings, timeline
2. Generate brief with:
   - Executive summary: 3-5 bullet points answering the primary question
   - Key findings: confirmed intelligence with confidence levels and citations
   - Target matrix: all targets, status, key connections
   - Timeline summary: major events in chronological order
   - Collection gaps: what we still need
   - Hypotheses status: supported / refuted / undetermined
   - Recommended next steps: prioritized by impact, tagged with Energy + Time Est
3. Save to `output/briefs/brief-YYYY-MM-DD.md`
4. Present to user

Argument: $ARGUMENTS (optional: "executive" for short version)
