# Iteration Handler Protocol

Manage artifact versioning, evidence delta tracking, and cross-iteration synthesis when re-running analysis techniques.

> **Path note:** `{{ANALYSIS_DIR}}` is resolved by the orchestrator before this protocol runs. It points to the active case's analysis directory. Use it as-is -- do not hardcode `analyses/`.

---

## When This Protocol Is Invoked

The orchestrator calls this protocol in two scenarios:

1. **User-invoked iteration**: When `--iterate` is detected. Runs before any technique execution and after technique execution for cross-iteration synthesis.
2. **Auto-remediation**: When the orchestrator's Auto-Remediation Gate detects HIGH-severity Layer 2 flags after Phase A. The orchestrator invokes this handler with trigger type `auto-remediation (Layer 2)`, scoped to the flagged techniques.

Both trigger types follow the same Steps 1–7 workflow. The only differences for auto-remediation:
- **Step 3c**: Evidence collection uses the combined evidence focus from the review-summary.md HIGH flags (e.g., "Seek sources for the underrepresented side" + "Collect evidence on the counter-argument scenario")
- **Step 4**: Iteration trigger detail is set to `"Auto-remediation: Layer 2 flagged {{FLAG_DESCRIPTIONS}}"`
- **Report regeneration**: Always full (not scoped-only), since the user has not yet seen any report

---

## Step 1 — Detect Iteration Number

1. Check if `{{ANALYSIS_DIR}}/iterations/` directory exists
2. If **absent**: this is iteration 2
   - Create `iterations/` directory
   - Create `iterations/iteration-1-meta.md` as a retroactive baseline snapshot:
     - Read current `meta.md` for technique list and dates
     - Read current `evidence-registry.md` for evidence count
     - Read current report key judgments for confidence levels
     - Populate the iteration-meta-template with baseline values
     - Set Trigger Type to `BASELINE` and Detail to `"Retroactive snapshot of original analysis"` (or `"Retroactive snapshot before auto-remediation"` if trigger is auto-remediation)
   - Set `{{CURRENT_ITER}}` = 2
3. If **present**: count existing `iteration-*-meta.md` files → set `{{CURRENT_ITER}}` = count + 1
4. Read `{{ANALYSIS_DIR}}/next-steps.md` (if it exists):
   - Parse the Iteration Items table
   - Filter to `OPEN` items only
   - Extract technique names and evidence focus descriptions
   - These become the iteration scope (overrides meta.md technique list when next-steps.md exists)
   - If `next-steps.md` does not exist (legacy analysis created before this feature): fall back to reading meta.md for technique list (existing behavior)

---

## Step 2 — Archive Prior Artifacts

For each technique artifact that will be re-run:

1. Determine the prior version number:
   - If `working/{{name}}.v1.md` does not exist, the current `working/{{name}}.md` is version 1
   - Otherwise, find the highest existing `.v{N}.md` → prior version = N
2. Rename the current canonical artifact:
   - `working/{{name}}.md` → `working/{{name}}.v{{PRIOR_VERSION}}.md`
3. The new technique execution will write to the canonical `working/{{name}}.md`

**Important**: Only archive artifacts for techniques that are being re-run. In a scoped iteration, unchanged technique artifacts remain at their canonical paths untouched.

### Archive Report and Monitoring Plan

Before report regeneration:
1. If `report.md` exists: rename to `report.v{{PRIOR_VERSION}}.md`
2. If `monitoring-plan.md` exists: rename to `monitoring-plan.v{{PRIOR_VERSION}}.md`

These are archived alongside technique artifacts so the report synthesis subagent can reference the prior report for comparison.

---

## Step 3 — Evidence Delta

### 3a — Read Current Registry

1. Read `evidence-registry.md`
2. Parse the highest evidence ID (e.g., `E20` → next ID starts at `E21`)
3. Note the current total evidence count

### 3b — Add Iter Column (if not present)

If the Evidence Inventory table does not already have an `Iter` column:

1. Add `Iter` column after `Diagnostic Value`
2. Set all existing items to `Iter` = `1`

### 3c — Collect New Evidence

1. If OSINT is enabled: run evidence collection per `protocols/evidence-collector.md`
   - New items start at `E{{NEXT_ID}}`
   - Each new item gets `Iter` = `{{CURRENT_ITER}}`
2. If scoped iteration with targeted collection focus:
   - Pass the collection focus from the iteration trigger to the evidence collector
   - Example (user-invoked): "Collect evidence specifically addressing pessimistic bias — seek optimistic/neutral sources on US cyber defense capability improvements"
   - Example (auto-remediation): "Collect evidence addressing Layer 2 flags — seek sources for the underrepresented hypothesis side; collect evidence on the counter-argument scenario identified in self-critique"
3. Append new items to the existing registry (never replace existing items)

### 3d — Update Collection Summary

Update the Collection Summary table counts to reflect the combined evidence base.

---

## Step 4 — Dispatch Techniques

For each technique being re-run, provide additional SETUP context:

1. **Prior artifact path**: `"Read prior iteration artifact at working/{{name}}.v{{PRIOR_VERSION}}.md for comparison"`
2. **Iteration number**: `"This is iteration {{CURRENT_ITER}}. Compare your findings against the prior version."`
3. **Evidence delta**: `"New evidence items E{{START}}-E{{END}} were collected for this iteration. Evaluate whether they change prior findings."`
4. **Iteration trigger**: `"This re-run was triggered by: {{TRIGGER_DETAIL}}"`

The technique protocol itself is unchanged — it follows the same SETUP → PRIME → EXECUTE → ARTIFACT → FINDINGS → HANDOFF sequence. The additional context above is prepended to the technique's SETUP step.

---

## Step 5 — Cross-Iteration Synthesis

