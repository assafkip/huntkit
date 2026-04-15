# Orchestrator Protocol

Route modes, select techniques, and manage the analysis workflow.

---

## Path Resolution (MUST run first)

Before any file operations or subagent dispatch, resolve these two path variables:

### `{{SKILL_DIR}}`
Path to this skill's directory (relative to project root). Set to:
```
skills/structured-analysis
```
All protocol files, template files, and library files are under this path. When building subagent prompts, always use the full `{{SKILL_DIR}}/...` path -- subagents cannot resolve relative skill paths.

The routing table's `Protocol File` and `Template File` columns are relative to `{{SKILL_DIR}}`. When filling `{{PROTOCOL_PATH}}` and `{{TEMPLATE_PATH}}` in subagent prompts, prepend `{{SKILL_DIR}}/`:
- Routing table says `protocols/techniques/ach.md` -> subagent gets `skills/structured-analysis/protocols/techniques/ach.md`

### `{{ANALYSIS_DIR}}`
The output directory for this analysis. Set to:
```
investigations/<active-case>/output/analyses/{{ANALYSIS_ID}}
```

1. Read `./.active-case` to get the active case folder name
2. If the file is empty or missing, ask the user which case this analysis belongs to, then write their answer to `.active-case`
3. Resolve the full path: `investigations/<active-case>/output/analyses/{{ANALYSIS_ID}}`

**All paths in this protocol and in subagent prompts use these variables.** When constructing subagent prompts, substitute the resolved paths -- subagents do not read SKILL.md and cannot resolve relative paths on their own.

---

## Mode Detection

Parse the skill invocation arguments:

| Input | Mode |
|-------|------|
| No args | **Adaptive** — auto-select techniques |
| Technique name (e.g., `ach`, `kac`) | **Direct** — run single technique |
| `--guided` | **Guided** — walk through all phases |
| `--resume <id>` | **Resume** — continue or update existing analysis |
| `--iterate <id>` | **Iterate** — re-run with artifact versioning and evidence delta |
| `--iterate <id> <technique>` | **Iterate (scoped)** — re-run specific technique(s) only |
| `--lean` | **Lean** — Problem Restatement + KAC + Inconsistencies only (overrides rubric) |
| `--comprehensive` | **Comprehensive** — full 14-question rubric, no technique cap, unlocks adversarial + deception checks |
| `--no-osint` | Flag — disable web research |

Flags combine with modes: `--guided --no-osint` is valid.

### Mode Flag Conflict Resolution

| Combination | Resolution |
|---|---|
| `--lean` + `--comprehensive` | ERROR: conflicting effort levels — prompt user to choose |
| `--lean` + `--guided` | Lean overrides technique selection; guided phases still execute |
| `--comprehensive` + `--guided` | Both apply: full rubric + phased execution |
| `--no-osint` + any mode | OSINT disabled; all modes respect this |

---

## Technique Routing Table

