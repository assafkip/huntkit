# /// script
# requires-python = ">=3.10"
# dependencies = ["mcp[cli]>=1.0.0"]
# ///
"""
Threat Intelligence MCP Server

Wraps VirusTotal, URLhaus, ThreatFox, and crt.sh into Claude Code tools.
Zero context bloat -- API knowledge lives here, not in prompts.

API keys via env vars:
  VIRUSTOTAL_API_KEY
  ABUSECH_AUTH_KEY
"""

import os
import json
import urllib.request
import urllib.parse
import urllib.error
from datetime import datetime, timezone

from mcp.server.fastmcp import FastMCP

mcp = FastMCP("threat-intel")

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

def _get_env(name: str) -> str:
    val = os.environ.get(name, "")
    if not val:
        raise ValueError(f"Missing env var: {name}")
    return val


def _http_get(url: str, headers: dict | None = None) -> dict:
    req = urllib.request.Request(url, headers=headers or {})
    with urllib.request.urlopen(req, timeout=15) as resp:
        return json.loads(resp.read())


def _http_post(url: str, data: dict | bytes | None = None, headers: dict | None = None, is_json: bool = False) -> dict:
    if is_json:
        body = json.dumps(data).encode() if isinstance(data, dict) else data
        headers = headers or {}
        headers["Content-Type"] = "application/json"
    elif isinstance(data, dict):
        body = urllib.parse.urlencode(data).encode()
    else:
        body = data
    req = urllib.request.Request(url, data=body, headers=headers or {}, method="POST")
    with urllib.request.urlopen(req, timeout=15) as resp:
        return json.loads(resp.read())


def _age(timestamp: str | int | None) -> str:
    """Human-readable age from a unix timestamp or ISO date."""
    if not timestamp:
        return "unknown"
    try:
        if isinstance(timestamp, (int, float)):
            dt = datetime.fromtimestamp(timestamp, tz=timezone.utc)
        else:
            dt = datetime.fromisoformat(str(timestamp).replace("Z", "+00:00"))
        delta = datetime.now(tz=timezone.utc) - dt
        days = delta.days
        if days == 0:
            return "today"
        if days == 1:
            return "yesterday"
        if days < 30:
            return f"{days} days ago"
        if days < 365:
            return f"{days // 30} months ago"
        return f"{days // 365} years ago"
    except Exception:
        return str(timestamp)


# ---------------------------------------------------------------------------
# VirusTotal
# ---------------------------------------------------------------------------

