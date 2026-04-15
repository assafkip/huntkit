# Protocol: Opportunities Incubator

> **Phase**: Decision Support | **Effort**: 30-60 minutes | **Bias Mitigated**: Threat fixation (negativity bias)
> **Output Artifact**: `working/opportunities.md`
> **Library**: 00-prime §4 (Extended: Frontier), 00-prime §5 (14-Question Rubric), 04-agile-rigor-update

---

## Purpose

Counter the intelligence bias of focusing exclusively on threats while ignoring strategic advantages. Systematically scan for emerging trends, identify where multiple trends converge to create windows of opportunity, and define observable indicators for timing action.

---

## Execution

### 1. SETUP
- Read problem context, evidence base, and any trend data from prior techniques or OSINT
- Review evidence registry for signals across multiple domains
- Note any opportunities or positive developments already surfaced but not yet analyzed

### 2. PRIME
State: "I'll now look for opportunities, not just threats — scanning for emerging trends and convergences that create windows for action."

### 3. EXECUTE

1. **Environmental Scan** — Scan the evidence base for emerging trends across four domains:
   - **Technology**: New capabilities, platform shifts, adoption curves
   - **Economic**: Market movements, resource availability, cost changes
   - **Social**: Behavioral shifts, demographic changes, sentiment trends
   - **Political**: Policy changes, regulatory shifts, alliance movements
   - Rate each trend's signal strength (Strong / Moderate / Emerging)
2. **Driver Convergence** — Identify where 2+ trends from different domains intersect to create opportunities:
   - For each convergence, define the opportunity it creates
   - Assess confidence (High / Moderate / Low) and timeframe
   - Prioritize convergences with the strongest signal strength on both sides
3. **Windows of Opportunity** — For each identified opportunity:
   - Define **opening indicators**: observable events signaling the window is becoming available
   - Define **closing indicators**: observable events signaling the window is narrowing or shutting
   - Recommend a specific action tied to the window's timing
4. **Priority Ranking** — Rank opportunities by combination of confidence, impact, and time sensitivity

### 4. ARTIFACT
Write `working/opportunities.md` using the Opportunities Incubator template.

### 5. FINDINGS
Summarize: top opportunities with timing indicators, highest-confidence convergences, and any windows that are already opening or at risk of closing.

### 6. HANDOFF
Pass opportunity assessments and timing indicators to the decision-maker or the next technique in the workflow (e.g., Decision Matrix for resource allocation).

---

## Watch-Outs
- **Threat fixation**: The single most common failure mode. Intelligence culture defaults to threat analysis. Actively resist reframing opportunities as risks to mitigate.
- **Wishful thinking**: Opportunities must be grounded in evidence, not aspiration. Every trend must cite at least one source from the evidence registry.
- **Domain tunnel vision**: The most valuable opportunities emerge from cross-domain convergences. If all your trends come from one domain, expand your scan.
- **Timing blindness**: An opportunity without timing indicators is not actionable. Force specificity on opening and closing indicators.
- **Stale windows**: Flag any windows that evidence suggests are already closing. Late action on a closing window is worse than no action.
