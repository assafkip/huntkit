# Protocol: Red Hat Analysis

> **Phase**: Challenge | **Effort**: 1 – 2 hours | **Bias Mitigated**: Mirror-imaging, rationality attribution
> **Output Artifact**: `working/red-hat.md`
> **Library**: 01-tradecraft-primer §3 (Red Team Protocol), 05-taxonomy #31

---

## Purpose

Adopt the adversary's perspective using the "Four Ways of Seeing" framework. Rather than projecting our logic onto the adversary ("what would a rational actor do?"), immerse in their worldview, constraints, culture, and incentives to predict their actual behavior.

---

## Execution

### 1. SETUP
- Identify the adversary or opposing actor relevant to the analysis
- Read ALL prior technique outputs in the `working/` directory
- Gather available information on adversary background: decision-making style, cultural context, institutional constraints, stated objectives, historical behavior patterns
- If OSINT evidence is available, prioritize adversary-sourced materials (speeches, doctrine, state media, internal documents)

### 2. PRIME
State: "I will now adopt the adversary's perspective completely. I am not predicting what a rational actor would do — I am modeling what THIS specific actor would do given THEIR worldview, constraints, and incentives."

### 3. EXECUTE

1. **Adversary background profile** — document:
   - Who is the adversary? (specific actor, not abstract category)
   - Decision-making structure and key decision-makers
   - Cultural and institutional context
   - Known objectives (stated and assessed)
   - Historical behavior patterns and precedents
   - Current constraints (political, economic, military, domestic)
2. **Four Ways of Seeing** — complete all four lenses:
   - **How we see ourselves**: Our self-image, values, and assumptions about our own behavior
   - **How the adversary sees itself**: Their self-image, legitimacy narrative, and self-justification
   - **How we see the adversary**: Our assessment of their capabilities, intentions, and rationality
   - **How the adversary sees us**: Their perception of our intentions, vulnerabilities, and likely responses
3. **First-person memo** — write a memo FROM the adversary's perspective (mandatory first-person format):
   - Address it to their leadership or decision-making body
   - Use their framing, terminology, and logic
   - Assess the current situation from their viewpoint
   - Recommend courses of action they would consider
   - Identify what they perceive as our vulnerabilities
4. **Predicted adversary reactions** — based on the immersion, predict:
   - Most likely adversary action and rationale
   - Alternative actions under different conditions
   - Red lines or triggers that would change their calculus
   - Timeline expectations
5. **Debrief** — step out of the adversary perspective and extract insights:
   - What surprised you about their perspective?
   - Where does our analysis assume rationality that doesn't apply?
   - What actions of ours might provoke unintended escalation?
   - What opportunities does their perspective reveal?

### 4. ARTIFACT
Write `working/red-hat.md` using the Red Hat Analysis template.

### 5. FINDINGS
Summarize: key insights from the adversary perspective, predicted most likely action, and identified mirror-imaging risks in the current analysis.

### 6. HANDOFF
Pass findings to report generator. Flag any mirror-imaging biases discovered in prior technique outputs for potential re-analysis.

---

## Watch-Outs
- **Mirror-imaging**: The most critical risk. Do NOT simply invert our logic ("we would do X, so they'll do the opposite"). Immerse in their actual worldview, culture, and constraints.
- **First-person format is mandatory**: The memo must be written as if authored by the adversary. This cognitive exercise forces genuine perspective-taking. Third-person analysis ("they would likely...") is explicitly insufficient.
- **Rationality attribution**: Adversaries may not be "rational" by our standards. They may have different information, different values, different risk tolerances, or face domestic pressures we don't see.
- **Cultural humility**: Avoid projecting Western/familiar decision-making patterns onto culturally different actors. Seek adversary-sourced materials over our own assessments of them.
- **Over-empathy**: Understanding the adversary's perspective does not mean endorsing it. The debrief step explicitly transitions back to analytical objectivity.