After all re-run techniques complete:

1. For each re-run technique, compare new artifact against prior version:
   - What findings changed?
   - What remained stable?
   - Did confidence levels shift? In which direction?
   - What new evidence drove the changes?

2. Generate a **delta summary** covering:
   - Judgment revisions (prior confidence → new confidence → driver)
   - Findings that strengthened or weakened
   - New findings not present in prior iteration
   - Findings from prior iteration that were invalidated

3. For **full iterations**: regenerate the report with a "Revision History" section
4. For **scoped iterations**: write a findings summary in the iteration metadata (do NOT regenerate the full report unless explicitly requested)
5. For **auto-remediation**: always regenerate the full report (the user has not seen any report yet), with a "Revision History" section noting the auto-remediation. Dispatch the Phase A subagent per `protocols/report-generator.md` using the orchestrator's Iterate Mode Step 7 prompt template (with the `## Iteration Context` block populated from `iteration-context.md`).

---

## Step 5a — Write Iteration Context for Report Generator

After cross-iteration synthesis, write `{{ANALYSIS_DIR}}/working/iteration-context.md`:

```markdown
# Iteration Context

- **Iteration**: {{CURRENT_ITER}}
- **Trigger**: {{TRIGGER_DETAIL}}
- **Scope**: {{FULL_OR_SCOPED}} — techniques: {{TECHNIQUE_LIST}}
- **Prior report**: report.v{{PRIOR_VERSION}}.md

## Delta Summary

### Judgment Revisions
| Judgment | Prior (v{{PRIOR}}) | Current (v{{CURRENT}}) | Driver |
|----------|-------------------|----------------------|--------|
{{JUDGMENT_REVISION_ROWS}}

### Findings That Strengthened
{{STRENGTHENED_LIST}}

### Findings That Weakened
{{WEAKENED_LIST}}

### New Findings
{{NEW_FINDINGS_LIST}}

### Invalidated Findings
{{INVALIDATED_LIST}}

### Confidence Shifts
{{CONFIDENCE_SHIFT_NARRATIVE}}
```

This file is consumed by the report synthesis subagent (Phase A) to populate the Revision History section.

---

## Step 5b — Update Next Steps Ledger

After cross-iteration synthesis, update `{{ANALYSIS_DIR}}/next-steps.md`:

1. **Resolve completed items**: For each technique that was re-run in this iteration:
   - Find matching `OPEN` items in the Iteration Items table
   - Update Status from `OPEN` to `RESOLVED — Iter {{CURRENT_ITER}}`
   - In the Detail section, change `[OPEN]` to `[RESOLVED — Iter {{CURRENT_ITER}}]`
   - Append a resolution note:
     ```
     - **Resolved**: Iteration {{CURRENT_ITER}} ({{DATE}}). {{NEW_EVIDENCE_COUNT}} new evidence items ({{ID_RANGE}}). {{ONE_LINE_SUMMARY_FROM_DELTA}}.
     ```

2. **Append new flags**: If the iteration's Layer 2 self-critique (run during report regeneration) produces new actionable flags:
   - Append new rows to the Iteration Items table with sequential numbering continuing from the last item
   - Add corresponding Detail sections at the bottom
   - Set Status to `OPEN` for all new items

3. **Update summary counts**: Recalculate TOTAL, REMEDIATED, RESOLVED, and OPEN counts in the Summary line

4. **Update suggested command**: Regenerate the `/analyze --iterate` command with only the techniques from remaining `OPEN` items. If no `OPEN` items remain, replace with: `"No open iteration items. All identified gaps have been addressed."`

5. **Update header**: Set `Iteration: {{CURRENT_ITER}}` and update Quality Score if a new score was produced

**Legacy fallback**: If `next-steps.md` does not exist (analysis predates this feature), skip this step. The iteration's Phase A report synthesis will create `next-steps.md` as part of its normal output, bootstrapping the ledger for future iterations.

---

## Step 6 — Write Iteration Metadata

Create `iterations/iteration-{{CURRENT_ITER}}-meta.md` using `templates/iteration-meta-template.md`:

1. Record the trigger (monitoring indicator, critique follow-up, new evidence, human request, auto-remediation)
2. Record scope (full or scoped, which techniques)
3. Record evidence delta (new item count, ID range, sources)
4. Record judgment revisions from cross-iteration synthesis
5. Record archived artifacts with version numbers

---

## Step 7 — Update Meta.md

1. Update the `Iteration` field in the Session table to `{{CURRENT_ITER}}`
2. Update technique statuses — re-run techniques show new `Iter` value
3. Add a row to the Iteration History table:

```
| {{CURRENT_ITER}} | {{DATE}} | {{TRIGGER_SUMMARY}} | {{SCOPE}} | {{NEW_EVIDENCE_COUNT}} items | {{KEY_CHANGES_SUMMARY}} |
```

---

## Cross-Iteration Citation Format

When referencing findings from prior iterations within new artifacts:

```
[PRIOR-v{{N}}: technique_name]
```

Examples:
- `[PRIOR-v1: ach-matrix]` — references ACH findings from iteration 1
- `[PRIOR-v2: assumptions]` — references KAC findings from iteration 2

This format is registered in the skill's citation methods and should be used alongside OSINT, FILE, USER, and ANALYSIS citations.

---

## Error Handling

- If a prior artifact is missing (e.g., technique was not run in a prior iteration): skip archiving, execute technique as if first-run, note in iteration metadata
- If evidence collection fails: proceed with existing evidence base, log failure in iteration metadata, flag in Layer 1 self-correction
- If the iterations directory exists but contains no files: treat as corrupt state, recreate iteration-1-meta.md baseline

---

*Protocol: Iteration Handler | Structured Analysis Skill*
