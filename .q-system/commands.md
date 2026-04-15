# Q Investigation System -- Commands

Last updated: 2026-04-03

---

## /q-new-case -- Create New Investigation

**Purpose:** Scaffold a new investigation case from templates. Each investigation gets its own folder under `investigations/`.

**Steps:**
1. Ask for case name (short slug) and brief description
2. Generate case ID: `case-NNN-{slug}` (increment from highest existing)
3. Copy `templates/new-investigation/` to `investigations/case-NNN-{slug}/`
4. Write the new case folder name to `./.active-case`
5. Update scope.md with case description and today's date
6. Suggest running `/q-scope` to define full parameters

---

## /q-begin -- Start Investigation Session

**Purpose:** Load all context for a case before starting work.

**Steps:**
1. Identify active case (if multiple, ask the user)
2. Write the active case folder name (e.g., `case-005-ask_reddit_icp`) to `./.active-case` so other commands and `/analyze` can resolve it without asking
3. Read in parallel: scope.md, collection-plan.md, investigation-state.md, last-handoff.md
4. Read preflight.md
5. Check for existing analyses in `output/analyses/` -- list any with their status (complete/in-progress) and last technique run
6. Output: case name, primary question, where we left off, top 3 priorities, blockers, active/completed analyses

---

## /q-end -- End Investigation Session

**Purpose:** Summarize changes and save state for session continuity.

**Steps:**
1. List all files modified this session
2. Update investigation-state.md with session summary
3. Create session log in memory/sessions/
4. Generate handoff note in memory/last-handoff.md
5. Report effort metrics

---

## /q-handoff -- Session Handoff

**Purpose:** Generate a context note for the next session. Saved to `memory/last-handoff.md`.

**Contents:** Session summary, in-progress work, decisions made, files modified, blocked items, suggested next action.

---

## /q-screenshots -- Capture Evidence Screenshots

**Purpose:** Full-page PDF screenshots of all URLs referenced in a report or brief.

**Steps:**
1. Extract all URLs from the target file
2. Capture full-page PDFs using GO FULL PAGE Chrome extension
3. Save to `screenshots/` subfolder alongside the report
4. Add appendix listing screenshots with source URLs

---

## /q-reality-check -- Stress-Test Conclusions

**Purpose:** Argue AGAINST current hypotheses to find weak spots before a client or attorney does.

**Steps:**
1. Read scope, findings, investigation state
2. For each hypothesis, argue the opposite
3. Rate each as STRONG / MODERATE / WEAK
4. For MODERATE/WEAK: what evidence would upgrade it? What's the simplest alternative?
5. Write to findings/REALITY-CHECK-YYYY-MM-DD.md

---

## /q-scope -- Define Investigation Parameters

**Purpose:** Set or update the investigation's scope, hypotheses, and collection requirements.

**Steps:**
1. Ask the user to describe the investigation (target, question, context)
2. Define:
   - **Primary question:** What are we trying to answer?
   - **Targets:** People, entities, domains, accounts to investigate
   - **Hypotheses:** Working theories to test
   - **Collection requirements:** What data do we need? From where?
   - **Boundaries:** What's out of scope? Legal/ethical limits?
3. Write to `canonical/scope.md`
4. Create initial target files in `investigation/targets/`
5. Create initial collection plan in `canonical/collection-plan.md`
6. Confirm with user

---

## /q-intake [type] -- Add New Information

**Purpose:** Process new information into the investigation structure.

**Types:** target, finding, evidence, tip

**Steps:**
1. Ask for the information (or accept paste/file)
2. Classify: What type of information is this?
3. Assess reliability: How trustworthy is the source?
4. Route to appropriate file:
   - New person/entity -> `investigation/targets/[name].md`
   - Confirmed intelligence -> `investigation/findings/`
   - Raw data/screenshots -> `investigation/evidence/`
   - Timeline events -> `investigation/timelines/`
5. Cross-reference against existing targets and findings
6. Flag any new leads or connections surfaced
7. Update `memory/investigation-state.md`

---

## /q-target [name] -- Create or Update Target Profile

**Purpose:** Build a structured profile for an investigation target.

**Steps:**
1. Create/update `investigation/targets/[name].md` with:
   - **Identity:** Name, aliases, known accounts, affiliations
   - **Digital footprint:** Social media, domains, email patterns
   - **Connections:** Links to other targets, organizations, events
   - **Timeline:** Key events and activities
   - **Collection status:** What we have, what we need
   - **Assessment:** Current understanding, confidence level
2. Cross-reference against other target files for connections
3. Update `investigation/timelines/` if new events found
4. Flag collection gaps

---

## /q-collect -- Plan or Execute OSINT Collection

**Purpose:** Plan collection activities or process collected data.

