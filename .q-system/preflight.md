# Investigation Preflight & Execution Harness

> Read this at the start of every investigation session.

---

## 1. Tool Manifest

### Critical (halt if unavailable)

| Tool | Test Command | Pass Criteria | Fallback |
|------|-------------|---------------|----------|
| **File system** | Read/Write/Edit tools | Can read/write investigation files | None. Halt. |

### Non-Critical (note and continue)

| Tool | Test Command | Pass Criteria | Fallback |
|------|-------------|---------------|----------|
| **Chrome** | `mcp__claude-in-chrome__tabs_context_mcp` | Returns a tab ID | Skip browser-dependent collection |
| **Apify** | Check `mcp__apify__*` via ToolSearch | Tool schema returned | REST API or manual collection |
| **Web search** | WebSearch tool | Returns results | Manual search |

### OSINT Skill (integrated)

Full toolkit at `skills/osint/SKILL.md` with 55+ Apify actors and 7 search APIs.

**Run diagnostics first:** `bash skills/osint/scripts/diagnose.sh`

### Structured Analysis Skill (integrated)

18 IC-standard Structured Analytic Techniques at `skills/structured-analysis/SKILL.md`.

**Key commands:**
- `/analyze ach --no-osint` -- formal hypothesis testing against collected evidence
- `/analyze kac --no-osint` -- structured assumptions check
- `/analyze deception --no-osint` -- detect planted/false info
- `/analyze premortem --no-osint` -- stress-test conclusions before briefing
- `/analyze --lean --no-osint` -- quick sanity check (restatement + KAC + inconsistencies)

**Typical flow:** Collect first (`/q-osint`), then analyze (`/analyze --no-osint`).

**Active case:** Reads from `./.active-case` (written by `/q-begin` and `/q-new-case`).

**Required env vars (at least one search API needed):**
- `APIFY_API_TOKEN` -- social media scraping (free tier ~$5/mo)
- `PERPLEXITY_API_KEY` -- AI search + deep research
- `EXA_API_KEY` -- semantic search + people/company research
- `TAVILY_API_KEY` -- agent-optimized search
- `JINA_API_KEY` -- URL reader + search
- `BRIGHTDATA_MCP_URL` -- CAPTCHA/authwall bypass (Facebook, LinkedIn fallback)

### DO NOT USE

| Approach | Why |
|----------|-----|
| Reddit search URLs via Apify | Scraper ignores `restrict_sr`, returns random subs |
| Chrome for bulk scraping | Apify is faster, cheaper, more reliable |
| LinkedIn pain-language search | Returns vendors, not targets |
| yt-dlp or BrightData for YouTube | YouTube blocks them. Use Apify actors. |

---

## 2. Known Issues Registry

### KI-1: Apify Reddit Scraper ignores search URLs
- Use direct /new/ or /top/ URLs only, never search URLs

### KI-2: Emdash ban
- NEVER use emdashes in any output. Use -- (double hyphen) instead.

---

## 3. Source Reliability Scale

Use this scale for all evidence and sources:

| Grade | Reliability | Description |
|-------|------------|-------------|
| A | Confirmed | Multiple independent sources, verified firsthand |
| B | Usually Reliable | Single trusted source, consistent with other data |
| C | Fairly Reliable | Source has been right before, some corroboration |
| D | Not Usually Reliable | Limited track record, minimal corroboration |
| E | Unreliable | Known issues with source, contradicts other data |
| F | Cannot Be Judged | New source, no track record |

---

## 4. Confidence Levels for Assessments

| Level | Meaning |
|-------|---------|
| **Confirmed** | Multiple independent sources, verified |
| **High confidence** | Strong evidence from reliable sources |
| **Moderate confidence** | Some evidence, plausible but gaps exist |
| **Low confidence** | Limited evidence, significant gaps |
| **Speculative** | Hypothesis only, no direct evidence |

---

## 5. Session Workflow

1. Read `memory/investigation-state.md` for where we left off
2. Read `canonical/scope.md` for investigation parameters
3. Check `output/analyses/` for any in-progress or completed analyses
4. Check what's changed since last session
5. Pick up highest-priority thread
6. At session end, run `/q-checkpoint`