| Invocation Name | Protocol File | Template File | Artifact | Phase |
|---|---|---|---|---|
| `customer-checklist` | `protocols/techniques/customer-checklist.md` | `templates/techniques/customer-checklist.md` | `requirements.md` | Launch |
| `issue-redefinition` | `protocols/techniques/issue-redefinition.md` | `templates/techniques/issue-redefinition.md` | `problem-framing.md` | Launch |
| `restatement` | `protocols/techniques/problem-restatement.md` | `templates/techniques/problem-restatement.md` | `problem-framing.md` (appends) | Launch |
| `brainstorm` | `protocols/techniques/structured-brainstorming.md` | `templates/techniques/brainstorm.md` | `brainstorm.md` | Exploration |
| `kac` | `protocols/techniques/key-assumptions-check.md` | `templates/techniques/assumptions.md` | `assumptions.md` | Diagnostic |
| `ach` | `protocols/techniques/ach.md` | `templates/techniques/ach-matrix.md` | `ach-matrix.md` | Diagnostic |
| `inconsistencies` | `protocols/techniques/inconsistencies-finder.md` | `templates/techniques/inconsistencies.md` | `inconsistencies.md` | Diagnostic |
| `cross-impact` | `protocols/techniques/cross-impact-matrix.md` | `templates/techniques/cross-impact.md` | `cross-impact.md` | Diagnostic |
| `what-if` | `protocols/techniques/what-if.md` | `templates/techniques/what-if.md` | `what-if.md` | Challenge |
| `premortem` | `protocols/techniques/premortem.md` | `templates/techniques/premortem.md` | `premortem.md` | Challenge |
| `counterfactual` | `protocols/techniques/counterfactual-reasoning.md` | `templates/techniques/counterfactual.md` | `counterfactual.md` | Foresight |
| `narratives` | `protocols/techniques/contrasting-narratives.md` | `templates/techniques/contrasting-narratives.md` | `narratives.md` | Foresight |
| `devils-advocacy` | `protocols/techniques/devils-advocacy.md` | `templates/techniques/devils-advocacy.md` | `devils-advocacy.md` | Challenge |
| `red-hat` | `protocols/techniques/red-hat-analysis.md` | `templates/techniques/red-hat-analysis.md` | `red-hat-analysis.md` | Challenge |
| `bowtie` | `protocols/techniques/bowtie-analysis.md` | `templates/techniques/bowtie.md` | `bowtie.md` | Decision Support |
| `opportunities` | `protocols/techniques/opportunities-incubator.md` | `templates/techniques/opportunities.md` | `opportunities.md` | Decision Support |
| `alt-futures` | `protocols/techniques/alternative-futures.md` | `templates/techniques/alternative-futures.md` | `alt-futures.md` | Foresight |
| `deception` | `protocols/techniques/deception-detection.md` | `templates/techniques/deception-detection.md` | `deception.md` | Diagnostic |

All paths are relative to the skill directory (`skills/structured-analysis/`).

---

## Analysis Directory Setup

At the start of ANY analysis:

1. Generate analysis ID: `YYYY-MM-DD-<slugified-problem-title>`
2. Create directories:
   - `{{ANALYSIS_DIR}}/working/` — technique artifacts
   - `{{ANALYSIS_DIR}}/working/osint-raw/` — raw scraped content (Step 3a output)
   - `{{ANALYSIS_DIR}}/working/osint-processed/` — extracted evidence items (Step 3b output)
3. Write initial `meta.md` using `templates/meta-template.md`
4. Note the analysis directory path — all artifacts go here

---

## Adaptive Mode Selection Logic

### Step 1 — Trigger Check

Ask these questions about the problem:
- Is this high-consequence? (significant risk, resource allocation, strategic implications)
- Is there persistent uncertainty? (incomplete, ambiguous, contradictory data)
- External scrutiny expected? (output briefed to stakeholders)
- Complex interaction? (multiple actors with competing interests)

If **NONE** apply: suggest expert judgment + Problem Restatement only. Confirm with user.
If **ANY** apply: proceed to technique selection.

### Step 2 — Stage Check

Map the conversation context to the appropriate phase:

| Situation | Start With |
|-----------|-----------|
| New project, no analysis yet | Launch → Customer Checklist + Issue Redefinition |
| Have data, need to evaluate | Diagnostic → KAC, ACH |
| Strong consensus exists | Challenge → What If?, Premortem |
| Need to model futures | Foresight → Counterfactual, Contrasting Narratives |
| Need to decide between options | Decision Support → Bowtie, Opportunities |

### Step 3 — Challenge Check (14-Question Rubric)

The rubric operationalizes four selection dimensions from the library's decision framework:
- **Uncertainty type**: Is the uncertainty factual, causal, or predictive? (drives Q2, Q3, Q4)
- **Data volatility**: How fast is the information environment changing? (drives Q1, Q5, Q11)
- **Bias susceptibility**: Which cognitive traps are most likely? (drives Q6, Q9, Q13, Q14)
- **Analytic complexity**: How many interacting variables and actors? (drives Q4, Q8, Q10, Q12)

Questions 1–11 are always active. Questions 12–14 activate in `--comprehensive` mode.

