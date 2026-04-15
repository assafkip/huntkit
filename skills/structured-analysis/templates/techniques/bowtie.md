# Bowtie Analysis: {{PROBLEM_TITLE}}

> **Analysis ID**: {{ANALYSIS_ID}} | **Date**: {{DATE}} | **Phase**: Decision Support
> **Evidence base**: {{EVIDENCE_COUNT}} items | [Full registry](../evidence-registry.md)

---

## Top Event

{{TOP_EVENT}}
<!-- The catastrophic event being avoided. State precisely: what single event, if it occurs, triggers unacceptable consequences? -->

---

## Left Side: Causes & Preventative Barriers

| # | Threat / Cause | Likelihood | Preventative Barrier | Barrier Strength |
|---|---------------|------------|---------------------|-----------------|
| 1 | {{THREAT}} | {{LIKELIHOOD}} | {{BARRIER}} | {{STRENGTH}} |
| 2 | {{THREAT}} | {{LIKELIHOOD}} | {{BARRIER}} | {{STRENGTH}} |
| 3 | {{THREAT}} | {{LIKELIHOOD}} | {{BARRIER}} | {{STRENGTH}} |
| 4 | {{THREAT}} | {{LIKELIHOOD}} | {{BARRIER}} | {{STRENGTH}} |

**Likelihood scale**: Near-Certain / Probable / Even Chance / Unlikely / Remote
**Barrier strength**: Strong (tested, redundant) / Moderate (exists, untested) / Weak (partial, degraded) / Absent

---

## Right Side: Consequences & Reactive Mitigations

| # | Consequence | Severity | Reactive Mitigation | Mitigation Readiness |
|---|------------|----------|--------------------|--------------------|
| 1 | {{CONSEQUENCE}} | {{SEVERITY}} | {{MITIGATION}} | {{READINESS}} |
| 2 | {{CONSEQUENCE}} | {{SEVERITY}} | {{MITIGATION}} | {{READINESS}} |
| 3 | {{CONSEQUENCE}} | {{SEVERITY}} | {{MITIGATION}} | {{READINESS}} |
| 4 | {{CONSEQUENCE}} | {{SEVERITY}} | {{MITIGATION}} | {{READINESS}} |

**Severity scale**: Catastrophic / Critical / Significant / Moderate / Minor
**Mitigation readiness**: Exercised / Planned / Conceptual / None

---

## Escalation Factors

| # | Escalation Factor | Barriers Weakened | Effect on Posture |
|---|------------------|-------------------|-------------------|
| 1 | {{FACTOR}} | {{BARRIERS_AFFECTED}} | {{EFFECT}} |
| 2 | {{FACTOR}} | {{BARRIERS_AFFECTED}} | {{EFFECT}} |
| 3 | {{FACTOR}} | {{BARRIERS_AFFECTED}} | {{EFFECT}} |

<!-- Escalation factors are conditions or trends that degrade the effectiveness of one or more barriers on either side of the bowtie. -->

---

## Defensive Posture Assessment

| Dimension | Rating | Rationale |
|-----------|--------|-----------|
| **Prevention (left side)** | {{RATING}} | {{RATIONALE}} |
| **Mitigation (right side)** | {{RATING}} | {{RATIONALE}} |
| **Escalation exposure** | {{RATING}} | {{RATIONALE}} |
| **Overall posture** | {{RATING}} | {{RATIONALE}} |

**Rating scale**: Robust / Adequate / Vulnerable / Critical

{{POSTURE_NARRATIVE}}
<!-- Summary narrative: Where is the defensive posture strongest? Where is it most fragile? What is the single highest-priority gap? -->

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
