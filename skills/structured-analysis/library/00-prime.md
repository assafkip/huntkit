# Structured Analytic Techniques — Prime Reference Library

> **Purpose**: Unified synthesis of all source materials into a single authoritative reference
> **Scope**: Theory, taxonomy, selection logic, axioms, critiques, and modern practice of SATs
> **For**: Building an AI-augmented structured analysis skill

---

## Source Materials

This library synthesizes content spanning three eras of Structured Analytic Techniques doctrine:

| Era | Source | What It Contains |
|---|---|---|
| **2009 Foundation** | CIA "Tradecraft Primer" (PDF) | Original doctrine: 3 categories, ~12 techniques, cognitive bias framework, historical failure cases |
| **2020 Expansion** | Pherson & Heuer 3rd Edition (via Gemini analyses) | Expanded to 6 families, 66 techniques (9 new), Selection Matrix, frontier techniques |
| **2023–2026 Modern** | Empirical studies & HMT frameworks (via Gemini analyses) | ACH efficacy challenges, Agile Rigor paradigm, Human-Machine Teaming, Lean SATs |

> **Important**: The 2009 Primer is the primary source document in this repository. The 2020 and later content is synthesized from secondary analyses. Empirical research citations (e.g., Dhami et al., Denzler) are reported as described in those analyses and should be verified against original publications for formal use.

---

## Table of Contents

