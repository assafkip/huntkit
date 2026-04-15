← [Back to Prime](00-prime.md) | [Library Index](00-prime.md#library-index)

# Technique Selection Framework & Decision Matrix

> **Source**: "Can we derive a decision matrix on when to use particular techniques" (Gemini analysis)
> **Focus**: When and how to select the right technique for a given analytic challenge
> **Reading Time**: ~10 minutes | **Audience**: Practitioners | **Prerequisites**: [05 — Taxonomy](05-66-techniques-taxonomy.md) or [09 — Core Techniques](09-core-techniques.md)

---

## Key Principle

> No single technique is inherently superior. The "right" technique is the one that best mitigates the specific risk or information gap present in a project.

---

## 1. High-Level Decision Triggers

SATs are warranted when **one or more** of these conditions are met:

| Trigger | Description |
|---|---|
| **High-Consequence Outcomes** | Significant risk, resource allocation, or national security implications |
| **Persistent Uncertainty** | Incomplete, ambiguous, or contradictory data that intuition alone cannot resolve |
| **External Scrutiny** | Report will be briefed to senior leadership/stakeholders who demand transparent reasoning |
| **Complex Interaction** | Multiple actors with competing interests and feedback loops |

---

## 2. Functional Selection Matrix

Select techniques based on **where you are** in the analytic production process:

| Analytical Task / Stage | Targeted Family | Objective |
|---|---|---|
| Launch and Scoping | **Getting Organized** | Define scope, clarify consumer requirements, identify key questions |
| Data Visualization | **Exploration** | Map relationships, look for linkages/groupings, identify gaps |
| Evidence Evaluation | **Diagnostic** | Test assumptions, provide answers, identify likely hypotheses |
| Logic Stress-Testing | **Reframing** | Challenge mindsets, simulate adversary reactions, manage conflicts |
| Estimative Warning | **Foresight** | Anticipate future trends, drivers of change, scenario permutations |
| Actionable Guidance | **Decision Support** | Weigh options, assess operational risk, prioritize resources |

---

## 3. The 12-Question Diagnostic Rubric

Use these questions to narrow technique selection within the 66-technique toolkit:

| # | Question | Triggered Technique |
|---|---|---|
| 1 | Is the task primarily to explain the past, monitor the present, or foresee the future? | *Determines family selection* |
| 2 | Is there a large volume of data to sort and prioritize? | Sorting; Weighted Ranking |
| 3 | Are the foundational premises explicit and well-supported? | Key Assumptions Check |
| 4 | Are there multiple mutually exclusive explanations? | ACH |
| 5 | Is the situation highly uncertain with many moving parts? | Alternative Futures; Multiple Scenario Generation |
| 6 | Are you concerned about being blindsided by a "unthinkable" surprise? | What If? Analysis |
| 7 | Do you need to understand how an adversary will react? | Red Hat Analysis; Role Playing |
| 8 | Is the analysis vulnerable to groupthink or dominant mindset? | Devil's Advocacy; Structured Self-Critique |
| 9 | Is the goal to identify opportunities rather than just risks? | Opportunities Incubator™ |
| 10 | Is there a risk of intentional deception by the target? | Deception Detection |
| 11 | Do you need to track a situation over time for early warning? | Indicators |
| 12 | Is the task to support a decision between competing courses of action? | Decision Matrix; SWOT Analysis |

---

## 4. Proportional Effort Rubric ("Agile Rigor")

Match the **depth of structure** to the project's timeline and stakes:

### Low Intensity (Minutes to Hours)
**Use Core Techniques** — "first line of defense" with minimal cognitive drag

- Key Assumptions Check (KAC)
- Issue Redefinition
- What If? Analysis
- Problem Restatement

### Moderate Intensity (Hours to Days)
**Apply matrix-based tools** when evidence is complex but structured

- Analysis of Competing Hypotheses (ACH)
- Cross-Impact Matrices
- Inconsistencies Finder™

### High Intensity (Days to Weeks)
**Execute collaborative, imaginative exercises** for high-stakes strategic assessments

- Red Teaming
- Alternative Futures Analysis
- Delphi Method
- Full Scenario Generation

---

## Quick-Reference Decision Flow

```
START: New analytic task received
  │
  ├─ Is this high-consequence, uncertain, or subject to scrutiny?
  │   NO → Use expert judgment (but consider Problem Restatement)
  │   YES ↓
  │
  ├─ Where am I in the analytic process?
  │   → Match to appropriate FAMILY (see Functional Selection Matrix)
  │
  ├─ What is the specific cognitive challenge?
  │   → Run through 12-QUESTION RUBRIC to select technique(s)
  │
  └─ How much time do I have?
      → Apply PROPORTIONAL EFFORT RUBRIC
         Minutes → Lean techniques
         Hours/Days → Matrix techniques
         Days/Weeks → Collaborative exercises
```

---

## Related Documents

| Document | Relationship |
|---|---|
| [05 — 66 Techniques Taxonomy](05-66-techniques-taxonomy.md) | The full set of techniques this matrix helps select from |
| [09 — Core Techniques](09-core-techniques.md) | The 8 essential techniques for low-intensity situations |
| [07 — Axioms and Laws](07-axioms-and-laws.md) | The Law of Proportional Effort underpinning the effort rubric |
| [03 — Practical Guides](03-practical-guides.md) | Step-by-step workflow for applying selected techniques |
