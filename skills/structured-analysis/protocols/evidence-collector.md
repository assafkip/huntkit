# Evidence Collector Protocol

Gather, rate, and organize evidence across three tiers. Every item must be cited. Uncited claims are not permitted.

> **Path note:** `{{ANALYSIS_DIR}}` is resolved by the orchestrator before this protocol runs. It points to the active case's analysis directory. Use it as-is -- do not hardcode `analyses/`.

---

## Evidence Tiers

Collect in order. Each tier adds breadth.

### Tier 1: Conversation Context
- Extract claims, data, constraints, and assumptions from conversation history
- Tag each item: `[User-provided, session context]`

### Tier 2: Local Files
- Read files the user referenced or attached
- Use Glob to discover relevant files in the working directory
- **Q Investigation System**: Always search the active case's collected intelligence first. These are the highest-value local files:
  - `investigations/<active-case>/investigation/targets/` -- target profiles with collection status
  - `investigations/<active-case>/investigation/findings/` -- confirmed/assessed findings with confidence levels
  - `investigations/<active-case>/investigation/evidence/` -- raw evidence and screenshots
  - `investigations/<active-case>/investigation/timelines/` -- chronological event data
  - `investigations/<active-case>/canonical/scope.md` -- hypotheses and collection requirements
- Tag each item: `[filename:line_range]`

### Tier 3: OSINT (skip if `--no-osint` flag is set)

> **Important — MCP tool availability in sub-agents**:
> - **Background sub-agents** (`run_in_background: true`): MCP tools are **not available**. This is a Claude Code architectural constraint.
> - **Foreground sub-agents**: MCP tools **are** inherited from the parent conversation and will work, but they block the main conversation while running.

Collect OSINT via a four-step pipeline that keeps raw web content out of the main context window. All raw article text is written to disk by subagents; only compact summaries flow back.

#### Theme Scaling

The number of search themes adapts to analysis complexity. Three core themes always run. Adaptive themes are generated based on the problem domain, selected techniques, and stakeholder perspectives not covered by core themes.

| Mode | Core Themes | Adaptive Themes | Total |
|------|-------------|-----------------|-------|
| Lean (`--lean`) | 3 | 3 | 6 |
| Default | 3 | 5 | 8 |
| Comprehensive (`--comprehensive`) | 3 | 7 | 10 |

#### Step 3.0 — Theme Planning

Before raw collection, generate the full theme list.

**Core themes (always included):**

| Theme # | `{{THEME_NAME}}` | `{{THEME_SLUG}}` | `{{SEARCH_INSTRUCTIONS}}` | `{{SOURCE_COUNT}}` |
|---------|-------------------|-------------------|---------------------------|---------------------|
| 1 | Background & Context | background | Authoritative sources, data, and expert analysis on | 3-5 |
| 2 | Contrarian & Critical | contrarian | Counterarguments, failures, risks, critics' views, and alternative explanations for | 2-3 |
| 3 | Recent Developments | recent | Developments from the last 6 months — new data, policy changes, market shifts, emerging trends, breaking news about | 2-3 |

**Adaptive theme generation:**

Generate additional themes by analyzing three inputs:

1. **Problem domain** — What sectors, disciplines, or knowledge areas does the problem span? Each distinct domain that the core themes won't adequately cover becomes a candidate theme.
   - Examples: "regulatory/legal landscape", "technical architecture", "economic/market dynamics", "geopolitical context"

2. **Selected techniques' analytical needs** — What evidence do the selected techniques specifically require that generic background searches won't surface?
   - ACH/Inconsistencies → theme targeting evidence that discriminates between hypotheses
   - Cross-Impact → theme targeting data on variable interactions and feedback loops
   - Contrasting Narratives → theme targeting each competing narrative's proponents
   - What-If/Premortem → theme targeting historical precedents and analogous scenarios
   - Bowtie → theme targeting barrier effectiveness data and failure modes
   - Red Hat/Deception → theme targeting adversary doctrine, capabilities, and strategic communications

