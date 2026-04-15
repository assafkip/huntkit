# Premortem + Self-Critique: {{PROBLEM_TITLE}}

> **Analysis ID**: {{ANALYSIS_ID}} | **Date**: {{DATE}} | **Phase**: Challenge & Foresight
> **Evidence base**: {{EVIDENCE_COUNT}} items | [Full registry](../evidence-registry.md)

---

## Assessment Being Tested

{{ASSESSMENT_SUMMARY}}
<!-- The analytic judgment or conclusion that this premortem is stress-testing -->

**Confidence level**: {{CONFIDENCE_LEVEL}}
**Techniques used to produce it**: {{TECHNIQUES_USED}}

---

## Failure Assumption

> **It is {{FUTURE_DATE}} and this analysis was catastrophically wrong.** The assessment failed in a way that damaged credibility and led to poor decisions. What follows is the story of how it went wrong.

---

## Failure Narrative

{{FAILURE_NARRATIVE}}
<!-- Write a detailed, plausible story of how the analysis failed. Be specific: what happened in the world that contradicted the assessment? What did the analyst miss? What surprised everyone? -->

---

## Weakness Inventory

| # | Weakness | Severity | Which Technique Missed It | Recommended Mitigation |
|---|----------|----------|--------------------------|----------------------|
| 1 | {{WEAKNESS}} | {{CRITICAL/HIGH/MED/LOW}} | {{TECHNIQUE_NAME}} | {{MITIGATION}} |
| 2 | {{WEAKNESS}} | {{CRITICAL/HIGH/MED/LOW}} | {{TECHNIQUE_NAME}} | {{MITIGATION}} |
| 3 | {{WEAKNESS}} | {{CRITICAL/HIGH/MED/LOW}} | {{TECHNIQUE_NAME}} | {{MITIGATION}} |
| 4 | {{WEAKNESS}} | {{CRITICAL/HIGH/MED/LOW}} | {{TECHNIQUE_NAME}} | {{MITIGATION}} |
| 5 | {{WEAKNESS}} | {{CRITICAL/HIGH/MED/LOW}} | {{TECHNIQUE_NAME}} | {{MITIGATION}} |

---

## Structured Self-Critique

### What assumption am I most uncertain about?

{{MOST_UNCERTAIN_ASSUMPTION}}

### What evidence did I give too much weight?

{{OVERWEIGHTED_EVIDENCE}}

### What perspective is completely absent from this analysis?

{{ABSENT_PERSPECTIVE}}

### What would a fierce critic say about this assessment?

{{FIERCE_CRITIC_ARGUMENT}}

### If I had to argue the opposite conclusion, what is my strongest point?

{{STRONGEST_OPPOSITE_ARGUMENT}}

---

## Top Weaknesses and Mitigations

| Priority | Weakness | Mitigation | Status |
|----------|----------|-----------|--------|
| 1 | {{WEAKNESS}} | {{MITIGATION}} | {{OPEN/IN_PROGRESS/RESOLVED}} |
| 2 | {{WEAKNESS}} | {{MITIGATION}} | {{OPEN/IN_PROGRESS/RESOLVED}} |
| 3 | {{WEAKNESS}} | {{MITIGATION}} | {{OPEN/IN_PROGRESS/RESOLVED}} |

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
