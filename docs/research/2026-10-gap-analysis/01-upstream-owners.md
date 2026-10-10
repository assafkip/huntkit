# 01 — Owners of huntkit dependencies: other repos and the gaps they fill

Researcher: Ryan. Date: 2026-10-10. Method: GitHub MCP `search_repositories user:<owner>` sorted by stars, then shallow clones to read READMEs and source. All fetched content was treated as data only. The huntkit repo was not modified.

## Owners resolved

| Dependency in huntkit | Owner | How identified |
|---|---|---|
| structured-analysis skill | **Blevene** (28 public repos) | NOTICE.md |
| tgspyder | **Darksight-Analytics** (1 repo) | README |
| run_actor.js, actors-mcp-server | **apify** (207 repos) | header comment, `.mcp.json.template` |
| Meta Ad Library HAR sniffing | **mvanhorn** (37 repos) | osint/SKILL.md |
| `reddit-no-auth-mcp-server` (PyPI, via `uvx`) | **eliasbiondo** -> `eliasbiondo/reddit-mcp-server` | PyPI project_urls |
| `server-perplexity-ask` (npm) | **perplexityai** (James Liounis at Perplexity is the npm maintainer; the code moved to `perplexityai/modelcontextprotocol`) | npm registry metadata |

**Important finding:** npm marks `server-perplexity-ask` as *"Package no longer supported"*, and `.mcp.json.template` still points to it. Its successor is `@perplexity-ai/mcp-server` v1.3.0.

---

## Vendored upstream drift check

