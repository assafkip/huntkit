# Protocol: Premortem + Structured Self-Critique

> **Phase**: Challenge | **Effort**: 30 min – 2 hours | **Bias Mitigated**: Overconfidence, Blind spots
> **Output Artifact**: `working/premortem.md`
> **Library**: 00-prime §4 (Essential 8), 09-core-techniques

---

## Purpose

Imagine the analysis has already failed catastrophically — then work backward to find the weaknesses before they matter. Combines Premortem Analysis (prospective hindsight) with Structured Self-Critique to surface blind spots, overweighted evidence, and absent perspectives.

---

## Execution

### 1. SETUP
- Read ALL prior technique outputs in the `working/` directory
- Identify the central assessment or judgment being tested
- Note the confidence level and which techniques contributed to it

### 2. PRIME
State: "I will now imagine this analysis has failed — and find out why before it does."

### 3. EXECUTE

1. **State the assessment being tested** — write the core judgment clearly, including confidence level and supporting techniques
2. **Assume failure at a future date** — set a specific date (e.g., 6 months from now) and state: "It is [date] and this analysis was catastrophically wrong"
3. **Write the failure story** — construct a detailed, plausible narrative of how the analysis failed:
   - What happened in the world that contradicted the assessment?
   - What did the analyst miss or underweight?
   - What surprised everyone?
   - Be specific — vague failure stories are useless
4. **Inventory weaknesses per technique** — for each technique used in the analysis, identify:
   - What weakness it introduced or failed to catch
   - Severity of that weakness (Critical / High / Medium / Low)
   - A specific mitigation
5. **Structured Self-Critique** — answer each question honestly and thoroughly:
   - **What assumption am I most uncertain about?**
   - **What evidence did I give too much weight?**
   - **What perspective is completely absent from this analysis?**
   - **What would a fierce critic say about this assessment?**
   - **If I had to argue the opposite conclusion, what is my strongest point?**
6. **Prioritize** — rank the top 3-5 weaknesses by severity and identify actionable mitigations for each

### 4. ARTIFACT
Write `working/premortem.md` using the Premortem + Self-Critique template.

### 5. FINDINGS
Summarize: the top 3-5 weaknesses with their mitigations and current status. Flag any weakness rated Critical that has not been resolved.

### 6. HANDOFF
Pass findings back to the relevant technique for remediation, or forward to final assessment compilation.

---

## Watch-Outs
- **Overconfidence**: The most dangerous bias here. If the analyst feels "this analysis is solid," that is exactly when the premortem is most needed.
- **Blind spots**: By definition, you cannot see your own blind spots. The self-critique questions are designed to surface them — answer each one genuinely, not defensively.
- **Reluctance to criticize own work**: The premortem requires intellectual honesty. A premortem that finds no weaknesses has failed.
- **Shallow failure stories**: "The data was wrong" is not a useful failure narrative. Specify WHAT data, WHY it was wrong, and HOW the analyst was deceived.
