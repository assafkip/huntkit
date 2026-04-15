Map and document the relationship between two investigation targets.

Execute the /q-link steps from `.q-system/commands.md`.

1. Read both target profiles from `investigation/targets/`
2. Search evidence for shared: organizations, events, digital infrastructure, communication patterns, third-party connections
3. Classify relationship: direct / indirect / inferred / unknown
4. Assess strength: strong / moderate / weak / speculative
5. Document in both target files + create finding in `investigation/findings/`
6. Update `investigation/timelines/master-timeline.md` if relationship has temporal dimension

Argument: $ARGUMENTS (required: two target names, e.g. "John Smith" "Jane Doe")