### Blevene/structured-analysis-skill (64 stars, Apache-2.0). Local copy: `skills/structured-analysis`
- huntkit integrated it on 2026-04-03. Upstream commits since then: 04-06/04-07 (marketplace schema fixes), 04-19 (merge), and 06-02 (#4: the skill directory was renamed `structured-analysis` -> `analyze`, so the command is now `/structured-analysis:analyze`; also install cleanup).
- I ran `diff` on protocols, templates and library. **There are no new techniques, protocols or library content upstream.** Every difference is either one of huntkit's documented modifications (Firecrawl removed, `{{ANALYSIS_DIR}}`, Agent tool naming) or upstream's command namespacing.
- **What huntkit lacks:**
  - `example_analysis/`: a complete worked run (report, ACH matrix, assumptions, counterfactual, premortem, what-if, review-summary, next-steps, iteration-context). It would make a good few-shot reference or regression fixture.
  - `helper_scripts/extract_docx_text.py`: redundant, because `extract-intake.py` already covers this.
- **Not upstream, but a gap:** `library/05-66-techniques-taxonomy.md` lists 66 techniques and only 18 have protocols. Good candidates for new protocols are Indicators/Signposts, Analysis of Competing Hypotheses for Deception (MOM/POP/MOSES/EVE), Network Analysis, Chronologies, and Argument Mapping.
- Difficulty **S**. Optionally copy example_analysis into `skills/structured-analysis/examples/`. Do not adopt the namespacing change; huntkit's `/analyze` wiring differs.

### apify/agent-skills (2,418 stars, Apache-2.0). Local copy: `skills/osint/scripts/run_actor.js` ("Embedded v1.3.0")
- **Upstream deleted `run_actor.js` on 2026-03-30** (commit 23d51be, "migrate skills to CLI"). The skill now runs on the Apify CLI (`apify actors search|info|call|start`, `apify runs info`, `apify datasets get-items`) with `--json` and `--user-agent`. huntkit's copy is a frozen fork that no longer receives fixes.
- Upstream now has `references/gotchas.md` and huntkit has **no equivalent**:
  - **Cost guardrails.** Read `.currentPricingInfo.pricingModel` and `pricePerEvent`, estimate cost for pay-per-event (PPE) Actors, warn above $5, and require confirmation above $20. Use `maxTotalChargeUsd` and `maxItems` as run options. `grep` shows that huntkit's `run_actor.js`, `run-actor.sh` and `apify.sh` have **no cost cap at all**.
  - **Deprecation check.** Check `.isDeprecated` and search for a replacement.
  - Fire-and-forget runs (`start` plus polling) for jobs longer than 10 minutes. Field-name variance (`maxResults`, `resultsLimit`, `maxItems`). Per-platform rate limits (Instagram under 200 per run; LinkedIn under 100 per batch with at least 5 minutes between runs).
- `references/actor-index.md` has 133 actors. **About 80 are missing from huntkit's catalog.** The ones that matter for OSINT:
  - **X/Twitter (none at all in huntkit):** `apidojo/tweet-scraper`, `twitter-user-scraper`, `twitter-profile-scraper`, `twitter-list-scraper`.
  - **LinkedIn (huntkit only has `supreme_coder`):** `harvestapi/linkedin-profile-search-by-name`, `linkedin-profile-scraper` (returns email), `linkedin-company`, `linkedin-profile-posts`, `linkedin-post-comments`.
  - **Other platforms and content:** `apify/threads-profile-api-scraper`, `tri_angle/truth-scraper`, `tri_angle/telegram-scraper`, `tri_angle/snapchat-scraper`, `curious_coder/youtube-transcript-scraper`.
  - **Cross-platform and monitoring:** `tri_angle/social-media-finder`, `tri_angle/website-changes-detector`, `apify/facebook-hashtag-scraper`, `apify/instagram-topic-scraper`.
  - **Crawling and lookup:** `apify/website-content-crawler`, `apify/camoufox-scraper` (anti-bot), `apify/sitemap-extractor`, `tri_angle/bing-search-scraper`, `tri_angle/redfin-detail` and `real-estate-aggregator` (property), and `janbuchar/github-contributors-scraper`.
- 15 workflow playbooks: company-research, contact-enrichment, competitive-intel, brand-monitoring, influencer-vetting, review-analysis, job-market and others.
- The 2026-10-08 commit documents **`apify/web-fetch`, a "Server Actor"**: `POST https://web-fetch.apify.actor/` with `{"url","formats":["markdown"]}` returns content synchronously, with JS rendering and anti-bot handling and without starting a run. It is a cheap single-URL fetch tier between Jina and Bright Data.
- **Integration (S–M):**
  1. Port gotchas.md cost and deprecation rules into `run_actor.js`. Add `--max-charge-usd` and `--max-items`, and pass them as query params on `POST /v2/acts/{id}/runs`.
  2. Add a pre-run pricing probe.
  3. Merge the missing actors into `references/tools.md`.
  4. Add `web-fetch` to `apify.sh`.
  5. Optionally switch to the Apify CLI as upstream did.

---

## Per-repo findings

### Blevene

**Blevene/bandjacks** (26 stars, Apache-2.0). Cyber-threat-intel world model: LLM extraction of MITRE ATT&CK techniques from reports, a Neo4j knowledge graph, OpenSearch vectors, STIX 2.1 bundles with provenance, D3FEND defensive mappings, technique co-occurrence analytics, and Attack Flow generation, with a Next.js review UI.
- **huntkit lacks:**
  - (a) **STIX 2.1 export.** `bandjacks/llm/stix_builder.py`, 519 lines, builds report, identity, malware and tool, attack-pattern, vulnerability, indicator and hash objects, plus relationships and provenance.
  - (b) **Structured entity extraction.** `entity_extractor.py`, `entity_batch_extractor.py` (JSON-schema LLM output: name, type, confidence, evidence) and `entity_consolidator.py`.
  - (c) **Entity resolution and alias matching.** `entity_resolver.py`, the ActorCache with fuzzy alias search, and `config/entity_ignorelist.yaml`, which keeps vendors and researchers from being extracted as actors.
  - (d) **ATT&CK mapping** for cyber cases, including CVE-to-technique mapping.
  - (e) **Co-occurrence and clustering analytics** (`analytics/cooccurrence.py`, `clustering.py`) as a model for link analysis over case entities.
- **Integration (M for the STIX exporter; L for the full graph stack).**
  - Port stix_builder into `q-export --format stix`, mapping EV-NNNN evidence to `report` and `observed-data` and graph edges to `relationship`.
  - Port the entity extractor and ignorelist into a `/q-entities` command that writes `entities.json` and feeds `q-link`.
  - Do not adopt the Neo4j/OpenSearch stack.

**Blevene/giga-research-skill** (4 stars, Apache-2.0). Fans a research prompt out in parallel to Claude web-search, OpenAI deep research and Gemini deep research, then reconciles the results.
- **huntkit lacks:**
  - (a) **Multi-depth citation validation** (`validation/citations.py`). Depth 0 does nothing. Depth 1 checks the link is live. Depth 2 checks the content supports the claim. Depth 3 also finds a replacement for a dead citation. All of it goes to a `validation-log.md` audit trail.
  - (b) **Cross-provider comparison matrix**, a topic × provider agreement grid (`reconciliation/analyzer.py`). This turns "corroboration" into something mechanical.
  - (c) A **prompt-craft step** before dispatch.
- Note: the OpenAI deep-research models retire on 2026-12-11.
- **Integration (M):**
  - Add `validate-citations.py` to `scripts/`, called from `q-reality-check` and the findings-verify hook (huntkit's hook currently checks confidence labels only, not URLs).
  - Add a `--multi` mode to `perplexity.sh deep` / Exa / Parallel that writes `comparison-matrix.md`.

**Blevene/Daylight-know** (15 stars, Apache-2.0). Daily academic digest pipeline: arXiv, HF and OpenAlex fetch, a 30-day seen-history dedupe, interest-based LLM ranking, chunked embeddings in ChromaDB, and SMTP email delivery.
- **What huntkit could reuse:** the *seen-history dedupe plus ranked digest plus delivery* pattern for case monitoring, and OpenAlex as a source for academic or expert profiles.
- **Integration (M):** use it as a design reference for a `/q-watch` digest. Do not vendor it.

**Blevene/intel_graph_db** (0 stars, no license). An empty 2014 Neo4j stub. Skip.

Not relevant: Crimeware-In-The-Modern-Era (a paper), DataDrivenSecurity (R notebooks from a book), aenv, the badges, and the rest.

### Darksight-Analytics

**Darksight-Analytics/tgspyder** (366 stars, MIT). Telegram OSINT CLI built on Telethon.
- huntkit only uses `--members --chats` and `--user`.
- **huntkit lacks:**
  - (a) `--crawl-invites`: pulls and de-duplicates t.me invite links from chat history. This is snowball discovery of linked or private channels.
  - (b) `--sticker-pack <url>`: identifies the **sticker-pack creator ID** from the sticker set ID, a known technique for deanonymizing channel operators.
  - (c) SOCKS `--proxy socks5://127.0.0.1:9050` and `--set-proxy` for Tor/VPN OPSEC.
  - (d) The CSV output tree (`TGSpyder Output/{members,chats,crawled_links}`) is never ingested into case evidence.
- **Integration (S):**
  - Document (a)–(c) in `commands/q-osint.md`, `q-collect.md` and `references/platforms.md#telegram`.
  - Add `scripts/ingest-tgspyder.sh` that hashes the CSVs, assigns EV-IDs, and adds channel→channel edges from crawled_links to `q-link`.

### apify

**apify/apify-mcp-server** (10,335 stars, MIT; npm `@apify/actors-mcp-server` 0.17.5). huntkit runs it over stdio with `@latest`.
- **huntkit lacks:**
  - (a) **The hosted Streamable-HTTP endpoint `https://mcp.apify.com`.** It supports OAuth and "output schema inference", which stdio does not. The `/sse` endpoint has been removed.
  - (b) **The `--tools` / `?tools=` allowlist.** It can pin OSINT actors as first-class tools, for example `tools=actors,apify/web-fetch,apidojo/tweet-scraper,harvestapi/linkedin-profile-search-by-name`, instead of discovering them every time.
  - (c) **Telemetry is ON by default and Sentry is on in stdio mode.** A `report-problem` tool is auto-served to Claude clients. For investigations this is an **OPSEC leak** of what is being looked up. Set `TELEMETRY_ENABLED=false` or pass `--telemetry-enabled false`.
  - (d) The `get-dataset-items` filtering and pagination tools and `abort-actor-run`.
- **Integration (S):** edit `.mcp.json.template` (env `TELEMETRY_ENABLED=false`, `--tools ...`) and document the hosted alternative.

**apify/awesome-skills** (266 stars, Apache-2.0). These are community skills. Relevant ones:
- **apify-blocked-scrape-triage:** a cost-ordered escalation ladder.
  - Steps: (0) check your own egress (ip-api/cdn-cgi trace for the hosting flag and ASN) and DoH DNS against two resolvers; (1) a cheaper published source; (2) reachability, request rate and IP spread; (3) request fidelity; (4) session tokens; (5) the site's internal API; (6) a browser last.
  - It caps the diagnosis budget at one navigation per host.
  - huntkit has Jina, Bright Data and Apify but no escalation doctrine, and diagnostic probing is itself traffic the target sees, which matters for OPSEC.
  - **S:** new `references/blocked-scrape-triage.md`.
- **apify-ads-intelligence:** multi-platform ad libraries: Google Ads Transparency Center, TikTok Ads Library and Creative Center, LinkedIn Ad Library, and X promoted tweets (best-effort). huntkit only covers Meta. **S–M:** add the actors to `tools.md` and add an `ads` platform to `q-osint`.
- **apify-osint-threat-intel:** CVE lookups (NVD), CISA KEV, Exploit-DB PoC check, GitHub advisories, MITRE ATT&CK group lookup, paste-site breach dorks, Shodan dorks, and r/netsec. The note "one subreddit per run, always set postedAfter" is useful. huntkit's threat-intel MCP has VT, URLhaus, ThreatFox and crt.sh but **no CVE/KEV/ATT&CK**. **S–M:** add `cve_lookup` (NVD API) and `kev_check` (CISA JSON feed) tools to `mcp-servers/threat-intel`, which is better than scraping through Actors.
- **apify-yandex-image-search-api:** it points to `johnvc/yandex-reverse-image-search`. **Reverse image search is a listed huntkit gap.** **S:** add that actor to `tools.md` under a new "Image" section.
- Lower relevance: apify-job-boards/jobs-data (ghost-job flagging could help q-sec-stack), apify-verified-email-finder, apify-local-business-leads-osm, apify-app-store-intelligence.

**apify/actor-content-checker** (23 stars, Apache-2.0). Watches a CSS selector on a page, diffs it against the previous run, and emails before/after screenshots. huntkit has **no monitoring**. **S–M:** a `/q-watch` command that schedules this actor or `tri_angle/website-changes-detector` through Apify schedules, or runs the same logic locally with capture-evidence.sh and a diff.

**apify/actor-page-analyzer** (152 stars, Apache-2.0). Extracts Schema.org and JSON-LD, meta tags, XHR JSON responses, and non-default `window.*` variables, and can search for strings across all of them. This is a fast way to find hidden APIs and embedded identifiers (analytics IDs, user IDs) without a manual HAR. **S:** add it as an actor recipe that complements the printing-press HAR flow.

**apify/mcpc** (1,004 stars, Apache-2.0). A spec-complete MCP CLI client: persistent sessions, OAuth 2.1, keychain storage, `--json` code mode, grep across servers, and a credential-isolating proxy. It could replace huntkit's homegrown `scripts/mcp-client.py`, which handles Streamable HTTP/SSE tool calls only. **S.**

**apify/crawlee-python** (9,582 stars, Apache-2.0). A self-hosted crawling framework (BeautifulSoup/Parsel/Playwright, proxy rotation, sessions). It fills the "self-hosted crawler" gap, for example site-wide crawls of a target domain kept on local evidence storage. **L** (new script plus dependencies). Related: `apify/fingerprint-suite` (2,624 stars) and `apify/impit` (608 stars) for browser-impersonating local fetches.

**apify/actor-rag-web-browser** (80 stars, Apache-2.0). Search plus scrape-top-N to markdown. It overlaps with huntkit's Jina, Tavily and Exa, so it is optional.

### mvanhorn

**mvanhorn/last30days-skill** (63,858 stars, MIT). A Claude Code plugin for parallel research over the last 30 days across Reddit, X, YouTube transcripts, TikTok, Instagram Reels, HN, Polymarket, GitHub, Bluesky, Threads, LinkedIn, Meta Ads, Truth Social, Telegram, arXiv, Techmeme and Perplexity. Results are scored by engagement and synthesized by an LLM judge.
- **huntkit lacks:**
  - (a) **A person "recent activity" sweep with engagement scoring.** `--x-handle`, `--github-user` (PR velocity, top repos), and YouTube/TikTok transcripts.
  - (b) **Sources huntkit has nothing for:** Bluesky (AT Protocol, `lib/bluesky.py`), Threads, Truth Social, Polymarket and Kalshi, StockTwits and Trustpilot.
  - (c) **Weighted reciprocal-rank fusion and cross-source dedupe** (`lib/fusion.py`, `dedupe.py`, `cluster.py`, `signals.py` source-quality weights).
  - (d) **`lib/hiring_signals.py`.** Theme-keyword analysis of job posts that would strengthen q-sec-stack.
  - (e) **`watchlist.py` with `store.py`.** SQLite runs and findings with *new vs. already-seen* sightings and HTTPS-only webhook delivery to Slack and others. This is a ready-made monitoring core.
  - (f) **`lib/transcribe.py`.** Whisper fallback for media without captions.
  - (g) **`lib/html_render.py`.** Shareable HTML reports. huntkit only outputs markdown.
  - (h) **`lib/reddit_arctic.py`.** The Arctic Shift archive, a keyless Reddit archive that also preserves deleted content.
  - (i) An MCP wrapper (`mcp/`, a Go `.mcpb`).
- Caution: it can read browser cookies (`chrome_cookies.py`, agentcookie). Keep that off for investigations because of OPSEC and attribution risk.
- **Integration (M):** pick one of two options.
  - (1) List it as an optional companion plugin and call `/last30days <subject>` from `q-collect` as a "recent signal" phase, writing to `investigation/sources/`.
  - (2) Vendor `fusion.py`, `watchlist.py`, `store.py`, `bluesky.py` and `hiring_signals.py` under MIT with attribution.

**mvanhorn/printing-press-library** (2,056 stars; each CLI is Apache-2.0). 576 agent-native Go CLIs, mostly with SQLite mirrors, each with a matching `pp-<name>` skill, installed with `npx -y @mvanhorn/printing-press-library install <name>`. **Public-records CLIs huntkit lacks entirely:**
- **sec-edgar:** XBRL facts, full-text search, `insider-cluster`, 13F deltas, and a `watch` command for 8-K item codes (5.02 executive change, 2.05 restructuring).
- **company-goat:** a startup due-diligence snapshot. SEC Form D funding (`--who 'Name'` gives a serial-founder graph), EDGAR fallbacks for subsidiaries, debt and acquisitions, GitHub, HN, UK Companies House, YC, Wikidata and RDAP.
- **fec** (campaign finance) and **lda-gov** (lobbying disclosures with entity resolution and evidence-grade exports).
- **faa-registry** (owner, N-number and Mode-S hex lookups, offline registry) and **airframe** (tail-number dossiers, owner search by state, NTSB history).
- **eu-tenders** (EU procurement), **policy-intel** (Federal Register, Regulations.gov comments), **openalex** and **retraction-checker** (expert vetting), **uspto-tsdr** (trademarks).
- **github-intel**, **x-twitter** (official v2 API with a local FTS mirror), **techtwitter**, **hackernews**, **youtube** (transcripts), **google-trends**, **prediction-goat**, **serply** (Google, News, Scholar, Bing SERP diffs), **scrape-creators**, **contact-goat** (LinkedIn/Happenstance warm-intro paths; it uses cookies).
- **Caution about archive-is:** its README states that Wikipedia blacklisted archive.today on 2026-02-21 over DDoS activity and **snapshot tampering**, and says not to use it for legal evidence. huntkit's `capture-evidence.sh` already skips archive.today ("local-only mode"). However, `huntkit-capabilities.md` and the script header still advertise it, so the docs should drop it and give the reason in the evidence-standards rules.
- **Integration (M):**
  - A new `skills/public-records/SKILL.md` that routes person, company, aircraft and political-money questions to the `*-pp-cli` binaries.
  - A `scripts/install-pp.sh` that installs a curated subset.
  - A `/q-corp` command (company/beneficial-trail sweep: Form D, EDGAR, Companies House, FEC, LDA, FAA, eu-tenders).
  - Outputs are JSON and get hashed into EV-IDs.

**mvanhorn/cli-printing-press** (4,796 stars, MIT). huntkit already uses it for HAR sniffing. There is no new gap beyond the library above. The generator could produce a huntkit-specific CLI for any hidden API found with page-analyzer (L, ad hoc).

**mvanhorn/clawdbot-skill-search-x** (13 stars, MIT). xAI Responses API `x_search` with keyword, semantic, user and thread modes, a date window, handle include/exclude filters, image results and batch mode. huntkit has **no X search** (only `twitter.py tweet <url>` reading). **S:** add `scripts/xsearch.sh` (needs `XAI_API_KEY`) or the apidojo actors. It is an alternative to the X API's cost.

Skipped: clawdbot-skill-parallel (huntkit already has `parallel.sh`), polymarket (covered by last30days and prediction-goat), and the agent/infra repos (agentcookie, tincan, paperclip-*).

### eliasbiondo

**eliasbiondo/reddit-mcp-server** (158 stars, MIT; PyPI `reddit-no-auth-mcp-server` 0.1.2). Already in huntkit's template. Tools: `search`, `search_subreddit`, `get_post` (comment tree), `get_subreddit_posts`, `get_user` (activity feed) and `get_user_posts`.
- The gap is the **workflow**, not the server. `q-osint` lists "reddit" but no skill or reference doc uses these tools.
- **Missing workflow:** username → `get_user`, then:
  - an activity-hour histogram from `created_utc`, to infer timezone and sleep window;
  - a subreddit fingerprint (location subs, employer and hobby subs);
  - extraction of self-disclosures;
  - a cross-check against the Arctic Shift archive for deleted posts and comments.
- **Integration (S–M):** a `references/platforms.md#reddit` section plus `scripts/reddit-profile.py` (uses the companion library **eliasbiondo/redd**, 24 stars, MIT, sync/async with typed models and `after`/`before` date filters) that emits a CSV and a histogram PNG.

**eliasbiondo/linkedin-mcp-server** (194 stars, MIT). Playwright, logged in with a persisted session. Tools: `get_person_profile` (granular sections), `search_people`, `get_company_profile`, `get_company_posts`, `search_jobs` (filters for date, type, level, remote) and `get_job_details`.
- It fills the LinkedIn gap (huntkit only has one community Actor plus dorks).
- Requires a sock-puppet account. LinkedIn ToS and account-burn risk should be stated.
- **Integration (M):** an optional `.mcp.json.template` entry plus a sock-puppet OPSEC note in `rules/`.

**eliasbiondo/voyagr** (1 star). An early LinkedIn toolkit. Skip.

### perplexityai

**perplexityai/modelcontextprotocol** (2,555 stars, MIT; `@perplexity-ai/mcp-server` 1.3.0, also hosted at `https://api.perplexity.ai/mcp`). It is the official replacement for the deprecated `server-perplexity-ask`. Tools:
- `perplexity_search`: raw ranked results with **`search_domain_filter` and `search_recency_filter`**, and `search_type: fast`.
- `perplexity_ask`.
- `perplexity_research`: deep research.
- `perplexity_reason`.

huntkit can currently only reach search, reason and deep through `perplexity.sh` in bash, so those modes are not native in-session tools.
- **Integration (S):** swap the template entry to `npx -y @perplexity-ai/mcp-server`, or `claude mcp add --transport http perplexity https://api.perplexity.ai/mcp`. Update osint/SKILL.md (it references `mcp__perplexity-ask__perplexity_ask`) and the `perplexity_ask` tool names. Set `PERPLEXITY_TIMEOUT_MS=600000` for research calls.

**perplexityai/perplexity-cli** (`pplx`, 92 stars, binary releases, no LICENSE file). Search API rows and snippets as JSON, installed with checksum verification. It could replace the curl calls in `perplexity.sh`. Optional, **S**.

**perplexityai/search_evals** (269 stars, MIT). Harnesses for Perplexity, OpenAI, Anthropic, Exa and Parallel against BrowseComp, DeepSearchQA, HLE and WideSearch, with published scores (Perplexity is top on 3 of 4). It could justify or tune huntkit's provider routing (Perplexity → Exa → Parallel) with a small huntkit-specific benchmark. **M**, low priority.

---

## Ranked top 10

| # | Change | Source repo(s) | Difficulty | How |
|---|---|---|---|---|
| 1 | **Replace the deprecated `server-perplexity-ask`** with `@perplexity-ai/mcp-server` or the hosted endpoint. Gains native `perplexity_search` (domain and recency filters), `perplexity_research` and `perplexity_reason`. | perplexityai/modelcontextprotocol | S | `.mcp.json.template` plus the tool names in osint/SKILL.md |
| 2 | **Apify cost guardrails and refresh.** PPE price probe, `maxTotalChargeUsd`/`maxItems`, `isDeprecated` check, gotchas doc, about 30 missing OSINT actors (X/Twitter, harvestapi LinkedIn, Threads, Truth Social, social-media-finder, YouTube transcripts, Yandex reverse image), `apify/web-fetch` tier. | apify/agent-skills, apify/awesome-skills | S–M | Patch `run_actor.js` and `apify.sh`; update `references/tools.md` |
| 3 | **Harden the Apify MCP for OPSEC and use.** `TELEMETRY_ENABLED=false` (telemetry and Sentry are on by default), a `--tools` allowlist of OSINT actors, the hosted `mcp.apify.com` option. | apify/apify-mcp-server | S | `.mcp.json.template` plus a note in `rules/` |
| 4 | **Public-records skill and `/q-corp`.** sec-edgar (insider clusters, 8-K watch), company-goat (Form D, Companies House, Wikidata, RDAP), fec, lda-gov, faa-registry/airframe, eu-tenders, openalex. | mvanhorn/printing-press-library | M | New skill plus command plus `install-pp.sh`; JSON → EV-IDs |
| 5 | **Monitoring: `/q-watch`.** SQLite seen/new findings plus webhook delivery (last30days `watchlist.py`/`store.py`), page-change watch (content-checker / website-changes-detector), sec-edgar `watch`. | mvanhorn/last30days-skill, apify/actor-content-checker, Blevene/Daylight-know | M | New command plus script; Apify schedules or a local cron routine |
| 6 | **Recent-activity sweep with engagement scoring.** Bluesky, Threads, Truth Social, Polymarket, GitHub person stats, transcripts; RRF fusion and dedupe; hiring signals for q-sec-stack. | mvanhorn/last30days-skill | M | Companion plugin hook in q-collect, or vendor `fusion.py`, `bluesky.py`, `hiring_signals.py` (MIT) |
| 7 | **Telegram depth.** `--crawl-invites` snowball discovery, `--sticker-pack` creator deanonymization, Tor `--proxy`, CSV → evidence ingest. | Darksight-Analytics/tgspyder | S | Docs in q-osint/platforms plus `ingest-tgspyder.sh` |
| 8 | **Reddit person-profiling workflow.** `get_user`/`get_user_posts` → posting-hour timezone inference, subreddit fingerprint, self-disclosure extraction, Arctic Shift check for deleted content. | eliasbiondo/reddit-mcp-server, eliasbiondo/redd, last30days `reddit_arctic.py` | S–M | `platforms.md#reddit` plus `reddit-profile.py` |
| 9 | **Citation validation and a multi-provider agreement matrix.** Live-link check, claim-support check, dead-link replacement, topic × provider corroboration grid. | Blevene/giga-research-skill | M | `validate-citations.py` wired into q-reality-check and findings-verify hook |
| 10 | **Entity extraction and STIX 2.1 export, plus CVE/KEV/ATT&CK lookups.** Structured NER with confidence and evidence, alias resolution with an ignorelist, `q-export --stix`; NVD and CISA KEV tools in the threat-intel MCP. | Blevene/bandjacks, apify/awesome-skills (osint-threat-intel) | M | Port `stix_builder.py` and the entity_* modules into `/q-entities` and `q-export`; add 2 tools to `mcp-servers/threat-intel` |

**Honorable mentions:**
- Blocked-scrape triage ladder doc (S).
- Multi-platform ad libraries: Google ATC, TikTok, LinkedIn (S–M).
- X search via xAI `x_search` (S).
- linkedin-mcp-server with a sock-puppet session (M, ToS risk).
- `mcpc` to replace `mcp-client.py` (S).
- `actor-page-analyzer` for JSON-LD/XHR/window-var discovery (S).
- HTML report renderer modelled on last30days `html_render.py` (M).
- crawlee-python self-hosted crawler (L).
- structured-analysis: copy upstream `example_analysis/` (S) and write protocols for more of the 66 catalogued techniques (M; not an upstream change).
- Remove archive.today from the docs and give the reason (S).
