# Protocol: Analysis of Competing Hypotheses

> **Phase**: Diagnostic | **Effort**: Hours to days | **Bias Mitigated**: Confirmation bias, premature closure, anchoring
> **Output Artifact**: `working/ach-matrix.md`
> **Library**: 00-prime §4 (Essential 8), 00-prime §6 (ACH Protocol), 00-prime §2 (Diagnostic Dominance), 01-tradecraft-primer, 02-tradecraft-primer-analysis

---

## Purpose

Evaluate all hypotheses simultaneously by focusing on disconfirmation rather than confirmation. Identify the hypothesis with the least inconsistent evidence as most plausible.

---

## Execution

### 1. SETUP
- Read problem framing from `working/requirements.md`
- Read assumptions from `working/assumptions.md` (if available)
- Read evidence registry for all available evidence items
- Read brainstorm output from `working/brainstorm.md` (if available)

### 2. PRIME
State to user: "I will now evaluate ALL hypotheses simultaneously. The focus is on disproving hypotheses, not confirming a preferred one."

### 3. EXECUTE

1. **Frame the problem** as a clear, unbiased, open-ended inquiry. Avoid causal language.
2. **Brainstorm hypotheses** — generate at least 3, including:
   - A null hypothesis (nothing has changed / conventional explanation)
   - A denial/deception possibility
   - At least one unconventional alternative
3. **List all evidence and arguments**, including:
   - Positive evidence (what is observed)
   - Negative evidence (absence of expected indicators)
   - Rate source reliability for each item
4. **Build the diagnosticity matrix** — hypotheses across columns, evidence down rows
5. **Rate each cell**: C (Consistent), I (Inconsistent), N (Neutral)
6. **Apply the Law of Diagnostic Dominance** — flag evidence rated C or N across ALL hypotheses as zero-diagnostic-value
7. **Tally inconsistencies** per hypothesis — the hypothesis with the fewest inconsistencies is most plausible
8. **Conduct sensitivity analysis** — identify evidence items that, if removed or reinterpreted, would change the conclusion
9. **Define future indicators** — observable events that would confirm or refute the leading hypothesis

### 4. ARTIFACT
Write `working/ach-matrix.md` using the Analysis of Competing Hypotheses template.

### 5. FINDINGS
Summarize: most plausible hypothesis, confidence level, key discriminating evidence, and critical sensitivities.

**Layer 1 Self-Check:**
- [ ] At least 3 hypotheses evaluated?
- [ ] Null hypothesis included?
- [ ] Denial/deception possibility considered?
- [ ] Zero-diagnostic-value items identified and flagged?
- [ ] Unitarity: If probability estimates are assigned, do they sum to ~1.0 (MECE)? If not, hypotheses may overlap or a possibility is missing.

### 6. HANDOFF
Pass findings to Challenge phase techniques (Premortem, What If?) for stress-testing.

---

## Watch-Outs
- **Initial framing error**: If the true explanation is not among the listed hypotheses, the matrix will yield a false winner. Revisit hypothesis list if results feel forced.
- **Mechanical box-checking**: ACH is a thinking aid, not a calculator. Each C/I/N rating requires genuine analytical judgment.
- **Noise amplification**: Large matrices (5+ hypotheses x 10+ evidence items) accumulate random judgment noise. Consider the Inconsistencies Finder as a lean alternative for time-constrained analysis.
- **Confirmation through consistency**: Do not mistake "most consistent" for "most plausible." Focus on inconsistencies.
