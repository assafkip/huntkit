# 04 - Own repos (assafkip) vs huntkit: what huntkit is missing

Reviewer: Ryan. Date: 2026-10-10. Read-only. Nothing cloned, nothing executed.
## Method
- Public repos read as data from raw.githubusercontent.com (README depth plus a few named source files); kipi read in depth from a local copy. Nothing executed.
- A private internal repo was also reviewed; its findings are summarized here as capability names only. Private repos without session access were not reviewed.


Key huntkit facts used for comparison:
- `osint-infra` MCP has 5 tools: `whois_lookup`, `dns_lookup`, `reverse_dns`, `wayback_snapshots`, `wayback_fetch`.
- `threat-intel` MCP has 4 tools: `vt_lookup`, `urlhaus_lookup`, `threatfox_lookup`, `crt_lookup`.
- `q-link` writes markdown edges only (`commands/q-link.md`). There is no graph store, no metrics and no visualization.
- No IOC/defang extraction exists anywhere (grep for `defang|refang` returns nothing). `extract-intake.py` does verbatim text extraction only.
- `rules/q-investigation.md` defines its tiers as person-centric: T1 = "paid database (IDI, IRBsearch), court filing, government record, SSN". Infra records (WHOIS, RDAP, DNS, CT, on-chain) are not named as T1.
- Hooks: `token-guard.py` (PreToolUse) and `findings-verify-hook.py` (PostToolUse, which checks that a CONFIRMED/HIGH label has crosslinks). There is no hard-token claim check, no scope or budget hook and no dead-hook audit.

---

## 1. kipi (assafkip/kipi, local copy) - HIGH PRIORITY
**What it is:** Self-hosted OSINT platform (Python + SQLite + Flask-style webapp, Claude CLI agent). Documents go in, a typed entity graph comes out, an autonomous investigator digs the web, and graph analytics run on the case. It is the public OSS cut of private internal repo 

**Capabilities huntkit lacks (with evidence):**

