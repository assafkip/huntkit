Run a broad OSINT collection sweep across all applicable platforms for the current target.

Read `skills/osint/SKILL.md` for the full tool catalog and escalation flow.

1. Read any existing `canonical/collection-plan.md` for outstanding requirements
2. Read `memory/investigation-state.md` for what's been collected
3. Launch parallel first-volley searches (Perplexity, Brave, Tavily, Exa) via `skills/osint/scripts/first-volley.sh`
4. Merge results with `skills/osint/scripts/merge-volley.sh`
5. Capture new evidence through `skills/osint/scripts/capture-evidence.sh` — see `rules/evidence-capture-protocol.md`
6. Update `memory/investigation-state.md` with findings

OSINT scripts live at `skills/osint/scripts/<name>.sh`. Run `bash skills/osint/scripts/diagnose.sh` to check which APIs are configured.

Argument: $ARGUMENTS (optional: target name or case slug; defaults to the active case)
