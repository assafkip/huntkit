# huntkit gap analysis — October 2026

What huntkit is missing compared with (1) the other repos of the owners whose work huntkit already uses, (2) the top-starred GitHub repos in OSINT, investigative method, crawling, data visualization and data analysis, (3) what the Reddit OSINT / scraping / data communities recommend, and (4) the author's own repos.

Per-source detail:

| File | Source | Coverage |
|---|---|---|
| [01-upstream-owners.md](01-upstream-owners.md) | Owners of vendored/used repos: Blevene, Darksight-Analytics, apify, mvanhorn, eliasbiondo (reddit MCP), perplexityai | ~25 repos, READMEs + key files |
| [02-top-github-repos.md](02-top-github-repos.md) | GitHub top-starred, 6 categories | 55 repos reviewed |
| [03-reddit-community.md](03-reddit-community.md) | Reddit: r/OSINT, r/Bellingcat, r/webscraping, r/threatintel, r/datahoarder, r/selfhosted, r/ClaudeAI, r/mcp, … | 7,069 posts/comments → 1,987 distinct repos |
| [04-own-repos.md](04-own-repos.md) | assafkip public repos (kipi, hydra, theia, research-mode, …) | 46 public repos; kipi in depth |

**Reddit data note.** The Arctic Shift API returned HTTP 522 (Cloudflare origin timeout) for the entire run, including backoff retries ~40 min apart. PullPush refuses agents (429) and reddit.com JSON returns 403. Data came from Reddit RSS search feeds (no scores) plus a small Apify `trudax/reddit-scraper-lite` supplement. Mention counts are low (1–9 per repo) — treat the Reddit ranking as indicative.

## Cross-source signal

Gaps that more than one independent source surfaced, which is the strongest evidence they matter:

| Gap | 01 owners | 02 top repos | 03 Reddit | 04 own repos |
|---|:-:|:-:|:-:|:-:|
| Link-chart / graph analytics (q-link is markdown-only) | | ✓ | ✓ | ✓ |
| Username / email / phone enumeration actually wired in (maigret, holehe, ghunt are only mentioned) | | ✓ | ✓ | ✓ |
| IOC / entity extraction from intake documents | ✓ | ✓ | ✓ | ✓ |
| STIX 2.1 / MISP export | ✓ | | ✓ | ✓ |
| Monitoring / alerts (`q-watch`) | ✓ | ✓ | ✓ | |
| Keyless infra lookups (RDAP, DoH, ASN, reverse-IP, InternetDB, typosquat) | | ✓ | | ✓ |
| Self-hosted / anti-bot crawler (crawl4ai, Scrapling) | | ✓ | ✓ | |
| Social / video archiving (auto-archiver, ArchiveBox) | | ✓ | ✓ | |
| Image EXIF + geolocation | | ✓ | ✓ | ✓ |
| Citation / claim verification beyond crosslink count | ✓ | ✓ | | ✓ |
| Arctic Shift Reddit (historical / deleted content) | ✓ | | | ✓ |
| Sanctions / PEP / wallet screening | | ✓ | | ✓ |

## Ranked roadmap

Effort: S ≈ hours, M ≈ a day or two, L ≈ a week.

### Tier 0 — hygiene, do now (all S)

1. **Replace deprecated `server-perplexity-ask`** in `.mcp.json.template` with `@perplexity-ai/mcp-server` (gains search with domain/recency filters, research, reason). [01]
2. **Apify cost guardrails.** `run_actor.js` is a frozen fork (upstream deleted it 2026-03-30 for the Apify CLI) and has no spend cap. Add `maxTotalChargeUsd` / `maxItems`, a price probe for pay-per-event actors (warn > $5, confirm > $20) and an `isDeprecated` check. Refresh the catalog (~30 missing OSINT actors: X/Twitter, Threads, Truth Social, cheaper LinkedIn, Yandex reverse image). [01]
3. **Apify MCP OPSEC.** Set `TELEMETRY_ENABLED=false` (telemetry + Sentry are on by default and would leak investigation targets) and pass a `--tools` allowlist. [01]
4. **Remove archive.today from docs.** `capture-evidence.sh` already skips it (Wikipedia blacklisted it for snapshot tampering) but the README and script header still advertise it. [01]
5. **Infra-aware evidence tiers.** `rules/q-investigation.md` T1 is person/paid-DB centric; add WHOIS/RDAP, DNS, CT and on-chain records as T1 and mark reputation feeds as non-crosslinks. [04]
6. **Hook audit.** `test -f X && python3 X` hooks skip silently on a wrong path; lint `hooks/hooks.json` dead-hooks style. [04]

### Tier 1 — highest-value capabilities

