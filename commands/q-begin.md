Start a new investigation session. Read all state files to load context before doing anything.

## Steps

1. Identify the active case folder in `investigations/`
   - If only one case exists, use it
   - If multiple cases exist, ask the user which case to work on
2. Read these files in parallel from the active case:
   - `canonical/scope.md`
   - `canonical/collection-plan.md`
   - `memory/investigation-state.md`
   - `memory/last-handoff.md` (if exists)
3. Read `.q-system/preflight.md`
4. Output a brief status:
   - Case name and primary question
   - Where we left off (from investigation-state.md)
   - Handoff notes (from last-handoff.md)
   - Top 3 priorities
   - Any blockers or outstanding client responses

Do NOT start any collection or analysis until the user confirms direction.
