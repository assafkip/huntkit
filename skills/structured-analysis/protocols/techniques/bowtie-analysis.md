# Protocol: Bowtie Analysis

> **Phase**: Decision Support | **Effort**: 30-60 minutes | **Bias Mitigated**: Linear thinking, failure to see second-order effects
> **Output Artifact**: `working/bowtie.md`
> **Library**: 00-prime §4 (Extended: Frontier), 00-prime §5 (Selection Metrics: Complexity), 04-agile-rigor-update

---

## Purpose

Visualize both sides of a high-impact risk: what causes it and what follows. Map preventative barriers and reactive mitigations to expose gaps in defensive posture. Especially effective for complex, multi-variable risk environments where linear threat-consequence thinking misses critical interactions.

---

## Execution

### 1. SETUP
- Read problem context, prior technique outputs, and identified risks
- Review evidence registry for threat data, vulnerability assessments, and consequence indicators
- Identify the central risk event the analysis should focus on

### 2. PRIME
State: "I'll visualize both sides of this risk — what causes it and what follows — to map the full defensive posture."

### 3. EXECUTE

1. **Define the Top Event** — State the single catastrophic event being avoided. Be precise: vague top events produce vague analysis.
2. **Left Side — Causes and Prevention**:
   - List all credible threats and causes that could trigger the top event
   - For each cause, assess likelihood (Near-Certain / Probable / Even Chance / Unlikely / Remote)
   - For each cause, identify the preventative barrier that stands between it and the top event
   - Rate each barrier's strength (Strong / Moderate / Weak / Absent)
3. **Right Side — Consequences and Mitigation**:
   - List all consequences that follow if the top event occurs
   - For each consequence, assess severity (Catastrophic / Critical / Significant / Moderate / Minor)
   - For each consequence, identify the reactive mitigation in place
   - Rate each mitigation's readiness (Exercised / Planned / Conceptual / None)
4. **Identify Escalation Factors** — What conditions or trends weaken barriers on either side? Map which specific barriers each factor degrades.
5. **Assess Overall Defensive Posture** — Rate prevention, mitigation, and escalation exposure. Identify the single highest-priority gap.

### 4. ARTIFACT
Write `working/bowtie.md` using the Bowtie Analysis template.

### 5. FINDINGS
Summarize: weakest barriers, most critical escalation factors, overall posture rating, and the single most important gap to address.

### 6. HANDOFF
Pass defensive posture assessment and priority gaps to the decision-maker or the next technique in the workflow (e.g., Decision Matrix for prioritizing remediation).

---

## Watch-Outs
- **Vague top events**: "Bad things happen" is not a top event. Force specificity — the top event must be a single, clearly defined occurrence.
- **Barrier inflation**: Listing a barrier does not mean it works. Rate honestly — untested barriers are Moderate at best.
- **Missing escalation factors**: These are the most analytically valuable part of the bowtie. If you find none, you have not looked hard enough.
- **Static snapshot bias**: A bowtie captures posture at a point in time. Flag any barriers or mitigations that are degrading or improving.
- **Use in cyber**: New vulnerabilities reveal which barriers weaken. Map CVEs and emerging threats directly onto the left side to visualize how the defensive posture shifts.
