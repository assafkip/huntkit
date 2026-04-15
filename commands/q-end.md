End investigation session. Summarize all changes and save state.

## Steps

1. List all files modified during this conversation (investigation files, findings, evidence, targets)
2. Summarize what was collected, analyzed, or discovered
3. Update the active case's `memory/investigation-state.md` with:
   - Session date and summary
   - What was collected/analyzed
   - Outstanding tasks
   - Next priority
   - Updated hypothesis status
4. Create a session log file in `memory/sessions/session-YYYY-MM-DD-HHMM.md`
5. Generate a handoff note and save to `memory/last-handoff.md`:
   - What happened this session
   - In-progress work (anything started but not finished)
   - Decisions made
   - Files modified
   - Blocked items (waiting on client, missing API keys, etc.)
   - Suggested next action for next session
6. Flag any inconsistencies between findings, targets, and timeline
7. Report effort: "This session: X tool calls, Y findings documented, Z targets updated"