**Steps:**
1. Read `canonical/collection-plan.md` for outstanding requirements
2. Read `memory/investigation-state.md` for what's been collected
3. Identify highest-priority collection gaps
4. For each gap, suggest:
   - What to collect
   - Where to collect it (platform, source)
   - Tool/method to use
   - Expected yield
   - Energy tag + Time Est
5. Present as choices, not commands
6. When the user brings back data, process via `/q-intake`

**OSINT Toolkit:** Read `skills/osint/SKILL.md` for full tool catalog, actor IDs, and escalation flow.

**Quick reference -- collection scripts:**
```bash
# Self-diagnostics (run first)
bash skills/osint/scripts/diagnose.sh

# Parallel search across all engines
bash skills/osint/scripts/first-volley.sh "Target Name" "context"

# Merge and deduplicate results
bash skills/osint/scripts/merge-volley.sh /tmp/osint-<timestamp>

# Platform-specific
bash skills/osint/scripts/apify.sh linkedin "<url>"
bash skills/osint/scripts/apify.sh instagram "<handle>"
bash skills/osint/scripts/perplexity.sh search "query"
bash skills/osint/scripts/exa.sh people "Name"
bash skills/osint/scripts/tavily.sh search "query"
bash skills/osint/scripts/jina.sh read "<url>"
bash skills/osint/scripts/brightdata.sh scrape "<url>"

# Universal Apify runner (55+ actors)
bash skills/osint/scripts/run-actor.sh "actor/id" '{"input":"json"}'
```

**Escalation:** Level 1 (free, fast) -> Level 2 (source verify) -> Level 3 (social scrape) -> Level 4 (deep research, ~$0.50)

**Additional sources (manual/CLI):**
- Domain/WHOIS: `whois`, `dig`, `nslookup`
- Web archives: Wayback Machine API
- Google dorking: search operators via browser
- DNS/IP: `dig`, `nslookup`, Shodan
- Public records: platform-specific

---

## /q-osint [platform] [target] -- Platform-Specific Collection

**Purpose:** Run targeted OSINT collection on a specific platform. Uses the OSINT skill's scripts and actors.

**Before first use:** Run `bash skills/osint/scripts/diagnose.sh` to check available tools.

**LinkedIn:** `/q-osint linkedin [profile-url]`
- `bash skills/osint/scripts/apify.sh linkedin "<url>"` (profile data)
- Fallback: `bash skills/osint/scripts/brightdata.sh scrape "<url>"`
- Map connections to existing targets
- Output structured profile + activity patterns
- Save to `investigation/targets/[name].md`

**Instagram:** `/q-osint instagram [handle]`
- `bash skills/osint/scripts/apify.sh instagram "<handle>"` (profile + posts)
- Tagged posts: `bash skills/osint/scripts/run-actor.sh "apify/instagram-tagged-scraper" '{"username":"handle"}'`
- Comments: `bash skills/osint/scripts/run-actor.sh "apify/instagram-comment-scraper" '...'`

**Facebook:** `/q-osint facebook [url]`
- Pages: `bash skills/osint/scripts/run-actor.sh "apify/facebook-pages-scraper" '...'`
- Personal profiles: `bash skills/osint/scripts/brightdata.sh scrape "<url>"` (only Bright Data works)

**Reddit:** `/q-osint reddit [username]`
- Pull post/comment history via JSON API or Apify
- Map active subreddits and topics
- Identify behavioral patterns, posting times
- Cross-reference usernames and language patterns

**X/Twitter:** `/q-osint x [handle]`
- Pull tweet history (last 90 days)
- Map interactions (replies, RTs, mentions)
- Identify key relationships from engagement

**TikTok:** `/q-osint tiktok [handle]`
- `bash skills/osint/scripts/run-actor.sh "clockworks/tiktok-profile-scraper" '{"profiles":["handle"]}'`
- Discovery: `bash skills/osint/scripts/run-actor.sh "clockworks/tiktok-user-search-scraper" '{"keywords":"name"}'`

**YouTube:** `/q-osint youtube [channel]`
- `bash skills/osint/scripts/run-actor.sh "streamers/youtube-channel-scraper" '...'`

**Domain:** `/q-osint domain [domain.com]`
- WHOIS lookup (`whois domain.com`)
- DNS records: `dig domain.com ANY`
- Subdomain enumeration
- Historical records: Wayback Machine
- SSL certificate transparency logs

**Email:** `/q-osint email [address]`
- Check known breach databases (HIBP)
- Identify associated accounts/platforms
- Domain analysis for custom domains
- Contact enrichment: `bash skills/osint/scripts/run-actor.sh "vdrmota/contact-info-scraper" '{"urls":["site.com"]}'`

