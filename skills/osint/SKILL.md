---
name: osint
description: >
  Conduct deep OSINT research on individuals. Build full digital footprint, psychoprofile
  (MBTI/Big Five), career history, social graph with confidence scores. Recursive
  self-evaluation until completeness threshold is met. Includes internal intelligence
  (Telegram history, email, vault contacts) before going external.
  Use when: "osint", "research person", "find everything about", "due diligence",
  "background check", "digital footprint", "dossier", "profile someone".
  NOT for: company/product research without a named person, competitive analysis,
  market research, content generation, or general web scraping tasks.
---

# OSINT Skill v3.2

Systematic intelligence gathering on individuals. From a name or handle to a scored
dossier with psychoprofile, career map, and entry points.

## Phase Router

Determine entry point from context:

- New name/handle/URL, "find out about" → Phase 0 (full cycle)
- "Add LinkedIn/Instagram data" to existing dossier → Phase 2 (extraction)
- "Build psychoprofile" from existing data → Phase 4
- "Rate completeness" of existing dossier → Phase 5
- "Reformat" or "present" findings → Phase 6

Default (full research request): Phase 0 → 1 → 1.5 → 2 → 3 → 4 → 5 → 6.

## Environment

All API keys via environment variables. Never hardcode tokens.

- `PERPLEXITY_API_KEY` — Perplexity Sonar (fast answers + deep research)
- `EXA_API_KEY` — Exa AI (semantic search, company/people research, deep research)
- `TAVILY_API_KEY` — Tavily (agent-optimized search + extract, $0.005/req basic)
- `APIFY_API_TOKEN` — Apify scraping (LinkedIn, Instagram, Facebook)
- `JINA_API_KEY` — Jina reader/search/deepsearch
- `PARALLEL_API_KEY` — Parallel AI search
- `BRIGHTDATA_MCP_URL` — Bright Data MCP endpoint (full URL with token)
- `MCPORTER_CONFIG` — mcporter config path

## Scripts

Run from skill dir: `bash scripts/<name>.sh`.
Each validates env vars, exits with descriptive error + URL to get the key.

**Search & Research:**
- `diagnose.sh` — run FIRST. Capability map of all tools.
- **Perplexity (first-pass default):** when operating through Claude, call the MCP tool `mcp__perplexity-ask__perplexity_ask` directly. It returns an AI answer with citations (equivalent to `sonar` mode). Use the shell script for `search` (ranked web results), `reason` (reconcile contradictions), and `deep` (long-form research) modes, or from bash pipelines.
- `perplexity.sh` — `search <query>` | `sonar <query>` (AI answer) | `reason <query>` (sonar-reasoning-pro, compare leads / reconcile contradictions) | `deep <query>` (deep research). Required by `first-volley.sh` and any bash-only pipeline.
- `tavily.sh` — `search <query>` (basic $0.005) | `deep <query>` (advanced) | `extract <url>`
- `exa.sh` — `search <query>` | `company <name>` | `people <name>` | `crawl <url>` | `deep <prompt>`
- `first-volley.sh "Name" "context"` — parallel search, all engines at once.
- `merge-volley.sh <outdir>` — deduplicate and merge first-volley results.