| # | Condition | Primary Technique | Substitutes | Complements | Threshold |
|---|-----------|-------------------|-------------|-------------|-----------|
| 1 | Large data volume to sort? | Structured Brainstorming | — | feeds → KAC, ACH | — |
| 2 | Premises not explicit? | Key Assumptions Check | — | feeds → ACH, Devil's Advocacy | — |
| 3 | Multiple exclusive explanations? | ACH | Inconsistencies Finder (≤2 hyp) | ← KAC; → Deception Detection | ≤2 hyp → Inconsistencies; 3+ → ACH |
| 4 | High uncertainty, many variables? | Cross-Impact Matrix | — | + Alternative Futures (if forecasting) | — |
| 5 | Fear of surprise? | What If? Analysis | — | + Premortem (if existing judgment) | — |
| 6 | Groupthink or dominant mindset? | Premortem + Self-Critique | — | + Devil's Advocacy (stronger challenge) | — |
| 7 | Need to find opportunities? | Opportunities Incubator | — | — | — |
| 8 | Competing options to evaluate? | Bowtie Analysis | — | — | — |
| 9 | Competing narratives in play? | Contrasting Narratives | — | + Deception Detection (if adversarial) | — |
| 10 | Need to understand causal dynamics? | Counterfactual Reasoning | — | — | — |
| 11 | Need to track over time? | Include Monitoring Plan | — | — | — |
| 12 | Multiple plausible futures? ★ | Alternative Futures | — | feeds → Monitoring Plan | — |
| 13 | Need to model adversary reaction? ★ | Red Hat Analysis | — | + Devil's Advocacy | — |
| 14 | Risk of intentional deception? ★ | Deception Detection | — | revises → ACH/Inconsistencies | — |

★ = Comprehensive mode only

