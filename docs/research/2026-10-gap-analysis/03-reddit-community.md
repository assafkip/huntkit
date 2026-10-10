# 03 - Reddit-mined GitHub repos for huntkit (Ryan)

Date: 2026-10-10. All fetched Reddit and README content was treated as untrusted data.

## 1. Mechanism: what worked and what did not

| Mechanism | Result |
|---|---|
| Arctic Shift API (`/api/posts/search`, `/api/comments/search`) | **Down.** HTTP 522 on every attempt: the initial probe, a backoff of 5/15/30/60s with `limit=5&after=2025-01-01`, a retry about 40 min later, and the comments endpoint too. Never usable. |
| PullPush API | HTTP 429 with the message "does not provide free scraping resources for agents". Not usable. |
| reddit.com `.json` / api.reddit.com / old.reddit `.json` | 403 or a login wall. Not usable. |
| **Reddit Atom RSS** (`/r/<sub>/search.rss?q=..&restrict_sr=on&sort=top&t=all&limit=100` and `/<thread>/.rss?limit=100`) | **Worked (primary, free).** Heavily rate-limited: about 1 request per 10s with frequent 429s. I used a 9s spacing plus 30/60/90s backoff. Collected 2,976 posts from 14 subs (2-3 queries each) and 3,428 comments from about 100 tool or recommendation threads (OSINT, Bellingcat, DataHoarder, webscraping, threatintel, netsec, AskNetsec, cybersecurity, dataisbeautiful, datascience, opensource). The selfhosted comments phase was stopped by 429s. RSS has no vote scores, so I ranked by mention and thread counts. |
| **Apify `trudax~reddit-scraper-lite`** (async `/runs` + dataset fetch; the sync endpoint was cut by the proxy) | **Worked (supplement).** 3 runs, about 800 items, **about $2.89 total**. Covered OSINT, DataHoarder, netsec, dataisbeautiful, datascience, cybersecurity, ClaudeAI and mcp (comments plus posts). It returns no upvote field in clean output. |
| WebSearch `site:reddit.com` | Weak. Mostly listicles, but it surfaced reconurge/flowsint and the r/OSINT thread "Maltego is dead, what now". |

Corpus: 7,069 unique Reddit documents, 1,987 distinct `github.com/owner/repo` references. The full ranking is in [`reddit-repos-ranked.json`](reddit-repos-ranked.json); raw scrape data was not committed.

**Caveat on signal strength:** the counts are small (1-9). Reddit users mostly name tools and rarely paste GitHub URLs, so URL counting under-counts famous tools such as sherlock, maigret and crawl4ai. Some lists also repeat across crossposts; the awesome-* lists in r/OSINT came from about 4 reposts of one link dump. The raw top of the list is dominated by off-scope r/selfhosted and r/opensource apps (immich, vaultwarden, Android FOSS apps), which I filtered out. The table below is the **in-scope** ranking for OSINT, investigations, crawling, visualization and analysis.

Notable: **assafkip/huntkit itself was mentioned** in r/ClaudeAI (/r/ClaudeAI/comments/1smh5r1) and r/threatintel (/r/threatintel/comments/1skxzv7, "Perplexity is an OSINT tool").

## 2. Ranked repos (in scope)

"Mentions" counts the Reddit documents (posts plus comments) that contain the URL. "Threads" counts distinct threads.

