Extract structured findings from a conversation, interview, document, or source.

Execute the /q-debrief steps from `.q-system/commands.md`.

1. Ask user to describe or paste the source material
2. Extract:
   - New targets or entities mentioned
   - Facts (with reliability assessment using A-F scale from `.q-system/preflight.md`)
   - Timeline events (with dates)
   - Relationships between entities
   - Contradictions with existing findings
   - New collection leads
3. Route to appropriate investigation files in `investigation/`
4. Cross-reference against existing data
5. Update `memory/investigation-state.md`

Argument: $ARGUMENTS (optional: paste source material directly)