| # | Capability | Evidence | Notes |
|---|---|---|---|
| K1 | **Graph analytics**: degree, betweenness (k-sampled above 500 nodes), eigenvector, Louvain communities, path confidence. Deterministic, per case, idempotent, with a stale-value guard | `graph_metrics.py` (`run`, `compute_path_confidence`, `_EDGE_CONF`); tests `tests/test_graph_metrics.py`, `test_graph_pathfinding.py`, `test_path_confidence.py` | huntkit `q-link` only writes markdown prose edges. Uses networkx + python-louvain |
| K2 | **Typed entity graph store**: entities, mentions, typed_relationships (status, first-seen/last-seen bounds), node_properties with provenance | `storage/schema.sql`, `storage/db.py`, `tests/test_edge_time_bounds.py` | Would replace huntkit's free-text link files |
| K3 | **Closed relationship vocabulary** (`normalize_rel` with `linked_to` fallback) | `enrich/rel_vocab.py` | Stops LLM label drift in q-link |
| K4 | **Single entity-admission gate**: one function decides whether a value is a real entity or noise (CSS fragments, bare-digit "phones", date-shaped numbers, WHOIS/registry boilerplate domains, journalist domains) | `admission.py`, `noise.py`, CDN tagging `tests/test_cdn_tagging.py` | huntkit has no noise gate |
| K5 | **Deterministic regex entity extractor** (emails, URLs, handles, t.me, phones, hashes, IPv4, BTC/ETH wallets, domains, person candidates) | `ingest/extractor.py` | huntkit has nothing like it. Pairs with theia (section 3) |
| K6 | **Hard-token claim verification**: any ISO date, IPv4, email or ETH address in a claim must appear in a tool result or source. Otherwise the claim is flagged | `verify.py` (`hard_tokens`), used in `agent/investigator.py` `_claim_hard_tokens` / `_attribute_findings` | The private internal repo |
| K7 | **Enrichment adapters huntkit lacks** (keyless unless noted): RDAP, ASN, ipgeo, Shodan InternetDB, typosquat (dnstwist with DNS liveness check, T3 to T1 gate), email triage (MX, SPF, DMARC, disposable) plus raw-header to source-IP hop chain, username sweep (curated, no bot-walled sites), phone (libphonenumber offline, VOIP flag), EXIF (exiftool GPS and device serial), Gravatar, git commit-author email mining, Ahmia dark-web (T3), Scam Sniffer crypto blocklist (T3), OFAC (Chainalysis oracle eth_call plus SDN CSV), wallets BTC (mempool) / ETH (Etherscan key) / TRON / TON / Solana / ENS / WalletExplorer / Blockchair, OpenCorporates, OTX, GreyNoise, urlscan, Censys, WhoisXML reverse-NS, HIBP, AbuseIPDB, Reddit via Arctic Shift | `enrich/*.py` (48 files), `enrich/data/wmn-data.json` (WhatsMyName), `enrich/data/etherscan_labels.json` | Largest single gap vs `osint-infra` / `threat-intel` |
| K8 | **Deterministic infra enumeration** ("Shape C"): one call runs the type-appropriate belt over all seeds (crt.sh + whois/RDAP + DNS for domains, rDNS + geo for IPs, reverse-whois for emails), then runs a tier-2 pass once. Zero LLM, with seed caps | `enrich/enumerate.py` (MAX_SEEDS 25, MAX_TIER2 15); MCP tool `enumerate_infra` | Replaces ~13 turn-by-turn calls. Big token saver |
| K9 | **kipi-osint MCP server** wrapping all adapters through a registry | `agent/osint_mcp.py`, `enrich/registry.py`, `enrich/runner.py` | Could replace both huntkit MCP servers with one |
| K10 | **Agent guard hooks**: `scope_hook.py` (PreToolUse, denies investigating targets not on the case roster; fails open) and `budget_hook.py` (PreToolUse, per-run tool-call cap) | `agent/scope_hook.py`, `agent/budget_hook.py`, tests `test_scope_gate.py`, `test_budget_gate.py` | huntkit has only the global token-guard |
| K11 | **Phase gates**: a phased run pauses for the analyst between phases (continue / redirect / stop) | `agent/phase_gates.py` | Maps onto q-begin / q-collect |
| K12 | **Pivot classifier**: splits recommended pivots into "do now" vs "needs external", with a reason (subpoena, internal logs, missing key) | `agent/pivots.py` | Deterministic keyword rules |
| K13 | **Swarm volley, then adversarial verify, then loop until dry** (parallel workers, caps) | `agent/swarm.py` | huntkit has first-volley.sh / merge-volley.sh, but no verify-and-iterate loop |
| K14 | **Identity anchor**: a per-case reference identity of confirmed actors, so a same-handle profile is not silently merged | `identity_anchor.py` | Directly relevant to the osint person skill |
| K15 | **Claims layer**: contradiction detection, supersession (nothing deleted), reprojection | `claims.py`, `tests/test_claim_reject_cascade.py` | |
| K16 | **Hypothesis stance tags on edges** (supports / contradicts / consistent_with), i.e. graph-side ACH | `hypotheses.py` | Bridges q-analyze ACH and q-link |
| K17 | **Tradecraft checklist** (Scope / Challenge / Premortem gates plus helpers), code-enforced by artifact existence, soft nudge in the brief | `tradecraft.py` | |
| K18 | **Exports**: STIX 2.1 bundle, MISP event JSON, flat CSV | `export/intel_exports.py` | huntkit has none |
| K19 | **Visualization exports**: Obsidian vault (entity pages) and Obsidian Canvas (clusters as groups, edges coloured by confidence, nodes sized by score, plus IOC canvas and diff canvas) | `export/obsidian.py`, `export/canvas.py` | Cheapest way to give huntkit a graph view with no web app |
| K20 | **Ingest**: Telegram JSON (native export and harvest formats), XLSX, DOCX images, PDF embedded images, linked images, record ingest | `ingest/telegram.py`, `xlsx_ingest.py`, `pdf_assets.py`, `docx_assets.py`, `linked_images.py` | huntkit `extract-intake.py` covers PDF/DOCX/CSV/OCR/EML/MD but has no Telegram JSON and no XLSX |
| K21 | **Focus delta loop**: top-N by threat score, delta vs last run, "newly elevated" / "cooling off" | `focus.py` | |
| K22 | **Cross-report and cross-case correlation** plus alias auto-link | `correlate/engine.py`, `tests/test_cross_case.py` | |
| K23 | **OSS secrets / export-boundary audit** | `scripts/oss_secrets_audit.sh` | Relevant before publishing case artifacts |
| K24 | **Test suite** (~200 pytest files) and `tests/diff_harness.py` | `investigations/tests/` | huntkit has one test file |

