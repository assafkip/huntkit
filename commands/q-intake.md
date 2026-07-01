Process new information into the investigation structure.

Execute the /q-intake steps from `.q-system/commands.md`.

Types: target, finding, evidence, tip

1. Ask for the information (or accept paste/file)
2. Classify: What type of information is this?
3. Assess reliability using the A-F scale from `.q-system/preflight.md`
4. Route to appropriate file:
   - New person/entity -> `investigations/<case>/targets/[name].md`
   - Confirmed intelligence -> `investigations/<case>/findings/`
   - Raw data/screenshots -> `investigations/<case>/evidence/`
   - Timeline events -> `investigations/<case>/timelines/`
5. Cross-reference against existing targets and findings
6. Flag any new leads or connections surfaced
7. Update `memory/investigation-state.md`

Argument: $ARGUMENTS (optional: type -- target, finding, evidence, or tip)