**Full sweep:** `/q-osint sweep [name]`
- Runs the OSINT skill's full pipeline (Phase 1 -> 2 -> 3)
- **Default first pass (Perplexity playbook, parallel with first-volley):**
  ```bash
  bash skills/osint/scripts/perplexity-playbook.sh <type> <slug> "<target>" --case <active-case> &
  bash skills/osint/scripts/first-volley.sh "Name" "context" &
  wait
  ```
  `<type>` = `person|company|domain|incident`. Playbook writes merged citations
  to `/tmp/osint-<slug>-<ISO8601>/evidence.json` and persists to the case's
  `raw-collections/`. Add `--capture` to auto-run `capture-evidence.sh --batch`
  on the deduped URL list.
- Merge results, score confidence, identify platforms
- Populate target profile with all findings

**Email:** `/q-osint email [address]`
- Check known breach databases (HIBP)
- Identify associated accounts/platforms
- Domain analysis for custom domains
- Pattern matching against known targets

**Rules:**
- Always use Apify or API tools before Chrome
- Log all collection to `investigation/evidence/`
- Tag source reliability (A-F scale)
- Never exceed ethical/legal boundaries defined in scope

---

## /q-analyze -- Connect the Dots

**Purpose:** Review all collected data and surface patterns, connections, gaps.

**Steps:**
1. Read all target profiles in `investigation/targets/`
2. Read all findings in `investigation/findings/`
3. Read timeline in `investigation/timelines/`
4. Read any completed structured analyses in `output/analyses/` -- incorporate their key judgments, ACH matrices, and assumptions checks rather than re-deriving conclusions
5. Identify:
   - **Connections:** Links between targets not previously noted
   - **Patterns:** Behavioral patterns, timing correlations, shared infrastructure
   - **Gaps:** Missing information that would confirm/deny hypotheses
   - **Contradictions:** Data points that conflict
   - **New leads:** Targets or threads not yet in scope
6. For each finding, assess:
   - Confidence level (confirmed / high / moderate / low / speculative)
   - Supporting evidence (cite specific files)
   - Alternative explanations
7. Update `investigation/findings/` with new assessments
8. Update collection plan with new requirements
9. Present analysis to user

---

## /q-link [target-a] [target-b] -- Map Relationships

**Purpose:** Explicitly map and document the relationship between two targets.

**Steps:**
1. Read both target profiles
2. Search evidence for any shared:
   - Organizations, employers, affiliations
   - Events, timeframes, locations
   - Digital infrastructure (domains, IPs, accounts)
   - Communication patterns
   - Third-party connections
3. Classify relationship: direct / indirect / inferred / unknown
4. Assess strength: strong / moderate / weak / speculative
5. Document in both target files + `investigation/findings/`
6. Update timeline if relationship has temporal dimension

---

## /q-timeline -- Build or Update Timeline

**Purpose:** Reconstruct chronological sequence of events.

**Steps:**
1. Read all target profiles and findings
2. Extract dated events
3. Build/update `investigation/timelines/master-timeline.md`
4. Identify:
   - Clusters of activity
   - Gaps (periods with no data)
   - Temporal correlations between targets
   - Sequence patterns (A always happens before B)
5. Present timeline to user
6. Flag periods that need more collection

---

## /q-brief -- Generate Investigation Brief

**Purpose:** Produce a structured summary of current investigation state.

**Steps:**
1. Read scope, all targets, all findings, timeline
1b. Read any completed analyses in `output/analyses/` -- incorporate key judgments, confidence levels, and technique outputs into the brief
2. Generate brief with:
   - **Executive summary:** 3-5 bullet points answering the primary question (current state)
   - **Key findings:** Confirmed intelligence, with confidence levels and citations
   - **Target matrix:** All targets, their status, key connections
   - **Timeline summary:** Major events in chronological order
   - **Collection gaps:** What we still need
   - **Hypotheses status:** Which are supported/refuted/undetermined
   - **Recommended next steps:** Prioritized by impact, tagged with Energy + Time Est
3. **PDF screenshot pass:** Compile all URLs referenced in the brief. Capture full-page PDF of each using GO FULL PAGE Chrome extension. Save to `output/briefs/screenshots/`.
4. Save to `output/briefs/brief-YYYY-MM-DD.md`
5. Present to user

---

## /q-status -- Quick Snapshot

**Purpose:** Fast overview of investigation state.

**Steps:**
1. Read `memory/investigation-state.md`
2. Output compact summary:
   - Targets: X total, Y fully profiled, Z with gaps
   - Findings: X confirmed, Y assessed, Z speculative
   - Collection: X sources tapped, Y outstanding
   - Analyses: list any in `output/analyses/` with technique(s) and status
   - Hypotheses: status of each
   - Top 3 priorities

---

## /q-debrief -- Process Conversation or Source

**Purpose:** Extract structured findings from a conversation, interview, document, or source.

