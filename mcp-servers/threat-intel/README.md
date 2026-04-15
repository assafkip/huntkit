# Threat Intel MCP Server

Threat intelligence lookups as Claude Code tools. Zero context bloat -- API knowledge lives in code, not prompts.

## Tools

| Tool | Source | What it does |
|------|--------|--------------|
| `vt_lookup` | VirusTotal | Domain/URL/IP/hash reputation across 70+ engines |
| `urlhaus_lookup` | URLhaus (abuse.ch) | Malware URL database lookup |
| `threatfox_lookup` | ThreatFox (abuse.ch) | IOC search -- IPs, domains, hashes, malware families |
| `crt_lookup` | crt.sh | Certificate transparency history (no key needed) |

## Setup

### 1. Get API keys

- **VirusTotal**: Sign up at https://virustotal.com/gui/join-us (free, 500 req/day)
- **abuse.ch**: Sign up at https://auth.abuse.ch (free, covers URLhaus + ThreatFox)

### 2. Add to Claude Code

```bash
claude mcp add threat-intel -- uv run --directory /path/to/threat-intel-mcp server.py
```

### 3. Set env vars

Add to your `.claude/settings.local.json` (or `~/.claude/settings.json` for global):

```json
{
  "env": {
    "VIRUSTOTAL_API_KEY": "your-key-here",
    "ABUSECH_AUTH_KEY": "your-key-here"
  }
}
```

## Usage

Once configured, just ask Claude:

- "Check if example.com is malicious"
- "Look up this hash on VirusTotal: abc123..."
- "What certificates has example.com had?"
- "Search ThreatFox for Cobalt Strike IOCs"

The tools handle auto-detection of indicator types (domain vs IP vs URL vs hash).
