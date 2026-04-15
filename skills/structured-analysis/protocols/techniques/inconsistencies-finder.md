# Protocol: Inconsistencies Finder

> **Phase**: Diagnostic | **Effort**: Minutes to 1 hour | **Bias Mitigated**: Confirmation bias, satisficing
> **Output Artifact**: `working/inconsistencies.md`
> **Library**: 00-prime §4 (Extended: Lean SATs), 00-prime §7 (Agile Rigor), 04-agile-rigor-update

---

## Purpose

Streamlined alternative to full ACH. Focus exclusively on the lead hypothesis and search for evidence that contradicts it. Forces a scientific mindset — trying to prove yourself wrong.

**Speed advantage**: Bypasses the noise amplification problem of large ACH matrices by concentrating analytical effort on a single hypothesis.

---

## Execution

### 1. SETUP
- Read problem framing from `working/requirements.md`
- Read the current lead hypothesis (from prior analysis or stated by user)
- Read evidence registry for all available evidence

### 2. PRIME
State to user: "I will now focus ONLY on the lead hypothesis and try to prove it wrong. This is a deliberate stress test."

### 3. EXECUTE

1. **State the lead hypothesis** clearly and completely
2. **Search the evidence base** systematically for items that contradict, weaken, or are unexplained by the lead hypothesis
3. **For each contradicting item**, explain:
   - What the evidence states
   - How specifically it contradicts the lead hypothesis
   - The source and reliability of the contradicting evidence
4. **Assess survival** — does the lead hypothesis survive the contradiction search?
   - **Survives**: No strong contradictions found; proceed with confidence
   - **Weakened**: Some contradictions exist; caveats required
   - **Refuted**: Strong contradictions undermine the hypothesis fundamentally
5. **If contradictions are strong**, suggest the next-best alternative explanation

### 4. ARTIFACT
Write `working/inconsistencies.md` using the Inconsistencies Finder template.

### 5. FINDINGS
Summarize: lead hypothesis status (survives/weakened/refuted), strongest contradictions found, and recommended next step.

### 6. HANDOFF
If lead hypothesis survives, pass to Challenge phase. If refuted, return to ACH or hypothesis generation.

---

## Watch-Outs
- **Confirmation bias**: The entire point is to fight this. Do not dismiss contradictions because they are inconvenient.
- **Weak contradictions**: Distinguish between evidence that genuinely contradicts and evidence that is merely ambiguous.
- **Single-hypothesis tunnel**: This technique tests one hypothesis only. If the problem space is genuinely open, use full ACH instead.
