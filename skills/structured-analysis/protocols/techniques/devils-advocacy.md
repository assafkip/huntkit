# Protocol: Devil's Advocacy

> **Phase**: Challenge | **Effort**: 30 min – 1 hour | **Bias Mitigated**: Groupthink, consensus bias
> **Output Artifact**: `working/devils-advocacy.md`
> **Library**: 01-tradecraft-primer §2, 05-taxonomy #38

---

## Purpose

Build the strongest possible case AGAINST the prevailing judgment. Unlike Premortem (which imagines future failure), Devil's Advocacy directly attacks the current logic, evidence, and reasoning chain to expose weaknesses in the existing assessment.

---

## Execution

### 1. SETUP
- Read ALL prior technique outputs in the `working/` directory
- Identify the prevailing judgment or consensus from the analysis so far
- Confirm a clear mainline assessment exists — if no judgment has been formed yet, this technique cannot execute (flag and suggest KAC or ACH first)

### 2. PRIME
State: "I will now construct the strongest possible argument against the prevailing assessment. This is a genuine intellectual challenge, not token contrarianism."

### 3. EXECUTE

1. **State the mainline judgment** — write the prevailing assessment clearly, including its confidence level, key supporting evidence, and which techniques produced it
2. **Identify vulnerable assumptions** — pull from KAC output if available, otherwise enumerate the assumptions underlying the judgment. For each:
   - State the assumption
   - Rate vulnerability (High / Medium / Low)
   - Explain what breaks if this assumption is wrong
3. **Review evidence for gaps and inconsistencies** — examine the evidence base for:
   - Evidence that was dismissed or downweighted
   - Missing evidence that should exist if the judgment is correct
   - Evidence with provenance concerns or deception markers
   - Contradictory evidence that was explained away
4. **Build the contrarian argument** — construct a coherent, compelling narrative that:
   - Directly challenges the mainline judgment
   - Uses real evidence from the analysis (not hypothetical)
   - Explains away the evidence supporting the mainline judgment
   - Proposes an alternative explanation for the observed evidence
   - Is genuinely persuasive, not a straw man
5. **Assess the challenge** — honestly evaluate the strength of the contrarian argument:
   - **Weak**: Contrarian case relies on speculation; mainline judgment holds
   - **Moderate**: Contrarian case raises legitimate concerns; mainline judgment needs caveats
   - **Strong**: Contrarian case is competitive; confidence should be lowered or judgment revised
   - Recommend specific action based on assessment

### 4. ARTIFACT
Write `working/devils-advocacy.md` using the Devil's Advocacy template.

### 5. FINDINGS
Summarize: the contrarian position, its assessed strength, and the recommended action (confirm judgment with caveats / lower confidence / revise judgment / request additional evidence).

### 6. HANDOFF
Pass findings to report generator. If assessment is Strong, flag for Layer 2 self-critique and consider triggering re-run of relevant diagnostic techniques.

---

## Watch-Outs
- **Token contrarianism**: The contrarian argument must be genuinely challenging. "What if the data is wrong?" is not a real argument. Build a coherent alternative explanation using actual evidence.
- **Requires prior judgment**: This technique cannot execute in a vacuum — it needs a prevailing assessment to challenge. If none exists, flag and recommend running diagnostic techniques first.
- **Distinct from Premortem**: Premortem imagines future failure and works backward. Devil's Advocacy attacks the current reasoning chain directly. Both are valuable but serve different cognitive functions.
- **Overcompensation risk**: A strong contrarian argument does not automatically mean the mainline judgment is wrong. It means the judgment needs better support or appropriate caveats.
