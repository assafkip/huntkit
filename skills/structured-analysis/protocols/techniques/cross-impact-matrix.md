# Protocol: Cross-Impact Matrix

> **Phase**: Diagnostic | **Effort**: Hours | **Bias Mitigated**: Linear thinking, failure to see second-order effects
> **Output Artifact**: `working/cross-impact.md`
> **Library**: 00-prime §4 (Essential 8), 09-core-techniques

---

## Purpose

Examine how key variables interact with and impact one another. Surface second-order effects, reinforcing loops, and cascading chains that linear analysis misses.

---

## Execution

### 1. SETUP
- Read problem framing from `working/requirements.md`
- Read brainstorm output from `working/brainstorm.md` (if available)
- Read evidence registry for variables and factors identified in the evidence base

### 2. PRIME
State to user: "I will now map how the key variables in this problem interact with each other, looking for hidden second-order effects."

### 3. EXECUTE

1. **List key variables** — identify the critical factors, actors, forces, or trends relevant to the problem (aim for 4–8 variables)
2. **Build the NxN matrix** — for each pair of variables, assess:
   - **Direction**: Does Variable A reinforce (+) or oppose (-) Variable B?
   - **Magnitude**: High (H), Medium (M), or Low (L) impact?
3. **Identify reinforcing loops** — chains where A strengthens B which strengthens A (escalation risk)
4. **Identify balancing loops** — chains where A strengthens B which weakens A (stabilizing)
5. **Surface second-order effects** — what happens when two first-order impacts combine? Trace indirect pathways.
6. **Document key interaction chains** — the most consequential multi-step causal paths

### 4. ARTIFACT
Write `working/cross-impact.md` using the Cross-Impact Matrix template.

### 5. FINDINGS
Summarize: most impactful variables (highest row/column totals), critical interaction chains, and second-order effects the analyst should monitor.

### 6. HANDOFF
Pass interaction insights to ACH (as additional evidence) or to Foresight phase for scenario development.

---

## Watch-Outs
- **Linear thinking**: The purpose of this technique is to overcome it. Do not assess variables in isolation.
- **Missing indirect effects**: Always trace at least two steps beyond the direct impact. Ask "and then what?"
- **Variable overload**: More than 8 variables makes the matrix unwieldy. Consolidate or prioritize.
- **Static snapshot**: Interactions may change over time. Note any time-dependent dynamics.