@mcp.tool()
def vt_lookup(indicator: str, indicator_type: str = "auto") -> str:
    """Look up a domain, URL, IP address, or file hash on VirusTotal.

    Args:
        indicator: The domain, URL, IP, or hash to check.
        indicator_type: One of "domain", "url", "ip", "hash", or "auto" (default).
    """
    api_key = _get_env("VIRUSTOTAL_API_KEY")
    headers = {"x-apikey": api_key}
    base = "https://www.virustotal.com/api/v3"

    # Auto-detect type
    if indicator_type == "auto":
        if indicator.startswith(("http://", "https://")):
            indicator_type = "url"
        elif all(c in "0123456789abcdefABCDEF" for c in indicator) and len(indicator) in (32, 40, 64):
            indicator_type = "hash"
        elif indicator.replace(".", "").isdigit() or ":" in indicator:
            indicator_type = "ip"
        else:
            indicator_type = "domain"

    try:
        if indicator_type == "domain":
            data = _http_get(f"{base}/domains/{indicator}", headers)
        elif indicator_type == "ip":
            data = _http_get(f"{base}/ip_addresses/{indicator}", headers)
        elif indicator_type == "hash":
            data = _http_get(f"{base}/files/{indicator}", headers)
        elif indicator_type == "url":
            url_id = urllib.parse.quote_plus(indicator).replace("+", "%20")
            # VT uses base64url of the URL as the ID
            import base64
            url_id = base64.urlsafe_b64encode(indicator.encode()).decode().rstrip("=")
            data = _http_get(f"{base}/urls/{url_id}", headers)
        else:
            return f"Unknown indicator_type: {indicator_type}"
    except urllib.error.HTTPError as e:
        if e.code == 404:
            return f"Not found on VirusTotal: {indicator}"
        if e.code == 429:
            return "VirusTotal rate limit hit (4 req/min or 500/day). Wait and retry."
        return f"VirusTotal error: HTTP {e.code}"

    attrs = data.get("data", {}).get("attributes", {})
    stats = attrs.get("last_analysis_stats", {})
    reputation = attrs.get("reputation", "N/A")

    malicious = stats.get("malicious", 0)
    suspicious = stats.get("suspicious", 0)
    harmless = stats.get("harmless", 0)
    undetected = stats.get("undetected", 0)
    total = malicious + suspicious + harmless + undetected

    result = {
        "indicator": indicator,
        "type": indicator_type,
        "malicious": malicious,
        "suspicious": suspicious,
        "harmless": harmless,
        "undetected": undetected,
        "total_engines": total,
        "reputation_score": reputation,
        "verdict": "MALICIOUS" if malicious > 2 else "SUSPICIOUS" if (malicious > 0 or suspicious > 2) else "CLEAN",
    }

    # Type-specific fields
    if indicator_type == "domain":
        result["creation_date"] = _age(attrs.get("creation_date"))
        result["registrar"] = attrs.get("registrar", "unknown")
        result["categories"] = attrs.get("categories", {})
        result["last_analysis_date"] = _age(attrs.get("last_analysis_date"))
    elif indicator_type == "ip":
        result["country"] = attrs.get("country", "unknown")
        result["as_owner"] = attrs.get("as_owner", "unknown")
        result["asn"] = attrs.get("asn", "unknown")
    elif indicator_type == "hash":
        result["file_name"] = attrs.get("meaningful_name", attrs.get("names", ["unknown"])[0] if attrs.get("names") else "unknown")
        result["file_type"] = attrs.get("type_description", "unknown")
        result["file_size"] = attrs.get("size", "unknown")
        result["first_seen"] = _age(attrs.get("first_submission_date"))

    return json.dumps(result, indent=2)


# ---------------------------------------------------------------------------
# URLhaus (abuse.ch)
# ---------------------------------------------------------------------------

@mcp.tool()
def urlhaus_lookup(indicator: str, lookup_type: str = "auto") -> str:
    """Look up a host or URL on URLhaus (abuse.ch malware URL database).

    Args:
        indicator: A domain/host or full URL to check.
        lookup_type: "host", "url", or "auto" (default).
    """
    auth_key = _get_env("ABUSECH_AUTH_KEY")
    headers = {"Auth-Key": auth_key}
    base = "https://urlhaus-api.abuse.ch/v1"

    if lookup_type == "auto":
        lookup_type = "url" if indicator.startswith(("http://", "https://")) else "host"

    try:
        if lookup_type == "host":
            data = _http_post(f"{base}/host/", data={"host": indicator}, headers=headers)
        else:
            data = _http_post(f"{base}/url/", data={"url": indicator}, headers=headers)
    except urllib.error.HTTPError as e:
        return f"URLhaus error: HTTP {e.code}"

    status = data.get("query_status", "unknown")

    if status == "no_results":
        return json.dumps({"indicator": indicator, "verdict": "NOT FOUND", "detail": "No URLhaus records for this indicator"})

    result = {
        "indicator": indicator,
        "query_status": status,
    }

    if lookup_type == "host":
        result["urls_online"] = data.get("urls_online", 0)
        result["blacklists"] = data.get("blacklists", {})
        urls = data.get("urls", [])
        result["total_urls_tracked"] = len(urls)
        result["recent_urls"] = [
            {
                "url": u.get("url", ""),
                "status": u.get("url_status", ""),
                "threat": u.get("threat", ""),
                "date_added": u.get("date_added", ""),
                "tags": u.get("tags", []),
            }
            for u in urls[:5]
        ]
        result["verdict"] = "MALICIOUS" if data.get("urls_online", 0) > 0 else "PREVIOUSLY FLAGGED" if urls else "CLEAN"
    else:
        result["threat"] = data.get("threat", "unknown")
        result["url_status"] = data.get("url_status", "unknown")
        result["date_added"] = data.get("date_added", "")
        result["tags"] = data.get("tags", [])
        result["payloads"] = [
            {
                "filename": p.get("filename", ""),
                "file_type": p.get("file_type", ""),
                "sha256": p.get("response_sha256", ""),
                "signature": p.get("signature", ""),
            }
            for p in (data.get("payloads") or [])[:5]
        ]
        result["verdict"] = "MALICIOUS" if data.get("threat") else "UNKNOWN"

    return json.dumps(result, indent=2)