| # | Repo | Mentions (posts/comments) | Threads | Subreddits | Sample thread |
|---|---|---|---|---|---|
| 1 | yusufkaraaslan/skill_seekers | 9 (9/0) | 4 | ClaudeAI, mcp | /r/ClaudeAI/comments/1ok9v3d (I tested 30 community Claude skills) |
| 2 | d4vinci/Scrapling | 6 (6/0) | 4 | webscraping | /r/webscraping/comments/1n5t3p2 (Scrapling v0.3, solve Cloudflare automatically) |
| 3 | stanfrbd/cyberbro | 5 (4/1) | 4 | OSINT, threatintel, cybersecurity, selfhosted | /r/OSINT/comments/1k8am0b (graph feature); /r/OSINT/comments/1kpg96k (MCP server) |
| 4 | snooppr/snoop | 5 (5/0) | 4 | OSINT | /r/OSINT/comments/1df58x1 (Snoop v1.4.1, username search) |
| 5 | microsoft/playwright-mcp | 5 (5/0) | 4 | ClaudeAI, mcp | /r/mcp/comments/1m59pk0 (my 5 most useful MCP servers) |
| 6 | 0xMassi/webclaw | 5 (5/0) | 4 | ClaudeAI, mcp | /r/ClaudeAI/comments/1s9syoj (webclaw hit 400 stars in 8 days) |
| 7 | kaifcodec/user-scanner | 4 (2/2) | 2 | OSINT | /r/OSINT/comments/1rgqnso (user-scanner 2-in-1 email/username) |
| 8 | agentdeskai/browser-tools-mcp | 4 (4/0) | 3 | ClaudeAI, mcp | /r/ClaudeAI/comments/1l1sgb9 (built and tested 40 MCP servers) |
| 9 | sherlock-project/sherlock | 3 (3/0) | 3 | OSINT | /r/OSINT/comments/195rd2a (favourite OSINT tools) |
| 10 | smicallef/spiderfoot | 3 (3/0) | 2 | OSINT, cybersecurity | /r/cybersecurity/comments/sp144h; "SpiderFoot was dead on modern Python. It's back." |
| 11 | 3nock/sub3suite | 3 (3/0) | 2 | OSINT, cybersecurity | /r/OSINT/comments/tv7c7m |
| 12 | daijro/camoufox | 3 (3/0) | 3 | webscraping | /r/webscraping/comments/1ljk054 (fingerprint rotation) |
| 13 | biolds/sosse | 3 (3/0) | 3 | selfhosted | /r/selfhosted/comments/1ieacg9 (web archiving + crawling search engine) |
| 14 | intelowlproject/IntelOwl | 3 (2/1) | 2 | cybersecurity | /r/cybersecurity/comments/i6sj4n |
| 15 | justanotherarchivist/snscrape | 3 (2/1) | 2 | DataHoarder | /r/DataHoarder/comments/yy7tig (Backup twitter now) |
| 16 | itayrosen/parallel-browser-mcp | 3 (3/0) | 3 | ClaudeAI, mcp | /r/mcp/comments/1sm18kj |
| 17 | yt-dlp/yt-dlp (+ mikf/gallery-dl, ripmeapp/ripme) | 3 / 1 / 2 | 3 | DataHoarder, selfhosted, opensource | /r/DataHoarder/comments/tamgau (2022 convoy protest archive) |
| 18 | khashashin/ogi (OpenGraph Intel) | 2 (1/1) | 2 | OSINT, selfhosted | /r/selfhosted/comments/1rlyreh |
| 19 | be0vlk/owlculus | 2 (2/0) | 2 | OSINT | /r/OSINT/comments/1c07auh (OSINT case management) |
| 20 | mxrch/GHunt | 2 (2/0) | 2 | OSINT | /r/OSINT/comments/198t7hm |
| 21 | ArchiveBox/ArchiveBox (+ bellingcat/auto-archiver x1) | 2 / 1 | 2 / 1 | DataHoarder, threatintel, Bellingcat | /r/bellingcat/comments/1mp09m3 (tool that preserved 150,000 ...) |
| 22 | maxandrews/Epstein-doc-explorer | 2 (2/0) | 1 | dataisbeautiful | /r/dataisbeautiful/comments/1p251h4 (graph of relationships extracted with Claude) |
| 23 | frishtik/osint-tools-mcp-server | 2 (2/0) | 1 | OSINT | /r/OSINT/comments/1opzeng (AI agents + OSINT tools) |
| 24 | sparkyniner/Netryx (street-level geolocation) | 2 (2/0) | 1 | OSINT | /r/OSINT/comments/1rv9s3n (geolocated missile strikes in Qatar) |
| 25 | apify/crawlee-python, jaypyles/Scraperr, 0x676e67/rnet, thalissonvs/pydoll | 2 / 2 / 2 / 1 | - | webscraping, selfhosted | /r/webscraping/comments/1ggqylr (best AI scraping libs for python) |
| 26 | ozanunal0/viper, nikhilh-20/threatloom | 2 / 2 | 2 / 2 | threatintel, cybersecurity | /r/threatintel/comments/1kou9h0 |
| 27 | reconurge/flowsint, p1ngul1n0/blackbird, pirxthepilot/wtfis, soxoj/maigret, megadose/toutatis, Kanaries/pygwalker | 1 each | 1 | OSINT, netsec, threatintel, datascience | /r/OSINT/comments/1oe3t0q (introducing Flowsint) |

Also present but low relevance to huntkit: codegraphcontext (code graph MCP), upstash/context7, github/github-mcp-server, awesome-lists (jivoi/awesome-osint x4, hslatman/awesome-threat-intelligence, sacridini/awesome-geospatial, brucedone/awesome-crawler, edoardottt/awesome-hacker-search-engines), and danielmiessler/SecLists.

Already referenced in huntkit (as CLI instructions, not packaged): holehe (skills/osint/SKILL.md), maigret and ghunt (commands/q-osint.md, q-collect.md). yt-dlp is explicitly rejected for YouTube in .q-system/preflight.md.