**Port path:**
- (a) Add `skills/osint/scripts/graph/`: a small SQLite or JSON graph built from `investigations/<case>/findings` + `targets`, plus `graph_metrics.py` (networkx) and `canvas.py` (Obsidian Canvas) and `intel_exports.py` (STIX/MISP). Upgrade `q-link` to write typed edges with `rel_vocab`. New command `q-graph`.
- (b) Fold the keyless adapters into `osint-infra` as new MCP tools, or adopt `osint_mcp.py` wholesale.
- (c) Make `verify.py` hard tokens a PostToolUse hook on findings files.
- (d) Add `scope_hook` / `budget_hook` as optional hooks keyed off case files.

**Effort:** L overall. Individual pieces are S-M (see the ranked list).

---

## 2. Private internal repo (summary only)
Capabilities present there and not in huntkit: infra-aware evidence tiers (WHOIS/RDAP/DNS/CT/on-chain as T1); an evidence-ledger gate on client deliverables (every number/quote must trace to recorded evidence); closed-world stat verification; a cited-file grounding stop hook; a read-first gate; a skill-trigger eval harness; a sycophancy harness; a large-PDF per-section extractor; a scrape-to-file helper; rules (no-orphan-findings, loop-exits, skill-hook-pairing, wiring-check, self-healing-retry, memory-confidence); an RCA kit; a golden-case parity/regression harness; Playwright MCP in the MCP template; and drift between its copies of the q-* commands and huntkit's (worth a 3-way diff).

## 3. theia (public) - IOC extraction - HIGH PRIORITY
**What it is:** Next.js app. Paste a PDF or URL of a TI report and get deterministic, defang-aware IOC extraction with byte-exact source spans. Also named-threat gazetteer (MITRE ATT&CK + Malpedia), printed ATT&CK IDs, verbatim vendor Sigma/YARA/Snort, single-field Sigma sweep snippets, CSV export. Optional LLM noise flag that never adds or removes indicators. Has a harness over real advisories.

**huntkit lacks:** all of it. Evidence (fetched as data):
- `app/lib/iocExtract.mjs` (224 lines). Defang grammar (`[.]`, `(dot)`, `hxxp`, `[:]`, `[at]`), in-place matching so `source_span = text.slice(start,end)`, IANA TLD set, a FILENAME_TLDS guard (`.zip`, `.py`, `.sh` treated as filenames), list-delimiter handling.
- `app/lib/grounding.mjs`: a three-pass normalization (whitespace + ZWSP, PDF hyphen-wrap, typographic fold), then case-sensitive containment. A 1:1 port of a Python gate (a private gate).
- `app/lib/attackIds.mjs`, `entities.mjs`. `package.json` also lists `sigmaTemplate`, `ruleTranscribe`, `extractLoop`, `context`, and `scripts/harness.mjs` plus `scripts/build-gazetteer.mjs`.

