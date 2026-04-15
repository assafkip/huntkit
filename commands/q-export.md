Export investigation data in a structured format.

Execute the /q-export steps from `.q-system/commands.md`.

Formats: markdown, json, timeline-html

1. Gather all investigation files from `investigation/`
2. Export in requested format:
   - markdown: Full investigation report
   - json: Structured data (targets, findings, links, timeline)
   - timeline-html: Interactive timeline visualization
3. Save to `output/exports/`
4. Present to user

Argument: $ARGUMENTS (optional: format -- markdown, json, or timeline-html. Defaults to markdown.)
