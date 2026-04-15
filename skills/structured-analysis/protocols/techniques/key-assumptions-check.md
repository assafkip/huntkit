# Protocol: Key Assumptions Check

> **Phase**: Diagnostic | **Effort**: 15 minutes to 2 hours | **Bias Mitigated**: Status quo bias, institutional inertia
> **Output Artifact**: `working/assumptions.md`
> **Library**: 00-prime §4 (Essential 8), 00-prime §6 (KAC Protocol), 01-tradecraft-primer, 02-tradecraft-primer-analysis

---

## Purpose

Surface and challenge the hidden premises supporting an analytic judgment. Identify linchpin assumptions whose failure would demand fundamental rethinking.

---

## Execution

### 1. SETUP
- Read problem framing from `working/requirements.md`
- Read any prior outputs (brainstorm, evidence registry)
- Identify the current analytic line to be examined

### 2. PRIME
State to user: "I will now surface the hidden premises behind this analytic line and stress-test each one."

### 3. EXECUTE

1. **State the analytic line** — write it down clearly and completely
2. **List ALL premises** — include both stated and unstated assumptions that must be true for the analytic line to hold
3. **Challenge each assumption**:
   - Why must this be true?
   - Does it hold under all conditions?
   - Was it true in the past but less so now?
   - What evidence supports it? What evidence challenges it?
4. **Bin each assumption**:
   - **S** (Supported) — well-corroborated by evidence
   - **C** (Correct with Caveats) — generally holds but with notable exceptions
   - **U** (Unsupported) — accepted without evidence or contradicted
5. **Identify linchpin assumptions** — those whose failure would collapse the analytic line
6. **For each linchpin**, document:
   - What conditions would make it false
   - What would need to happen to demand rethinking
   - The impact on the overall judgment if wrong

### 4. ARTIFACT
Write `working/assumptions.md` using the Key Assumptions Check template.

### 5. FINDINGS
Summarize: number of assumptions identified, linchpin assumptions, fault lines requiring action, and overall confidence impact.

### 6. HANDOFF
Pass linchpin assumptions and fault lines to ACH or Inconsistencies Finder for hypothesis testing.

---

## Watch-Outs
- **Status quo bias**: Long-accepted premises feel "obviously true." Challenge them hardest.
- **Missing unstated assumptions**: The most dangerous assumptions are those nobody thought to articulate. Probe for them explicitly.
- **Superficial challenge**: Asking "is this true?" is insufficient. Ask "under what specific conditions would this fail?"
