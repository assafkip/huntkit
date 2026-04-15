# Report Generator Protocol

Synthesize all technique outputs into the final report and monitoring plan. Execute Layer 2 self-critique before writing.

> **Path note:** `{{ANALYSIS_DIR}}` is resolved by the orchestrator before this protocol runs. It points to the active case's analysis directory. Use it as-is -- do not hardcode `analyses/`.

---

## Execution Architecture

The report generator runs in two phases to keep full artifact content out of the main context:

**Phase A — Synthesis Subagent** (foreground Agent subagent):
- Executes Steps 1–3 and Step 5 (gather inputs, synthesize, self-critique, write artifacts)
- Reads all working artifacts from disk (fresh context window — no main context pollution)
- Writes: `report.md`, `monitoring-plan.md`, `working/review-summary.md`, `next-steps.md`
- Returns ONLY: "Report written. Quality score: X/5.0 (STATUS). HIGH flags: N."

**Phase B — Human Review & Finalization** (main context):
- Executes Steps 4, 6, and 7 (human review gate, present results, iteration suggestions)
- Reads ONLY `working/review-summary.md` (~500 tokens)
- If user provides feedback: dispatches a revision subagent to apply edits to report.md

### Phase A Subagent Prompt

The orchestrator dispatches Phase A using the Agent tool with `subagent_type: "general-purpose"` and this prompt. Substitute ALL `{{VARIABLES}}` with their resolved values -- including `{{ANALYSIS_DIR}}`, `{{SKILL_DIR}}`, and `{{ITERATION_CONTEXT}}`:

```
You are a structured analysis report synthesizer. Your task:

1. Read all working artifacts from {{ANALYSIS_DIR}}/working/
2. Read {{ANALYSIS_DIR}}/evidence-registry.md
3. Read {{ANALYSIS_DIR}}/meta.md
4. Read the report-generator protocol at {{SKILL_DIR}}/protocols/report-generator.md — execute Steps 1-3, Step 5, and Steps 7a-7c (self-critique flag mapping and iteration suggestions)
5. Read and fill {{SKILL_DIR}}/templates/report-template.md (disposition first, detail last)
6. Read {{SKILL_DIR}}/templates/monitoring-plan-template.md and generate the monitoring plan
7. Read {{SKILL_DIR}}/templates/review-summary-template.md and fill it with summary data
7a. Read {{SKILL_DIR}}/templates/next-steps-template.md — populate it using the Layer 2 flags (Steps 3a-3h) and sufficiency gate flags collected during self-critique. Set all items to Status: OPEN. Write to {{ANALYSIS_DIR}}/next-steps.md
8. Write four files:
   - {{ANALYSIS_DIR}}/report.md
   - {{ANALYSIS_DIR}}/monitoring-plan.md
   - {{ANALYSIS_DIR}}/working/review-summary.md
   - {{ANALYSIS_DIR}}/next-steps.md
9. Update {{ANALYSIS_DIR}}/meta.md with completion status and quality score
10. Count the number of HIGH-severity flags identified in Step 7b's mapping table. Include this count as the HIGH flags value in the return string.

{{ITERATION_CONTEXT}}

Return ONLY: "Report written. Quality score: X/5.0 (STATUS). HIGH flags: N."
```

Where `{{ITERATION_CONTEXT}}` is empty for first-run analyses, or contains iteration-specific instructions (see iteration-handler protocol).

### Phase B Flow

After the Phase A subagent returns:

1. Read `{{ANALYSIS_DIR}}/working/review-summary.md`
2. Execute Step 4 (Human Review Gate) using the summary data
3. If user provides feedback:
   - Dispatch a revision subagent with: the feedback text, path to report.md, and instruction to apply edits and rewrite
   - After revision subagent returns, re-read review-summary.md if quality score changed
4. If no feedback: proceed
5. Execute Step 6 (Present Results) — use summary data for the conversation output
   - Reference `next-steps.md` path when presenting iteration suggestions
6. Execute Step 7 (Iteration Suggestions) — use the suggestions from review-summary.md
7. Execute Step 8 (Q Investigation Feedback) — write analysis results back to the case

