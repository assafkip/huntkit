# osint-infra-mcp

MCP server for OSINT infrastructure lookups: DNS, WHOIS, and Wayback Machine.

## Tools

| Tool | What it does |
|------|-------------|
| `whois_lookup` | WHOIS registration data for a domain |
| `dns_lookup` | DNS records (A, AAAA, MX, NS, TXT, CNAME, SOA, ANY) |
| `reverse_dns` | PTR record for an IP address |
| `wayback_snapshots` | List archived snapshots of a URL |
| `wayback_fetch` | Fetch content of a specific archived snapshot |

## Setup

```bash
cd osint-infra-mcp
python3.13 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
```

## Run standalone

```bash
python server.py
```

## Add to Claude Code

Add to `.mcp.json` in your project root:

```json
{
  "mcpServers": {
    "osint-infra": {
      "command": "${CLAUDE_PLUGIN_ROOT}/mcp-servers/osint-infra/.venv/bin/python",
      "args": ["${CLAUDE_PLUGIN_ROOT}/mcp-servers/osint-infra/server.py"]
    }
  }
}
```

## Requirements

- Python 3.10+
- `whois` and `dig` CLI tools (pre-installed on macOS/Linux)
- No API keys needed -- all lookups use public infrastructure