**Steps:**
1. Ask user to describe or paste the source material
2. Extract:
   - New targets or entities mentioned
   - Facts (with reliability assessment)
   - Timeline events (with dates)
   - Relationships between entities
   - Contradictions with existing findings
   - New collection leads
3. Route to appropriate investigation files
4. Cross-reference against existing data
5. Update `memory/investigation-state.md`

---

## /q-export [format] -- Export Investigation Data

**Purpose:** Export investigation data in a structured format.

**Formats:** markdown, json, timeline-html

**Steps:**
1. Gather all investigation files, including `output/analyses/` (structured analysis reports, technique artifacts, evidence registries)
2. Export in requested format:
   - **markdown:** Full investigation report, with structured analysis appendix (technique outputs, ACH matrices, key assumptions)
   - **json:** Structured data (targets, findings, links, timeline, analysis summaries)
   - **timeline-html:** Interactive timeline visualization
3. **PDF screenshot pass:** Compile all URLs referenced in the report and appendix. Capture full-page PDF of each using GO FULL PAGE Chrome extension. Save to `output/exports/screenshots/`.
4. Save to `output/exports/`
5. Present to user

---

## /q-checkpoint -- Save State

**Purpose:** Save current investigation state. Auto-triggers at session end.

**Steps:**
1. Update `memory/investigation-state.md` with:
   - Session summary
   - What was collected/analyzed
   - Outstanding tasks
   - Next priority
2. Verify target files are consistent with findings, timeline, and any structured analysis conclusions in `output/analyses/`
3. Flag any inconsistencies (including between Q findings and /analyze outputs)
4. Confirm save

---

## /analyze -- Structured Analytic Techniques (SAT)

**Purpose:** Run IC-standard Structured Analytic Techniques on investigation data. This is a Claude Code skill (not a Q command) -- it has its own orchestrator, evidence collector, and self-correction layers.

**Skill location:** `skills/structured-analysis/SKILL.md`

**When to use `/analyze` vs Q commands:**
- `/analyze ach` -- formal hypothesis testing with diagnosticity matrix. Use when you have 3+ competing hypotheses and need to systematically evaluate evidence for/against each.
- `/analyze kac` -- structured assumptions check. Use when key judgments rest on assumptions that haven't been tested.
- `/analyze deception` -- detect planted/false information. Use when source reliability is uncertain or adversary may be seeding disinformation.
- `/analyze premortem` -- failure-mode analysis. Use before delivering a brief to stress-test conclusions.
- `/analyze --lean` -- quick run (restatement + KAC + inconsistencies). Good mid-investigation sanity check.
- `/analyze --no-osint` -- analyze already-collected evidence only. **Recommended for most Q investigation use** since we collect via `/q-osint` first.
- `/q-challenge` -- still use for quick informal gut checks mid-session
- `/q-reality-check` -- still use for fast stress-tests when full SAT is overkill

**Output routing:** All analysis artifacts write to the active case's `output/analyses/<analysis-id>/`. The skill's SKILL.md has the path override instructions.

**Typical Q workflow:**
1. Collect evidence: `/q-osint`, `/q-collect`
2. Run analysis: `/analyze ach --no-osint` (uses collected evidence as Tier 2 local files)
3. Results auto-feed back into `investigation/findings/` and `investigation-state.md`
4. Brief the client: `/q-brief` (incorporates analysis findings)

---

## /q-challenge -- Challenge Assumptions

**Purpose:** Force a structured challenge of all investigation assumptions and hypotheses at the midpoint. Prevents confirmation bias and circular reasoning.

**Steps:**
1. Read `canonical/scope.md` for hypotheses
2. Read ALL files in `investigation/findings/`
3. Read key evidence files
4. Read `memory/investigation-state.md`
5. For each hypothesis, evaluate:
   - What evidence SUPPORTS this? (cite files)
   - What evidence CONTRADICTS this? (cite files)
   - What would DISPROVE this? (describe the test)
   - Have we actually looked for disproving evidence?
   - Is this based on fact, inference, or assumption?
   - Could the same evidence support a different explanation?
6. Check for: circular reasoning, name-matching traps, confirmation bias, source independence, community inference vs. identification
7. Write to `investigation/findings/CHALLENGE-YYYY-MM-DD.md`
8. Present revised confidence levels and top 3 weakest assumptions as choices

---

## /q-client-questions -- Draft Client Questions

**Purpose:** Draft targeted questions for the client based on current collection gaps. The client often knows the answer to things that would take 50+ tool calls to research.

**Steps:**
1. Read `canonical/scope.md` for hypotheses
2. Read `canonical/collection-plan.md` for outstanding gaps
3. Read `investigation/targets/` for collection status
4. Read `memory/investigation-state.md` for what's been tried
5. Draft 3-5 questions that target the biggest collection gaps, ask about relationships, and request identification of unknown persons
6. Format as a copy-paste-ready email
7. Present to user for review -- never send directly
