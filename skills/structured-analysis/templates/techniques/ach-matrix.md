# Analysis of Competing Hypotheses: {{PROBLEM_TITLE}}

> **Analysis ID**: {{ANALYSIS_ID}} | **Date**: {{DATE}} | **Phase**: Diagnostic
> **Evidence base**: {{EVIDENCE_COUNT}} items | [Full registry](../evidence-registry.md)

---

## Problem Statement

{{PROBLEM_STATEMENT}}
<!-- Frame as clear, unbiased, open-ended inquiry. Avoid causal language. -->

---

## Hypotheses

| ID | Hypothesis | Source / Basis |
|----|-----------|----------------|
| H1 | {{HYPOTHESIS}} | {{SOURCE}} |
| H2 | {{HYPOTHESIS}} | {{SOURCE}} |
| H3 | {{HYPOTHESIS}} | {{SOURCE}} |
| H4 | {{HYPOTHESIS}} | {{SOURCE}} |
<!-- Include null hypothesis and denial/deception possibility -->

---

## Evidence Inventory

| ID | Evidence | Source | Reliability | Citation |
|----|----------|--------|-------------|----------|
| E1 | {{EVIDENCE}} | {{SOURCE}} | {{HIGH/MED/LOW}} | [{{REF}}] |
| E2 | {{EVIDENCE}} | {{SOURCE}} | {{HIGH/MED/LOW}} | [{{REF}}] |
| E3 | {{EVIDENCE}} | {{SOURCE}} | {{HIGH/MED/LOW}} | [{{REF}}] |
<!-- Include negative evidence (absence of expected indicators) -->

---

## Diagnosticity Matrix

| Evidence | H1 | H2 | H3 | H4 | Diagnostic Value |
|----------|----|----|----|----|------------------|
| E1 | {{C/I/N}} | {{C/I/N}} | {{C/I/N}} | {{C/I/N}} | {{HIGH/LOW/ZERO}} |
| E2 | {{C/I/N}} | {{C/I/N}} | {{C/I/N}} | {{C/I/N}} | {{HIGH/LOW/ZERO}} |
| E3 | {{C/I/N}} | {{C/I/N}} | {{C/I/N}} | {{C/I/N}} | {{HIGH/LOW/ZERO}} |

### Legend

| Rating | Meaning |
|--------|---------|
| **C** | Consistent — evidence supports this hypothesis |
| **I** | Inconsistent — evidence contradicts this hypothesis |
| **N** | Neutral — evidence neither supports nor contradicts |

> **Law of Diagnostic Dominance**: Evidence consistent with ALL hypotheses has **zero diagnostic value**. Only evidence inconsistent with specific hypotheses allows discrimination between them.

---

## Inconsistency Tally

| Hypothesis | Inconsistent Items | Score | Rank |
|------------|-------------------|-------|------|
| H1 | {{EVIDENCE_IDS}} | {{COUNT}} | {{RANK}} |
| H2 | {{EVIDENCE_IDS}} | {{COUNT}} | {{RANK}} |
| H3 | {{EVIDENCE_IDS}} | {{COUNT}} | {{RANK}} |
| H4 | {{EVIDENCE_IDS}} | {{COUNT}} | {{RANK}} |

<!-- Winner = hypothesis with LEAST inconsistencies (lowest score) -->

---

## Sensitivity Analysis

| Critical Evidence | If Removed / Reinterpreted | Impact on Conclusion |
|-------------------|----------------------------|----------------------|
| {{EVIDENCE_ID}} | {{SCENARIO}} | {{IMPACT}} |

---

## Preliminary Findings

- **Most plausible hypothesis**: {{HYPOTHESIS_ID}} — {{HYPOTHESIS_TEXT}}
- **Confidence**: {{HIGH/MODERATE/LOW}}
- **Rationale**: {{RATIONALE}}

---

## Sources & Citations

| Ref | Source | Retrieved | Reliability | Method |
|-----|--------|-----------|-------------|--------|
| [{{REF_NUM}}] | {{FULL_CITATION_WITH_URL}} | {{DATE}} | {{HIGH/MED/LOW}} | {{OSINT/FILE/USER/ANALYSIS}} |

**Citation Methods:**
- **OSINT**: Retrieved via WebSearch + WebFetch
- **FILE**: Read from local file system
- **USER**: Provided by analyst in conversation
- **ANALYSIS**: Analytical judgment produced via named technique protocol

> Every claim must be cited. Uncited claims are not permitted.
