← [Back to Prime](00-prime.md) | [Library Index](00-prime.md#library-index)

# Practical Guides & Research Toolkit

> **Source**: "I want to generate a deep research report and practical breakdown" (Gemini analysis)
> **Focus**: Reusable research prompt, actionable technique guides, SAT workflow
> **Reading Time**: ~10 minutes | **Audience**: Practitioners, AI integrators | **Prerequisites**: None

---

## Key Contribution

Provides a **reusable prompt template** for generating SAT analyses, plus concise actionable guides for the four most critical techniques and a complete SAT workflow checklist.

---

## Reusable Deep Research Prompt Template

```
Role: You are a Senior Intelligence Methodology Consultant and Expert in
Structured Analytic Techniques (SATs) for the US Intelligence Community.

Task: Conduct a deep-dive analysis and practical breakdown of [TARGET DOCUMENT/TOPIC].

Objectives:
1. Deconstruct the Framework: Explain how it fits into the broader Intelligence
   Cycle and how it satisfies ICD 203 (Analytic Standards).
2. Categorize & Analyze Techniques: Break down core categories. For the top 3-5
   most critical techniques, provide a detailed "How-To" guide including specific
   steps, required resources, and "watch-outs."
3. Practical Application: Create a "Practitioner's Checklist" for applying
   techniques to a modern, ambiguous problem.
4. Critical Assessment: Analyze limitations, addressing modern critiques
   (time cost, cognitive drag) and mitigations.

Output Format: Structured professional report with Executive Summary,
Methodology Framework, Technique Deep-Dives (Step-by-Step), and Critical Review.
```

---

## Concise Technique Guides

### ACH (Analysis of Competing Hypotheses)
**Best for**: Complex problems where you suspect bias toward a specific conclusion

1. **Brainstorm Hypotheses** — include "unlikely" ones ("target is bluffing," "third-party setup")
2. **List Evidence** — facts, inferences, AND absence of evidence
3. **Create Matrix** — hypotheses across top, evidence down side
4. **Diagnostics** — "Is this evidence consistent with this hypothesis?"
   - Evidence consistent with ALL hypotheses = **zero diagnostic value**
5. **Conclude** — eliminate hypotheses with too much inconsistent evidence

### Key Assumptions Check (KAC)
**Best for**: Starting new projects; reviewing long-standing judgments

1. **Write down** current analytic line
2. **List assumptions** that must be true for that line to hold
3. **Challenge each**: Is it solid (supported by fact)? Is it key (if wrong, does the analysis collapse)?
4. **Identify fault lines** — shaky key assumptions require warning the decision-maker

### Red Teaming
**Best for**: Understanding adversary mindset; avoiding mirror-imaging

1. **Form team** of non-primary-expert analysts
2. **Adopt adversary persona** — define THEIR goals, culture, fears, constraints (not yours)
3. **Develop attack plan** from their perspective
4. **Present as adversary** — first-person delivery to decision-maker

### Pre-Mortem ("What If?" Variant)
**Best for**: Preventing failure in a plan or prediction

1. **Assume the plan has already failed** ("It is 2028 and the project was a total disaster")
2. **Work backward** — tell the story of how it happened
3. **Identify missed triggers and indicators**
4. **Create monitoring plan** to watch for those triggers now

---

## SAT Workflow Checklist

### Step 1: Issue Definition
Do not just answer the question asked. Ask **"Why is this question being asked?"** and paraphrase to ensure you aren't solving the wrong problem.

### Step 2: Key Assumptions Check (15 min)
Before digging into data, list what you think you know.

### Step 3: Gather & Sort (Quality of Information Check)
- **Source Reliability**: Does the source have a history of truth?
- **Information Viability**: Is the claim physically/logically possible?
- **Deception**: Could this be a plant?

### Step 4: Select Core Technique

| Situation | Technique |
|---|---|
| High uncertainty + high data | ACH |
| Low data + high impact | Scenario Generation |
| Strong consensus exists | Devil's Advocacy (must challenge) |

### Step 5: Produce Output
- State confidence level explicitly
- Do NOT say "We believe..." — say **"We assess with high confidence..."**

---

## ICD 203 Technique Mapping (Concise)

| ICD 203 Standard | Technique Solution |
|---|---|
| Objectivity | ACH forces equal evaluation of all possibilities |
| Independent of political judgments | KAC separates facts from analyst beliefs/pressures |
| Analysis of alternatives | Scenario Generation + Red Teaming ensure multiple outcomes presented |

---

## Modern Critiques & Fixes

| Limitation | Fix |
|---|---|
| **Time Tax** (ACH too slow) | "Rapid ACH" — top 3 hypotheses vs. top 5 evidence items only |
| **Checklist Trap** (mechanical compliance) | Reward analysts who **change** their assessment after running a technique |
| **False Precision** (misleading quantification) | Logic is superior to math in intelligence; acknowledge when assumptions underlying numbers are flawed |

---

## Related Documents

| Document | Relationship |
|---|---|
| [02 — Tradecraft Primer Analysis](02-tradecraft-primer-analysis.md) | Detailed practitioner guides for ACH, KAC, and Red Team |
| [06 — Decision Matrix](06-decision-matrix.md) | When to select each technique |
| [09 — Core Techniques](09-core-techniques.md) | The essential 8 techniques prioritized for universal use |
| [04 — Agile Rigor Update](04-agile-rigor-update.md) | Modern HMT and Lean SAT approaches complementing this workflow |