**Port path:** a Python port as `skills/osint/scripts/extract-iocs.py` that reads `extract-intake.py` output and emits `iocs.csv` with value, type, raw span, offset and sentence context. Add a v007-style `grounding.py` used by the findings hook. Optionally vendor the gazetteer JSON. Wire into `q-intake` (auto-run on every intake document) and `q-export` (STIX/CSV). Port the harness pattern as a fixture test. **Effort:** M.

---

## 4. hydra (public) = kipi-web - HIGH PRIORITY for MCP coverage
**What it is:** 100% client-side OSINT app (Vite + TS + cytoscape). BYOK encrypted vault (AES-GCM), CSP egress allowlist with build-time `leakgate`, browser agent loop, live graph. Source reviewed locally at `private internal repo 

**Keyless lookups huntkit's `osint-infra` / `threat-intel` lack** (each file's header names the tier):
- `rdap.ts`: RDAP via rdap.org, structured WHOIS replacement (T1). huntkit shells out to port-43 `whois`.
- `doh.ts`: DNS-over-HTTPS (Google). Works with no `dig` binary, which huntkit requires.
- `dns-deep.ts`: SPF `include:` / `ip4:` and DMARC `rua` as pivots.
- `reverse-ip.ts`: HackerTarget reverse-IP, i.e. co-hosted domains (huntkit has only PTR).
- `ripestat.ts` and `asn.ts`: IP to ASN / BGP prefix (T1).
- `certspotter.ts`: a second CT source independent of crt.sh.
- `shodan-internetdb.ts`, `ipinfo.ts`, `ipwho-is.ts`, `ip-guide.ts`.
- `sans-isc.ts`, `stopforumspam.ts`: IP reputation (T3, infra:false).
- Wallets: `mempool.ts`, `blockstream.ts`, `blockcypher.ts`, `blockscout.ts`, `etherscan.ts`, `solana.ts`, `ton.ts`, `tron.ts`, `ens.ts`, `ofac.ts`.
- Identity: `gravatar.ts`, `github-user.ts`, `gitlab-user.ts`, `npm-user.ts`, `hackernews-user.ts`, `username-sweep.ts`, `xposedornot.ts` (breach, T3), `disposable-email.ts` (two providers cross-checked), `phone.ts`, `email-intel.ts`, `hibp-catalog.ts`.
- Registries: `gleif.ts` (LEI, T1), `wikidata.ts` (T3).
- `linkresolve.ts`: pulls the outbound destination from link-aggregator pages (e.g. Pinterest pins).
- `pivots.ts`: per-entity pivot URL templates (Shodan, VT, Etherscan, urlscan, PublicWWW).
- `tool-inventory.ts` / `catalog.ts`: a tool catalog with tier and infra flags.
- Design idea worth porting: every adapter declares `infra: true|false`, so T3 reputation hits can never inflate the infra crosslink count. This mirrors the gap the RESUME plan describes (`_INFRA_TOOL_TOKENS` / `_is_infra_source`).

**Port path:** add Python tools to `mcp-servers/osint-infra/server.py`: `rdap_lookup`, `doh_lookup` (fallback when `dig` is absent), `dns_mail_policy`, `reverse_ip`, `asn_lookup` (RIPEstat), `certspotter_lookup`, `internetdb_lookup`, `wallet_lookup` (BTC mempool / ETH Etherscan, with OFAC oracle), `gleif_lookup`, `username_sweep`. Add an `infra` flag in each tool's output header. kipi's `enrich/*.py` already holds Python versions of most of these (copy, don't re-port from TS). The browser vault and egress wall are not transferable to a CLI plugin. **Effort:** M.

---

## 5. account-procurement-tools (public) - Telegram pipeline
**What it is:** A no-LLM, offline Telegram OSINT pipeline: tgspyder scrape (messages + invite links), lingua language detect, Argos/CTranslate2 offline translate, rule extractor (account type, price, PIN, verified, qty, handles), then a client XLSX. Evidence: `account-procurement-pipeline/README.md`, which lists `src/scrape.py`, `lang_translate.py`, `extract.py`, `geo_clues.py`, `build_sheet.py`, `pipeline.py`, `config/keywords.json` (multilingual including Vietnamese and CJK), `config/countries.json`, offline tests, SOCKS proxy flag, Windows ps1 mirrors.

**Notable design:** "geo clues, never decide". The tool leaves country columns blank and fills `» Clue:` helper columns (language, country words, phone country, TG handles). Every row carries `» Original Text`, `» English Text`, `» Source Channel`, `» Message ID`, `» Confidence` and `» Needs Review`.

**huntkit lacks:** huntkit lists tgspyder only as an optional external tool. There is no scrape-to-structured pipeline, no offline translation and no Telegram ingest.

**Port path:** new skill `skills/telegram-harvest/` (pipeline generalized: keyword dictionaries as per-case config) feeding `extract-intake.py` (add Telegram JSON/CSV handling from kipi `ingest/telegram.py`). The "clue-not-verdict" helper-column pattern also fits `leak-record-classifier`. **Effort:** M.

---

## 6. reddit-business-research (public) - keyless Reddit
**What it is:** A Claude Code plugin. Reddit research via `reddit-no-auth-mcp-server` (uv), with an intake-questions, discovery, checkpoint, deep-dive, synthesis flow. Evidence: `skills/reddit-research/SKILL.md` (tools `mcp__reddit__reddit_search`, `_search_subreddit`, `_get_subreddit_posts`, `_get_post`, `_get_user`, `_get_user_posts`).

**Versus huntkit:** huntkit already lists `reddit-no-auth-mcp-server` as an MCP template, so this approach is mostly present. The **better** keyless approach lives in kipi and competitive-analysis: the **Arctic Shift archive mirror** with PullPush fallback (`kipi/investigations/enrich/reddit_arctic.py`, 243 lines). Its docstring records that `www.reddit.com/.json` returns 403 from datacenter IPs and that RSS returned 429 on 11 of 12 requests at 3s pacing. It also raises on a refused read, so a dead mirror is never mistaken for an empty subreddit. That matters for `user` history lookups in person investigations (historical and deleted content).

**Port path:** vendor `reddit_arctic.py` as `skills/osint/scripts/reddit-arctic.py` (user posts and comments by author, subreddit search, date ranges) and document it in `references/platforms.md`. The SKILL's "checkpoint after discovery" pattern could also go into q-collect. **Effort:** S.

---

## 7. research-mode (public) - citation enforcement
**What it is:** A toggle skill (`SKILL.md`): say "I don't know", cite everything, quote first. Source cascade: local, then WebSearch snippet, then WebFetch, then Scholar. Budget of 5 WebSearch / 3 WebFetch per question. Defines what counts as cited ("training data recall = NOT cited", `{{VERIFY_URL}}` marker).

**Versus huntkit rules:** `rules/q-investigation.md` already requires "every claim must cite its source and evidence tier" (line 70), and `sycophancy-core.md` exists. What huntkit lacks:
- (a) An explicit **cost cascade with per-question search/fetch budgets**. `token-discipline.md` is generic.
- (b) The **"quote first, then analyze"** rule for documents.
- (c) The **"recall is not a citation"** definition plus the `{{VERIFY_URL}}` placeholder.
- (d) Any of it enforced by code. Per kipi's own `skill-hook-pairing.md`, the deterministic part should be a hook: a regex that every finding bullet has an `EV-NNNN` or URL plus a tier.

**Port path:** append a "Citation discipline" section to `rules/q-investigation.md` and extend `findings-verify-hook.py` to flag uncited claim lines. **Effort:** S.

---

## 8. competitive-analysis (public)
**What it is:** A weekly market-intel collector (GitHub search, HN, Reddit via Arctic Shift, RSS, HF trending, arXiv, X via Apify). Normalizes items, detects repeated themes, writes a brief and a JSON report. Has a `coverage.jsonl` repeat-blocking ledger and a NotebookLM podcast brief.

**Transferable:** the **coverage ledger** (dedup across runs) for a future huntkit monitoring mode, and the multi-source collector config (`sources.json`, watchlist YAML) as a template for q-collect on organizations. **Effort:** M. Low priority unless monitoring is in scope.

## 9. customer-recon, investor-recon, trust-safety-recon, ai-reliability-recon (public)
**What they are:** Grounded Claude Code recon plugins. They share a pattern: intake questions; scoped to the subject; "Not found" instead of guessing; an explicit **"what it ruled out"** section; scorecards rated Missing / Partial / In place; ranked gaps.

**Transferable to huntkit:** the "ruled out, and why" section and the "Sources and gaps" section as **required q-brief / q-export template sections** (S). trust-safety-recon's abuse-vector mapping could become a q-* command for T&S cases (`q-abuse-surface`, M), but it is not core OSINT. investor-recon's fund-thesis brief is a model for organization profiling in q-target (S, prompt-only). Content beyond the READMEs not reviewed.

## 10. helios + vc-signals (public)
**What they are:** An hourly RSS monitor (GitHub Actions cron) that classifies hard vs soft signals, attributes them to person + firm, keeps a 30-day window, dedups, writes one JSON, and renders it in a static HTML dashboard.

**Transferable:** a pattern for **case monitoring / alerts** (huntkit has none): watch a target's RSS, Reddit (Arctic) and CT logs on a schedule and write a delta JSON. Low priority. **Effort:** M.

## 11. kipi-system (public)
**What it is:** "Founder OS". Knowledge supply chain (capture, organize, retrieve, deliver, prove), dated fact graph, commitments, lessons. Upstream of the private internal repo 

**Transferable:** the "deliver verbatim lines with file:line:date:status" retrieval contract could feed a `q-recall` for cross-case memory. Mostly covered by the private internal repo 

## 12. claude-cortex (public)
An OS bundle of claude-focus, memory-lifecycle, research-mode and agents ("15 OSINT investigations closed through the investigator instance"). Nothing transferable beyond its component repos.

## 13. claude-focus (public)
**What it is:** Three hooks: `token-guard.py`, `verification-gate.py` (catches false "done"), `echo-of-prompt.py` (re-injects `.claude/task-context.md` every N calls).

**Versus huntkit:** huntkit already ships `token-guard.py` (same lineage). It lacks **verification-gate** and **echo-of-prompt**. For long q-collect runs, echoing `canonical/scope.md` every 15 calls directly addresses scope drift. **Port:** add both hooks, with echo-of-prompt pointed at the active case scope file. **Effort:** S.

## 14. dead-hooks (public)
**What it is:** A linter that reads settings.json and flags hooks that can never fire: missing script; `test -f X && python3 Y` mismatch; `|| true` or all-`exit 0`.

**Relevance:** huntkit's `hooks.json` uses exactly the `test -f "...script" && python3 "...script"` pattern, which silently no-ops if the path is wrong. **Port:** run it as a CI or lefthook check over `hooks/hooks.json` (huntkit already has `lefthook.yml`). **Effort:** S.

## 15. memory-lifecycle and finish-the-day (public)
- memory-lifecycle: `decay: fast|medium|slow` tags and a SessionStart warning.
- finish-the-day: an `open-loops.json` ledger with `next_action` as a runnable command, `handoff_lint.py` (blocks a claim without provenance), memory freshness, heartbeat.

**Transferable:** `handoff_lint.py` fits **q-handoff / q-checkpoint** (block unprovenanced claims in handoff files). An open-loops ledger fits pending pivots and "awaiting client" items per case. Decay tags fit time-sensitive case facts (an account active "as of" a date). **Effort:** S each.

## 16. safe-autonomous-learning (public)
**What it is:** `client-data-gate` (fail-closed filter: text publishes only if it is provably free of configured client names, paths, emails and URLs), `job-watchdog`, `auto-learn`.

**Relevance to huntkit:** high for confidentiality. A **client-data gate before anything leaves a case directory**: lessons, shared templates, upstream PRs, `llms.txt` examples. huntkit's `evidence-pipeline-guard.py` header itself references a real case slug. **Port:** pre-commit / lefthook hook running client-data-gate over staged files with a per-case denylist (S-M).

## 17. kipi-rca (public; also inside private internal repo 
**What it is:** An RCA skill, `/rca-start`, `/rca-check`, an `rca-lint` hook (surface vs structural cause, cause-type tags, verification evidence, checkbox owners, blameless), an `rca-notify` hook and a premortem variant.

**Transferable:** the premortem variant fits q-challenge / q-reality-check, and an "investigation RCA" fits a wrong attribution caught after delivery. **Effort:** S (reuse as-is).

## 18. eyeball, claude-image (public)
- eyeball: zero-dependency CDP-driven headless Chrome render assertions.
- claude-image: HTML to PNG via headless Chrome.

**Transferable:** huntkit's `capture-evidence.sh` already uses Chrome PDF. eyeball's CDP-over-builtin-WebSocket approach could add **full-page PNG screenshots with DOM metadata** to evidence capture, and claude-image could render graph or timeline HTML to PNG for q-export reports. **Effort:** S-M. Low priority.

## 19. kipi-pipeline-plugin, notebooklm-daily-podcast (public)
Morning GTM pipeline (24 agents) and podcast generator. Pattern only: a phased agent pipeline with a bus/JSON per phase. **Nothing transferable** for OSINT, except NotebookLM audio briefings of a case, which is a novelty.

## 20. scam_shield, scam_shield_2 (public)
Flutter scam-education apps. Scenario JSON with tactic tags (authority, urgency, emotion). The tactic taxonomy could seed a fraud-tactic tag list for scam investigations. Otherwise **nothing transferable**. `safety_sigma_2.0`: README empty (0 bytes); not reviewed further.

## 21. Lower priority (README skim only)
- **voice-gate / founder-voice-kit / voice-loop / linkedin-brand / Linkedin_CMS / founder-skills / interview-coach / car-lease-negotiator / audhd-executive-function / adhd-output-style:** writing-voice and personal tooling. Two transferable ideas:
  - voice-gate's PostToolUse block-until-fixed pattern, applied to report style (banned hedges and AI tells in client deliverables) (S).
  - adhd-output-style ships an **eval harness proving a style doesn't degrade answers**, a model for evaluating huntkit output rules (M).
- **prd-os:** PRD to Codex review to atomic issues with scope enforcement and receipts. Process tooling for developing huntkit itself, not for investigations.
- **design-chain / design-room / slide-show-maker / claude-video-editor / claude-voice / claude-say:** nothing transferable (q-brief audio via claude-say is a novelty).
- **notion-writer-service:** an Express Notion REST wrapper. Nothing transferable.
- **Calude_password, claude_job_search:** README not found (404 on HEAD/README.md and readme.md). Not reviewed.


---

## Ranked top-15 port list

| Rank | Port | Source (evidence) | Into huntkit | Effort |
|---|---|---|---|---|
| 1 | Keyless infra belt as MCP tools: RDAP, DoH fallback, SPF/DMARC pivots, reverse-IP, ASN (RIPEstat), certspotter, Shodan InternetDB | kipi `enrich/{infra,asn,shodan,crtsh}.py`; hydra `kipi-web/src/osint/{rdap,doh,dns-deep,reverse-ip,ripestat,certspotter,shodan-internetdb}.ts` | `mcp-servers/osint-infra/server.py` | M |
| 2 | Deterministic, defang-aware IOC extractor with byte-exact spans + grounding normalizer | theia `app/lib/iocExtract.mjs`, `grounding.mjs`; kipi `ingest/extractor.py` | `skills/osint/scripts/extract-iocs.py`, auto-run in q-intake | M |
| 3 | Hard-token claim verification hook (dates / IPs / emails / wallets in a finding must appear in captured evidence) | kipi `verify.py`, `agent/investigator.py` `_claim_hard_tokens` | extend `findings-verify-hook.py` | S |
| 4 | Infra-aware evidence tiers (WHOIS/RDAP/DNS/CT/on-chain = T1; `infra` flag so T3 reputation never counts as a crosslink) | private internal repo | `rules/q-investigation.md` | S |
| 5 | Entity graph + analytics (betweenness, Louvain, path confidence) + closed rel vocab; new `q-graph` and upgraded `q-link` | kipi `graph_metrics.py`, `enrich/rel_vocab.py`, `storage/schema.sql` | `skills/osint/scripts/graph/` + `commands/q-graph.md` | L |
| 6 | Graph visualization via Obsidian Canvas/vault export (zero web app) | kipi `export/canvas.py`, `export/obsidian.py` | q-export option | S-M |
| 7 | STIX 2.1 / MISP / CSV export | kipi `export/intel_exports.py` | q-export | S |
| 8 | Crypto wallet + sanctions tools (BTC mempool, ETH, TRON, TON, SOL, ENS, OFAC oracle + SDN, Scam Sniffer blocklist) | kipi `enrich/{wallet,tron,wallet_ton,solana,ens,ofac,crypto_abuse,walletexplorer}.py` | `threat-intel` MCP | M |
| 9 | Person/identity keyless tools: username sweep (WhatsMyName data), email triage + header to IP, phone (libphonenumber), Gravatar, git commit-email mining, EXIF | kipi `enrich/{username,email_intel,phone,gravatar,git_osint,exif}.py`, `enrich/data/wmn-data.json` | osint skill scripts + MCP; fills the "NOT present" list | M |
| 10 | Evidence-ledger gate for client deliverables (every number / quote traces to an EV item) | private internal repo | PostToolUse hook on deliverables | M |
| 11 | Deterministic seed enumeration (one call, zero LLM, tier-2 once) + typosquat generation with liveness gate | kipi `enrich/enumerate.py`, `enrich/typosquat.py` | `enumerate_infra` MCP tool used by q-collect | M |
| 12 | Telegram harvest pipeline (tgspyder, offline translate, rule extract, XLSX with clue columns) + Telegram JSON ingest | account-procurement-tools pipeline README; kipi `ingest/telegram.py` | `skills/telegram-harvest/`, `extract-intake.py` | M |
| 13 | Arctic Shift Reddit client (keyless, historical, fail-loud) | kipi `enrich/reddit_arctic.py` | `skills/osint/scripts/reddit-arctic.py` | S |
| 14 | Scope + budget + echo-of-prompt hooks (roster-scoped targets, per-run tool cap, re-inject case scope) and dead-hooks lint over `hooks.json` | kipi `agent/scope_hook.py`, `budget_hook.py`; claude-focus `echo-of-prompt.py`; dead-hooks | `hooks/hooks.json`, `lefthook.yml` | S |
| 15 | Golden-case eval harness (ground-truth entities / edges, recall scorecard, ratchet) + skill-trigger eval fixtures | private internal repo | `skills/osint/tests/` + `evals/` | M-L |

Honourable mentions (S each):
- Research-mode citation cascade and budgets in rules.
- no-orphan-findings rule plus an open-loops ledger for pivots.
- `pdf-extract.py` large-report corpus.
- `firecrawl-scrape.py` scrape-to-file.
- client-data-gate pre-commit.
- Identity anchor (`identity_anchor.py`).
- Hypothesis stance tags on edges (`hypotheses.py`).
- Pivot classifier (`agent/pivots.py`).
- Playwright MCP in templates.
- 3-way diff of the 18 drifted `q-*.md` commands between private internal repo 