# ---------------------------------------------------------------------------
# ThreatFox (abuse.ch)
# ---------------------------------------------------------------------------

@mcp.tool()
def threatfox_lookup(indicator: str, search_type: str = "ioc") -> str:
    """Search ThreatFox for an IOC (IP, domain, URL, hash) or malware family.

    Args:
        indicator: The IOC value or malware name to search.
        search_type: "ioc" to search by indicator value, "malware" to search by malware name. Default "ioc".
    """
    auth_key = _get_env("ABUSECH_AUTH_KEY")
    headers = {"Auth-Key": auth_key}
    url = "https://threatfox-api.abuse.ch/api/v1/"

    if search_type == "malware":
        payload = {"query": "malwareinfo", "search_term": indicator}
    else:
        payload = {"query": "search_ioc", "search_term": indicator}

    try:
        data = _http_post(url, data=payload, headers=headers, is_json=True)
    except urllib.error.HTTPError as e:
        return f"ThreatFox error: HTTP {e.code}"

    status = data.get("query_status", "unknown")

    if status == "no_result":
        return json.dumps({"indicator": indicator, "verdict": "NOT FOUND", "detail": "No ThreatFox records"})

    iocs = data.get("data", []) or []

    result = {
        "indicator": indicator,
        "total_matches": len(iocs),
        "matches": [
            {
                "ioc": i.get("ioc", ""),
                "ioc_type": i.get("ioc_type", ""),
                "threat_type": i.get("threat_type", ""),
                "malware": i.get("malware_printable", ""),
                "confidence": i.get("confidence_level", ""),
                "first_seen": i.get("first_seen_utc", ""),
                "last_seen": i.get("last_seen_utc", ""),
                "tags": i.get("tags", []),
                "reporter": i.get("reporter", ""),
            }
            for i in iocs[:10]
        ],
        "verdict": "MALICIOUS" if iocs else "NOT FOUND",
    }

    return json.dumps(result, indent=2)


# ---------------------------------------------------------------------------
# crt.sh (Certificate Transparency)
# ---------------------------------------------------------------------------

@mcp.tool()
def crt_lookup(domain: str, include_expired: bool = True) -> str:
    """Look up certificate transparency records for a domain via crt.sh.

    Args:
        domain: The domain to search (e.g. "example.com"). Supports wildcards like "%.example.com".
        include_expired: Include expired certificates. Default True.
    """
    params = urllib.parse.urlencode({"q": domain, "output": "json"})
    if not include_expired:
        params += "&exclude=expired"

    try:
        data = _http_get(f"https://crt.sh/?{params}")
    except urllib.error.HTTPError as e:
        return f"crt.sh error: HTTP {e.code}"
    except Exception as e:
        return f"crt.sh error: {e}"

    if not data:
        return json.dumps({"domain": domain, "certificates": 0, "detail": "No certificates found"})

    # Deduplicate by serial number
    seen = set()
    unique = []
    for cert in data:
        serial = cert.get("serial_number", "")
        if serial not in seen:
            seen.add(serial)
            unique.append(cert)

    # Sort by most recent first
    unique.sort(key=lambda c: c.get("not_before", ""), reverse=True)

    result = {
        "domain": domain,
        "total_certificates": len(unique),
        "unique_issuers": list({c.get("issuer_name", "") for c in unique}),
        "earliest_cert": unique[-1].get("not_before", "") if unique else "",
        "latest_cert": unique[0].get("not_before", "") if unique else "",
        "recent_certificates": [
            {
                "common_name": c.get("common_name", ""),
                "name_value": c.get("name_value", ""),
                "issuer": c.get("issuer_name", ""),
                "not_before": c.get("not_before", ""),
                "not_after": c.get("not_after", ""),
                "serial": c.get("serial_number", ""),
            }
            for c in unique[:15]
        ],
    }

    return json.dumps(result, indent=2)


# ---------------------------------------------------------------------------
# Run
# ---------------------------------------------------------------------------

if __name__ == "__main__":
    mcp.run()