---

## Step 8: Q Investigation Feedback *(Phase B — runs in main context)*

After the analysis is finalized, feed key results back into the Q investigation system so they're visible to `/q-status`, `/q-brief`, `/q-challenge`, and other Q commands.

1. **Write findings summary** to `investigations/<active-case>/investigation/findings/analysis-{{ANALYSIS_ID}}.md`:
   - Key judgments from the report (with confidence levels)
   - Citation: `[Derived via /analyze, see output/analyses/{{ANALYSIS_ID}}/report.md]`
   - Technique(s) used
   - Date of analysis

2. **Update investigation-state.md** (`investigations/<active-case>/memory/investigation-state.md`):
   - Add to the analysis history: analysis ID, techniques run, quality score, key finding
   - Update hypothesis status if the analysis confirmed/refuted any
   - Add any new collection gaps identified by the analysis

3. **Flag collection gaps for `/q-scope`** (if the analysis surfaced new gaps):
   - Do NOT write to `canonical/collection-plan.md` directly (file authority: canonical/ only updated via `/q-scope`)
   - Instead, add new collection gaps to `memory/investigation-state.md` under a "Pending collection updates (from /analyze)" section
   - Present the gaps to the user and suggest: "Run `/q-scope` to formally add these to the collection plan"

---

## Step 1: Gather Inputs *(Phase A — runs in subagent)*

Read from the analysis directory (`{{ANALYSIS_DIR}}/`):
- All working artifacts in `working/`
- `evidence-registry.md`
- `meta.md` for technique execution order and modes

---

## Step 2: Cross-Technique Synthesis *(Phase A — runs in subagent)*

For every technique that produced findings:
1. Extract key findings with confidence levels
2. Identify **agreement** — techniques pointing to the same conclusion
3. Identify **disagreement** — techniques suggesting different conclusions
4. Resolve disagreements: explain which technique's methodology is more applicable to this specific problem and why
5. Generate an integrated assessment with overall confidence level

### 2b: Analytical Framework (Technique Weights)

After synthesis, assign each technique a weight reflecting its influence on the key judgments:

| Column | Values | Guidance |
|--------|--------|----------|
| **Role** | Diagnostic, Challenge, Foresight, Decision Support | Use the technique's Phase from the routing table |
| **Weight** | Primary, Supporting, Qualifying | Primary = technique directly shaped 2+ key judgments. Supporting = reinforced or refined primary findings. Qualifying = introduced caveats, conditions, or confidence adjustments without changing the direction of findings. |
| **Direction** | Confirming, Challenging, Mixed | Confirming = findings align with the emerging consensus across techniques. Challenging = findings push against it. Mixed = some findings confirm, others challenge. |
| **Key Contribution** | 1 sentence | The single most important thing this technique added to the assessment. |