## 3. Capability gaps and integration paths (top 20, from READMEs)

| Repo | Concrete capability huntkit lacks | Integration path | Effort |
|---|---|---|---|
| **d4vinci/Scrapling** | Local stealth fetching that bypasses Cloudflare Turnstile, adaptive selectors that survive site redesigns, and a spider with pause/resume plus proxy rotation. Its **official MCP server strips prompt-injection content** before the model sees a page. huntkit currently depends on paid APIs (Bright Data, Apify, Jina) for hard pages. | Add a `scrapling` entry to the `.mcp.json` template (`pip install "scrapling[ai]"`, then `scrapling mcp`) and use it as the free first tier in q-collect, falling back to Bright Data or Apify. | S |
| **stanfrbd/cyberbro** (+ stanfrbd/mcp-cyberbro) | **IoC extraction from messy input** (logs, emails, reports) followed by bulk reputation checks across many services (AbuseIPDB, Shodan, GreyNoise, Hudson Rock infostealer data, OpenCTI, grep.app, Chrome extension IDs). Also automated pivoting through reverse DNS and RDAP, history, a graph view and CSV/XLSX export. huntkit's threat-intel MCP covers only VT, URLhaus, ThreatFox and crt.sh, one indicator at a time. | Short term: port an IoC regex extractor into `scripts/extract-iocs.py` that feeds the threat-intel MCP. Optional: a docker-run cyberbro plus mcp-cyberbro template entry for bulk enrichment. | S/M |
| **snooppr/snoop, sherlock-project/sherlock, kaifcodec/user-scanner, p1ngul1n0/blackbird** (+ maigret) | **Username and email enumeration** with structured output. user-scanner covers 2,500+ username and 210+ email vectors with metadata scraping (avatars, bios, UIDs) and an automatic pivot engine. Blackbird is WhatsMyName-based with low false positives and PDF/CSV export. Snoop is strong on the CIS region. huntkit only mentions maigret and holehe as ad-hoc commands, with no normalized output or EV-ID evidence capture. | New `scripts/username-sweep.sh` that runs maigret `--json`, user-scanner and blackbird when installed, merges and deduplicates into `evidence/` with EV-NNNN IDs and A-F grades, and is called from q-target and q-osint. Alternatively, wire **frishtik/osint-tools-mcp-server** (sherlock, holehe, spiderfoot, ghunt, maigret behind one MCP). | M |
| **microsoft/playwright-mcp, agentdeskai/browser-tools-mcp, itayrosen/parallel-browser-mcp** | Agent-driven **interactive browsing**: clicking through logged-in or JS-heavy pages, filling search forms on registries and court portals, and parallel browser sessions. huntkit has Chrome PDF capture only (capture-evidence.sh), not navigation. | Add a playwright-mcp template entry. Document in q-collect and q-screenshots when to use it, and pipe the final URL into capture-evidence.sh for hashing. | S |
| **0xMassi/webclaw** | URL to clean markdown/JSON for LLM context, as a CLI or MCP, self-hostable. It overlaps Jina and Firecrawl, but is free and local. | Optional MCP template entry as a no-cost alternative to the Jina wrapper. | S |
| **smicallef/spiderfoot** | 200+ automated recon modules with a YAML **correlation engine** (37 rules), CSV/JSON/**GEXF** export, Tor search and a SQLite back end. huntkit has no automated multi-module footprinting of a domain, IP or email. | Run headless (`sf.py -s target -o json`) from a new `q-footprint` step. Ingest the JSON into evidence, and the GEXF into the future graph view. | M |
| **IntelOwl** | Observable and file enrichment at scale, including **YARA, oletools and file/malware analyzers**, and **MISP/OpenCTI connectors**. huntkit has no STIX/MISP export. | Do not embed. Add a `q-export --stix` mode (python stix2) and document an optional pyintelowl hook. | M/L |
| **3nock/sub3suite** | Template-driven OSINT collection and attack-surface mapping (subdomains, certs, ASN). | Low priority. crt.sh plus osint-infra already cover most of it. | - |
| **daijro/camoufox** (+ pydoll, rnet) | Anti-detect Firefox with fingerprint rotation and TLS-fingerprint-correct HTTP (rnet) for heavily protected targets. | Used under Scrapling's StealthyFetcher; document as an advanced fallback. | S |
| **biolds/sosse, jaypyles/Scraperr, apify/crawlee-python** | **Self-hosted crawler with recurring crawls**, change detection, webhooks and full-text search over archived pages: a **monitoring/alerts** capability that huntkit lacks. | Optional docker-compose recipe plus a `q-monitor` command that registers case URLs in sosse with a webhook into the case log. Alternatively, crawlee-python for a scripted site crawl. | M |
| **ArchiveBox, bellingcat/auto-archiver** | Bulk archiving to **WARC/WACZ**, singlefile HTML, media (yt-dlp/gallery-dl) and screenshots. auto-archiver adds Google Sheets/CSV-driven batch jobs, social-media-aware archivers (Telegram, X, Instagram, TikTok), hashing and timestamping. huntkit's capture-evidence.sh works one URL at a time without WARC or media. | Add an `--archiver auto-archiver` path to capture-evidence.sh for batch and social URLs, mapping outputs to EV IDs. | M |
| **snscrape, yt-dlp, gallery-dl, ripme** | Free **social-media and media scraping** (profiles, hashtags, Telegram channels, Mastodon, VK, Weibo; image galleries). snscrape's Twitter support is degraded. | Use gallery-dl for image/profile-media pulls into evidence (it is not YouTube-blocked like yt-dlp). Note snscrape for Telegram, Mastodon and VK. | S |
| **khashashin/ogi (OpenGraph Intel), reconurge/flowsint** | **Visual link-analysis graph** (Maltego-like): 20+ transforms, graph analytics (centrality, community detection, shortest path), GraphML/MTGX import/export, an AI investigator mode. huntkit's q-link produces only markdown edges. | Export q-link edges to **GraphML/GEXF and Maltego MTGX** (`scripts/link-export.py`, using networkx) so analysts can open them in OGI, Flowsint or Gephi. Add networkx centrality/community stats to q-analyze. | S/M |
| **be0vlk/owlculus** | Multi-user case management with an entity system (people, companies, domains, IPs, vehicles), **cross-case correlation scan**, and a browser extension that saves pages to case evidence. huntkit is single-user and per-case. | Borrow the idea: a `q-correlate` command that greps entities across `investigations/*/` (emails, domains, phones, handles) and reports overlaps. | S |
| **mxrch/GHunt** | Google account intel (Gaia ID, Maps reviews, Drive, BSSID geolocation). It needs a cookie login. | Already referenced. Add a login-setup note and normalized JSON-to-evidence ingestion. | S |
| **maxandrews/Epstein-doc-explorer** | A **document-corpus to knowledge-graph** pipeline: Claude extracts actors, actions, locations and relationships into SQLite, with an interactive network UI. huntkit has extract-intake.py but no entity extraction or relationship graph. | New `scripts/extract-entities.py`: intake text to a JSON entity/relationship table with source EV IDs, rendered as a self-contained HTML graph (vis-network or cytoscape). This closes both the NER gap and the graph-visualization gap. | M |
| **sparkyniner/Netryx** | Street-level **photo geolocation** (CosPlace + ALIKED + LightGlue against crawled panoramas). huntkit has no image or geolocation capability. It needs a GPU and a panorama crawl. | Document as an optional external tool. Add a lighter `q-geolocate` (EXIF via exiftool plus reverse-image search links) first. | L (Netryx) / S (EXIF) |
| **Kanaries/pygwalker** (+ owid-grapher, d3) | Tableau-like exploratory analysis of tabular case data (leak CSVs, transaction lists). | Have leak-record-classifier and q-timeline optionally emit a pygwalker HTML view. | S |
| **ozanunal0/viper, nikhilh-20/threatloom** | CVE prioritization (NVD, EPSS, CISA KEV, public exploits) via MCP, and an AI-summarized CTI feed. Useful only if huntkit expands into vuln/CTI work. | Optional template entry. | S |
| **yusufkaraaslan/skill_seekers** | Converts documentation sites, repos and PDFs into Claude skills: a scraping-to-skill pipeline. It was the most-mentioned repo in r/ClaudeAI and r/mcp. | Meta-tool for huntkit maintainers: generate skills from tool docs (e.g. a maigret or SpiderFoot reference). Not end-user facing. | S |

## 4. Recommended priority (by community signal x gap size)

1. **Scrapling MCP** as a free stealth-fetch tier with built-in prompt-injection stripping (S).
2. **Username/email sweep script** with normalized evidence: maigret, user-scanner, blackbird (M).
3. **Graph export** of q-link and entity extraction to GraphML/GEXF/MTGX plus an HTML network view (S/M).
4. **IoC extractor plus bulk reputation** (cyberbro-style), feeding the existing threat-intel MCP (S/M).
5. **playwright-mcp** for interactive navigation (S).
6. **Batch archiving** via auto-archiver/ArchiveBox with WARC output (M).
7. **Monitoring** via sosse recurring crawls and webhooks (M).
8. **STIX/MISP export** (M/L).