**Reading the interaction columns:**
- **Substitutes**: Use INSTEAD of primary when threshold applies (e.g., Inconsistencies Finder replaces ACH for ≤2 hypotheses)
- **Complements**: Use IN ADDITION to primary (e.g., Devil's Advocacy adds to Premortem when both Q2+Q6 match). Complements are recommendations, not automatic additions.
- **feeds →**: Output of this technique is input to the next (prerequisite relationship)
- **+ technique**: Consider running alongside (reinforcing relationship)
- **revises →**: Output may require re-running a prior technique

### Step 4 — Effort Check & Technique Cap

**Lean Mode** (`--lean`):
- Use ONLY Problem Restatement + KAC (abbreviated: limit to 5 most critical premises; still identify linchpins — the linchpin scan is fast and high-value) + Inconsistencies Finder
- Overrides all rubric selections — no exceptions

**Default Mode** (no effort flag):
- Questions 1–11 active; max 6 techniques
- Prioritization when >6 match:
  1. Phase alignment (prefer techniques matching Stage Check result)
  2. Diagnostic before Challenge (test assumptions before stress-testing)
  3. Essential 8 before Extended techniques
- If >6 match, inform user: "I identified [N] matching techniques. Recommending [6 prioritized]. Use --comprehensive to run all."

**Comprehensive Mode** (`--comprehensive`):
- Full 14-question rubric (adds Q12–14: adversary reaction, deception risk, alternative futures)
- No technique cap — all matching techniques execute
- Complements from interaction model are promoted to selections (not just suggestions)

Present recommendation with rationale. Wait for user confirmation.

### No-Match Fallback

If zero Challenge Check questions match (or user requests minimal structure):

1. Problem Restatement (Launch)
2. Key Assumptions Check (Diagnostic)
3. Evidence collection
4. Inconsistencies Finder (≤2 hypotheses) or ACH (3+)
5. Premortem (Challenge)
6. Report with low-confidence flag

This ensures minimum viable rigor for edge cases.

---

## Guided Mode Phases

Execute in order, each phase building on the previous:

1. **Framing**: Customer Checklist → Issue Redefinition
2. **Assumptions**: Key Assumptions Check
3. **Evidence**: Read and execute `protocols/evidence-collector.md`
4. **Evidence Gate**: Execute the Evidence Sufficiency Gate (defined in `protocols/evidence-collector.md`). If hard checks fail, retry or halt. If soft checks fail, log flags and proceed.
5. **Core Analysis**: Use selection logic (Steps 2-3 above) to pick technique(s), then execute via the Technique Execution Contract (in-context for 1 technique, subagent dispatch for 2+)
6. **Stress Test**: Premortem + What If?
7. **Report**: Dispatch report synthesis subagent per `protocols/report-generator.md` Phase A. Then execute Auto-Remediation Gate (see section below). Then execute Phase B (human review gate) in main context.

---

## Direct Mode

1. Look up technique in the routing table. If the technique name is not found, respond with: "Unknown technique '{{INPUT}}'. Valid techniques: `customer-checklist`, `issue-redefinition`, `restatement`, `brainstorm`, `kac`, `ach`, `inconsistencies`, `cross-impact`, `what-if`, `premortem`, `counterfactual`, `narratives`, `devils-advocacy`, `red-hat`, `bowtie`, `opportunities`, `alt-futures`, `deception`." — then stop.
2. Create analysis directory
3. If OSINT not disabled, run evidence collector first
4. Execute Evidence Sufficiency Gate; if hard checks fail, retry or surface to analyst before proceeding
5. Execute the technique via the Technique Execution Contract (Direct mode always uses in-context execution since it's a single technique)
6. Present findings in conversation
7. Offer: "Would you like me to continue with a full analysis, or is this technique sufficient?"

---

## Resume Mode

1. Read `{{ANALYSIS_DIR}}/meta.md`
2. If analysis is **incomplete**: continue from last completed technique
3. If analysis is **complete**: read `{{ANALYSIS_DIR}}/monitoring-plan.md`, run fresh OSINT against indicators, update indicator status column and review log

---

## Iterate Mode

When `--iterate <id>` is detected (with or without a technique specifier):

1. Read the existing analysis at `{{ANALYSIS_DIR}}/`
2. Read `{{SKILL_DIR}}/protocols/iteration-handler.md` and follow its steps in order

### Full Iteration (`--iterate <id>`)

Execute the complete iteration workflow:

1. **Detect iteration number** — iteration-handler Step 1
2. **Collect new evidence** — re-run OSINT via `protocols/evidence-collector.md` (unless `--no-osint`), iteration-handler Step 3
3. **Evidence Gate** — evaluate only the evidence delta (newly collected items), not the full accumulated registry. Techniques execute against the combined evidence base (prior + new).
4. **Archive ALL working artifacts** — iteration-handler Step 2
5. **Re-run all techniques** — use the same technique set from `meta.md`, iteration-handler Step 4, dispatched via the Technique Execution Contract (subagent dispatch for 2+ techniques)
6. **Cross-iteration synthesis** — iteration-handler Step 5, comparing new vs. prior findings
7. **Regenerate report** — dispatch report synthesis subagent per `protocols/report-generator.md` Phase A with iteration context. The subagent prompt includes:
   ```
   ## Iteration Context
   This is iteration {{N}}. Read working/iteration-context.md for the delta summary.

   Additional instructions:
   - Populate the Revision History section in the report template
   - For each key judgment, note whether it changed from prior iteration and why
   - Reference prior findings using [PRIOR-v{{N}}: technique_name] citation format
   - Read the prior report at report.v{{PRIOR}}.md for comparison
   ```
   Then execute Auto-Remediation Gate (see section below). Then execute Phase B (human review gate) in main context.
8. **Update monitoring plan** — refresh indicators based on new findings
9. **Write iteration metadata** — iteration-handler Step 6
10. **Update meta.md** — iteration-handler Step 7
11. **Present delta summary** — show the analyst what changed, what remained stable, and what drove revisions

### Scoped Iteration (`--iterate <id> <technique>`)

Execute a targeted re-run of specific technique(s):

1. **Detect iteration number** — iteration-handler Step 1
2. **Optionally collect targeted evidence** — if the iteration trigger specifies a collection focus (e.g., "counter-evidence for pessimistic bias"), run evidence collection with that focus. Otherwise, skip.
3. **Evidence Gate** — evaluate only the evidence delta if new evidence was collected
4. **Archive only the specified technique's artifact(s)** — iteration-handler Step 2 (scoped)
5. **Re-run the specified technique(s)** — iteration-handler Step 4, dispatched via the Technique Execution Contract
6. **Cross-iteration synthesis** — compare new vs. prior findings for the re-run technique(s) only
7. **Write iteration findings summary** — write findings to iteration metadata. If the analyst explicitly requests report regeneration, dispatch report synthesis subagent with iteration context (same as full iteration Step 7). Otherwise, skip report regeneration.
8. **Update meta.md** — iteration-handler Step 7
9. **Present delta summary** — show what changed for the re-run technique(s)

---

## Evidence Gate (All Modes)

After evidence collection and before any technique execution, run the **Evidence Sufficiency Gate** defined in `protocols/evidence-collector.md`. This applies to Adaptive, Guided, and Direct modes.

- If hard checks fail: retry evidence collection or surface to analyst
- If soft checks fail: log flags in `meta.md` under Self-Correction > Layer 1 Flags, then proceed
- The Evidence Sufficiency Report should be included in the orchestrator's handoff to each technique

**Iteration Note**: In iterate mode, the sufficiency gate evaluates only the
evidence delta (newly collected items), not the full accumulated registry.
Techniques execute against the combined evidence base (prior + new).

---

## Technique Execution Contract

### Dispatch Decision

**Threshold rule**: If only 1 technique is selected (Direct mode), execute in-context to avoid subagent overhead. If 2+ techniques are selected, use subagent dispatch.

### In-Context Execution (1 technique)

1. **Read** the protocol file from the routing table
2. **Read** the template file from the routing table
3. **Execute** the protocol's SETUP → PRIME → EXECUTE → ARTIFACT → FINDINGS → HANDOFF steps
4. **Write** the artifact to `{{ANALYSIS_DIR}}/working/{{ARTIFACT_NAME}}.md`
5. **Layer 1 Check** (silent): Did the protocol complete all required steps? Are all template sections filled? Any {{PLACEHOLDER}} tokens remaining unfilled?
6. If Layer 1 fails: re-execute the missed steps before proceeding
7. **Update** `meta.md` with technique completion status and `Dispatch: in-context`

### Subagent Dispatch (2+ techniques)

#### Dependency Tier Assignment

Assign each selected technique to a tier based on its input dependencies. Only include tiers that contain at least one selected technique.

| Tier | Techniques | Dependencies | Dispatch | Timeout |
|------|-----------|-------------|----------|---------|
| 0 (Launch) | customer-checklist, issue-redefinition, restatement | Conversation context only | **In-context** (interactive, produce `requirements.md`) | — |
| — | Evidence Collection | requirements.md | Existing subagent pipeline (unchanged) | 10 min |
| 1 | brainstorm, kac | requirements.md, evidence-registry.md | Background, parallel | 5 min |
| 2 | ach, cross-impact, inconsistencies | + assumptions.md, brainstorm.md | Background, parallel | 5 min |
| 3 | what-if, counterfactual, narratives, bowtie, opportunities, deception | + prior technique outputs | Background, parallel | 8 min |
| 4 | premortem, devils-advocacy, red-hat, alt-futures | ALL prior working/ artifacts | Background, parallel | 8 min |

Within each tier, techniques run in parallel (no intra-tier dependencies). The orchestrator waits for all subagents in tier N to complete (or timeout) before dispatching tier N+1.

**Timeout handling**: If a subagent exceeds its tier timeout, mark it as `PARTIAL`, log a Layer 1 flag ("Technique {{NAME}} timed out after {{TIMEOUT}} — partial results may be incomplete"), and proceed with downstream tiers. Do not retry timed-out techniques automatically.

#### Dispatch Sequence

1. **Assign tiers**: Map each selected technique to its tier from the table above
2. **Tier 0**: Execute Launch techniques in-context (if selected) — these are interactive and produce `requirements.md`
3. **Evidence Collection**: Run existing evidence subagent pipeline (unchanged)
4. **For each tier (1 → 4)**, if that tier has selected techniques:
   a. Build the file manifest: list all files currently in `{{ANALYSIS_DIR}}/working/`
   b. Construct one subagent prompt per technique using the template below
   c. Launch all tier subagents as background agents (via Agent tool) in parallel
   d. Wait for all tier subagents to complete
   e. Collect and validate each subagent's return summary
   e2. **Artifact validation**: For each completed subagent, verify the artifact file exists on disk and contains no unfilled `{{PLACEHOLDER}}` tokens. If validation fails, log as `PARTIAL` and add a Layer 1 flag.
   f. If any subagent returns `FAILED`: log the error, skip that technique, add a Layer 1 flag
   g. If any subagent returns `PARTIAL`: log warnings, accept partial results, add a Layer 1 flag
   h. Update `meta.md` with each technique's status and dispatch tier
   **i. Run Tier Gate Protocol** (see above): scan accumulated findings for signals, inject corrective context into next tier's subagent prompts if needed
5. **Accumulate findings**: After all tiers complete, the main context holds only the compact summaries — not full technique work

#### Subagent Prompt Template

Each technique subagent receives this prompt. Substitute ALL `{{VARIABLES}}` with their resolved values -- including `{{SKILL_DIR}}`, `{{ANALYSIS_DIR}}`, `{{TECHNIQUE_NAME}}`, `{{PROTOCOL_PATH}}`, `{{TEMPLATE_PATH}}`, `{{ARTIFACT_NAME}}`, `{{ANALYSIS_ID}}`, `{{PROBLEM_STATEMENT_SUMMARY}}`, `{{FLAGS_OR_NONE}}`, and `{{FILE_MANIFEST}}`:

```
You are a structured analysis technique executor. Execute a single analytic technique and write the artifact to disk.

## Technique
- **Name**: {{TECHNIQUE_NAME}}
- **Protocol file**: {{SKILL_DIR}}/{{PROTOCOL_PATH}}
- **Template file**: {{SKILL_DIR}}/{{TEMPLATE_PATH}}
- **Artifact output**: {{ANALYSIS_DIR}}/working/{{ARTIFACT_NAME}}.md

## Analysis Context
- **Analysis ID**: {{ANALYSIS_ID}}
- **Problem statement**: {{PROBLEM_STATEMENT_SUMMARY}}
- **Evidence sufficiency flags**: {{FLAGS_OR_NONE}}

## Available Working Files
{{FILE_MANIFEST — list of paths currently in working/}}

## Instructions

1. Read the protocol file and template file
2. Read working files as needed per the protocol's SETUP step
3. Execute ALL protocol steps: SETUP → PRIME → EXECUTE → ARTIFACT → FINDINGS → HANDOFF
4. For PRIME step: note the analytical posture internally (do not attempt user interaction)
5. Write the completed artifact to the output path above
6. Perform Layer 1 compliance check:
   - All protocol steps completed?
   - All template sections filled?
   - Any unfilled {{PLACEHOLDER}} tokens?
   - If Layer 1 fails: fix and re-write the artifact
7. Return ONLY this summary (nothing else):

Technique: {{TECHNIQUE_NAME}}
Artifact: {{ANALYSIS_DIR}}/working/{{ARTIFACT_NAME}}.md
Status: COMPLETED | FAILED | PARTIAL
Layer1: PASS | FAIL (details)
Findings:
- [finding] [Confidence: High|Moderate|Low]
- [finding] [Confidence: High|Moderate|Low]
- [finding] [Confidence: High|Moderate|Low]
Handoff: [key outputs for downstream techniques, 1-2 sentences]
Errors: [any errors or "none"]

IMPORTANT:
- Do NOT return full artifact content — only the summary above
- Every claim in the artifact must cite evidence from the registry or prior artifacts
- All paths are relative to the repository root
```

#### Return Contract

The orchestrator collects summaries from each subagent. Main context accumulates ONLY:
- Technique name + status + Layer 1 result
- 3-5 line findings summary with confidence levels
- Handoff notes (1-2 sentences)
- Artifact file path

This replaces full protocol execution in the main window. The report synthesis subagent (Phase A) reads full artifacts from disk.

**Context window note (comprehensive mode)**: When 10+ techniques are selected, the main context accumulates 10+ compact summaries (~200-400 tokens each, ~5K total). This is well within limits. Subagents each get a fresh context and read artifacts from disk — do NOT restrict which artifacts a subagent can read. Tier 4 techniques (Premortem, Devil's Advocacy, Red Hat) require access to ALL prior `working/` artifacts to function correctly.

#### Tier Gate Protocol

After collecting all subagent summaries for tier N and before dispatching tier N+1, run this lightweight check in main context. The gate reads ONLY the compact findings summaries already accumulated (~200-400 tokens each) — no disk reads.

**Check 1: MISSING HYPOTHESIS**
- Scan findings for phrases like "gap in hypothesis coverage," "missing hypothesis," "additional hypothesis needed," or "not captured in current framework"
- Action: If a downstream technique can address it (What-If for scenarios, Contrasting Narratives for competing explanations, ACH re-run for matrix expansion), add to that technique's SETUP context: `"Prior technique {{NAME}} identified missing hypothesis: {{DESCRIPTION}}. Incorporate this into your analysis."`

**Check 2: EVIDENCE GAP**
- Scan findings for phrases like "insufficient evidence on," "no evidence available for," "evidence gap," or "unable to assess due to missing data"
- Action: If OSINT is enabled, spawn a targeted evidence collection mini-round before the next tier:
  - Generate 1-2 focused search themes addressing the gap
  - Dispatch as foreground Agent subagent(s) using the Step 3a prompt template from `protocols/evidence-collector.md`
  - Run Step 3b extraction on new raw files
  - Update evidence-registry.md with new items
  - Add to downstream techniques' SETUP context: `"New evidence E{{START}}-E{{END}} collected targeting: {{GAP_DESCRIPTION}}"`

**Check 3: CONTRADICTION**
- Scan findings from the same tier for conflicting conclusions (e.g., Technique A finds X likely while Technique B finds X unlikely)
- Action: Add to downstream techniques' SETUP context: `"Tier {{N}} produced conflicting findings: {{TECHNIQUE_A}} found {{X}} while {{TECHNIQUE_B}} found {{Y}}. Your analysis should address this tension."`

**Check 4: CONFIDENCE COLLAPSE**
- Scan findings for a technique where ALL findings are Low confidence
- Action: Log a Layer 1 flag in meta.md. Add warning to downstream techniques' SETUP context: `"{{TECHNIQUE}} returned all findings at Low confidence. Treat its outputs as provisional."`

**Gate rules:**
- Gates are **additive only** — they inject SETUP context or add mini-collection rounds. They never remove or skip already-selected techniques.
- A gate can add at most **1 targeted evidence collection round** (1-2 themes) per tier transition.
- If no checks trigger, the gate passes silently (no logging, no output).
- All gate actions are logged in `meta.md` under a new **Tier Gate Actions** subsection of Self-Correction.
- Gate processing should take <30 seconds — it reads only compact summaries already in main context.

**Meta.md logging format** (under Self-Correction > Tier Gate Actions):

| Tier | Check | Signal | Action Taken |
|------|-------|--------|-------------|
| {{TIER_N}} | {{CHECK_NAME}} | {{SIGNAL_PHRASE}} | {{ACTION_DESCRIPTION}} |

---

## Auto-Remediation Gate

After Phase A returns and before Phase B (human review), the orchestrator checks whether Layer 2 self-critique identified HIGH-severity flags that warrant automatic remediation. This gate reuses the existing iteration handler — no new artifacts or protocols.

### Gate Logic

1. **Parse Phase A return string**: Extract the HIGH flag count from `"Report written. Quality score: X/5.0 (STATUS). HIGH flags: N."` **Fallback**: If the HIGH flag count cannot be parsed from the return string (malformed output, missing field), read `{{ANALYSIS_DIR}}/next-steps.md` directly and count entries with Status `OPEN` and Severity `HIGH` in the Iteration Items table.
2. **Fast path**: If `N = 0`, skip this gate entirely and proceed to Phase B. Zero overhead.
3. **If `N > 0`**:
   a. Read `{{ANALYSIS_DIR}}/next-steps.md` (if not already read during fallback parsing)
   b. Parse the Iteration Items table for entries with Severity `HIGH` and Status `OPEN`
   c. Collect the flagged techniques and evidence focus descriptions
   d. Notify the user: `"Layer 2 identified {{N}} HIGH-severity flag(s). Auto-remediating before presenting report (~5-15 minutes depending on technique count and evidence collection)..."`
   e. Invoke the iteration handler (`protocols/iteration-handler.md`) with:
      - **Trigger type**: `auto-remediation (Layer 2)`
      - **Scope**: scoped to the flagged techniques (deduplicated)
      - **Evidence focus**: combined evidence focus descriptions from the HIGH flags
      - **Full report regeneration**: yes (the user has not seen any report yet)
   f. The iteration handler executes its standard workflow:
      - Archives current artifacts (Step 2)
      - Collects targeted evidence using the combined evidence focus (Step 3)
      - Re-runs flagged techniques with iteration context (Step 4)
      - Produces cross-iteration synthesis (Step 5)
      - Writes iteration-context.md (Step 5a)
      - Regenerates report via Phase A with iteration context (producing iteration 2)
      - Updates meta.md with iteration history (Step 7)
   g. **Update next-steps.md**: Read `{{ANALYSIS_DIR}}/next-steps.md`. For each HIGH flag that was remediated in step 3e-3f:
      - Update the Status column from `OPEN` to `REMEDIATED` in the Iteration Items table
      - Update the detail section: change `[OPEN]` to `[REMEDIATED]` and append a remediation note: `"Auto-remediated in cycle 1. Prior artifact archived at working/{{ARTIFACT_NAME}}.v{{PRIOR_VERSION}}.md"`
      - Update the Summary line counts (increment REMEDIATED, decrement OPEN)
      - Update the Suggested Command to exclude remediated techniques
   h. Phase B now presents the iteration-2 report (post-remediation)

### Caps and Guards

- **Max technique re-runs**: 3 per remediation cycle. If >3 techniques are flagged HIGH, remediate the first 3 using this priority order: (1) 3h quality score failure, (2) 3b evidence imbalance, (3) 3g sycophancy/anchoring bias, (4) 3a unstated critical premises, (5) 3d strong counter-argument. Remaining HIGH flags are demoted to "Suggested for Manual Iteration."
- **Max cycles**: 1 auto-remediation cycle. The iteration-2 Phase A may produce new HIGH flags — these are NOT auto-remediated again. They appear as manual iteration suggestions.
- **Quality score < 3.0 (3h)**: This is a mandatory remediation trigger — it always consumes one of the 3 technique slots and targets the lowest-scoring quality criterion's technique.
- **No recursive remediation**: After the remediation cycle's Phase A completes, proceed directly to Phase B regardless of new HIGH flags.

### Meta.md Logging

Auto-remediation appears in meta.md as a standard iteration entry:

```
| 2 | {{DATE}} | Auto-remediation (Layer 2) | Scoped: {{TECHNIQUE_LIST}} | {{NEW_EVIDENCE_COUNT}} items | Addressed {{N}} HIGH-severity flags: {{FLAG_SUMMARY}} |
```

### Interaction with Iterate Mode

- If the user later runs `/analyze --iterate`, it builds on top of the auto-remediation iteration (iteration 3+)
- Auto-remediation and user-initiated iteration share the same versioning scheme (`.vN.md` archives)
- The iteration handler treats auto-remediation identically to user-invoked iteration — no special-casing needed beyond the trigger type label