**Assignment rules**:
- At least one technique must be weighted Primary (the analysis must have a backbone)
- Challenge-phase techniques (Premortem, What If?, Devil's Advocacy) are typically Qualifying or Challenging — if a challenge technique confirms, note that explicitly as it strengthens confidence
- If all techniques are Confirming, flag this in the Confidence Calibration check (potential groupthink)
- Weights are qualitative labels for reader orientation, not numeric scores — do not assign percentages

---

## Step 3: Layer 2 Self-Critique *(Phase A — runs in subagent)*

Execute ALL eight checks before writing the report. Results from 3a–3g go into the "Risks & Blind Spots" section. Results from 3h are logged to `meta.md`.

### 3a. Assumption Audit
Review all working artifacts for unstated premises embedded in findings. List each with its source artifact.

### 3b. Evidence Balance
Count evidence items supporting each hypothesis or finding. Flag any imbalance exceeding 2:1. Ask: is the imbalance justified by evidence quality, or does it reflect collection bias?

### 3c. Confidence Calibration
Check for Bipolar Bias — are confidence levels proportional to actual evidence strength, or over/under-corrected? Analysts tend to cluster at High or Low while avoiding Moderate.

### 3d. Alternative Check
Write the strongest 2-3 sentence case AGAINST the top finding. If you cannot construct a credible counter-argument, the finding may be trivially true (and therefore low-value). If the counter-argument is strong, the confidence level may need lowering.

### 3e. Missing Voices
List domains, perspectives, or stakeholder viewpoints where no evidence was gathered. These are blind spots, not necessarily errors.

### 3f. Internal Consistency Audit
Cross-reference validation across generated artifacts. Flag discrepancies and explain measurement differences where applicable:
- Evidence registry diagnostic values vs ACH diagnosticity ratings (these measure different things — flag mismatches, explain the difference)
- Hypothesis rankings consistent between ACH matrix, synthesis section, executive summary, and key judgments table
- Confidence levels consistent across technique findings and the integrated assessment
- Evidence IDs referenced in technique artifacts actually exist in the evidence registry
- Negative evidence items properly dual-rated (factual reliability vs interpretive reliability)

### 3g. Analytical Bias Scan
Check for known cognitive biases in the assessment:
- **Sycophancy**: Does the assessment tell the user what they want to hear? If the user-provided hypothesis is confirmed, apply extra scrutiny to the confirming evidence chain.
- **Completion bias**: Is quality conflated with thoroughness? Running many techniques does not strengthen a conclusion — only discriminating evidence does.
- **Authority bias**: Are high-reliability sources given disproportionate weight over diagnostic value? A reliable source with low diagnostic power should not outweigh a less established source with high diagnostic power.
- **Anchoring**: Does the original hypothesis framing dominate the assessment despite problem restatement? Compare the original framing to the reframed problem — if findings track the original framing more closely, anchoring may be present.
- **Vividness bias**: Are emotionally compelling narratives (e.g., "front company," "state-sponsored") given more weight than their evidence supports? Flag vivid framings and verify their evidentiary basis independently.

### 3h. Quality Score
Quantitative self-assessment. Compute silently; log results to `meta.md` under the Quality Score section.

| Criterion | Base Weight | What to Assess | Requires |
|-----------|-------------|----------------|----------|
| Evidence discrimination | 0.30 | What % of evidence items have non-zero diagnostic value in ACH? | ACH |
| Hypothesis separation | 0.25 | How many inconsistencies separate the top-ranked from bottom-ranked hypothesis? | ACH or Inconsistencies |
| Assumption coverage | 0.20 | What % of linchpin assumptions have direct supporting or challenging evidence? | KAC |
| Cross-technique convergence | 0.15 | Do techniques agree on the primary finding? | 2+ techniques |
| Deception resilience | 0.10 | What % of high-diagnostic evidence is rated LOW deception risk? | Deception Detection |

**Weight renormalization**: If a required technique was not run, drop that criterion and redistribute its weight proportionally among the remaining criteria. For example, in Lean mode (no ACH, no Deception Detection), drop Evidence discrimination (0.30) and Deception resilience (0.10), then renormalize: Hypothesis separation becomes 0.25/0.60 ≈ 0.42, Assumption coverage becomes 0.20/0.60 ≈ 0.33, Cross-technique convergence becomes 0.15/0.60 ≈ 0.25. Always ensure weights sum to 1.0.

Score each criterion 1–5, compute weighted total (using renormalized weights). Log to `meta.md`.
- **Score > 4.0**: PASS — proceed to report finalization.
- **Score 3.0–4.0**: ADVISORY — note in report, proceed unless human review overrides.
- **Score < 3.0**: FAIL — flag for mandatory iteration before report finalization. Do not finalize without addressing the lowest-scoring criteria.

---

## Step 4: Human Review Gate *(Phase B — runs in main context)*

Read `{{ANALYSIS_DIR}}/working/review-summary.md` and present its contents in conversation:

```
## Analysis Summary for Review

[Present the review summary contents directly — problem, evidence stats, key finding, quality score, Layer 2 flags]

What would you adjust before I finalize?
```

If user provides feedback, dispatch a revision subagent:
- Input: user feedback text + `{{ANALYSIS_DIR}}/report.md`
- Instruction: Apply the specified edits to the report. Rewrite the file.
- Return: "Revisions applied."

If no feedback, proceed to Step 6.

---

## Step 5: Write Final Artifacts *(Phase A — runs in subagent)*

### Report (`report.md`)
Read `templates/report-template.md` and fill every section in document order (disposition first, detail last). The template is the authoritative section ordering — follow it exactly.

**Reusable section components** (in `templates/sections/`):
- `header.md` — standard artifact header format
- `confidence-scale.md` — confidence level definitions (High/Moderate/Low with criteria) per ICD 203 Standard 2
- `judgment-table.md` — key judgments table format with technique/assumption/indicator cross-references
- `citation-block.md` — standard citation table with method explanations

Use these as reference for consistent formatting across all report sections.

### Monitoring Plan (`monitoring-plan.md`)
Use `templates/monitoring-plan-template.md`. For each key judgment:
- Generate 2-3 confirming indicators (what to look for if judgment is correct)
- Generate 2-3 disconfirming indicators (what to look for if judgment is wrong)
- Each indicator must be observable and have a specific source to check
- Set trigger threshold: recommend re-analysis when ≥2 disconfirming indicators observed
- Initialize empty review log

### Meta Update (`meta.md`)
Update with completion status, final technique list, and file manifest.

---

## Step 6: Present Results *(Phase B — runs in main context)*

Read `{{ANALYSIS_DIR}}/working/review-summary.md`. In conversation, provide:
- One-paragraph summary of the key finding with confidence (from the summary)
- File paths to all generated artifacts
- Monitoring plan highlights (top 2-3 indicators to watch)
- Invitation: "Would you like me to deep-dive into any section or adjust the analysis?"

---

## Step 7: Iteration Suggestions *(Phase B — runs in main context)*

**Guard**: Check the review-summary.md for iteration suggestions. If the summary says "No actionable iteration suggestions," skip this step.

Present the iteration suggestions from the review summary in conversation.

**Note**: Steps 7a-7c are executed by the Phase A subagent and their output is written to review-summary.md. Phase B simply presents the pre-computed suggestions. The subsections below document how the Phase A subagent computes suggestions.

### 7a. Collect Flags

Read flags from:
- **Layer 1**: Sufficiency Gate soft-check warnings in `evidence-registry.md` (LOW SOURCE DIVERSITY, LOW DIAGNOSTIC POWER, STALE EVIDENCE)
- **Layer 2**: Self-critique results from Step 3 above (3a–3h checks)

### 7b. Map Flags to Iterations

Use this mapping table to convert each actionable flag into a concrete iteration suggestion:

| Flag Source | Flag Type | Default Severity | Suggested Technique(s) | Evidence Focus |
|---|---|---|---|---|
| Sufficiency Gate | LOW SOURCE DIVERSITY | MEDIUM | *(evidence collection only)* | Broaden source types |
| Sufficiency Gate | LOW DIAGNOSTIC POWER | MEDIUM | `ach`, `inconsistencies` | Seek evidence that discriminates between hypotheses |
| Sufficiency Gate | STALE EVIDENCE | LOW | *(evidence collection only)* | Focus on last 6 months |
| Layer 2 - 3a | Unstated premises impacting key judgment | HIGH | `kac` | Collect evidence testing the flagged assumptions |
| Layer 2 - 3a | Unstated premises (non-critical) | MEDIUM | `kac` | Collect evidence testing the flagged assumptions |
| Layer 2 - 3b | Evidence imbalance >2:1 | HIGH | `ach` | Seek sources for the underrepresented side |
| Layer 2 - 3c | Bipolar bias detected | — | *(confidence recalibration — no re-run)* | N/A |
| Layer 2 - 3d | Strong counter-argument | HIGH | `what-if`, `premortem` | Collect evidence on the counter-argument scenario |
| Layer 2 - 3e | Missing perspectives | MEDIUM | `narratives` | Collect evidence from the missing viewpoint |
| Layer 2 - 3f | Internal inconsistency found | — | *(in-report fix — no technique re-run)* | Correct the inconsistency in the report |
| Layer 2 - 3g | Analytical bias — sycophancy/anchoring | HIGH | `devils-advocacy` or `red-hat` | Seek evidence that counters the biased direction |
| Layer 2 - 3g | Analytical bias — mild flags | MEDIUM | `devils-advocacy` or `red-hat` | Seek evidence that counters the biased direction |
| Layer 2 - 3h | Quality score < 3.0 | HIGH (mandatory) | Technique(s) driving lowest-scoring criterion | Collect discriminating evidence |

**Severity classification guidance:**
- **HIGH**: Undermines analytical foundation, biases hypothesis ranking, or distorts conclusions. Triggers auto-remediation gate in the orchestrator.
- **MEDIUM**: Identifies blind spots or minor biases worth noting. Presented as manual iteration suggestions.
- **LOW**: Minor issues or stale data. Advisory only.
- **—**: Not actionable as iteration (in-report adjustments only). Not assigned a severity.

**Override guidance**: The Phase A subagent may upgrade MEDIUM → HIGH when a flag directly undermines a key judgment (e.g., missing perspective that contradicts the top finding), or downgrade HIGH → MEDIUM when the flag is technically triggered but has minimal impact on findings (e.g., 2.1:1 evidence imbalance where the underrepresented hypothesis was independently disconfirmed).

**Rules**:
- Bipolar bias (3c) is noted in the report but NOT mapped to an iteration — it's an in-report confidence adjustment, not a re-run trigger.
- Internal inconsistency (3f) is corrected in the report directly — no technique re-run needed.
- Quality score failures (3h) map to the technique(s) responsible for the lowest-scoring criterion, not a blanket re-run.
- Evidence-only flags (LOW SOURCE DIVERSITY, STALE EVIDENCE) suggest re-running evidence collection without technique re-runs.
- Deduplicate techniques — if multiple flags map to the same technique, combine their evidence focus descriptions.

### 7c. Present Suggestions

Append to the conversation output (after Step 6) using this format:

```
## Iteration Suggestions

{{#IF HAS_HIGH_FLAGS}}
### Auto-Remediated (HIGH severity)
The following {{HIGH_COUNT}} flags were automatically addressed before report finalization:

{{#EACH HIGH_FLAG}}
{{INDEX}}. **{{FLAG_TYPE}}** [AUTO-REMEDIATED]: {{FLAG_DESCRIPTION}}
   → Re-ran: {{TECHNIQUES}} | Evidence focus: {{FOCUS}}
{{/EACH}}
{{/IF}}

{{#IF HAS_REMAINING_FLAGS}}
### Suggested for Manual Iteration (MEDIUM/LOW severity)
Self-critique identified {{REMAINING_COUNT}} additional items:

{{#EACH REMAINING_FLAG}}
{{INDEX}}. **{{FLAG_TYPE}}** [{{SEVERITY}}]: {{FLAG_DESCRIPTION}}
   → Re-run: {{TECHNIQUES}} | Evidence focus: {{FOCUS}}
{{/EACH}}

Suggested command: `/analyze --iterate {{ANALYSIS_ID}} {{TECHNIQUE_LIST}}`
{{/IF}}

{{#IF NO_FLAGS}}
No actionable iteration suggestions. All self-critique checks passed or produced only in-report adjustments.
{{/IF}}
```

- After presenting iteration suggestions in conversation, add: `"Full iteration ledger with status tracking: {{ANALYSIS_DIR}}/next-steps.md"`
- `{{HIGH_COUNT}}` = count of HIGH-severity flags that were auto-remediated
- `{{REMAINING_COUNT}}` = count of MEDIUM/LOW actionable flags (excluding 3c bipolar bias and 3f in-report fixes)
- `{{INDEX}}` = sequential numbering within each section (1, 2, 3...)
- `{{TECHNIQUE_LIST}}` = deduplicated, space-separated list of all MEDIUM/LOW suggested techniques (HIGH flags are already handled)
- If only evidence-collection flags exist (no technique re-runs), omit the technique list from the command and note that re-running evidence collection is the primary action
- Each numbered item corresponds to one flag with its mapped technique(s), severity, and evidence focus
- HIGH-severity flags appear under "Auto-Remediated" only if the orchestrator's auto-remediation gate ran. If auto-remediation was not triggered (e.g., first analysis run before this feature existed), all flags appear under "Suggested for Manual Iteration."