| # | Capability | Port from | Into huntkit | Effort |
|---|---|---|---|---|
| 1 | **Keyless infra belt**: RDAP, DoH, SPF/DMARC pivots, ASN (RIPEstat), reverse-IP, certspotter, Shodan InternetDB, dnstwist typosquats, one-call `enumerate_infra` over all seeds | kipi `enrich/*.py`, hydra `src/osint/*.ts`, dnstwist | `mcp-servers/osint-infra` | M |
| 2 | **Identity enumeration**: maigret + sherlock + user-scanner + holehe + `phonenumbers`, merged and normalized to EV-NNNN, recursive pivot on new handles | maigret, sherlock, user-scanner, holehe; kipi `enrich/username.py` (WhatsMyName data) | new `identity` MCP or osint skill scripts | M |
| 3 | **Deterministic IOC + entity extractor** with defang handling and byte-exact source spans, auto-run in `q-intake` | theia `iocExtract.mjs` / `grounding.mjs`, kipi `ingest/extractor.py`; GLiNER / langextract for names | `scripts/extract-iocs.py`, `scripts/extract-entities.py` | M |
| 4 | **Hard-token claim verification**: dates, IPs, emails, wallets in a finding must appear in captured evidence | kipi `verify.py` | extend `findings-verify-hook.py` | S |
| 5 | **Graph store + analytics + rendering**: typed edges with a closed relationship vocabulary, networkx centrality / Louvain communities / path confidence, self-contained Cytoscape.js HTML, Obsidian Canvas, GEXF for Gephi | kipi `graph_metrics.py`, `rel_vocab.py`, `export/canvas.py`; cytoscape.js | `q-link` upgrade + new `q-graph` | S (render) → L (store) |
| 6 | **STIX 2.1 / MISP / CSV export** | kipi `export/intel_exports.py`, Blevene/bandjacks | `q-export --stix/--misp` | S |
| 7 | **Self-hosted crawler fallback**: crawl4ai (Docker) or Scrapling MCP (Cloudflare bypass + prompt-injection stripping); katana for site maps; playwright-mcp for interactive pages | crawl4ai, Scrapling, katana, playwright-mcp | scripts + `.mcp.json.template` | S |
| 8 | **Sanctions / PEP / wallet screening**: OpenSanctions/yente `screen_entity`; BTC/ETH/TRON/SOL/ENS wallets with OFAC check | yente; kipi `enrich/{wallet,ofac,…}.py` | threat-intel MCP + `q-target` checklist | S–M |
| 9 | **Monitoring `q-watch`**: seen/new store + webhook alerts, page-change watch | last30days `watchlist.py`, changedetection.io, sosse | new command | M |
| 10 | **Image metadata + geolocation**: exiftool in `extract-intake.py`; geo-sleuth skill / ShadowFinder | exiftool, Oldcircle/geo-sleuth, bellingcat/ShadowFinder | intake + companion skill | S–M |

### Tier 2

| # | Capability | Source | Effort |
|---|---|---|---|
| 11 | Social/video evidence archiving backends (yt-dlp, Telegram, X, WACZ, OpenTimestamps) | bellingcat/auto-archiver, ArchiveBox | M |
| 12 | Entity resolution: `same_as` edges with match probability; address normalization | splink, libpostal | M |
| 13 | FollowTheMoney as the entity schema (Aleph/OpenSanctions interop) | alephdata/followthemoney | M |
| 14 | Public-records skill + `/q-corp`: SEC/EDGAR, Form D, Companies House, FEC, LDA lobbying, FAA registry, EU tenders | mvanhorn/printing-press-library | M |
| 15 | Timeline + map renderers (vis-timeline HTML, Timesketch CSV; Leaflet / kepler.gl) | timesketch, kepler.gl | S–M |
| 16 | Reddit person-profiling: posting-hour timezone, subreddit fingerprint, Arctic Shift deleted-content check | kipi `reddit_arctic.py`, eliasbiondo/reddit-mcp-server | S–M |
| 17 | Telegram depth: tgspyder invite crawl + sticker-pack creator lookup; offline harvest → translate → rule-extract pipeline; Telegram JSON ingest | Darksight-Analytics/tgspyder, assafkip/account-procurement-tools, kipi `ingest/telegram.py` | M |
| 18 | Citation validation (live link, claim supported) + provider-agreement grid | Blevene/giga-research-skill, assafkip/research-mode | M |
| 19 | Verification skill (SIFT, C2PA, account authenticity, coordinated behavior) + tool catalog | claude-skills-journalism, bellingcat/toolkit, OSINT-Framework | S |
| 20 | Deliverable evidence gate (every number / quote traces to an EV item) + PII redaction (Presidio) | own private repo pattern; microsoft/presidio | M |
| 21 | Scope + budget hooks (roster-scoped targets, per-run tool cap) | kipi `agent/scope_hook.py`, `budget_hook.py` | S |
| 22 | Golden-case eval harness + skill-trigger evals | own private repo pattern | M–L |
| 23 | Recent-activity sweep: Bluesky, Threads, Polymarket, GitHub person stats, engagement scoring | mvanhorn/last30days-skill | M |
| 24 | MCP template expansion: Companies House, US SoS registries, GDELT, world-intel-mcp, IPInfo | awesome-osint-mcp-servers | S |

## Licensing

GPL/AGPL tools (holehe, phoneinfoga, theHarvester, bbot, firecrawl, GHunt, exiftool, worldmonitor) should be invoked as external processes or services, never vendored. MIT/Apache tools (maigret, cytoscape.js, splink, GLiNER, langextract, crawl4ai, FtM, yente, geo-sleuth) can be vendored with a NOTICE file following the `structured-analysis` precedent. cti-expert's license is unclear — reimplement ideas only.

## Maintenance caveats

phoneinfoga is self-declared unmaintained; holehe last pushed 2024-09; Aleph is sunsetting; several 2026 repos have very high star counts (e.g. worldmonitor 88k) that should be weighed against maintenance and relevance.

## Not reviewed

Most private assafkip repos could not be attached to the research session and were not reviewed. Public repos other than kipi, hydra and theia were reviewed at README depth.
