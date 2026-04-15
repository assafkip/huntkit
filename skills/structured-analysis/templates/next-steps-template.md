# Next Steps: {{ANALYSIS_ID}}

Generated: {{DATE}} | Iteration: {{N}} | Quality Score: {{SCORE}}/5.0

## Summary
{{TOTAL_COUNT}} items identified. {{REMEDIATED_COUNT}} auto-remediated. {{RESOLVED_COUNT}} resolved. {{OPEN_COUNT}} open.

## Iteration Items

| # | Flag Source | Flag Type | Severity | Status | Technique(s) | Evidence Focus |
|---|-----------|-----------|----------|--------|-------------|----------------|
{{#EACH ITEM}}
| {{N}} | {{FLAG_SOURCE}} | {{FLAG_TYPE}} | {{SEVERITY}} | {{STATUS}} | {{TECHNIQUES}} | {{EVIDENCE_FOCUS}} |
{{/EACH}}

## Detail

{{#EACH ITEM}}
### {{N}}. [{{STATUS}}] {{FLAG_TYPE}} ({{FLAG_SOURCE}}) — {{SEVERITY}}
{{DESCRIPTION}}
- **Technique**: {{TECHNIQUES}}
- **Evidence focus**: {{EVIDENCE_FOCUS}}
{{#IF REMEDIATED}}
- **Remediation note**: Auto-remediated in cycle {{CYCLE}}. Prior artifact archived at working/{{ARTIFACT_NAME}}.v{{PRIOR_VERSION}}.md
{{/IF}}
{{#IF RESOLVED}}
- **Resolved**: Iteration {{ITER_N}} ({{DATE}}). {{NEW_EVIDENCE_COUNT}} new evidence items ({{ID_RANGE}}). {{RESOLUTION_SUMMARY}}.
{{/IF}}
{{/EACH}}

## Suggested Command
{{#IF HAS_OPEN_ITEMS}}
`/analyze --iterate {{ANALYSIS_ID}} {{OPEN_TECHNIQUE_LIST}}`
{{/IF}}
{{#IF NO_OPEN_ITEMS}}
No open iteration items. All identified gaps have been addressed.
{{/IF}}
