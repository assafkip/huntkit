# Protocol: Deception Detection

> **Phase**: Diagnostic | **Effort**: 1 – 2 hours | **Bias Mitigated**: Accepting information at face value, discredited evidence persistence
> **Output Artifact**: `working/deception.md`
> **Library**: 05-taxonomy #26, 00-prime §1 (Evidence Quality Framework)

---

## Purpose

Systematically examine the evidence base for markers of denial and disinformation. Assess whether any weight-bearing evidence may be the product of intentional deception, and evaluate the impact on analytical conclusions if compromised evidence is removed or downweighted.

---

## Execution

### 1. SETUP
- Read the evidence registry (`evidence-registry.md`) and all prior technique outputs in `working/`
- Identify the weight-bearing evidence: which evidence items most strongly support the prevailing hypotheses or judgments?
- Identify actors with motive and capability to deceive

### 2. PRIME
State: "I will now systematically assess whether any evidence in this analysis may be the product of intentional deception. Not all inconsistency is deception — genuine confusion, bureaucratic dysfunction, and honest error exist. The goal is calibrated skepticism, not paranoia."

### 3. EXECUTE

1. **Identify deception-capable actors** — for each relevant actor:
   - Motive: Do they benefit from us believing something false?
   - Capability: Do they have the means to plant, fabricate, or manipulate information?
   - History: Have they engaged in deception or disinformation before?
2. **Assess each evidence item for deception markers** — evaluate:
   - **Provenance gaps**: Can the evidence be traced to an independent, reliable origin? Or does it flow through channels controlled by an interested party?
   - **Convenient timing**: Did the evidence appear at a suspiciously opportune moment?
   - **Too-perfect alignment**: Does the evidence confirm expectations too neatly? (Genuine intelligence is usually messy and incomplete)
   - **Internal inconsistencies**: Does the evidence contradict itself or other items from the same source?
   - **Absence of expected evidence**: If the claimed scenario is true, what corroborating evidence should exist but doesn't?
   - **Source multiplicity**: Do multiple "independent" sources actually trace to the same origin?
3. **Rate each evidence item** — assign deception risk:
   - **HIGH**: Multiple markers present, plausible deception motive and capability, weight-bearing evidence
   - **MEDIUM**: Some markers present or motive exists but capability unclear
   - **LOW**: No significant markers, independent provenance confirmed
4. **Analyze high-risk items in depth** — for each HIGH-rated item:
   - What specific deception scenario is plausible?
   - If this evidence is fabricated, what does the analysis look like without it?
   - Are there alternative explanations for the deception markers? (incompetence, bureaucratic error, etc.)
5. **Revised hypothesis assessment** — re-evaluate the prevailing hypotheses:
   - If high-risk evidence is removed, which hypotheses weaken?
   - If high-risk evidence is downweighted, how does confidence change?
   - Are any hypotheses entirely dependent on potentially compromised evidence?
6. **Recommendations** — propose specific actions:
   - Evidence items to seek for independent corroboration
   - Hypotheses that need caveats about evidence reliability
   - Confidence adjustments warranted by deception risk

### 4. ARTIFACT
Write `working/deception.md` using the Deception Detection template.

### 5. FINDINGS
Summarize: number of evidence items assessed, count by risk level, any high-risk items that affect weight-bearing evidence, and recommended confidence adjustments.

### 6. HANDOFF
Pass findings to ACH or Inconsistencies Finder for potential re-evaluation. Flag high-risk items in the evidence registry. Forward confidence adjustments to report generator.

---

## Watch-Outs
- **Paranoia trap**: Not all inconsistency is deception. Bureaucratic dysfunction, honest error, source confusion, and incomplete information are common and should be considered as alternative explanations.
- **Deception confirmation bias**: Once you suspect deception, everything looks like evidence of deception. Maintain calibrated skepticism — require multiple markers before rating HIGH.
- **Discredited evidence persistence**: Even after evidence is identified as potentially compromised, its conclusions tend to persist in analytical judgments. Explicitly re-evaluate all downstream assessments that relied on flagged evidence.
- **Not all actors are deception-capable**: Planting convincing disinformation requires significant capability. Small actors or disorganized groups may lack the means for sophisticated deception even if they have the motive.
- **Integration with ACH**: If ACH has already been run, deception findings may require re-running the consistency matrix with revised evidence weights. Flag this for the orchestrator.
