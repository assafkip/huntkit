Run or continue a security-stack intelligence investigation on a company. Maintains a single written case file (`CASE.md`) per company that holds all info in one place.

Arguments: $ARGUMENTS (company name or domain, e.g. "elite.com" or "Acme Corp")

## When to use

- User says "/q-sec-stack <company>" to start or continue a security stack intel run
- Goal: identify security tooling, team structure, threats (last 12mo); keep all of it in one written case file
- Output feeds a downstream demo/product tool that converts intel into tool- and team-specific action items

## One file rule (NON-NEGOTIABLE)

One `CASE.md` per company. That file is the only source of truth. No supplementary YAML, no split briefs, no scattered notes. Every run updates sections in place and appends to section 10 (Update History).

Template: `templates/sec-stack-case/CASE.md`
Location in each case: `investigations/case-NNN-<slug>/CASE.md`

## Preflight

1. Read `./.active-case` to see if a case already exists for this company
2. Look for an existing case folder matching the slug (e.g. `case-NNN-<company-slug>`)
3. If found: load `CASE.md` as source of truth; merge new findings into sections 2-9; append run entry to section 10
4. If not found: scaffold a new case:
   - Next case number (increment from highest in `investigations/`)
   - Slug: company name lowercased, non-alphanum -> hyphens
   - `cp -R templates/new-investigation investigations/case-NNN-<slug>`
   - `cp templates/sec-stack-case/CASE.md investigations/case-NNN-<slug>/CASE.md`
   - Fill header fields (company, case ID, domain, as_of_date, status=active)
   - Write folder name to `./.active-case`
   - Leave canonical/scope.md minimal or delete it -- CASE.md is authoritative for sec-stack cases

## Entity disambiguation (MANDATORY FIRST PASS)

Before collection:
1. Resolve the legal entity behind the company name (whois, DNS, LinkedIn, SEC EDGAR if public)
2. If multiple candidates exist (e.g. "elite.com" -> Elite SEM vs Elite World Group vs Elite Singles), STOP and ask the user which entity
3. Record resolution in CASE.md section 2 (Entity & Scope)

## Collection method (follow this order)

A) **Scope the company precisely:** legal entity, primary domain, major brands, subsidiaries -> fill section 2
B) **Collect tooling evidence:**
   - Trust center / security page / compliance reports (SOC 2, ISO 27001, PCI)
   - Job postings (Greenhouse, Lever, LinkedIn) -- extract required tools from JDs
   - Engineering blog, GitHub org, conference talks
   - Customer case studies published by security vendors
   - Public DNS / cert transparency (crt.sh) -- clearly label limitations
   - Fill section 3 (Security Stack) with confidence grade + EV-NNNN evidence ref
C) **Collect team structure evidence:**
   - LinkedIn job ladders, role families, reporting lines
   - Public org pages, leadership bios
   - Fill section 4 (Team Structure)
D) **Collect threat evidence (last 12 months):**
   - News reports, SEC filings, regulator notices
   - HIBP, DataBreaches.net, ransomware leak sites (flag as unverified)
   - Industry-specific threat campaigns only if connectable by evidence
   - Fill section 5 (Threats)
E) **Derive concerns + action items:** fill sections 6 and 7
F) **Reconcile conflicts:** if sources disagree, list both in the relevant section with confidence scores
G) **Regenerate section 1 (Executive Summary)** to reflect the current state of sections 2-7 (max 350 words)
H) **Append section 10 entry** with run date, new findings, confidence changes, resolved questions, next priorities

## Evidence capture (ENFORCED)

Every URL-sourced claim must be captured via `capture-evidence.sh` into `investigation/evidence/items/EV-NNNN-<slug>/` per `.claude/rules/evidence-capture-protocol.md`. Cite by EV-NNNN in CASE.md section 8 (Evidence Log) and reference from the relevant section (3-7).

## Output format

CASE.md section order is fixed. Do not reorder or rename sections. Do not add new top-level sections without user approval.

1. Executive Summary (350 words max, regenerated each run)
2. Entity & Scope
3. Security Stack (table, 16 categories, confidence grade + EV ref)
4. Team Structure
5. Threats (Last 12 Months) -- confirmed events + unverified claims + industry campaigns
6. Concerns & Drivers -- confirmed + inferred
7. Action Item Seeds -- by team
8. Evidence Log -- all EV-NNNN entries
9. Open Questions
10. Update History (append-only)

## Demo tool input

When the user asks "what do I share with my demo tool," share `CASE.md`. It contains everything in one file.

## Quality bar

- Every `confirmed` claim in section 3 needs at least one reputable source in section 8
- If you cannot find credible evidence for a tool, do not list it as `confirmed`
- Job postings are `strong_signal` at best, never `confirmed` (include link + date in section 8)
- Ransomware leak site claims go under "Unverified claims" in section 5 until corroborated

## Fail-stop

If entity disambiguation fails, if capture-evidence.sh fails, or if 10 tool calls produce no usable evidence: STOP, tell the user what broke, wait.