**Scraping:**
- `apify.sh` — `linkedin <url>` | `instagram <handle>` | `run` | `results` | `store-search`
- `run-actor.sh` — **universal Apify runner (55+ actors).** Embedded from [apify/agent-skills](https://github.com/apify/agent-skills).
  Quick answer: `bash scripts/run-actor.sh "actor/id" '{"input":"json"}'`
  Export: `bash scripts/run-actor.sh "actor/id" '{"input":"json"}' --output /tmp/out.csv`
- `jina.sh` — `read <url>` | `search <query>` | `deepsearch <query>`
- `parallel.sh` — `search <query>` | `extract <url>`
- `brightdata.sh` — `scrape <url>` | `scrape-batch` | `search` | `search-geo <cc>` | `search-yandex`

## Research Escalation Flow

**Principle: cheap before expensive, fast before deep.**

### Level 1: Quick Answers (seconds, ~$0.00)
Always start here. Get quick context before digging.
Run ALL in parallel:
```bash
# Perplexity (default: MCP tool, not the shell script)
#   Claude call: mcp__perplexity-ask__perplexity_ask with a structured prompt
#   (see "Prompt Templates" section — use the Entity Profile template, not ad-hoc "Who is X")
# Shell fallback (bash pipelines or when you need sonar explicitly):
#   bash skills/osint/scripts/perplexity.sh sonar "<structured prompt from Entity Profile template>"
# Brave Search — classic web search
web_search "<Name> <company> <role>"
# Tavily — agent-optimized search with AI answer
bash skills/osint/scripts/tavily.sh search "<Name> <context>"
# Exa — semantic search + company/people research
bash skills/osint/scripts/exa.sh search "<Name> <context>"
bash skills/osint/scripts/exa.sh people "<Name>"
```
→ Returns: quick facts, links, context.
→ Decision: enough? → Phase 6. Need more? → Level 2.

### Level 2: Source Verification (seconds to minutes, ~$0.01)
Verify sources from Level 1 via fetch:
```bash
# Read discovered URLs
web_fetch "<url_from_perplexity>"
bash skills/osint/scripts/jina.sh read "<url>"
bash skills/osint/scripts/parallel.sh extract "<url>"
```
→ Returns: verified facts, cross-references.
→ Match? → enrich the dossier. Need deeper? → Level 3.

### Level 3: Social Media Deep Dive (~$0.01-0.10)
Bring in scrapers for social platforms:
```bash
# LinkedIn
bash skills/osint/scripts/apify.sh linkedin "<url>"
# Instagram
bash skills/osint/scripts/apify.sh instagram "<handle>"
# Facebook, geo-blocked sites
bash skills/osint/scripts/brightdata.sh scrape "<url>"
```
→ Returns: structured profiles, photos, connections.

### Level 4: Deep Research (~$0.05-0.50)
If you need to go deeper — compose an extended prompt and send to deep research.
Run ALL in parallel (30-60 sec each):
```bash
# Perplexity Deep Research — use a template from "Prompt Templates" section
bash skills/osint/scripts/perplexity.sh deep "<filled-in Entity Profile or Network Mapping template>"
# Perplexity Reasoning — reconcile contradictions surfaced in Level 1-3
bash skills/osint/scripts/perplexity.sh reason "<filled-in Contradiction Reconciliation template>"
# Exa Deep Research
bash skills/osint/scripts/exa.sh deep "<detailed prompt>"
# Parallel AI Deep Search
bash skills/osint/scripts/parallel.sh search "<detailed query>"
# Jina DeepSearch
bash skills/osint/scripts/jina.sh deepsearch "<query>"
```

**Rule:** the Level 4 prompt must be EXTENDED — include everything you already know
from Level 1-3 so deep research does not repeat basic facts and digs further instead.

## Prompt Templates (Perplexity MCP / shell)

Every OSINT query to Perplexity (`mcp__perplexity-ask__perplexity_ask`, `perplexity.sh sonar|reason|deep`) must follow the 5-part pattern. Ad-hoc queries produce summary blobs; structured queries produce source-anchored tables we can route to `investigation/findings/`.

### 5-part pattern
- **Objective:** what we're trying to determine
- **Entities:** names, aliases, domains, companies, handles, locations
- **Time window:** current / last 30 days / since YYYY-MM-DD
- **Source types:** public web, social, filings, archived pages, forums; exclude aggregators
- **Output:** table, timeline, confidence levels, direct URLs

### Reusable templates

**Entity profile** (mode: `deep` or `sonar`)
```
Use public sources only to profile <TARGET>. Identify associated social profiles,
domains, companies, locations, and public activity since <DATE>. Prioritize primary
sources (social, filings, forums); exclude news aggregators and obvious duplicates.
Output: table with source URL, evidence snippet, date, confidence (high/medium/low),
followed by a timeline of key events. End with "what is missing or weakly supported?"
```

**Network mapping** (mode: `deep`)
```
Map connections between <ENTITY_A> and <ENTITY_B>. Find shared infrastructure,
co-mentions, emails, social links, funding ties from public sources (GitHub, LinkedIn,
WHOIS, SEC filings) in the last 2 years. Return a table: nodes, edges, source URLs,
link strength (strong/moderate/weak/speculative); highlight contradictions.
```

**Event timeline** (mode: `deep`)
```
Reconstruct the timeline of <EVENT> from public mentions on forums, social, blogs,
and official statements since <DATE>. Focus on IOCs, affected parties, responses.
Output: chronological table (date, source URL, key fact, credibility grade). End
with a "gaps in evidence" list and suggested follow-up queries.
```

**Infrastructure recon** (mode: `deep`)
```
Enumerate public-facing infrastructure for <DOMAIN_OR_IP>: subdomains, hosting
provider, tech stack, linked domains, certificates, and changes since <DATE>.
Pull from Shodan/Censys/VirusTotal/CT-log-style public data. Output: table with
asset, details, source URL, last observed; end with an exposure risk assessment.
```

**Geolocation** (mode: `sonar` or `deep`)
```
Find public geolocation signals for <TARGET>. Correlate images, posts, metadata,
check-ins from Instagram/X/Telegram since <DATE>. Privacy-compliant sources only.
Output: table with estimated lat/long, source URL, confidence; note any conflicting
locations.
```

**Contradiction reconciliation** (mode: `reason`)
```
I have these conflicting claims about <TARGET>:
1. <CLAIM_A> (source: <URL_A>)
2. <CLAIM_B> (source: <URL_B>)
Reason step-by-step about which is more likely correct, what additional evidence
would resolve the conflict, and what the most plausible combined narrative is.
Output: assessment, confidence, missing evidence, recommended next queries.
```

### Routing rules
- All URLs surfaced by Perplexity go through `bash skills/osint/scripts/capture-evidence.sh` before being cited in any brief or report.
- Map Perplexity confidence (high/medium/low) to our A-F source reliability scale when writing to `investigation/findings/`.
- `reason` mode output is the preferred input to `/analyze ach` when reconciling contradictions.

## Default Perplexity entry point: `perplexity-playbook.sh`

For the first research pass on any target, run the playbook rather than crafting ad-hoc `sonar` calls. The playbook runs a fixed, target-type-specific query set in parallel, then merges citations with URL normalization and dedupe into a reproducible run directory.

```bash
# Target types: person | company | domain | incident
bash skills/osint/scripts/perplexity-playbook.sh person "jane-doe" "Jane Doe, CEO Acme"
bash skills/osint/scripts/perplexity-playbook.sh domain "acmecorp-com" "acmecorp.com"

# Fully automated pass: playbook -> capture -> persist to active case
bash skills/osint/scripts/perplexity-playbook.sh company "acme-inc" "Acme Inc" \
  --capture --case case-015-linkedin-algorithm
```

Output lives at `/tmp/osint-<slug>-<ISO8601>/`: `evidence.json` (merged citations), `urls.txt`, `urls.tsv` (batch input for `capture-evidence.sh`), `report.md`, `run_manifest.json`. With `--case`, artifacts are copied to `investigations/<case>/investigation/evidence/raw-collections/`.

**Use `perplexity.sh` modes directly only for follow-up queries outside the target-type doctrine** (e.g., `reason` for contradiction reconciliation, `deep` for a specific Level 4 deep dive). The playbook is the default so that first-pass research is uniform, auditable, and parallel.

## Swarm Mode (DEFAULT)

OSINT research runs as a **swarm of parallel sub-agents on Sonnet**.
The main agent is the coordinator — it does NOT scrape itself.

### How it works:
1. Main agent runs Phase 0 (tooling check) and Phase 1 (seed collection) to get initial context
2. Main agent spawns 3-5 sub-agents via `sessions_spawn` with `model: sonnet`, `mode: run`
3. Each sub-agent gets a focused task + all known data from Phase 1
4. Sub-agents return results → main agent merges into dossier

### Task split pattern:
- **Agent 1: YouTube/Content** — extract transcripts via Apify (NOT yt-dlp, NOT BrightData — YouTube blocks them). 3-5 videos, speech style, topics. Use `streamers/youtube-channel-scraper` for channel data
- **Agent 2: Facebook deep** — BrightData scrape: profile, posts, about, photos, friends (use m.facebook.com for more data). For public Pages: `apify/facebook-pages-scraper` + `apify/facebook-page-contact-information`
- **Agent 3: Social platforms** — Instagram (Apify + tagged/comments scrapers), DOU, company websites, LinkedIn (BrightData). Contact enrichment: `vdrmota/contact-info-scraper` on found websites
- **Agent 4: TikTok + Regional** — TikTok profile/videos (`clockworks/tiktok-profile-scraper`), local registries, press, university records, Yandex search, Google Maps (`compass/crawler-google-places` if business owner)
- **Agent 5: Deep research** — Perplexity deep, Exa deep, Parallel deep (if needed)

### Rules:
- Always pass ALL known data to each sub-agent (names, URLs, emails, phones, context)
- Each sub-agent saves results to `/tmp/osint-<subject>-<task>.md`
- Main agent waits for all results, then runs Phase 3-6 (cross-reference, psychoprofile, dossier)
- Budget: each sub-agent ≤$0.15, total swarm ≤$0.50
- YouTube transcripts: use **Apify** actors, NOT BrightData or yt-dlp (both blocked by YouTube)

### Why swarm:
- 5 agents × 5 min = 10 min total (vs 30+ min sequential)
- Sonnet is 5x cheaper than Opus
- Parallel scraping avoids rate limit stacking on single IP

---

## Phase 0: Tooling Self-Check

1. Execute `bash skills/osint/scripts/diagnose.sh`.
2. Log available vs missing tools.
3. Check optional internal intelligence sources (Telegram recon CLI, local email client, CRM/notes archive). Skip Phase 1.5 entirely if none are configured.
4. If Bright Data unavailable → Facebook and LinkedIn deep scrape limited. Inform user.
5. If Apify unavailable → Instagram and LinkedIn structured data limited.
6. Proceed with available toolset.

## Phase 1: Seed Collection

**Start with Level 1 (quick answers) ALWAYS before heavy scraping.**

1. Parse user input. Extract identifiers: names, handles, URLs, companies, locations.
2. **Perplexity fast pass (default first-pass OSINT):**
   - Claude orchestration: call MCP tool `mcp__perplexity-ask__perplexity_ask` with the question. Returns AI answer + citations in-session.
   - Bash pipeline fallback: `bash skills/osint/scripts/perplexity.sh search "Who is <Name>, <context>"` (ranked web results) or `sonar` (AI answer).
3. **Brave + Parallel in parallel:**
   ```bash
   web_search "<Name> <company>"
   bash skills/osint/scripts/first-volley.sh "Full Name" "context"
   ```
4. **Review Perplexity citations** — fetch and verify top sources:
   ```bash
   web_fetch "<citation_url_1>"
   web_fetch "<citation_url_2>"
   ```
5. Parse & merge: `bash skills/osint/scripts/merge-volley.sh /tmp/osint-<timestamp>`.
6. Collect all identifiers into seed list. Deduplicate.
7. Flag name collisions (common names → verify with company/location cross-reference).
8. **Decision point:** enough context? → skip to Phase 4. Need social media? → Phase 2. Need deep dive? → Level 4 (deep research).

**Rate limiting:** wait 1s between Brave queries, 2s between Jina calls.
Do NOT hammer APIs in tight loops — stagger parallel launches.

## Phase 1.5: Internal Intelligence (Optional)

**Before going external, check what you already know.** This phase is optional and applies
only when you have local/internal sources that may contain relevant history on the target:
prior conversations, email archives, CRM cards, or notes. Skip entirely if none apply.

### Telegram History (if you have a Telegram session + recon tool)
The `tgspyder` CLI (third-party, see README) or equivalent Telegram OSINT tool can pull
public group membership, chat messages, and user lookups. Use only on data you are
authorized to access.

**What to extract from Telegram history:**
- Communication style (formal/informal, language, emoji patterns)
- Topics discussed — what they care about, what they ask for
- Response patterns — reply speed, active hours → timezone
- Shared links/files — projects they work on
- How they address the user — relationship dynamics
- Mentioned colleagues, partners, competitors → social graph seeds
- Pricing discussions, deal terms (if business contact)

⚠️ **Telegram history is Grade A intelligence** — unfiltered, real-time, authentic.
Weight it higher than curated LinkedIn/Instagram profiles.
⚠️ **Privacy:** internal intelligence stays in the dossier. Never quote DMs in public outputs.

### Email History (if you have a local email CLI/archive)
Any local email client (himalaya, mutt, notmuch, etc.) or mail archive can be searched
for prior correspondence with the target or their domain.

**What to extract from email:**
- Formal communication style vs Telegram style (contrast = insight)
- Business proposals, invoices → financial relationship
- CC'd people → organizational map
- Signature block → title, phone, company, social links (often richer than LinkedIn)

### CRM / Notes Check (if you have a local knowledge base)
If you maintain a CRM, vault, or notes system (Obsidian, Notion export, plain-text notes),
check for existing cards on the target before starting external research. Enrich the
existing card after research completes instead of duplicating.

### Internal Intelligence Summary
After Phase 1.5, you should know:
- Do we have prior relationship? (cold/warm/hot contact)
- What language do they prefer?
- What's their communication style?
- Any existing business context?
- Social graph seeds from conversations

This context shapes Phase 2 priorities — if we already know their career from emails,
focus external research on psychoprofile and social media instead.

## Phase 2: Platform Extraction

Read `references/platforms.md` ONLY when needing URL patterns or extraction signals.

Tool priority (primary → fallback). **If primary fails, switch immediately. Never retry same tool.**

- LinkedIn: `apify.sh linkedin` → `brightdata.sh scrape` → `jina.sh read`
- Instagram: `apify.sh instagram` → `brightdata.sh scrape`
- Instagram deep: `run-actor.sh "apify/instagram-tagged-scraper"` (who tags them), `apify/instagram-comment-scraper` (sentiment)
- Facebook personal: `brightdata.sh scrape` → none (only Bright Data works)
- Facebook pages/groups: `run-actor.sh "apify/facebook-pages-scraper"` → `brightdata.sh scrape`
- TikTok: `run-actor.sh "clockworks/tiktok-profile-scraper"` → `clockworks/tiktok-scraper` (comprehensive)
- TikTok discovery: `run-actor.sh "clockworks/tiktok-user-search-scraper"` (find by keywords)
- YouTube: `run-actor.sh "streamers/youtube-channel-scraper"` → `jina.sh read` → `brightdata.sh scrape`
- Telegram channels: `web_fetch t.me/s/{channel}` → `jina.sh read`
- Twitter/X: `python3 scripts/twitter.py tweet <url>` → `jina.sh read`
- Google Maps (businesses): `run-actor.sh "compass/crawler-google-places"`
- Contact enrichment: `run-actor.sh "vdrmota/contact-info-scraper"` (extract emails/phones from any URL)
- Any site: `jina.sh read` → `brightdata.sh scrape`

**run-actor.sh** = universal Apify runner (embedded, 55+ actors). See `references/tools.md` for full actor catalog.

Read `references/tools.md` ONLY when troubleshooting a failed tool.

### ⚠️ Content Platform Rule (CRITICAL)

When you find YouTube, podcast, blog, or conference talks — read `references/content-extraction.md` **immediately** and extract 3-5 pieces of content on the spot.

Do NOT just note the URL. Extract transcripts/text NOW.
A 20-minute YouTube video reveals more about a person than their entire LinkedIn.
Content platforms are the #1 source for psychoprofile — skipping them = shallow dossier.

### OpSec-Aware Targets

If initial searches return unusually little for someone who should have a footprint:

1. **Wayback Machine:** `web_fetch "https://web.archive.org/web/2024*/target-url"` — deleted profiles, old bios
2. **Google Cache:** `web_search "cache:domain.com/path"` — recently removed pages
3. **Yandex Cache:** `brightdata.sh search-yandex "Name"` — Yandex indexes CIS deeper and caches longer
4. **Username variations:** try transliteration of non-Latin names (e.g., Ivanov → ivanov / ivanoff), birth year suffixes, company abbreviations
5. **Reverse image search:** if photo found, check for other profiles using same avatar
6. **Conference archives:** speaker bios often survive after profiles are deleted

## Phase 3: Cross-Reference & Confidence Scoring

### Step 1: Fact Table
List every claim as a row: fact | source 1 | source 2 | grade.

### Step 2: Cross-check key facts
For each critical fact (employer, role, location, education):
- Compare LinkedIn title vs Telegram signature vs email signature vs company website
- If 2+ match → Grade A
- If only 1 source → Grade B
- If inferred (timezone from messages, geotag) → Grade C
- If single unverified mention → Grade D

### Step 3: Resolve contradictions
If LinkedIn says "CEO" but company site says "Co-founder" — flag explicitly. Include both with sources. Do NOT silently pick one.

### Step 4: Name collision check
If common name — verify at least 2 facts (company + city, or photo + company) link to same person. If unsure, split into separate entities.

### Confidence grades:

- **A (confirmed)**: 2+ independent sources, or official/verified profile, or direct Telegram/email conversation
- **B (probable)**: 1 credible source (LinkedIn, official media, company site)
- **C (inferred)**: indirect evidence (photo geotag, timezone from message patterns, connections)
- **D (unverified)**: single mention, could be wrong

Internal intelligence (Phase 1.5) counts as an independent source.

## Phase 4: Psychoprofile

Read `references/psychoprofile.md` ONLY at this phase.

1. Collect text samples: posts, bios, interviews, channel content, **Telegram messages** (highest signal).
2. Assess MBTI per dimension with cited behavioral evidence and confidence (high/medium/low).
3. Quantify writing style: sentence length, emoji density, self-reference rate.
4. **Compare formal (LinkedIn/email) vs informal (Telegram/Instagram) voice** — the delta reveals the real person.
5. Deduce values from actions, not self-reported claims.
6. Zodiac ONLY if DOB confirmed (Grade A or B).

## Phase 5: Completeness Evaluation (Recursive)

### Axis 1: Data Coverage (pass/fail per dimension)

9 mandatory checks. If any fail, flag as critical gap:

1. Subject correctly identified? (not a namesake)
2. Current role/company confirmed?
3. At least 2 social platforms found?
4. At least 1 contact method (email/phone/messenger)?
5. Career history has 2+ verifiable positions?
6. Location (current) established?
7. At least 1 photo found?
8. No unresolved contradictions between sources?
9. Internal intelligence checked? (Telegram/email/vault — even if empty)

### Axis 2: Depth Score (8 weighted criteria)

| Dimension | Weight | What to score (1-10) |
|-----------|--------|---------------------|
| Identity | 0.15 | Full name, DOB, location, education, photo |
| Career | 0.20 | Completeness of work history, current role clarity |
| Digital footprint | 0.15 | Number of platforms found, account activity level |
| Psychoprofile | 0.15 | MBTI confidence, writing style quantified, values deduced |
| Internal intel | 0.10 | Telegram/email history depth, vault data |
| Personal life | 0.05 | Family, hobbies, lifestyle, pets |
| Cross-reference | 0.10 | How many facts are A-grade, contradiction count |
| Actionability | 0.10 | Entry points identified, approach strategy clear |

Weighted sum (1-10) = **Depth Score**.

### Axis 3: Source Diversity

Count unique source types used (max 12):
LinkedIn, Instagram, Facebook, Telegram DM, Telegram channel, VK, Twitter/X,
company website, press/media articles, conference profiles, government/business registries,
email correspondence.

- 8+ source types = Excellent
- 5-7 = Good
- 2-4 = Shallow
- 1 = Insufficient

### Gap Analysis

| Depth Score | Coverage | Diagnosis | Action |
|------------|----------|-----------|--------|
| 8+ | All pass | Strong dossier | Proceed to Phase 6 |
| 8+ | Some fail | Deep but blind spots | Target failed checks, 1 more cycle |
| <7 | All pass | Wide but shallow | Deepen via interviews/articles/deepsearch |
| <7 | Some fail | Restart needed | Different search angle, new tool combination |

### Stopping Criteria

**(a)** Depth Score ≥ 8.0 AND all coverage checks pass → exit to Phase 6
**(b)** 3 cycles completed → deliver best available with honest assessment
**(c)** Two cycles with delta < 0.5 → plateau reached, deliver with note

### Calibration Benchmarks

- **9-10**: full career timeline, 5+ platforms, confirmed DOB, psychoprofile with high confidence, family/hobbies known, multiple entry points, Telegram history analyzed. Equivalent to a professional PI report.
- **7-8**: career outline, 3+ platforms, most facts B-grade or above, psychoprofile with medium confidence. Solid due diligence.
- **5-6**: basic bio, 1-2 platforms, some gaps. Quick background check level.
- **<5**: minimal data found. Name + current role at best. Flag as insufficient.

## Phase 6: Dossier Output

Read `assets/dossier-template.md` before rendering. Follow the template structure exactly.
No markdown tables in output (Telegram cannot render). Bullet lists only.
Report Depth Score, source count, source types, and total API spend.

If internal intelligence was used, add a separate **"Internal intelligence"** section
(marked as internal/confidential, not for sharing outside).

## Budget

- ≤$0.50 per target: spend without asking.
- >$0.50: ask user before proceeding.
- Track cumulative spend per research session.

## Troubleshooting

- **All tools return empty**: target has minimal digital presence. Try Bright Data Yandex search (better for CIS region), search by company + role instead of name.
- **Wrong person keeps appearing**: add company name, city, or role to all queries. Use quotes around full name.
- **LinkedIn blocked**: use `brightdata.sh scrape` as primary instead of Apify.
- **Apify actor dead/changed**: check `apify.sh store-search "linkedin scraper"` for alternatives. Actors on Apify are volatile — always have a Bright Data fallback.
- **Depth Score stuck at 6-7**: likely missing press/media articles or internal intel. Search industry publications (AdIndex, Sostav, Forbes, Kommersant for Russian market). Try `jina.sh deepsearch`. Check Telegram history.
- **No social media found**: person may use pseudonyms. Search by email, phone, or company employee page. Search Apify store: `bash scripts/apify.sh store-search "people search"`. If `mcpc` installed: `APIFY_TOKEN=$APIFY_API_TOKEN mcpc --json mcp.apify.com --header "Authorization: Bearer $APIFY_TOKEN" tools-call search-actors keywords:="people search" limit:=10`. Check Telegram contacts by phone.
- **TikTok scraper fails**: try `clockworks/free-tiktok-scraper` (free tier) as fallback. TikTok usernames often differ from other platforms — search by real name via `clockworks/tiktok-user-search-scraper`.
- **Need emails from website**: use `vdrmota/contact-info-scraper` — it crawls the site and extracts all contact info.
- **Rate limited (429)**: back off 5s, then 15s. Switch to fallback tool. Never retry immediately.

## Anti-Patterns

1. Never start with a single tool. Launch all available in parallel.
2. Never retry a failed tool more than once. Switch to fallback.
3. Never guess DOB, family, or zodiac.
4. Never attribute data without cross-referencing against namesakes.
5. Never include unsourced facts.
6. Never reveal OSINT methods in public messages.
7. Never exceed 3 recursive cycles. Diminishing returns.
8. Never rate Depth Score 9+ without justification.
9. Never skip psychoprofile. Without it, dossier = Wikipedia article.
10. Never skip Phase 1.5 (internal intel). Telegram history is often the richest source.
11. Never quote DMs verbatim in shareable outputs. Summarize and cite.
12. Never hammer APIs without rate limiting. Stagger requests.
