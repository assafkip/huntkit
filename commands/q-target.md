Create or update a target profile for an investigation target.

Execute the /q-target steps from `.q-system/commands.md`.

1. Create/update `investigation/targets/[name].md` using the template from `investigation/targets/_TEMPLATE.md`
2. Populate: identity, digital footprint, connections, timeline, collection status, assessment
3. Cross-reference against other target files for connections
4. Update `investigation/timelines/master-timeline.md` if new events found
5. Flag collection gaps
6. Update `memory/investigation-state.md`

Argument: $ARGUMENTS (required: target name)
