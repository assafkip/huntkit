# Investigation Rules

## Execution

- Read any case preflight/brief at the start of every investigation session
- Read `memory/investigation-state.md` (if present) to pick up where you left off
- Fail-stop on any error: STOP, inform the user, WAIT

## File Authority

- `canonical/` only updated via an explicit scope change
- `investigation/` (or `investigations/<case>/`) updated every collection/analysis session
- `memory/investigation-state.md` — current state ONLY (targets, hypotheses, evidence inventory, next priority)
- `memory/sessions/` — one file per session (`session-YYYY-MM-DD-HHMM.md`), contains session log, tool calls, decisions
- Never mix session history into `investigation-state.md`. State file = "where are we now." Session files = "what happened when."

## Token Discipline

- After every 10 tool calls during collection, pause and ask: "Am I closer to answering the primary question than 10 calls ago?"
- If the answer is no for 2 consecutive checks, STOP collection and either switch approaches or ask the user
- Browser automation is the most expensive operation — plan exactly what you need before opening a page
- Before spawning any sub-agent, ask: "Is this worth 50K+ tokens?"
- Never retry a failed tool call without diagnosing why it failed first

## Client/User Questions Checkpoint

- After the FIRST hour of collection (or after initial sweep completes), pause and ask: "What questions should we send to the client before burning more tokens?"
- The client often knows the answer to questions that would take 50+ tool calls to research
- Draft targeted questions before continuing deep collection

## Intelligence Standards

- Every claim must cite its source
- Every assessment must have a confidence level
- Every target profile must track collection gaps
- Distinguish fact from assessment from speculation
- Use the source reliability A-F scale (see `skills/osint/SKILL.md`)
