# claude-osint

OSINT investigation plugin for [Claude Code](https://claude.com/claude-code). Structured research on people and infrastructure with 55+ scrapers, 7 search APIs, and bundled MCP servers for infra recon and threat intel.

## What you get

- **`/osint` skill** — 6-phase investigation workflow: tooling check → seed collection → optional internal intel → platform extraction → cross-reference → psychoprofile → completeness scoring → dossier.
- **`/q-osint` and `/q-collect` commands** — invoke targeted runs.
- **Two bundled MCP servers:**
  - `osint-infra` — WHOIS, DNS, reverse DNS, Wayback snapshots/fetch.
  - `threat-intel` — VirusTotal, URLhaus, ThreatFox, crt.sh certificate transparency.
- **Rules:** evidence capture protocol, investigation hygiene.

## Install as a Claude Code plugin

```bash
# from inside a Claude Code project
/plugin install assafkip/claude-osint
```

Or clone and point Claude Code at it:

```bash
git clone https://github.com/assafkip/claude-osint.git
```

## MCP server setup

Copy the template and fill in your keys:

```bash
cp .mcp.json.template .mcp.json
```

### `osint-infra` (WHOIS, DNS, Wayback)

No API keys needed. Just build the venv:

```bash
cd mcp-servers/osint-infra
python3.13 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
```

### `threat-intel` (VT, abuse.ch, crt.sh)

Get free keys:
- VirusTotal: https://virustotal.com/gui/join-us (500 req/day)
- abuse.ch (URLhaus + ThreatFox): https://auth.abuse.ch

Export them (or add to `.mcp.json`):

```bash
export VT_API_KEY=...
export ABUSE_CH_AUTH_KEY=...
```

### Optional search/scrape APIs

The skill's scripts support (all optional — it degrades gracefully):

| Env var | Service | Get key |
|---|---|---|
| `PERPLEXITY_API_KEY` | Perplexity Sonar / Deep | https://perplexity.ai |
| `EXA_API_KEY` | Exa semantic search | https://exa.ai |
| `TAVILY_API_KEY` | Tavily agent search | https://tavily.com |
| `APIFY_TOKEN` | Apify scrapers (LinkedIn, IG, TikTok, YouTube, FB pages) | https://apify.com |
| `JINA_API_KEY` | Jina reader / deepsearch | https://jina.ai |
| `PARALLEL_API_KEY` | Parallel AI search | https://parallel.ai |
| `BRIGHTDATA_MCP_URL` | Bright Data MCP (Facebook, LinkedIn, geo-blocked) | https://brightdata.com |

Run `bash skills/osint/scripts/diagnose.sh` to see which capabilities are active.

## Optional: Telegram recon

For Telegram private-message lookups, install [tgspyder](https://github.com/Darksight-Analytics/tgspyder) separately:

```bash
git clone https://github.com/Darksight-Analytics/tgspyder.git
cd tgspyder && pip install -r requirements.txt && pip install -e .
```

Not bundled — third-party with its own license.

## Usage

```
# In Claude Code
/osint research Jane Doe, CEO of Acme Corp
/q-osint linkedin https://linkedin.com/in/janedoe
/q-collect domain acmecorp.com
```

The skill auto-routes by target type (person / company / domain / incident) and runs a Perplexity first-volley, then escalates to scrapers and deep research if needed.

## Ethics

This plugin is for:
- Authorized security testing and due diligence
- Journalistic and academic research on public figures
- Defensive threat intelligence
- CTF / educational contexts

Do not use on private individuals without consent, for harassment, doxxing, or stalking. You are responsible for compliance with local laws and platform terms of service.

## Contributing

Issues and PRs welcome. The skill is versioned (currently v3.2); backward-compatible additions preferred over breaking changes.

## License

MIT. See [LICENSE](LICENSE).