3. **Stakeholder perspectives** — Who are the key actors, and which perspectives are absent from the core themes? Each unrepresented stakeholder with decision-making power or unique information access becomes a candidate theme.
   - Examples: "industry insider reporting", "allied/international perspective", "adversary strategic calculus", "insurance/financial risk assessment", "technical operator viewpoint"

**Theme construction rules:**
- Each adaptive theme needs: `{{THEME_NAME}}`, `{{THEME_SLUG}}`, `{{SEARCH_INSTRUCTIONS}}`, and `{{SOURCE_COUNT}}` (2-3 sources per adaptive theme)
- Adaptive themes are numbered sequentially after the core themes (4, 5, 6, ...)
- `{{SEARCH_INSTRUCTIONS}}` should be specific enough to produce differentiated results — avoid themes that would return the same sources as core themes
- Prioritize themes that address the most impactful blind spots first (in case collection is interrupted)
- Do NOT generate themes that duplicate core theme coverage — if a candidate theme overlaps significantly with Background, Contrarian, or Recent, drop it

Log the full theme list (core + adaptive) to `meta.md` under Evidence Collection before starting raw collection.

#### Step 3a — Raw Collection (Foreground Agent Subagents)

Spawn foreground Agent subagents in parallel batches. Each subagent inherits MCP tools from the parent and uses WebSearch + WebFetch for OSINT collection.

**Prerequisite**: Parallel dispatch requires search/scrape tools in the user's allow list (see Tool Permissions below). If tools require per-call approval, fall back to sequential dispatch (one theme at a time) to avoid permission prompt flooding.

**Batch dispatch**:
- **Batch 1 (Core themes 1-3)**: Launch all three core theme subagents simultaneously using the Agent tool. Wait for all three to complete before proceeding.
- **Batch 2 (Adaptive themes 4+)**: Launch all adaptive theme subagents simultaneously. Wait for all to complete.

Core themes run first so that if Batch 2 encounters errors (rate limits, tool failures), the foundational evidence is already collected.

**Error handling per batch**: Each subagent writes to its own file independently. If any subagent in a batch fails, the others still succeed. Failed themes are logged and can be retried in the sufficiency gate retry cycle.

For each theme, invoke the Agent tool with `subagent_type: "general-purpose"` and the following prompt template. Substitute ALL `{{VARIABLES}}` with their resolved values -- including `{{ANALYSIS_DIR}}`, `{{THEME_NAME}}`, `{{THEME_NUMBER}}`, `{{THEME_SLUG}}`, `{{SEARCH_INSTRUCTIONS}}`, `{{PROBLEM_SUMMARY}}`, and `{{SOURCE_COUNT}}`:

```
You are an OSINT evidence collector. Your task:

1. Search for: {{SEARCH_INSTRUCTIONS}} related to: {{PROBLEM_SUMMARY}}
2. For each relevant result (aim for {{SOURCE_COUNT}} sources):
   - Use WebSearch for discovery, then WebFetch for full content
   - If ALL web tools are denied, write a file noting the limitation and return
3. Write ALL raw scraped content to: {{ANALYSIS_DIR}}/working/osint-raw/theme-{{THEME_NUMBER}}-{{THEME_SLUG}}.md

Use this file format:
# OSINT Raw: Theme {{THEME_NUMBER}} — {{THEME_NAME}}
> Query: [your search query]
> Timestamp: [ISO timestamp]
> Tool: [WebSearch + WebFetch]

---

## Source 1
- **URL**: [url]
- **Title**: [title]
- **Retrieved**: YYYY-MM-DD

### Raw Content
[Full scraped article content]

---

(Repeat for each source)

4. Return ONLY this summary (nothing else):
   Sources found: [N]
   URLs: [url1], [url2], ...
   Errors: [any errors or "none"]
```

#### Step 3b — Evidence Extraction (Background Subagents)

After all raw files are on disk, spawn background Agent subagents in parallel (`run_in_background: true`) — one per theme. Each reads its raw file (no MCP tools needed) and extracts structured evidence.

For each theme, invoke the Agent tool with `subagent_type: "general-purpose"`, `run_in_background: true`, and this prompt template. Substitute ALL `{{VARIABLES}}` with their resolved values -- including `{{ANALYSIS_DIR}}`, `{{THEME_NAME}}`, `{{THEME_NUMBER}}`, and `{{THEME_SLUG}}`:

```
You are an evidence extraction processor. Your task:

1. Read the raw OSINT file: {{ANALYSIS_DIR}}/working/osint-raw/theme-{{THEME_NUMBER}}-{{THEME_SLUG}}.md
2. For each source in the file, extract structured evidence items:
   - One-sentence summary of key finding
   - Key quotes (direct quotes from the source)
   - Quality ratings using this scale:
     Source Reliability: High (established, verified track record) | Medium (known but unverified) | Low (unknown or biased)
     Information Credibility: High (corroborated, consistent) | Medium (plausible, partial) | Low (uncorroborated, contradictory)
     Diagnostic Value: High (contradicts hypotheses) | Medium (supports some) | Low (consistent with most) | Zero (consistent with ALL)
3. Write structured output to: {{ANALYSIS_DIR}}/working/osint-processed/theme-{{THEME_NUMBER}}-evidence.md

Use this file format:
# Processed Evidence: Theme {{THEME_NUMBER}} — {{THEME_NAME}}

## E-T{{THEME_NUMBER}}-01
- **Source**: [Publication Name]
- **Type**: OSINT
- **Summary**: [One-sentence summary]
- **Key Quotes**: "[Direct quote]"
- **Reliability**: [High | Medium | Low]
- **Credibility**: [High | Medium | Low]
- **Diagnostic Value**: [High | Medium | Low | Zero]
- **Citation**: [Source Title](URL) — Retrieved: YYYY-MM-DD

(Repeat for each evidence item)

## Theme Summary
- Items: [count]
- Reliability distribution: [N] High, [N] Medium, [N] Low
- Diagnostic value distribution: [N] High, [N] Medium, [N] Low, [N] Zero

4. Return ONLY this summary:
   Items extracted: [N]
   Reliability: [N] High, [N] Medium, [N] Low
```

#### Step 3c — Registry Integration (Main Context)

After all background subagents complete:

1. Read all processed evidence files from `working/osint-processed/`
2. Merge with Tier 1 (conversation) and Tier 2 (local files) evidence
3. Assign sequential E-IDs (E01, E02, ...) across all tiers
4. Record collection method used (WebSearch + WebFetch)
5. Run the **Evidence Sufficiency Gate** (see below)
6. Write the final `evidence-registry.md`

#### Error Handling

- **All web tools denied**: Step 3a subagent writes an empty raw file with limitation note; proceed with Tier 1 + Tier 2 only
- **Partial scrape failure**: Step 3b processes whatever sources are present in the raw file
- **Sufficiency Gate retry**: Spawn additional Step 3a subagents with broadened search terms; prior raw files remain on disk

### Tool Permissions

For OSINT to work without permission prompts, the user must whitelist the relevant tools. These permissions are inherited by foreground Agent subagents (Step 3a). Add the following to `.claude/settings.local.json`:

```json
{
  "permissions": {
    "allow": [
      "WebSearch",
      "WebFetch"
    ]
  }
}
```

Without these permissions, every web request will prompt the user for approval.

---

## Evidence Sufficiency Gate

After collecting evidence across all tiers, evaluate before proceeding to technique execution. This gate prevents analysis from running against an inadequate evidence base.

### Hard Checks (HALT if failed)

| Check | Threshold | Action on Failure |
|-------|-----------|-------------------|
| **Minimum count** | ≥8 items total (≥15 if adaptive mode with 4+ techniques; ≥20 if comprehensive) | Loop back: retry OSINT with broader search terms, try alternative tools, or surface to analyst with specific gap description |
| **Quality floor** | <50% of items rated Low reliability | Halt and surface to analyst: "Evidence base is unreliable — {{N}} of {{TOTAL}} items are Low reliability. Recommend gathering higher-quality sources before proceeding." |

### Soft Checks (WARN and proceed with flag)