### FOUNDATION
1. [Why Structure Exists](#1-foundation-why-structure-exists)
2. [The Axioms: Immutable Principles](#2-the-axioms-immutable-principles)

### TECHNIQUE REFERENCE
3. [Technique Taxonomy: The Complete Map](#3-technique-taxonomy-the-complete-map)
4. [Core Techniques: The Essential 8](#4-core-techniques-the-essential-8)
5. [Selection Logic: Choosing the Right Technique](#5-selection-logic-choosing-the-right-technique)

### APPLICATION
6. [Technique Protocols: Step-by-Step Guides](#6-technique-protocols-step-by-step-guides)

### MODERN PRACTICE
7. [Evolution, Critiques & Agile Rigor](#7-evolution-critiques--agile-rigor)
8. [Human-Machine Teaming & AI Integration](#8-human-machine-teaming--ai-integration)

### NAVIGATION
9. [Cognitive Bias → Technique Mapping](#9-cognitive-bias--technique-mapping)
10. [Time-Budget Quick Reference](#10-time-budget-quick-reference)
11. [Recommended Reading Paths](#11-recommended-reading-paths)
12. [Library Index](#12-library-index)

---

## 1. Foundation: Why Structure Exists

### The Core Problem
Human cognition is systematically flawed. Mental models form quickly, resist change, filter out contradictory evidence, and stop searching once a "good enough" answer is found. These are not character flaws — they are evolutionary features that become liabilities in high-stakes analysis.

### The Solution
**Externalized, structured processes** that force the mind past its default shortcuts. Not a guarantee of accuracy, but a systematic reduction of error through transparency, decomposition, and the disciplined consideration of alternatives.

### Historical Mandate *(2009 Primer)*
The SAT doctrine emerged from catastrophic intelligence failures where unchallenged assumptions led to surprise:

- **Pattern**: In every case (Pearl Harbor → Iraq WMD), the prevailing assumption was plausible and supported by evidence — but alternatives were never seriously considered
- **Root cause**: Not lack of information, but lack of structured challenge to the dominant mental model
- **Institutional response**: ICD 203 Analytic Standards (2007, revised 2015) mandating objectivity, analysis of alternatives, and transparent reasoning

### ICD 203 Compliance *(2009 Primer, formalized in ICD 203)*

SATs are the operational means for satisfying the 9 mandatory Analytic Standards:

| ICD 203 Standard | SAT Implementation | Impact |
|---|---|---|
| Source quality/credibility | Quality of Information Check | Prevents reliance on fragile/deceptive reporting |
| Express/explain uncertainties | Subjective Probability; Cone of Plausibility | Common vocabulary for likelihood |
| Distinguish info/assumptions/judgments | Key Assumptions Check | Makes "linchpin" assumptions auditable |
| Incorporate analysis of alternatives | ACH; Alternative Futures | Guards against groupthink and satisficing |
| Demonstrate customer relevance | Customer Checklist; Issue Development | Addresses consumer's "So What?" |
| Clear/logical argumentation | Argument Mapping; Brainstorming | Externalizes logic trail |
| Explain change/consistency | Indicators of Change; Chronologies | Tracks judgment evolution |
| Accurate judgments | Red Team Analysis; Peer Review | Competitive/adversarial validation |
| Effective visuals | Link Charts; Matrices; Event Trees | Complex relationship comprehension |

### Evidence Quality Framework *(2009 Primer, "Quality of Information Check")*

Every evidence item should be rated on three dimensions:

| Dimension | High | Medium | Low | Zero |
|---|---|---|---|---|
| **Source Reliability** | Established, verified track record | Known but independently unverified | Unknown source, potential bias | — |
| **Information Credibility** | Corroborated by independent sources | Plausible, partially confirmed | Uncorroborated, contradictory | — |
| **Diagnostic Value** | Contradicts specific hypotheses | Supports some, neutral for others | Consistent with most hypotheses | Consistent with ALL hypotheses (per Law of Diagnostic Dominance) |

> Evidence with zero diagnostic value must be explicitly flagged — it feels informative but discriminates nothing.

> *Detailed history, bias taxonomy, and case studies* → [01-tradecraft-primer-2009.md](01-tradecraft-primer-2009.md)
> *Full ICD 203 compliance mapping and expert practitioner guides* → [02-tradecraft-primer-analysis.md](02-tradecraft-primer-analysis.md)

---

## 2. The Axioms: Immutable Principles

These foundational laws underlie all SAT techniques. Any implementation must respect these principles.

> **Note on derivation**: Axioms in Sections 1–3 are distilled from principles explicit in the 2009 Primer and 2020 3rd Edition. Section 4 (Cyber/Forensic) represents domain extensions from Diamond Model integration (post-2009). Section 5 (Scientific) incorporates modern empirical findings.

### Why Structure (Philosophical) *(2009 Primer)*
| Axiom | Principle |
|---|---|
| **Externalization** | Analysis must be moved out of the head to be auditable and critiqued |
| **Metacognition** | Quality depends on awareness of one's own reasoning process |
| **Mindset Persistence** | Awareness of bias is insufficient; only structured correction works |
| **Satisficing** | The mind stops at "good enough"; structure forces continued search |

### How to Structure (Operational) *(2009 Primer, formalized in 2020 3rd Ed.)*
| Law | Principle |
|---|---|
| **Decomposition** | Break complex problems into assessable parts, then re-synthesize |
| **Simultaneous Hypotheses** | Evaluate multiple explanations concurrently to prevent confirmation bias |
| **Diagnostic Dominance** | Evidence consistent with all hypotheses has zero value; only discriminating evidence matters |
| **Strategic Context** | All analysis must anchor to the consumer's decision need ("So What?") |

### Constraints on Reasoning (Scientific) *(2020 3rd Ed. + empirical research)*
| Constraint | Principle |
|---|---|
| **Unitarity** | MECE hypothesis probabilities must sum to 1.0 |
| **Additivity** | No "unpacking effects" — probability math must be consistent |
| **Bipolar Bias** | Correcting one bias can trigger the opposite; over-correction is a real danger |

### Domain Extensions (Cyber/Forensic) *(Post-2009, Diamond Model integration)*
| Axiom | Principle |
|---|---|
| **Inevitable Vulnerability** | Every system has exploitable weaknesses |
| **Adversarial Relationship** | Attacker-victim link always exists |
| **Phase Succession** | Attacks require sequential phase completion |

### Meta-Law
| Law | Principle |
|---|---|
| **Proportional Effort** | Depth of structure must match stakes; lean structure beats no structure |

> *Full axiom derivations and dependency map* → [07-axioms-and-laws.md](07-axioms-and-laws.md)

---

## 3. Technique Taxonomy: The Complete Map

### Evolution

| Era | Structure | Techniques | Organizing Principle |
|---|---|---|---|
| **2009 Primer** | 3 categories | ~12 | Categorized by *intent*: Diagnostic, Contrarian, Imaginative |
| **2020 3rd Edition** | 6 families | 66 (9 new) | Organized by *process phase*: lifecycle of an intelligence product |

The original 3-category framework categorized what the analyst was *trying to do* (diagnose, challenge, imagine). The 2020 expansion reorganized around *where the analyst is in their workflow*, creating a "structured safety net" at every stage. This addressed "tool-kit cherry-picking" where analysts selected techniques in isolation.

### The Six Families *(2020 3rd Edition)*

| # | Family | Phase | Count | Purpose |
|---|---|---|---|---|
| 1 | **Getting Organized** | Inception | 9 | Define problem, client needs, data foundation |
| 2 | **Exploration** | Divergent collection | 9 | Generate ideas, map relationships, surface insights |
| 3 | **Diagnostic** | Evidence evaluation | 9 | Test assumptions, evaluate hypotheses, check information |
| 4 | **Reframing** | Challenge | 15 | Shift perspectives, expose assumptions, manage conflict |
| 5 | **Foresight** | Future modeling | 12 | Identify drivers, model scenarios, establish indicators |
| 6 | **Decision Support** | Actionable output | 12 | Weight options, assess risk, prioritize resources |

### The Original Three Categories *(2009 Primer)*

For reference, the 2009 Primer organized its ~12 techniques as:

- **Diagnostic**: Key Assumptions Check, Quality of Information Check, Indicators/Signposts, ACH
- **Contrarian**: Devil's Advocacy, Team A/Team B, High-Impact/Low-Probability, "What If?" Analysis
- **Imaginative**: Brainstorming, Outside-In Thinking, Red Team Analysis, Alternative Futures Analysis

> *Complete 66-technique enumeration (2020)* → [05-66-techniques-taxonomy.md](05-66-techniques-taxonomy.md)
> *Original 12 techniques with full methods (2009)* → [01-tradecraft-primer-2009.md](01-tradecraft-primer-2009.md)

---

## 4. Core Techniques: The Essential 8

> **Note on provenance**: The "Essential 8" is an expert-derived distillation based on frequency of application and breadth of cognitive bias coverage. This designation emerged from practitioner consensus and 3rd Edition guidance on core vs. specialized techniques. It does not appear as an explicit list in the 2009 Primer.

These address the most common cognitive biases across virtually all analytic projects:

| Phase | Technique | Primary Bias Mitigated | Effort |
|---|---|---|---|
| **Launch** | Customer Checklist | Type III Error (wrong problem) | Minutes |
| **Launch** | Issue Redefinition | Anchoring | Minutes |
| **Explore** | Structured Brainstorming | Premature closure, groupthink | 60–90 min |
| **Diagnose** | Key Assumptions Check | Status quo bias, institutional inertia | 15 min–2 hr |
| **Diagnose** | ACH | Confirmation bias, first-impression anchoring | Hours–days |
| **Diagnose** | Cross-Impact Matrix | Linear thinking, missed interactions | Hours |
| **Challenge** | What If? Analysis | Status quo bias, failure of imagination | Hours–days |
| **Challenge** | Premortem + Self-Critique | Overconfidence, blind spots | 30 min–2 hr |

**Supplementary**: Indicators/Signposts of Change (ongoing monitoring)

**Mastery priority**: These 8 should be learned first. The remaining 58 are specialized tools that build on this foundation.

### Extended Techniques: Lean SATs + Frontier

Beyond the Essential 8, six additional techniques complete the skill's 14-technique launch roster:

**Lean SATs** *(2020 3rd Edition, Agile Rigor paradigm — see Section 7)*

| Phase | Technique | Primary Bias Mitigated | Effort |
|---|---|---|---|
| **Launch** | Problem Restatement | Anchoring (rapid reframing) | 5 min |
| **Diagnose** | Inconsistencies Finder | Confirmation bias | 15–30 min |

- **Problem Restatement**: Rewrite the question 3 different ways, shifting perspective (actor→system, threat→vulnerability, why→how). The fastest anchoring-breaker in the toolkit. Lean alternative to Issue Redefinition.
- **Inconsistencies Finder**: Focus exclusively on the lead hypothesis — search for contradicting evidence. Bypasses ACH's noise amplification problem (Denzler 2024) by avoiding large matrix construction. Streamlined ACH for time-pressured situations.

**Frontier Techniques** *(2020 3rd Edition, expanded families)*

| Phase | Technique | Primary Bias Mitigated | Effort |
|---|---|---|---|
| **Foresight** | Counterfactual Reasoning | Rationality attribution, historical inevitability | Hours |
| **Foresight** | Contrasting Narratives | Narrative bias, emotional reasoning | Hours |
| **Decision Support** | Bowtie Analysis | Linear risk thinking, single-point failure focus | Hours |
| **Decision Support** | Opportunities Incubator | Threat fixation | Hours |

- **Counterfactual Reasoning**: Identify a pivotal past event, posit the smallest possible change, and rigorously trace how subsequent events would differ. Reveals hidden causal dynamics and deconstructs "historical inevitability" narratives. Particularly effective in disinformation analysis.
- **Contrasting Narratives**: Decompose competing narratives into structural elements (protagonist, antagonist, crisis, resolution), then stress-test each element against evidence. Identifies vulnerabilities where emotional resonance is high but factual support is low. Enables pre-bunking strategies. Optimized for "post-truth" information environments.
- **Bowtie Analysis**: Map both sides of a catastrophic risk — causes and preventative barriers on the left, consequences and reactive mitigations on the right. Identifies escalation factors that weaken barriers. In cyber applications, visualizes how new vulnerabilities degrade specific defensive layers.
- **Opportunities Incubator**: Scan for emerging trends across domains (technology, economic, social, political), identify convergences where 2+ trends create windows of opportunity, and define opening/closing indicators for each window. Counteracts intelligence analysis's systemic bias toward threats over opportunities.

> *Detailed core technique profiles and selection guide* → [09-core-techniques.md](09-core-techniques.md)
> *Lean SAT rationale and empirical basis* → [04-agile-rigor-update.md](04-agile-rigor-update.md)
> *Frontier technique origins in expanded families* → [05-66-techniques-taxonomy.md](05-66-techniques-taxonomy.md)

---

## 5. Selection Logic: Choosing the Right Technique

### Decision Flow

```
1. TRIGGER CHECK: Is SAT warranted?
   → High consequence? Persistent uncertainty? External scrutiny? Complex interaction?
   → If none: use expert judgment (consider Problem Restatement anyway)
   → If any: proceed

2. STAGE CHECK: Where am I in the process?
   → Map to appropriate FAMILY (see Section 3)

3. CHALLENGE CHECK: What specific cognitive problem am I facing?
   → Run through 12-QUESTION RUBRIC (below)

4. EFFORT CHECK: How much time do I have?
   → Minutes/Hours: Lean techniques (KAC, Issue Redefinition, What If?)
   → Hours/Days: Matrix techniques (ACH, Cross-Impact)
   → Days/Weeks: Collaborative exercises (Red Team, Alt Futures, Delphi)
```

### The 12-Question Rubric (Quick Reference)

| Situation | Technique |
|---|---|
| Large data volume to sort | Sorting, Weighted Ranking |
| Premises not explicit/supported | Key Assumptions Check |
| Multiple mutually exclusive explanations | ACH |
| High uncertainty, many moving parts | Alternative Futures, Scenarios |
| Fear of "unthinkable" surprise | What If? Analysis |
| Need to model adversary reaction | Red Hat Analysis, Role Playing |
| Groupthink or dominant mindset risk | Devil's Advocacy, Self-Critique |
| Goal is to find opportunities, not just threats | Opportunities Incubator |
| Risk of intentional deception | Deception Detection |
| Competing narratives or information warfare | Contrasting Narratives |
| Need to track over time | Indicators |
| Decision between competing options | Decision Matrix, SWOT |

### Selection Metrics *(2020 3rd Edition)*

| Metric | Low → Tool | High → Tool |
|---|---|---|
| **Uncertainty type** | Epistemic → Diagnostic | Aleatory → Foresight |
| **Data volatility** | Stable → Full matrices | High → Lean techniques |
| **Bias susceptibility** | Low → Standard workflow | High confirmation → Reframing |
| **Complexity** | Simple → Core techniques | Non-linear → Cross-Impact, Bowtie |

> *Full decision matrix with rubric details* → [06-decision-matrix.md](06-decision-matrix.md)

---

## 6. Technique Protocols: Step-by-Step Guides

These are condensed protocols for the three most critical techniques. For complete expert-level guides covering all core techniques, see the linked files.

### ACH Protocol *(2009 Primer, refined in 2020 3rd Ed.)*
1. Frame problem as unbiased, open-ended inquiry
2. Brainstorm all plausible hypotheses (include null + deception)
3. List all evidence including negative evidence (expected but absent)
4. Build matrix: hypotheses x evidence
5. Rate each cell: Consistent / Inconsistent / Neutral
6. **Focus on disproving** — tally inconsistencies per hypothesis
7. Winner = least inconsistent (not most confirmed)
8. Sensitivity analysis on critical evidence items
9. Define future indicators/signposts
10. Report ALL conclusions including weaker hypotheses

### KAC Protocol *(2009 Primer)*
1. State current analytic line clearly (write it down)
2. List ALL premises (stated + unstated) that must be true
3. Challenge each: Why must this be true? Under all conditions? Still true now?
4. Bin: Supported / Correct-with-Caveats / Unsupported
5. Focus on "Linchpin" assumptions (if wrong → analysis collapses)
6. Identify what information/events would demand rethinking

### Red Team Protocol *(2009 Primer)*
1. Define objective and scope (what's being tested)
2. Staff with cultural depth + language skills + outsiders
3. Immerse in adversary role (history, doctrine, values → "tactical empathy")
4. Apply "Four Ways of Seeing" matrix
5. Produce adversary-authentic outputs (memos, plans, correspondence)
6. Present in first person; debrief for strategic implications

### Practitioner Workflow
**Phase 1** — Direction: Customer Checklist → Problem Restatement → Initial KAC
**Phase 2** — Vetting: Source reliability → Gap identification
**Phase 3** — Execution: Brainstorming → Core technique (ACH/Scenarios/etc.)
**Phase 4** — Stress Test: Devil's Advocate → What-If → Visual synthesis

> *Expert-level practitioner guides with tools and watch-outs* → [02-tradecraft-primer-analysis.md](02-tradecraft-primer-analysis.md)
> *Concise actionable guides and reusable analysis prompt* → [03-practical-guides.md](03-practical-guides.md)

---

## 7. Evolution, Critiques & Agile Rigor

### Evolution Timeline

| Period | Development |
|---|---|
| **2009** | CIA Tradecraft Primer (3 categories, ~12 techniques) |
| **2015** | ICD 203 revised (strengthened analytic standards) |
| **2019** | First empirical challenges to ACH efficacy (Dhami et al.) |
| **2020** | 3rd Edition published (6 families, 66 techniques, Selection Matrix) |
| **2023** | "Crisis of Face Validity" — large-scale empirical testing begins |
| **2024** | Bipolarity Problem and Noise Neglect formally identified |
| **2024–25** | Cognitive offloading risks of AI reliance documented |
| **2025** | CISA/ENISA adopt SAT-based cyber frameworks (SSVC, CTL) |
| **2026** | "Agile Rigor" paradigm: Lean SATs + HMT as emerging standard |

### Empirical Critiques of ACH *(2019–2025, as reported in methodological reviews)*

| Finding | Researchers | Implication |
|---|---|---|
| ACH increases judgment inconsistency in probabilistic tasks | Dhami and colleagues (2019–2024) | Decomposition amplifies random noise |
| "Calibration gap" — felt rigorous but no more accurate | Dhami and colleagues (2024) | False security for decision-makers |
| 50-cell matrix noise can outweigh evidence signal | Denzler (2024) | More structure ≠ better structure |
| "Pseudo-uncertainty" from hyper-awareness of uncertainty | Multiple researchers (2023–25) | Under-confidence → watered-down intelligence |

> **Note**: These findings are reported as described in secondary methodological reviews. Specific paper titles and journal citations should be verified against original publications for formal use.

### The Bipolarity Problem
Suppressing overconfidence → triggers under-confidence → analyst unable to make definitive calls even when evidence supports it. No built-in metrics detect over-correction. This is not a flaw in any single technique but a systemic risk of structured debiasing.

### Cognitive Costs of AI Reliance
Over-reliance on generative AI → "cognitive offloading" → reduced baseline critical thinking and self-confidence (2024–2025 studies). This directly informs the guard-rails in the HMT framework (Section 8).

### The Agile Rigor Response

**Agile Rigor** = proportional application of structure, optimized for the specific cognitive challenge, delivered at the speed the environment demands.

**Three Pillars:**

**1. Lean SATs** — Maximum rigor-to-time ratio
- Problem Restatement (5 min): Rewrite question 3 ways → breaks anchoring
- Inconsistencies Finder (new in 2020 3rd Ed., streamlined ACH): Focus only on lead hypothesis → search for contradicting evidence → bypasses noise amplification
- KAC Quick (15 min): List and bin top 5 assumptions

**2. Empirical Selection** — Choose technique based on measured problem characteristics (see Selection Metrics in Section 5)

**3. Proportional Effort** — Match depth to stakes (see Time-Budget in Section 10)

### Cyber-Specific Adaptations *(2025)*
- **SSVC** (Stakeholder-Specific Vulnerability Categorization): Decision-tree replacing traditional scoring with structured exploitation-likelihood prioritization
- **CTL** (Cyber Threat Landscape Methodology): Pairs Alternative Futures with Indicators and Warning for real-time zero-day and IaaS threat monitoring (CISA/ENISA)

> *Full Agile Rigor framework and frontier techniques* → [04-agile-rigor-update.md](04-agile-rigor-update.md)
> *Chronological evolution details and research citations* → [08-updates-and-optimizations.md](08-updates-and-optimizations.md)

---

## 8. Human-Machine Teaming & AI Integration

### The HMT Framework *(2020–2026)*

| Layer | Human Role | Machine Role |
|---|---|---|
| **Administrative** (data intake) | Minimal — review/validate | Extract, normalize, anomaly-detect |
| **Analytical** (pattern finding) | Guide focus, judge relevance | Scale analysis, calculate coherence, permute scenarios |
| **Agentic** (strategic judgment) | Full ownership — synthesize, decide | Support with structured prompts, audit trails |

### Interrogative/Prompt Libraries (IPL)
Standardized prompts that guide LLMs through specific SAT protocols:

1. **Structural Framing**: Force AI to follow specific technique (not general questions)
   - Bad: "What is the risk of conflict in region X?"
   - Good: "Conduct an Inconsistencies Finder analysis on these 20 data points against hypothesis Y"
2. **Hallucination Mitigation**: Structured templates constrain AI output
3. **Traceability**: Digital audit trail of human + machine logic

### HMT by Family

| Family | Human | Machine | Output |
|---|---|---|---|
| Exploration | Scope + black-swan identification | Massive dataset scanning for weak signals | Prioritized variable map |
| Diagnostic | Source reliability + intent judgment | Probability coherence calculation | Calibrated assessment |
| Foresight | "So What?" for policymaker | 1000s of scenario permutations | Robust early warning system |

### Reusable SAT Analysis Prompt Template

The following template can be used to generate structured analyses through any advanced LLM:

```
Role: You are a Senior Intelligence Methodology Consultant and Expert in
Structured Analytic Techniques (SATs).

Task: Conduct a deep-dive analysis and practical breakdown of [TARGET TOPIC].

Objectives:
1. Deconstruct the Framework: Explain how it fits into the broader context
   and how it satisfies quality standards (e.g., ICD 203 Analytic Standards).
2. Categorize & Analyze: Break down core components. For the top 3-5 most
   critical elements, provide a detailed "How-To" guide including specific
   steps, required resources, and "watch-outs."
3. Practical Application: Create a "Practitioner's Checklist" for applying
   the analysis to a modern, ambiguous problem.
4. Critical Assessment: Analyze limitations, addressing modern critiques
   (time cost, cognitive drag) and mitigations.

Output Format: Structured report with Executive Summary, Framework,
Technique Deep-Dives (Step-by-Step), and Critical Review.
```

### Critical Guard-Rail
AI handles **computation and scale**. Humans retain **judgment and accountability**. Over-reliance on AI causes "cognitive offloading" — the system must be designed to keep the human analyst's critical thinking engaged.

> *Full HMT framework, IPL design, and frontier technique details* → [04-agile-rigor-update.md](04-agile-rigor-update.md)
> *Reusable prompt template and SAT workflow checklist* → [03-practical-guides.md](03-practical-guides.md)

---

## 9. Cognitive Bias → Technique Mapping

Cross-cutting reference: which biases are mitigated by which techniques.

| Bias | Description | Mitigating Technique(s) |
|---|---|---|
| **Confirmation bias** | Seeking evidence that supports existing beliefs | ACH, Inconsistencies Finder, Devil's Advocacy |
| **Anchoring** | Over-relying on first piece of information | Issue Redefinition, Problem Restatement |
| **Satisficing** | Stopping at "good enough" | Structured Brainstorming, Multiple Hypothesis Generation |
| **Groupthink** | Conforming to group consensus | Devil's Advocacy, Team A/Team B, Structured Debate |
| **Status quo bias** | Assuming current state will continue | What If? Analysis, Reversing Assumptions |
| **Overconfidence** | Excessive certainty in judgments | Premortem Analysis, Structured Self-Critique |
| **Mirror-imaging** | Assuming adversary thinks like you | Red Team Analysis, Red Hat Analysis, Role Playing |
| **Availability bias** | Judging likelihood by ease of recall | Outside-In Thinking, Alternative Futures |
| **Expectations bias** | Perceiving what you expect to perceive | Key Assumptions Check, Indicators of Change |
| **Discredited evidence** | Persisting with disproven beliefs | Quality of Information Check, Deception Detection |
| **Rationality attribution** | Assuming actors behave rationally | Red Team Analysis, Counterfactual Reasoning |
| **Missing information neglect** | Failing to account for absent data | ACH (negative evidence step), Quality of Information Check |

---

## 10. Time-Budget Quick Reference

| Available Time | Recommended Approach | Techniques |
|---|---|---|
| **5–15 minutes** | Lean rigor check | Problem Restatement, KAC Quick (top 5 assumptions) |
| **30–60 minutes** | Focused diagnostic | Full KAC, Structured Brainstorming, Inconsistencies Finder |
| **2–4 hours** | Matrix-based analysis | ACH, Cross-Impact Matrix, What If? Analysis |
| **1–2 days** | Collaborative deep-dive | Red Teaming, Alternative Futures Analysis, Scenario Generation |
| **3+ days** | Full strategic exercise | Delphi Method, Multi-team exercises, Full futures workshop |

---

## 11. Recommended Reading Paths

### New to SATs?
`00-prime` → [07-axioms](07-axioms-and-laws.md) → [09-core-techniques](09-core-techniques.md) → [01-tradecraft-primer](01-tradecraft-primer-2009.md)

### Need to apply SATs immediately?
`00-prime` → [06-decision-matrix](06-decision-matrix.md) → [03-practical-guides](03-practical-guides.md)

### Building AI integration?
`00-prime` → [04-agile-rigor](04-agile-rigor-update.md) → [02-expert-analysis](02-tradecraft-primer-analysis.md)

### Want complete mastery?
Read all files in numerical order (`00` → `09`), then revisit `00-prime` as a synthesis check.

### Need technique lookup?
`00-prime` Section 5 (Selection Logic) → [05-taxonomy](05-66-techniques-taxonomy.md) → [06-decision-matrix](06-decision-matrix.md)

---

## 12. Library Index

### Foundational Knowledge
| File | Content | Use When |
|---|---|---|
| [01-tradecraft-primer-2009.md](01-tradecraft-primer-2009.md) | Original 2009 doctrine — biases, history, 12 techniques with full methods | Need foundational technique details or historical context |
| [07-axioms-and-laws.md](07-axioms-and-laws.md) | Foundational principles and immutable laws | Need theoretical grounding or first-principles reasoning |

### Technique Reference
| File | Content | Use When |
|---|---|---|
| [05-66-techniques-taxonomy.md](05-66-techniques-taxonomy.md) | Complete enumeration of all 66 techniques by family (2020) | Need to look up any specific technique or browse the full toolkit |
| [09-core-techniques.md](09-core-techniques.md) | The essential 8 techniques for universal mastery | Need the minimum viable technique set |

### Selection & Application
| File | Content | Use When |
|---|---|---|
| [06-decision-matrix.md](06-decision-matrix.md) | Selection framework — triggers, rubric, proportional effort | Need to choose which technique to apply |
| [03-practical-guides.md](03-practical-guides.md) | Reusable prompt template, concise guides, SAT workflow checklist | Need quick-reference guides or the analysis prompt template |

### Modern Evolution
| File | Content | Use When |
|---|---|---|
| [04-agile-rigor-update.md](04-agile-rigor-update.md) | 2020–2026 evolution — frontier techniques, empirical critiques, HMT, Lean SATs | Need modern methodology, AI integration, or empirical findings |
| [08-updates-and-optimizations.md](08-updates-and-optimizations.md) | Post-2009 changes — doctrine, tools, empirical findings, cyber | Need chronological evolution or specific research citations |

### Expert Analysis
| File | Content | Use When |
|---|---|---|
| [02-tradecraft-primer-analysis.md](02-tradecraft-primer-analysis.md) | Expert analysis — ICD 203 mapping, detailed practitioner guides, critical assessment | Need compliance mapping or expert-level how-tos |
