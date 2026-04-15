← [Back to Prime](00-prime.md) | [Library Index](00-prime.md#library-index)

# Intelligence Tradecraft Primer — Expert Analysis

> **Source**: "Intelligence Tradecraft Primer Analysis" (Gemini analysis)
> **Focus**: ICD 203 alignment, expert practitioner guides, critical assessment
> **Reading Time**: ~12 minutes | **Audience**: Practitioners | **Prerequisites**: [01 — Tradecraft Primer](01-tradecraft-primer-2009.md)

---

## Key Contribution

This document bridges the 2009 Primer to **professional standards compliance** by mapping every technique to ICD 203 Analytic Standards, and provides the most detailed step-by-step practitioner guides.

---

## ICD 203 Alignment Matrix

| ICD 203 Standard | SAT Implementation | Impact |
|---|---|---|
| **Std 1**: Source quality/credibility | Quality of Information Check; Source Summary Statements | Mitigates confirmation bias; prevents reliance on fragile/deceptive reporting |
| **Std 2**: Express/explain uncertainties | Subjective Probability; Cone of Plausibility | Common vocabulary for likelihood ("highly improbable" to "nearly certain") |
| **Std 3**: Distinguish information/assumptions/judgments | Key Assumptions Check | Makes "linchpin" assumptions auditable |
| **Std 4**: Incorporate analysis of alternatives | ACH; Alternative Futures Analysis | Guards against groupthink and satisficing |
| **Std 5**: Demonstrate customer relevance | Customer Checklist; Issue Development | Ensures analysis addresses the consumer's "So What?" |
| **Std 6**: Clear/logical argumentation | Argument Mapping; Structured Brainstorming | Externalizes internal logic trail |
| **Std 7**: Explain change/consistency of judgments | Indicators of Change; Chronologies | Tracks evolution; acknowledges when evidence demands shift |
| **Std 8**: Accurate judgments | Red Team Analysis; Peer Review | Improves fidelity through competitive/adversarial modeling |
| **Std 9**: Effective visuals | Link Charts; Matrices; Event Trees | Enhances comprehension of complex relationships |

---

## Expert Practitioner Guides

### ACH — Detailed Procedure

1. **Define Problem Statement**: Frame as clear, unbiased, open-ended inquiry. Avoid causal language.
   - Bad: "Why is Group X planning an attack?"
   - Good: "What is the most plausible explanation for the observed movements of Group X?"
2. **List All Plausible Hypotheses**: Include null hypothesis and denial/deception possibility
3. **Gather Evidence and Arguments**: Include "negative evidence" (absence of expected things). Rate source reliability and information credibility.
4. **Construct Matrix**: Hypotheses (H₁, H₂... Hₙ) across top; Evidence (E₁, E₂... Eₙ) down side
5. **Analyze Diagnosticity**: Rate C/I/N or weighted scores (-1, 0, 1). Evidence consistent with all hypotheses has **zero diagnostic value**.
6. **Draw Tentative Conclusions**: Hypothesis with **least inconsistent** evidence is most plausible
7. **Sensitivity Analysis**: Identify evidence that, if wrong or reinterpreted, changes the entire conclusion
8. **Define Future Indicators**: Specific milestones/signposts to confirm or refute

**Tools**: Excel, PARC ACH 2.0, Decision Command, collaborative environments (CACHE)

**Watch-outs**: Avoid mechanical box-checking; ACH is sensitive to initial hypothesis framing — if the true explanation is not listed, the matrix yields a false winner.

### Key Assumptions Check — Detailed Procedure

1. **Review Analytic Line**: State current primary judgment clearly
2. **Articulate Premises**: List all stated AND unstated premises that must be true
3. **Challenge Each Assumption**: Why must this be true? Valid under all conditions? True in the past but less so now?
4. **Bin the List**: Supported (S) / Correct with Caveats (C) / Unsupported (U). Focus on "Linchpin" assumptions.

**Tools**: Facilitated group sessions; whiteboards, flip charts, MURAL, Miro

**Watch-outs**: Status quo bias — analysts find it difficult to challenge long-accepted "truths"

### Red Team Analysis — Detailed Procedure

1. **Define Objective/Scope**: What is being tested — adversary plan, defensive vulnerability, cultural reaction?
2. **Strategic Staffing**: Deep cultural knowledge, language skills, regional experience + "outsiders"
3. **Immerse in Role**: Study adversary's history, doctrine, values to achieve "tactical empathy"
4. **Apply "Four Ways of Seeing"**:
   - How we see ourselves
   - How the adversary sees itself
   - How we see the adversary
   - How the adversary sees us
5. **Produce Adversary Outputs**: Internal memos, operational maps, correspondence in adversary's voice
6. **Debrief**: How do adversary insights change "blue" team strategy?

**Watch-outs**: Mirror Imaging (assuming opponent shares your logic); overconfidence in simulation results

---

## Strategic Practitioner Checklist

### Phase 1: Direction and Framing
- [ ] Customer Requirements (Customer Checklist)
- [ ] Problem Restatement — identify root, not symptom
- [ ] Initial KAC — list and bin 5 most critical assumptions

### Phase 2: Information and Data Vetting
- [ ] Source Reliability — rate each source for accuracy and bias
- [ ] Identify Gaps — explicitly list unknowns and their impact

### Phase 3: Analytical Execution
- [ ] Structured Brainstorming (divergent/convergent; ≥15 explanations)
- [ ] ACH Matrix (if multiple explanations exist)
- [ ] Alternative Scenarios (2 key drivers → 2x2 matrix → 4 futures)

### Phase 4: Stress Testing and Production
- [ ] Structured Self-Critique (Devil's Advocate finds 3 biggest weaknesses)
- [ ] What-If Analysis (worst case → work backward)
- [ ] Visual Synthesis (Link Charts / Concept Maps for briefing)

---

## Critical Assessment

### Bipolar Bias
- SATs designed to mitigate "unipolar" biases (e.g., overconfidence)
- Suppressing one extreme can trigger the opposite (under-confidence → "watered-down" reports)
- No built-in metrics to detect when the analyst has "overshot"

### Random Noise from Decomposition
- Decomposition into many small judgments introduces random variation
- In multi-stage processes, noise compounds — can make final judgment **less consistent** than holistic expert opinion

### Cognitive Drag and Opportunity Cost
- Time cost is the primary adoption barrier
- In fast-paced environments (watch floors, incident response), ACH/Red Teaming are often too slow
- If structure doesn't produce demonstrably better results than expert intuition, the time cost is pure loss

### Mitigation Strategies
- **Lean SATs**: Problem Restatement, Pros-Cons-and-Fixes for short deadlines
- **Automated Synthesis**: AI handles data extraction, normalization, anomaly detection
- **Collaborative Adoption**: SATs as horizontal skills, not specialist domain
- **Situational Awareness**: Recognize high-bias situations (sleep deprivation, time pressure) where SATs are most necessary

---

## Related Documents

| Document | Relationship |
|---|---|
| [01 — Tradecraft Primer 2009](01-tradecraft-primer-2009.md) | The source document this analysis is based on |
| [03 — Practical Guides](03-practical-guides.md) | Complementary practitioner guides and workflow checklists |
| [06 — Decision Matrix](06-decision-matrix.md) | Framework for selecting which technique to apply |
| [08 — Updates and Optimizations](08-updates-and-optimizations.md) | How these techniques evolved post-2009 |