| Check | Threshold | Flag Text |
|-------|-----------|-----------|
| **Source diversity** | ≥2 distinct source types (e.g., government + journalism + think tank) | `⚠️ LOW SOURCE DIVERSITY: {{N}} source type(s) only. Risk of systematic bias.` |
| **Tier coverage** | At least Tier 1 + one of Tier 2 or 3 populated | `⚠️ SINGLE-TIER EVIDENCE: Only {{TIER}} evidence collected. Consider gathering from additional tiers.` |
| **Diagnostic coverage** | ≥1 item rated High diagnostic value | `⚠️ LOW DIAGNOSTIC POWER: No High-diagnostic evidence found. Evidence may not discriminate between hypotheses.` |
| **Temporal recency** | ≥1 item from the last 6 months (if topic is current/evolving) | `⚠️ STALE EVIDENCE: No recent sources. Analysis may miss current developments.` |

### Gate Logic

```
IF any hard check fails:
    → Attempt one retry cycle (broaden search terms, try fallback tools)
    → If still fails after retry: surface to analyst with specific gap description
    → Analyst can override with explicit approval ("proceed with limited evidence")

IF only soft checks fail:
    → Log all flags in meta.md under Self-Correction > Layer 1 Flags
    → Proceed to technique execution
    → Flags are surfaced again in Layer 2 self-critique and Human Review Gate
```

### Sufficiency Report

After the gate, report to the orchestrator:

```
## Evidence Sufficiency Assessment
- **Total items**: {{COUNT}} (Hard check: {{PASS/FAIL}})
- **Quality floor**: {{HIGH_COUNT}} High / {{MED_COUNT}} Medium / {{LOW_COUNT}} Low (Hard check: {{PASS/FAIL}})
- **Source diversity**: {{TYPE_COUNT}} source types (Soft check: {{PASS/WARN}})
- **Tier coverage**: Tier 1: {{T1}} / Tier 2: {{T2}} / Tier 3: {{T3}} (Soft check: {{PASS/WARN}})
- **Theme coverage**: {{THEMES_WITH_RESULTS}}/{{TOTAL_THEMES}} themes produced evidence (Core: {{CORE_COUNT}}/3, Adaptive: {{ADAPTIVE_COUNT}}/{{ADAPTIVE_TOTAL}})
- **Diagnostic power**: {{HIGH_DIAG_COUNT}} High-diagnostic items (Soft check: {{PASS/WARN}})
- **Temporal recency**: Most recent item from {{DATE}} (Soft check: {{PASS/WARN}})
- **Gate result**: {{PROCEED / RETRY / HALT}}
- **Active flags**: {{LIST_OF_FLAGS}}
```

---

## Evidence Quality Rating

Rate every evidence item on three dimensions (per 2009 Primer Quality of Information Check):

**Source Reliability:**
- **High**: Established source with verified track record
- **Medium**: Known source but independently unverified
- **Low**: Unknown source or potential bias identified

**Information Credibility:**
- **High**: Corroborated by independent sources, internally consistent
- **Medium**: Plausible and partially confirmed
- **Low**: Uncorroborated, contradictory, or single-source

**Diagnostic Value:**
- **High**: Contradicts one or more specific hypotheses
- **Medium**: Supports some hypotheses, neutral for others
- **Low**: Consistent with most hypotheses
- **Zero**: Consistent with ALL hypotheses — explicitly flag per Law of Diagnostic Dominance

---

## Citation Format

Every evidence item MUST include:

| Field | Format |
|-------|--------|
| OSINT | `[Source Title](URL)` — Retrieved: YYYY-MM-DD |
| File | `[filename:line_range]` |
| User | `[User-provided, session context]` |
| Analysis | `[Derived via {{TECHNIQUE_NAME}}]` |

**Rules:**
- OSINT is NEVER presented as fact — always "according to [source]"
- Every claim in every artifact must trace to at least one evidence item
- If `--no-osint` is set, note in registry: "OSINT collection disabled by analyst"

---

## Output

Write the completed evidence registry to `{{ANALYSIS_DIR}}/evidence-registry.md` using the evidence registry template.

Report to the orchestrator:
- Total evidence items collected per tier
- Evidence gaps identified (domains with no coverage)
- Diagnostic value distribution (how many High vs Zero items)
