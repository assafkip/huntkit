# Key Assumptions Check: {{PROBLEM_TITLE}}

> **Analysis ID**: {{ANALYSIS_ID}} | **Date**: {{DATE}} | **Phase**: Diagnostic
> **Evidence base**: {{EVIDENCE_COUNT}} items | [Full registry](../evidence-registry.md)

---

## Current Analytic Line

{{CURRENT_ANALYTIC_LINE}}

---

## Assumption Inventory

| # | Assumption | Stated / Unstated | Category | Bin (S/C/U) | Linchpin? |
|---|-----------|-------------------|----------|-------------|-----------|
| 1 | {{ASSUMPTION}} | {{STATED_OR_UNSTATED}} | {{CATEGORY}} | {{BIN}} | {{Y_OR_N}} |
| 2 | {{ASSUMPTION}} | {{STATED_OR_UNSTATED}} | {{CATEGORY}} | {{BIN}} | {{Y_OR_N}} |
| 3 | {{ASSUMPTION}} | {{STATED_OR_UNSTATED}} | {{CATEGORY}} | {{BIN}} | {{Y_OR_N}} |

**Bin Key:** S = Supported | C = Correct with Caveats | U = Unsupported

---

## Linchpin Analysis

### Linchpin {{NUM}}: {{ASSUMPTION_TEXT}}

- **Justification**: {{WHY_ASSUMED_TRUE}}
- **Failure conditions**: {{WHAT_WOULD_MAKE_IT_FALSE}}
- **Supporting evidence**: {{EVIDENCE_FOR}} [{{REF}}]
- **Challenging evidence**: {{EVIDENCE_AGAINST}} [{{REF}}]
- **Impact if wrong**: {{CONSEQUENCE}}

<!-- Repeat for each linchpin assumption -->

---

## Fault Lines Summary

| Priority | Assumption | Risk | Recommended Action |
|----------|-----------|------|--------------------|
| {{RANK}} | {{ASSUMPTION}} | {{RISK_DESCRIPTION}} | {{ACTION}} |

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
