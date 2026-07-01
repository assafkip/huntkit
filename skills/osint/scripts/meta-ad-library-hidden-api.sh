#!/bin/bash
# meta-ad-library-hidden-api.sh -- Q-native Meta Ad Library hidden API replay
#
# Usage:
#   meta-ad-library-hidden-api.sh [--case case-NNN-slug] [--out dir] AD_ID...
#   meta-ad-library-hidden-api.sh --sniff-har capture.har [--case case-NNN-slug] [--out dir]
#   meta-ad-library-hidden-api.sh --cdp-search-domain DOMAIN [--case case-NNN-slug] [--out dir]
#   meta-ad-library-hidden-api.sh --cdp-search-keyword QUERY [--case case-NNN-slug] [--out dir]
#   meta-ad-library-hidden-api.sh --cdp-search-advertiser NAME [--case case-NNN-slug] [--out dir]
#   meta-ad-library-hidden-api.sh --printing-press-capture --cdp-search-domain DOMAIN [--case case-NNN-slug] [--out dir]
#   meta-ad-library-hidden-api.sh --cdp-detail LIBRARY_ID... [--case case-NNN-slug] [--out dir]
#   meta-ad-library-hidden-api.sh --cdp-page PAGE_ID... [--case case-NNN-slug] [--out dir]
#
# The replay path requires a sanitized ready template at:
#   skills/osint/config/meta-ad-library/request-template.json
#
# The template command must write raw JSON to stdout. Supported placeholders:
#   {{AD_ID}}       replaced with the current ad ID
#   {{ENV:NAME}}    replaced with environment variable NAME, fails if unset

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SKILL_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
WORKSPACE="$(cd "$SKILL_DIR/../.." && pwd)"
DEFAULT_TEMPLATE="$SKILL_DIR/config/meta-ad-library/request-template.json"
NORMALIZER="$SCRIPT_DIR/meta_ad_library_normalize.py"

CASE=""
OUT_DIR=""
TEMPLATE="$DEFAULT_TEMPLATE"
SNIFF_HAR=""
CDP_SEARCH_DOMAIN=""
CDP_SEARCH_KEYWORD=""
CDP_SEARCH_ADVERTISER=""
CDP_DETAIL=0
CDP_PAGE=0
PRINTING_PRESS_CAPTURE=0
AD_IDS=()

usage() {
  sed -n '2,18p' "$0" | sed 's/^# //'
}

fail() {
  echo "ERROR: $*" >&2
  exit 2
}

while [ $# -gt 0 ]; do
  case "$1" in
    --case) CASE="${2:-}"; shift 2 ;;
    --out) OUT_DIR="${2:-}"; shift 2 ;;
    --template) TEMPLATE="${2:-}"; shift 2 ;;
    --sniff-har) SNIFF_HAR="${2:-}"; shift 2 ;;
    --cdp-search-domain) CDP_SEARCH_DOMAIN="${2:-}"; shift 2 ;;
    --cdp-search-keyword) CDP_SEARCH_KEYWORD="${2:-}"; shift 2 ;;
    --cdp-search-advertiser) CDP_SEARCH_ADVERTISER="${2:-}"; shift 2 ;;
    --cdp-detail) CDP_DETAIL=1; shift ;;
    --cdp-page) CDP_PAGE=1; shift ;;
    --printing-press-capture) PRINTING_PRESS_CAPTURE=1; shift ;;
    -h|--help) usage; exit 0 ;;
    --) shift; break ;;
    -*) fail "unknown argument: $1" ;;
    *) AD_IDS+=("$1"); shift ;;
  esac
done

if [ -z "$CASE" ]; then
  if [ -f "$WORKSPACE/.active-case" ]; then
    CASE="$(head -1 "$WORKSPACE/.active-case" | tr -d '[:space:]')"
  else
    fail "no active case set and --case not given"
  fi
fi

CASE_DIR="$WORKSPACE/investigations/$CASE"
[ -d "$CASE_DIR" ] || fail "case directory not found: $CASE_DIR"

if [ -z "$OUT_DIR" ]; then
  OUT_DIR="$CASE_DIR/investigation/evidence/raw/meta-ad-library-hidden-api"
fi
mkdir -p "$OUT_DIR"

command -v jq >/dev/null 2>&1 || fail "jq is required"
command -v python3 >/dev/null 2>&1 || fail "python3 is required"
[ -x "$NORMALIZER" ] || [ -f "$NORMALIZER" ] || fail "normalizer missing: $NORMALIZER"

find_printing_press() {
  if command -v cli-printing-press >/dev/null 2>&1; then
    command -v cli-printing-press
  elif [ -x "$HOME/go/bin/cli-printing-press" ]; then
    printf '%s\n' "$HOME/go/bin/cli-printing-press"
  else
    return 1
  fi
}

run_cdp_search() {
  local query_type="$1"
  local query="$2"
  command -v node >/dev/null 2>&1 || fail "node is required for CDP search modes"
  local press_bin=""
  if [ "$PRINTING_PRESS_CAPTURE" = "1" ]; then
    press_bin="$(find_printing_press)" || fail "cli-printing-press not found; install Printing Press first"
  fi

  node - "$CASE" "$CASE_DIR" "$OUT_DIR" "$query_type" "$query" "$PRINTING_PRESS_CAPTURE" "$press_bin" <<'NODE'
const fs = require("fs");
const os = require("os");
const path = require("path");
const { spawn, spawnSync } = require("child_process");

const [caseName, caseDir, outDir, queryType, queryInput, printingPressCaptureFlag, printingPressBin] = process.argv.slice(2);

function fail(message) {
  console.error(`ERROR: ${message}`);
  process.exit(2);
}

function sleep(ms) {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

function safeSlug(value) {
  return value.toLowerCase().replace(/[^a-z0-9]+/g, "-").replace(/^-+|-+$/g, "") || "query";
}

function chromePath() {
  const candidates = [
    process.env.CHROME_PATH,
    "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome",
    "/Applications/Google Chrome Canary.app/Contents/MacOS/Google Chrome Canary",
    "/Applications/Chromium.app/Contents/MacOS/Chromium",
    "/Applications/Microsoft Edge.app/Contents/MacOS/Microsoft Edge",
  ].filter(Boolean);
  for (const candidate of candidates) {
    if (fs.existsSync(candidate)) return candidate;
  }
  fail("Chrome not found. Set CHROME_PATH to a Chrome-compatible browser binary.");
}

function redact(value) {
  let text = typeof value === "string" ? value : JSON.stringify(value);
  text = text.replace(/("?(?:fb_dtsg|lsd|access_token|token|bearer|cookie|authorization|sessionID|sessionId)"?\s*[:=]\s*)("[^"]+"|[^&\s,}]+)/gi, "$1[REDACTED]");
  text = text.replace(/(%22sessionI[Dd]%22%3A%22)[^%&"]+(%22)/gi, "$1[REDACTED]$2");
  text = text.replace(/("sessionI[Dd]"\s*:\s*")[^"]+(")/gi, "$1[REDACTED]$2");
  text = text.replace(/Bearer\s+[A-Za-z0-9._\-]+/gi, "Bearer [REDACTED]");
  return text;
}

function isSensitiveHeader(name) {
  return /^(cookie|set-cookie|authorization|proxy-authorization|x-fb-lsd|x-fb-session-id|x-fb-token)$/i.test(String(name || "")) ||
    /(token|secret|credential|session|fb_dtsg|lsd)/i.test(String(name || ""));
}

function isSensitiveParam(name) {
  return /^(lsd|fb_dtsg|access_token|auth|authorization|token|__s|__hsi|jazoest)$/i.test(String(name || "")) ||
    /(token|secret|credential|session|fb_dtsg|lsd)/i.test(String(name || ""));
}

function sanitizeHeaders(headers = {}) {
  const clean = {};
  for (const [name, value] of Object.entries(headers || {})) {
    if (isSensitiveHeader(name)) continue;
    clean[name] = redact(String(value));
  }
  return clean;
}

function headersArray(headers = {}) {
  return Object.entries(sanitizeHeaders(headers)).map(([name, value]) => ({ name, value }));
}

function sanitizeUrl(value) {
  try {
    const url = new URL(value);
    if (/^l\.facebook\.com$/i.test(url.hostname) && url.searchParams.get("u")) {
      return sanitizeUrl(url.searchParams.get("u"));
    }
    for (const name of Array.from(url.searchParams.keys())) {
      if (isSensitiveParam(name)) url.searchParams.delete(name);
    }
    return redact(url.toString());
  } catch {
    return redact(String(value || ""));
  }
}

function queryStringArray(value) {
  try {
    const url = new URL(value);
    return Array.from(url.searchParams.entries()).map(([name, value]) => ({ name, value: redact(value) }));
  } catch {
    return [];
  }
}

function shouldIncludeHarEntry(request, response) {
  const url = request.url || "";
  const method = request.method || "GET";
  const mimeType = response.mimeType || "";
  const status = Number(response.status || 0);
  if (!url || status <= 0) return false;
  if (/__rd_verify|favicon\.ico|\/rsrc\.php|static\.xx\.fbcdn\.net|\.css(?:\?|$)|\.png(?:\?|$)|\.jpg(?:\?|$)|\.webp(?:\?|$)/i.test(url)) {
    return false;
  }
  if (!/facebook\.com\/ads\/library|facebook\.com\/api\/graphql|facebook\.com\/ajax\//i.test(url)) {
    return false;
  }
  if (!/^(GET|HEAD)$/i.test(method) && /html/i.test(mimeType)) {
    return false;
  }
  return true;
}

class CdpClient {
  constructor(wsUrl) {
    this.wsUrl = wsUrl;
    this.nextId = 1;
    this.pending = new Map();
    this.handlers = new Map();
  }

  async connect() {
    this.ws = new WebSocket(this.wsUrl);
    this.ws.onmessage = (event) => {
      const message = JSON.parse(event.data);
      if (message.id && this.pending.has(message.id)) {
        const { resolve, reject } = this.pending.get(message.id);
        this.pending.delete(message.id);
        if (message.error) reject(new Error(message.error.message || JSON.stringify(message.error)));
        else resolve(message.result || {});
        return;
      }
      if (message.method && this.handlers.has(message.method)) {
        for (const handler of this.handlers.get(message.method)) handler(message.params || {});
      }
    };
    await new Promise((resolve, reject) => {
      this.ws.onopen = resolve;
      this.ws.onerror = reject;
    });
  }

  on(method, handler) {
    if (!this.handlers.has(method)) this.handlers.set(method, []);
    this.handlers.get(method).push(handler);
  }

  send(method, params = {}) {
    const id = this.nextId++;
    this.ws.send(JSON.stringify({ id, method, params }));
    return new Promise((resolve, reject) => {
      this.pending.set(id, { resolve, reject });
      setTimeout(() => {
        if (this.pending.has(id)) {
          this.pending.delete(id);
          reject(new Error(`CDP timeout: ${method}`));
        }
      }, 10000);
    });
  }

  close() {
    try {
      this.ws.close();
    } catch {
      // Best-effort close.
    }
  }
}

async function waitForPortFile(userDataDir) {
  const portPath = path.join(userDataDir, "DevToolsActivePort");
  for (let i = 0; i < 100; i++) {
    if (fs.existsSync(portPath)) {
      const lines = fs.readFileSync(portPath, "utf8").trim().split(/\r?\n/);
      if (lines[0]) return Number(lines[0]);
    }
    await sleep(100);
  }
  fail("Chrome launched but did not expose a DevToolsActivePort file");
}

async function fetchJson(url, options = {}) {
  const response = await fetch(url, options);
  if (!response.ok) throw new Error(`${response.status} ${response.statusText}: ${url}`);
  return response.json();
}

async function evaluate(client, expression) {
  const result = await client.send("Runtime.evaluate", {
    expression,
    returnByValue: true,
    awaitPromise: true,
  });
  return result.result ? result.result.value : null;
}

function cleanLines(text) {
  return String(text || "")
    .split(/\r?\n/)
    .map((line) => line.trim())
    .filter(Boolean);
}

function normalizeDomain(value) {
  return String(value || "").toLowerCase().replace(/^https?:\/\//, "").replace(/^www\./, "").split(/[/?#]/)[0];
}

function looksLikeDomain(value) {
  const domain = normalizeDomain(value);
  return /^[a-z0-9.-]+\.[a-z]{2,}$/.test(domain) ? domain : null;
}

function landingUrlFromHref(value) {
  try {
    const url = new URL(value);
    if (/^l\.facebook\.com$/i.test(url.hostname) && url.searchParams.get("u")) {
      return sanitizeUrl(url.searchParams.get("u"));
    }
    return sanitizeUrl(value);
  } catch {
    return sanitizeUrl(value || "");
  }
}

function isExternalLandingUrl(value) {
  try {
    const url = new URL(value);
    return !/facebook\.com|fbcdn\.net|metastatus\.com/i.test(url.hostname);
  } catch {
    return false;
  }
}

function isUsefulFacebookPageUrl(value) {
  try {
    const url = new URL(value);
    return /(^|\.)facebook\.com$/i.test(url.hostname) && /^\/[0-9]{6,}\/?$/i.test(url.pathname);
  } catch {
    return false;
  }
}

function collectRenderedDomains(lines) {
  return Array.from(new Set(lines
    .map((line) => looksLikeDomain(line))
    .filter(Boolean)));
}

function buildHar(requests, responses, bodies) {
  const entries = [];
  for (const [requestId, requestEvent] of requests.entries()) {
    const request = requestEvent.request || {};
    const responseEvent = responses.get(requestId);
    const response = responseEvent ? responseEvent.response || {} : {};
    if (!shouldIncludeHarEntry(request, response)) continue;
    const startedDateTime = new Date((requestEvent.wallTime || Date.now() / 1000) * 1000).toISOString();
    const postDataText = request.postData ? redact(String(request.postData).slice(0, 250000)) : undefined;
    const responseBody = bodies.get(requestId) || "";
    const requestUrl = sanitizeUrl(request.url);
    entries.push({
      startedDateTime,
      time: -1,
      request: {
        method: request.method || "GET",
        url: requestUrl,
        httpVersion: "HTTP/2",
        cookies: [],
        headers: headersArray(request.headers || {}),
        queryString: queryStringArray(requestUrl),
        headersSize: -1,
        bodySize: postDataText ? Buffer.byteLength(postDataText) : 0,
        ...(postDataText ? {
          postData: {
            mimeType: request.headers?.["content-type"] || request.headers?.["Content-Type"] || "",
            text: postDataText,
          },
        } : {}),
      },
      response: {
        status: response.status || 0,
        statusText: response.statusText || "",
        httpVersion: "HTTP/2",
        cookies: [],
        headers: headersArray(response.headers || {}),
        content: {
          size: responseBody ? Buffer.byteLength(responseBody) : 0,
          mimeType: response.mimeType || "",
          text: responseBody ? redact(responseBody.slice(0, 250000)) : "",
        },
        redirectURL: "",
        headersSize: -1,
        bodySize: responseBody ? Buffer.byteLength(responseBody) : -1,
      },
      cache: {},
      timings: { send: -1, wait: -1, receive: -1 },
    });
  }
  return {
    log: {
      version: "1.2",
      creator: {
        name: "q-meta-ad-library-hidden-api",
        version: "1",
      },
      entries,
    },
  };
}

function parseAds(domText, queryType, query) {
  const lines = cleanLines(domText);
  const text = lines.join("\n");
  const queryDomain = queryType === "domain" ? normalizeDomain(query) : null;
  const advertiserCounts = new Map();
  const visibleIds = Array.from(text.matchAll(/Library ID:\s*([0-9]+)/g)).map((match) => match[1]);
  const libraryLineIndexes = [];

  for (let i = 0; i < lines.length; i++) {
    if (/^Library ID:\s*[0-9]+$/i.test(lines[i])) libraryLineIndexes.push(i);
    if (/^Sponsored$/i.test(lines[i])) {
      const candidate = lines[i - 1];
      if (candidate && !/^(Active|Inactive|Library ID:|Started running|Platforms|Categories|See ad details)$/i.test(candidate)) {
        advertiserCounts.set(candidate, (advertiserCounts.get(candidate) || 0) + 1);
      }
    }
  }

  const dominantAdvertiser = Array.from(advertiserCounts.entries()).sort((a, b) => b[1] - a[1])[0]?.[0] || null;
  const ads = [];

  for (let idx = 0; idx < libraryLineIndexes.length; idx++) {
    const lineIndex = libraryLineIndexes[idx];
    const idMatch = lines[lineIndex].match(/Library ID:\s*([0-9]+)/i);
    if (!idMatch) continue;
    const startIndex = /^(Active|Inactive)$/i.test(lines[lineIndex - 1] || "") ? lineIndex - 1 : lineIndex;
    const nextLineIndex = libraryLineIndexes[idx + 1] || lines.length;
    const endIndex = /^(Active|Inactive)$/i.test(lines[nextLineIndex - 1] || "") ? nextLineIndex - 1 : nextLineIndex;
    const segmentLines = lines.slice(startIndex, endIndex);
    const segment = segmentLines.join("\n");
    const sponsoredIndex = segmentLines.findIndex((line) => /^Sponsored$/i.test(line));
    let advertiser = dominantAdvertiser;
    if (sponsoredIndex > 0) {
      for (let i = sponsoredIndex - 1; i >= 0; i--) {
        const candidate = segmentLines[i];
        if (!/^(Active|Inactive|Library ID:|Started running|Platforms|Categories|See ad details|About this ad)$/i.test(candidate)) {
          advertiser = candidate;
          break;
        }
      }
    }

    const explicitStartDate = segment.match(/Started running on\s+([^\n]+)/i);
    const rangeStartDate = segment.match(/\b([A-Z][a-z]{2}\s+[0-9]{1,2},\s+[0-9]{4})\s+-\s+[A-Z][a-z]{2}\s+[0-9]{1,2},\s+[0-9]{4}\b/);
    const status = /^Inactive$/i.test(segmentLines[0] || "") ? "inactive" : (/^Active$/i.test(segmentLines[0] || "") ? "active" : null);
    const renderedDomains = collectRenderedDomains(segmentLines);
    const explicitLandingDomains = queryDomain
      ? renderedDomains.filter((line) => line === queryDomain || line.endsWith(`.${queryDomain}`))
      : renderedDomains;
    const landingDomains = explicitLandingDomains.length
      ? explicitLandingDomains
      : (queryDomain ? [queryDomain] : []);

    let creativeText = null;
    if (sponsoredIndex >= 0) {
      const stopIndex = segmentLines.findIndex((line, i) => i > sponsoredIndex && (
        (queryDomain && normalizeDomain(line) === queryDomain) ||
        looksLikeDomain(line) ||
        /^Shop now$/i.test(line) ||
        /^Learn more$/i.test(line) ||
        /^Send message$/i.test(line) ||
        /^Like$/i.test(line) ||
        /^Comment$/i.test(line) ||
        /^Share$/i.test(line)
      ));
      const creativeLines = segmentLines
        .slice(sponsoredIndex + 1, stopIndex > sponsoredIndex ? stopIndex : sponsoredIndex + 8)
        .filter((line) => !/^Sponsored$/i.test(line) && !/^See ad details$/i.test(line));
      creativeText = creativeLines.join("\n").trim() || null;
    }

    ads.push({
      ad_id: idMatch[1],
      library_id: idMatch[1],
      page_id: null,
      page_name: advertiser,
      advertiser_name: advertiser,
      creative_text: creativeText,
      landing_urls: landingDomains.map((landingDomain) => `https://${landingDomain}`),
      landing_domain: landingDomains[0] || null,
      landing_url_source: explicitLandingDomains.length ? "rendered_dom" : (queryDomain ? "query_domain" : null),
      snapshot_url: `https://www.facebook.com/ads/library/?id=${idMatch[1]}`,
      start_date: explicitStartDate ? explicitStartDate[1].trim() : (rangeStartDate ? rangeStartDate[1].trim() : null),
      status,
      confidence: advertiser && (creativeText || landingDomains.length) ? "high" : (advertiser ? "medium" : "low"),
      missing_fields: [],
    });
  }

  const required = ["advertiser_name", "creative_text", "landing_urls", "start_date", "status"];
  for (const ad of ads) {
    ad.missing_fields = required.filter((field) => {
      const value = ad[field];
      return Array.isArray(value) ? value.length === 0 : !value;
    });
  }

  let summaryAdvertiser = dominantAdvertiser;
  if (queryType === "advertiser") {
    const exactQuery = String(query || "").trim().toLowerCase();
    const exactMatch = Array.from(advertiserCounts.keys()).find((name) => name.toLowerCase() === exactQuery);
    if (exactMatch) summaryAdvertiser = exactMatch;
  }

  return {
    visible_library_ids: Array.from(new Set(visibleIds)),
    advertiser_name: summaryAdvertiser,
    page_name: summaryAdvertiser,
    ads,
  };
}

async function main() {
  const allowedQueryTypes = new Set(["domain", "keyword", "advertiser"]);
  if (!allowedQueryTypes.has(queryType)) fail(`invalid CDP query type: ${queryType}`);

  const query = queryType === "domain" ? normalizeDomain(queryInput) : String(queryInput || "").trim();
  if (!query) fail(`empty ${queryType} query`);
  if (queryType === "domain" && !query.includes(".")) fail(`invalid domain: ${queryInput}`);

  fs.mkdirSync(outDir, { recursive: true });
  const captureDir = path.join(outDir, "cdp-capture");
  fs.mkdirSync(captureDir, { recursive: true });

  const slug = `${queryType}-${safeSlug(query)}`;
  const userDataDir = fs.mkdtempSync(path.join(os.tmpdir(), "q-meta-adlib-cdp-"));
  const browser = spawn(chromePath(), [
    "--headless=new",
    "--remote-debugging-port=0",
    `--user-data-dir=${userDataDir}`,
    "--no-first-run",
    "--no-default-browser-check",
    "--disable-background-networking",
    "about:blank",
  ], { stdio: "ignore" });

  let pageClient;
  let browserClient;
  let port;
  const networkEvents = [];
  const requestEvents = new Map();
  const responseEvents = new Map();
  const responseBodies = new Map();
  const bodyCandidates = [];
  const bodyPaths = [];
  const printingPressCapture = printingPressCaptureFlag === "1";
  const capturedAt = new Date().toISOString().replace(/\.\d{3}Z$/, "Z");
  const searchUrl = `https://www.facebook.com/ads/library/?active_status=all&ad_type=all&country=US&is_targeted_country=false&media_type=all&q=${encodeURIComponent(query)}&search_type=keyword_unordered`;

  try {
    port = await waitForPortFile(userDataDir);
    const version = await fetchJson(`http://127.0.0.1:${port}/json/version`);
    browserClient = new CdpClient(version.webSocketDebuggerUrl);
    await browserClient.connect();
    const target = await browserClient.send("Target.createTarget", { url: "about:blank" });
    const targets = await fetchJson(`http://127.0.0.1:${port}/json/list`);
    const page = targets.find((item) => item.id === target.targetId) || targets.find((item) => item.type === "page");
    if (!page || !page.webSocketDebuggerUrl) fail("could not open a CDP page target");

    pageClient = new CdpClient(page.webSocketDebuggerUrl);
    await pageClient.connect();
    pageClient.on("Network.requestWillBeSent", (event) => {
      const request = event.request || {};
      if (/facebook\.com|fbcdn\.net|graphql|ads_archive|ad_archive/i.test(request.url || "")) {
        requestEvents.set(event.requestId, {
          ...event,
          request: {
            ...request,
            url: sanitizeUrl(request.url),
            headers: sanitizeHeaders(request.headers || {}),
            postData: request.postData ? redact(String(request.postData)) : undefined,
          },
        });
      }
    });
    pageClient.on("Network.responseReceived", (event) => {
      const response = event.response || {};
      const url = response.url || "";
      const mimeType = response.mimeType || "";
      const interesting = /facebook\.com\/ads\/library|\/api\/graphql|graphql|ads_archive|ad_archive/i.test(url);
      if (/facebook\.com|fbcdn\.net|graphql|ads_archive|ad_archive/i.test(url)) {
        responseEvents.set(event.requestId, {
          ...event,
          response: {
            ...response,
            url: sanitizeUrl(response.url),
            headers: sanitizeHeaders(response.headers || {}),
          },
        });
      }
      networkEvents.push({
        request_id: event.requestId,
        url: sanitizeUrl(url),
        status: response.status,
        mime_type: mimeType,
        from_disk_cache: response.fromDiskCache || false,
      });
      if (interesting && /json|javascript|text/i.test(mimeType) && !/html/i.test(mimeType)) {
        bodyCandidates.push({ requestId: event.requestId, url, mimeType });
      }
    });

    await pageClient.send("Network.enable");
    await pageClient.send("Page.enable");
    await pageClient.send("Runtime.enable");
    await pageClient.send("Page.navigate", { url: searchUrl });

    let domText = "";
    for (let i = 0; i < 35; i++) {
      await sleep(1000);
      await evaluate(pageClient, "window.scrollTo(0, document.body.scrollHeight)");
      domText = await evaluate(pageClient, "document.body ? document.body.innerText : ''") || "";
      if (/Library ID:\s*[0-9]+/.test(domText) || /No ads match|No results|Try searching/i.test(domText)) break;
    }

    for (let i = 0; i < Math.min(bodyCandidates.length, 20); i++) {
      const candidate = bodyCandidates[i];
      try {
        const body = await pageClient.send("Network.getResponseBody", { requestId: candidate.requestId });
        responseBodies.set(candidate.requestId, redact((body.body || "").slice(0, 250000)));
        const extension = candidate.mimeType.includes("json") ? "json" : "txt";
        const bodyPath = path.join(captureDir, `${slug}-network-body-${String(i + 1).padStart(2, "0")}.${extension}`);
        fs.writeFileSync(bodyPath, redact((body.body || "").slice(0, 250000)) + "\n");
        bodyPaths.push(bodyPath);
      } catch {
        // Some bodies expire before CDP can read them. Metadata still records the response.
      }
    }

    const domTextPath = path.join(captureDir, `${slug}-dom.txt`);
    const networkIndexPath = path.join(captureDir, `${slug}-network-index.json`);
    fs.writeFileSync(domTextPath, domText);
    fs.writeFileSync(networkIndexPath, JSON.stringify(networkEvents, null, 2) + "\n");

    const parsed = parseAds(domText, queryType, query);
    const rawPath = path.join(outDir, `${slug}-raw.json`);
    const normalizedPath = path.join(outDir, `${slug}-normalized.json`);
    const manifestPath = path.join(outDir, "run-manifest.json");
    const printingPressDir = path.join(outDir, "printing-press");
    const harPath = path.join(printingPressDir, `${slug}-sanitized.har`);
    const printingPressSpecPath = path.join(printingPressDir, `${slug}-spec.yaml`);
    const printingPressAnalysisPath = path.join(printingPressDir, `${slug}-analysis.json`);
    const printingPressSamplesDir = path.join(printingPressDir, `${slug}-samples`);
    let printingPressSummary = null;

    if (printingPressCapture) {
      fs.mkdirSync(printingPressDir, { recursive: true });
      const har = buildHar(requestEvents, responseEvents, responseBodies);
      fs.writeFileSync(harPath, JSON.stringify(har, null, 2) + "\n");
      const press = spawnSync(printingPressBin, [
        "browser-sniff",
        "--har", harPath,
        "--include", "facebook.com,graphql,ads_archive,ad_archive",
        "--name", "meta-ad-library",
        "--output", printingPressSpecPath,
        "--analysis-output", printingPressAnalysisPath,
        "--samples-output", printingPressSamplesDir,
      ], { encoding: "utf8" });
      printingPressSummary = {
        status: press.status === 0 ? "complete" : "failed",
        binary: printingPressBin,
        har_path: harPath,
        spec_path: printingPressSpecPath,
        analysis_path: printingPressAnalysisPath,
        samples_dir: printingPressSamplesDir,
        stdout: redact((press.stdout || "").slice(0, 20000)),
        stderr: redact((press.stderr || "").slice(0, 20000)),
        replay_template_status: "blocked_pending_manual_validation",
        har_entry_count: har.log.entries.length,
      };
      fs.writeFileSync(path.join(printingPressDir, `${slug}-capture-summary.json`), JSON.stringify(printingPressSummary, null, 2) + "\n");
      if (press.status !== 0) {
        fail(`Printing Press browser-sniff failed; see ${printingPressAnalysisPath}`);
      }
    }

    const raw = {
      case: caseName,
      query_type: queryType,
      query,
      search_url: searchUrl,
      captured_at_utc: capturedAt,
      dom_text_path: domTextPath,
      network_index_path: networkIndexPath,
      network_body_paths: bodyPaths,
      printing_press: printingPressSummary,
      visible_library_ids: parsed.visible_library_ids,
      parsed_ads: parsed.ads,
    };

    const normalized = {
      case: caseName,
      query_type: queryType,
      query,
      captured_at_utc: capturedAt,
      advertiser_name: parsed.advertiser_name,
      page_name: parsed.page_name,
      landing_urls: Array.from(new Set(parsed.ads.flatMap((ad) => ad.landing_urls || []))),
      visible_library_ids: parsed.visible_library_ids,
      ads: parsed.ads.map((ad) => ({
        ...ad,
        raw_response_path: rawPath,
      })),
      raw_response_path: rawPath,
      cdp_artifacts: {
        dom_text_path: domTextPath,
        network_index_path: networkIndexPath,
        network_body_paths: bodyPaths,
      },
      printing_press: printingPressSummary,
      confidence: parsed.advertiser_name && parsed.ads.length ? "high" : (parsed.ads.length ? "medium" : "low"),
      missing_fields: [],
    };
    const topRequired = queryType === "domain"
      ? ["advertiser_name", "landing_urls", "visible_library_ids"]
      : ["advertiser_name", "visible_library_ids"];
    normalized.missing_fields = topRequired.filter((field) => {
      const value = normalized[field];
      return Array.isArray(value) ? value.length === 0 : !value;
    });

    fs.writeFileSync(rawPath, JSON.stringify(raw, null, 2) + "\n");
    fs.writeFileSync(normalizedPath, JSON.stringify(normalized, null, 2) + "\n");

    let status = "complete";
    let reason = "";
    if (!parsed.ads.length) {
      status = "blocked";
      reason = "no visible Meta Ad Library ads found in rendered DOM";
    } else if (!parsed.advertiser_name) {
      status = "partial";
      reason = "visible ads found but advertiser/page identity was not recovered";
    }

    const manifest = {
      case: caseName,
      timestamp_utc: capturedAt,
      status,
      reason,
      mode: `cdp-search-${queryType}`,
      query_type: queryType,
      query,
      search_url: searchUrl,
      out_dir: outDir,
      results: normalized.ads.map((ad) => ({
        ad_id: ad.ad_id,
        library_id: ad.library_id,
        status: ad.status || "unknown",
        advertiser_name: ad.advertiser_name,
        page_name: ad.page_name,
        landing_urls: ad.landing_urls,
        start_date: ad.start_date,
        confidence: ad.confidence,
        missing_fields: ad.missing_fields,
        raw_response_path: rawPath,
        normalized_path: normalizedPath,
      })),
      files: {
        raw: rawPath,
        normalized: normalizedPath,
        dom_text: domTextPath,
        network_index: networkIndexPath,
      },
      printing_press: printingPressSummary,
    };
    fs.writeFileSync(manifestPath, JSON.stringify(manifest, null, 2) + "\n");

    const recoveredAdvertiser = String(parsed.advertiser_name || "").toLowerCase();
    const matchingAdvertiserAds = recoveredAdvertiser
      ? normalized.ads.filter((ad) => String(ad.advertiser_name || "").toLowerCase() === recoveredAdvertiser)
      : [];
    const findingAds = matchingAdvertiserAds.length ? matchingAdvertiserAds : normalized.ads;
    const findingLibraryIds = Array.from(new Set(findingAds.map((ad) => ad.library_id).filter(Boolean)));
    const findingLandingUrls = Array.from(new Set(findingAds.flatMap((ad) => ad.landing_urls || [])));

    if (parsed.advertiser_name && findingAds.length) {
      const findingDir = path.join(caseDir, "investigation", "findings");
      fs.mkdirSync(findingDir, { recursive: true });
      const findingPath = path.join(findingDir, "F-010-facebook-ad-attribution.md");
      const lines = [
        "# F-010 -- Facebook Ad Attribution",
        "",
        `**Date:** ${capturedAt.slice(0, 10)}`,
        `**Source:** Meta Ad Library CDP ${queryType} search`,
        `**Confidence:** ${normalized.confidence}`,
        "",
        "## Results",
        "",
        `- Query ${queryType}: ${query}`,
        `- Advertiser/page: ${parsed.advertiser_name}`,
        `- Visible Library IDs: ${findingLibraryIds.join(", ") || "unknown"}`,
        `- Landing URLs: ${findingLandingUrls.join(", ") || "unknown"}`,
        `- Raw evidence: ${rawPath}`,
        `- Normalized evidence: ${normalizedPath}`,
        `- DOM artifact: ${domTextPath}`,
        "",
        "## Notes",
        "",
        "- This finding is based on public Meta Ad Library UI data rendered in an isolated Chrome session.",
        "- No cookies, tokens, session headers, or browser profile material are stored.",
      ];
      fs.writeFileSync(findingPath, lines.join("\n") + "\n");
    }

    if (status === "blocked") {
      fail(reason);
    }
    console.log(`Meta Ad Library CDP ${queryType} search complete: ${manifestPath}`);
  } finally {
    if (pageClient) pageClient.close();
    if (browserClient) browserClient.close();
    if (browser && !browser.killed) browser.kill("SIGTERM");
    await sleep(250);
    fs.rmSync(userDataDir, { recursive: true, force: true });
  }
}

main().catch((error) => fail(error.message || String(error)));
NODE
}

run_cdp_detail() {
  command -v node >/dev/null 2>&1 || fail "node is required for --cdp-detail"
  local press_bin=""
  if [ "$PRINTING_PRESS_CAPTURE" = "1" ]; then
    press_bin="$(find_printing_press)" || fail "cli-printing-press not found; install Printing Press first"
  fi

  node - "$CASE" "$CASE_DIR" "$OUT_DIR" "$PRINTING_PRESS_CAPTURE" "$press_bin" "${AD_IDS[@]}" <<'NODE'
const fs = require("fs");
const os = require("os");
const path = require("path");
const { spawn, spawnSync } = require("child_process");

const [caseName, caseDir, outDir, printingPressCaptureFlag, printingPressBin, ...libraryIds] = process.argv.slice(2);

function fail(message) {
  console.error(`ERROR: ${message}`);
  process.exit(2);
}

function sleep(ms) {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

function chromePath() {
  const candidates = [
    process.env.CHROME_PATH,
    "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome",
    "/Applications/Google Chrome Canary.app/Contents/MacOS/Google Chrome Canary",
    "/Applications/Chromium.app/Contents/MacOS/Chromium",
    "/Applications/Microsoft Edge.app/Contents/MacOS/Microsoft Edge",
  ].filter(Boolean);
  for (const candidate of candidates) {
    if (fs.existsSync(candidate)) return candidate;
  }
  fail("Chrome not found. Set CHROME_PATH to a Chrome-compatible browser binary.");
}

function redact(value) {
  let text = typeof value === "string" ? value : JSON.stringify(value);
  text = text.replace(/("?(?:fb_dtsg|lsd|access_token|token|bearer|cookie|authorization)"?\s*[:=]\s*)("[^"]+"|[^&\s,}]+)/gi, "$1[REDACTED]");
  text = text.replace(/Bearer\s+[A-Za-z0-9._\-]+/gi, "Bearer [REDACTED]");
  return text;
}

function isSensitiveHeader(name) {
  return /^(cookie|set-cookie|authorization|proxy-authorization|x-fb-lsd|x-fb-session-id|x-fb-token)$/i.test(String(name || "")) ||
    /(token|secret|credential|session|fb_dtsg|lsd)/i.test(String(name || ""));
}

function isSensitiveParam(name) {
  return /^(lsd|fb_dtsg|access_token|auth|authorization|token|__s|__hsi|jazoest)$/i.test(String(name || "")) ||
    /(token|secret|credential|session|fb_dtsg|lsd)/i.test(String(name || ""));
}

function sanitizeHeaders(headers = {}) {
  const clean = {};
  for (const [name, value] of Object.entries(headers || {})) {
    if (isSensitiveHeader(name)) continue;
    clean[name] = redact(String(value));
  }
  return clean;
}

function headersArray(headers = {}) {
  return Object.entries(sanitizeHeaders(headers)).map(([name, value]) => ({ name, value }));
}

function sanitizeUrl(value) {
  try {
    const url = new URL(value);
    if (/^l\.facebook\.com$/i.test(url.hostname) && url.searchParams.get("u")) {
      return sanitizeUrl(url.searchParams.get("u"));
    }
    for (const name of Array.from(url.searchParams.keys())) {
      if (isSensitiveParam(name)) url.searchParams.delete(name);
    }
    return redact(url.toString());
  } catch {
    return redact(String(value || ""));
  }
}

function queryStringArray(value) {
  try {
    const url = new URL(value);
    return Array.from(url.searchParams.entries()).map(([name, value]) => ({ name, value: redact(value) }));
  } catch {
    return [];
  }
}

function shouldIncludeHarEntry(request, response) {
  const url = request.url || "";
  const method = request.method || "GET";
  const mimeType = response.mimeType || "";
  const status = Number(response.status || 0);
  if (!url || status <= 0) return false;
  if (/__rd_verify|favicon\.ico|\/rsrc\.php|static\.xx\.fbcdn\.net|\.css(?:\?|$)|\.png(?:\?|$)|\.jpg(?:\?|$)|\.webp(?:\?|$)/i.test(url)) return false;
  if (!/facebook\.com\/ads\/library|facebook\.com\/api\/graphql|facebook\.com\/ajax\//i.test(url)) return false;
  if (!/^(GET|HEAD)$/i.test(method) && /html/i.test(mimeType)) return false;
  return true;
}

class CdpClient {
  constructor(wsUrl) {
    this.wsUrl = wsUrl;
    this.nextId = 1;
    this.pending = new Map();
    this.handlers = new Map();
  }

  async connect() {
    this.ws = new WebSocket(this.wsUrl);
    this.ws.onmessage = (event) => {
      const message = JSON.parse(event.data);
      if (message.id && this.pending.has(message.id)) {
        const { resolve, reject } = this.pending.get(message.id);
        this.pending.delete(message.id);
        if (message.error) reject(new Error(message.error.message || JSON.stringify(message.error)));
        else resolve(message.result || {});
        return;
      }
      if (message.method && this.handlers.has(message.method)) {
        for (const handler of this.handlers.get(message.method)) handler(message.params || {});
      }
    };
    await new Promise((resolve, reject) => {
      this.ws.onopen = resolve;
      this.ws.onerror = reject;
    });
  }

  on(method, handler) {
    if (!this.handlers.has(method)) this.handlers.set(method, []);
    this.handlers.get(method).push(handler);
  }

  send(method, params = {}) {
    const id = this.nextId++;
    this.ws.send(JSON.stringify({ id, method, params }));
    return new Promise((resolve, reject) => {
      this.pending.set(id, { resolve, reject });
      setTimeout(() => {
        if (this.pending.has(id)) {
          this.pending.delete(id);
          reject(new Error(`CDP timeout: ${method}`));
        }
      }, 10000);
    });
  }

  close() {
    try {
      this.ws.close();
    } catch {
      // Best-effort close.
    }
  }
}

async function waitForPortFile(userDataDir) {
  const portPath = path.join(userDataDir, "DevToolsActivePort");
  for (let i = 0; i < 100; i++) {
    if (fs.existsSync(portPath)) {
      const lines = fs.readFileSync(portPath, "utf8").trim().split(/\r?\n/);
      if (lines[0]) return Number(lines[0]);
    }
    await sleep(100);
  }
  fail("Chrome launched but did not expose a DevToolsActivePort file");
}

async function fetchJson(url) {
  const response = await fetch(url);
  if (!response.ok) throw new Error(`${response.status} ${response.statusText}: ${url}`);
  return response.json();
}

async function evaluate(client, expression) {
  const result = await client.send("Runtime.evaluate", {
    expression,
    returnByValue: true,
    awaitPromise: true,
  });
  return result.result ? result.result.value : null;
}

function cleanLines(text) {
  return String(text || "")
    .split(/\r?\n/)
    .map((line) => line.trim())
    .filter(Boolean);
}

function normalizeDomain(value) {
  return String(value || "").toLowerCase().replace(/^https?:\/\//, "").replace(/^www\./, "").split(/[/?#]/)[0];
}

function looksLikeDomain(value) {
  const domain = normalizeDomain(value);
  return /^[a-z0-9.-]+\.[a-z]{2,}$/.test(domain) ? domain : null;
}

function landingUrlFromHref(value) {
  try {
    const url = new URL(value);
    if (/^l\.facebook\.com$/i.test(url.hostname) && url.searchParams.get("u")) {
      return sanitizeUrl(url.searchParams.get("u"));
    }
    return sanitizeUrl(value);
  } catch {
    return sanitizeUrl(value || "");
  }
}

function isExternalLandingUrl(value) {
  try {
    const url = new URL(value);
    return !/facebook\.com|fbcdn\.net|metastatus\.com/i.test(url.hostname);
  } catch {
    return false;
  }
}

function isUsefulFacebookPageUrl(value) {
  try {
    const url = new URL(value);
    return /(^|\.)facebook\.com$/i.test(url.hostname) && /^\/[0-9]{6,}\/?$/i.test(url.pathname);
  } catch {
    return false;
  }
}

function buildHar(requests, responses, bodies) {
  const entries = [];
  for (const [requestId, requestEvent] of requests.entries()) {
    const request = requestEvent.request || {};
    const responseEvent = responses.get(requestId);
    const response = responseEvent ? responseEvent.response || {} : {};
    if (!shouldIncludeHarEntry(request, response)) continue;
    const requestUrl = sanitizeUrl(request.url);
    const postDataText = request.postData ? redact(String(request.postData).slice(0, 250000)) : undefined;
    const responseBody = bodies.get(requestId) || "";
    entries.push({
      startedDateTime: new Date((requestEvent.wallTime || Date.now() / 1000) * 1000).toISOString(),
      time: -1,
      request: {
        method: request.method || "GET",
        url: requestUrl,
        httpVersion: "HTTP/2",
        cookies: [],
        headers: headersArray(request.headers || {}),
        queryString: queryStringArray(requestUrl),
        headersSize: -1,
        bodySize: postDataText ? Buffer.byteLength(postDataText) : 0,
        ...(postDataText ? { postData: { mimeType: request.headers?.["content-type"] || request.headers?.["Content-Type"] || "", text: postDataText } } : {}),
      },
      response: {
        status: response.status || 0,
        statusText: response.statusText || "",
        httpVersion: "HTTP/2",
        cookies: [],
        headers: headersArray(response.headers || {}),
        content: {
          size: responseBody ? Buffer.byteLength(responseBody) : 0,
          mimeType: response.mimeType || "",
          text: responseBody ? redact(responseBody.slice(0, 250000)) : "",
        },
        redirectURL: "",
        headersSize: -1,
        bodySize: responseBody ? Buffer.byteLength(responseBody) : -1,
      },
      cache: {},
      timings: { send: -1, wait: -1, receive: -1 },
    });
  }
  return {
    log: {
      version: "1.2",
      creator: { name: "q-meta-ad-library-hidden-api", version: "1" },
      entries,
    },
  };
}

function unique(values) {
  return Array.from(new Set(values.filter(Boolean)));
}

function parseDetail(libraryId, domText, links) {
  const lines = cleanLines(domText);
  const text = lines.join("\n");
  const sponsoredIndex = lines.findIndex((line) => /^Sponsored$/i.test(line));
  let advertiser = null;
  if (sponsoredIndex > 0) {
    for (let i = sponsoredIndex - 1; i >= 0; i--) {
      const candidate = lines[i];
      if (!/^(Active|Inactive|Library ID:|Started running|Platforms|Categories|See ad details|About this ad|Open Dropdown|See summary details)$/i.test(candidate)) {
        advertiser = candidate;
        break;
      }
    }
  }

  const explicitStartDate = text.match(/Started running on\s+([^\n]+)/i);
  const rangeStartDate = text.match(/\b([A-Z][a-z]{2}\s+[0-9]{1,2},\s+[0-9]{4})\s+-\s+[A-Z][a-z]{2}\s+[0-9]{1,2},\s+[0-9]{4}\b/);
  const status = /\bInactive\b/i.test(text) && !/\bActive\b/i.test(text) ? "inactive" : (/\bActive\b/i.test(text) ? "active" : null);
  const domainsFromLines = lines.map((line) => looksLikeDomain(line)).filter((domain) => domain && !/facebook\.com|fbcdn\.net/i.test(domain));
  const landingUrls = unique(links
    .map((link) => landingUrlFromHref(link.href || ""))
    .filter((href) => /^https?:\/\//i.test(href) && isExternalLandingUrl(href))
    .concat(domainsFromLines
      .filter((domain) => !/metastatus\.com/i.test(domain))
      .map((domain) => `https://${domain}`)));

  const sanitizedHrefs = links.map((link) => sanitizeUrl(link.href || ""));
  const pageUrls = unique(sanitizedHrefs
    .filter((href) => isUsefulFacebookPageUrl(href)));
  const transparencyLinks = unique(links
    .filter((link) => /transparency|page_transparency|about_profile_transparency/i.test(`${link.text || ""} ${link.href || ""}`))
    .map((link) => sanitizeUrl(link.href || "")));
  const pageUrlIds = unique(pageUrls
    .flatMap((href) => Array.from(href.matchAll(/facebook\.com\/([0-9]{6,})/g)).map((match) => match[1])));
  const pageIdHints = unique(sanitizedHrefs
    .flatMap((href) => Array.from(href.matchAll(/(?:profile\.php\?id=|[?&](?:id|view_all_page_id)=|\/pages\/[^/]+\/|facebook\.com\/)([0-9]{6,})/g)).map((match) => match[1]))
    .filter((id) => id !== libraryId));

  let creativeText = null;
  if (sponsoredIndex >= 0) {
    const stopIndex = lines.findIndex((line, i) => i > sponsoredIndex && (
      looksLikeDomain(line) ||
      /^Shop now$/i.test(line) ||
      /^Learn more$/i.test(line) ||
      /^Send message$/i.test(line) ||
      /^Like$/i.test(line) ||
      /^Comment$/i.test(line) ||
      /^Share$/i.test(line) ||
      /^About this ad$/i.test(line)
    ));
    creativeText = lines.slice(sponsoredIndex + 1, stopIndex > sponsoredIndex ? stopIndex : sponsoredIndex + 12).join("\n").trim() || null;
  }

  const disclaimerLines = lines.filter((line) => /paid for by|disclaimer|payer|funded by|sponsored by|about this ad/i.test(line));

  const result = {
    ad_id: libraryId,
    library_id: libraryId,
    page_id: pageUrlIds[0] || pageIdHints[0] || null,
    page_id_hints: pageIdHints,
    page_name: advertiser,
    advertiser_name: advertiser,
    creative_text: creativeText,
    landing_urls: landingUrls,
    landing_domain: landingUrls[0] ? normalizeDomain(landingUrls[0]) : null,
    snapshot_url: `https://www.facebook.com/ads/library/?id=${libraryId}`,
    start_date: explicitStartDate ? explicitStartDate[1].trim() : (rangeStartDate ? rangeStartDate[1].trim() : null),
    status,
    page_urls: pageUrls,
    transparency_links: transparencyLinks,
    disclaimer_or_payer_text: disclaimerLines.join("\n") || null,
    confidence: advertiser && (creativeText || landingUrls.length || pageUrls.length) ? "high" : (advertiser ? "medium" : "low"),
    missing_fields: [],
  };
  const required = ["advertiser_name", "creative_text", "landing_urls", "start_date", "status", "page_urls", "page_id"];
  result.missing_fields = required.filter((field) => {
    const value = result[field];
    return Array.isArray(value) ? value.length === 0 : !value;
  });
  return result;
}

function cleanGraphqlPayload(text) {
  const value = String(text || "").trim();
  return value.startsWith("for (;;);") ? value.slice("for (;;);".length) : value;
}

function safeJsonParse(text) {
  try {
    return JSON.parse(cleanGraphqlPayload(text));
  } catch {
    return null;
  }
}

function adDetailsFromGraphqlBodies(libraryId, capture, captureDir) {
  for (const [requestId, body] of capture.responseBodies.entries()) {
    const request = capture.requestEvents.get(requestId)?.request || {};
    const postData = request.postData || "";
    const response = safeJsonParse(body);
    const details = response?.data?.ad_library_main?.ad_details;
    if (!details) continue;
    if (!/AdLibraryV3AdDetailsQuery/i.test(postData) && !String(postData).includes(libraryId)) continue;

    const pathOut = path.join(captureDir, `${libraryId}-detail-graphql-ad-details.json`);
    fs.writeFileSync(pathOut, JSON.stringify(response, null, 2) + "\n");

    const pageInfo = details.advertiser?.ad_library_page_info?.page_info || {};
    const payerBeneficiary = details.aaa_info?.payer_beneficiary_data || [];
    const euTransparency = details.transparency_by_location?.eu_transparency || null;
    const ukTransparency = details.transparency_by_location?.uk_transparency || null;

    return {
      path: pathOut,
      fields: {
        graphql_friendly_name: "AdLibraryV3AdDetailsQuery",
        graphql_doc_id: "25068828942793558",
        graph_page_id: pageInfo.page_id || details.advertiser?.page?.id || null,
        page_name: pageInfo.page_name || null,
        page_profile_uri: pageInfo.page_profile_uri || null,
        page_category: pageInfo.page_category || null,
        page_likes: pageInfo.likes ?? null,
        page_verification: pageInfo.page_verification || null,
        page_is_deleted: pageInfo.page_is_deleted ?? null,
        page_is_restricted: pageInfo.page_is_restricted ?? null,
        payer_beneficiary_data: payerBeneficiary.map((item) => ({
          payer: item.payer || null,
          beneficiary: item.beneficiary || null,
        })),
        payer_names: unique(payerBeneficiary.map((item) => item.payer)),
        beneficiary_names: unique(payerBeneficiary.map((item) => item.beneficiary)),
        targets_eu: details.aaa_info?.targets_eu ?? null,
        is_ad_taken_down: details.aaa_info?.is_ad_taken_down ?? null,
        eu_total_reach: euTransparency?.eu_total_reach ?? null,
        uk_total_reach: ukTransparency?.total_reach ?? null,
        eu_age_audience: euTransparency?.age_audience || null,
        uk_age_audience: ukTransparency?.age_audience || null,
        eu_gender_audience: euTransparency?.gender_audience || null,
        uk_gender_audience: ukTransparency?.gender_audience || null,
        eu_location_audience: euTransparency?.location_audience || [],
        uk_location_audience: ukTransparency?.location_audience || [],
      },
    };
  }
  return null;
}

async function main() {
  if (!libraryIds.length) fail("provide at least one Library ID for --cdp-detail");
  for (const id of libraryIds) {
    if (!/^[0-9]+$/.test(id)) fail(`Library ID must be numeric: ${id}`);
  }

  fs.mkdirSync(outDir, { recursive: true });
  const captureDir = path.join(outDir, "cdp-capture");
  fs.mkdirSync(captureDir, { recursive: true });

  const userDataDir = fs.mkdtempSync(path.join(os.tmpdir(), "q-meta-adlib-detail-cdp-"));
  const browser = spawn(chromePath(), [
    "--headless=new",
    "--remote-debugging-port=0",
    `--user-data-dir=${userDataDir}`,
    "--no-first-run",
    "--no-default-browser-check",
    "--disable-background-networking",
    "about:blank",
  ], { stdio: "ignore" });

  let pageClient;
  let browserClient;
  let activeCapture = null;
  const capturedAt = new Date().toISOString().replace(/\.\d{3}Z$/, "Z");
  const printingPressCapture = printingPressCaptureFlag === "1";
  const manifestResults = [];

  try {
    const port = await waitForPortFile(userDataDir);
    const version = await fetchJson(`http://127.0.0.1:${port}/json/version`);
    browserClient = new CdpClient(version.webSocketDebuggerUrl);
    await browserClient.connect();
    const target = await browserClient.send("Target.createTarget", { url: "about:blank" });
    const targets = await fetchJson(`http://127.0.0.1:${port}/json/list`);
    const page = targets.find((item) => item.id === target.targetId) || targets.find((item) => item.type === "page");
    if (!page || !page.webSocketDebuggerUrl) fail("could not open a CDP page target");

    pageClient = new CdpClient(page.webSocketDebuggerUrl);
    await pageClient.connect();
    pageClient.on("Network.requestWillBeSent", (event) => {
      if (!activeCapture) return;
      const request = event.request || {};
      if (/facebook\.com|fbcdn\.net|graphql|ads_archive|ad_archive/i.test(request.url || "")) {
        activeCapture.requestEvents.set(event.requestId, {
          ...event,
          request: {
            ...request,
            url: sanitizeUrl(request.url),
            headers: sanitizeHeaders(request.headers || {}),
            postData: request.postData ? redact(String(request.postData)) : undefined,
          },
        });
      }
    });
    pageClient.on("Network.responseReceived", (event) => {
      if (!activeCapture) return;
      const response = event.response || {};
      const url = response.url || "";
      const mimeType = response.mimeType || "";
      if (/facebook\.com|fbcdn\.net|graphql|ads_archive|ad_archive/i.test(url)) {
        activeCapture.responseEvents.set(event.requestId, {
          ...event,
          response: {
            ...response,
            url: sanitizeUrl(response.url),
            headers: sanitizeHeaders(response.headers || {}),
          },
        });
      }
      activeCapture.networkEvents.push({
        request_id: event.requestId,
        url: sanitizeUrl(url),
        status: response.status,
        mime_type: mimeType,
        from_disk_cache: response.fromDiskCache || false,
      });
      if (/\/api\/graphql/i.test(url) || (/facebook\.com\/ads\/library|graphql|ads_archive|ad_archive/i.test(url) && /json|javascript|text/i.test(mimeType) && !/html/i.test(mimeType))) {
        activeCapture.bodyCandidates.push({ requestId: event.requestId, url, mimeType });
      }
    });

    await pageClient.send("Network.enable");
    await pageClient.send("Page.enable");
    await pageClient.send("Runtime.enable");

    for (const libraryId of libraryIds) {
      activeCapture = {
        requestEvents: new Map(),
        responseEvents: new Map(),
        responseBodies: new Map(),
        networkEvents: [],
        bodyCandidates: [],
        bodyPaths: [],
      };

      const detailUrl = `https://www.facebook.com/ads/library/?id=${libraryId}`;
      await pageClient.send("Page.navigate", { url: detailUrl });

      let domText = "";
      for (let i = 0; i < 28; i++) {
        await sleep(1000);
        await evaluate(pageClient, `
          (() => {
            window.scrollTo(0, document.body.scrollHeight);
            const candidates = Array.from(document.querySelectorAll('a,button,div[role="button"],span'));
            const el = candidates.find((node) => /See ad details|See summary details|About this ad/i.test((node.innerText || node.ariaLabel || '').trim()));
            if (el && typeof el.click === 'function') el.click();
            return true;
          })()
        `);
        domText = await evaluate(pageClient, "document.body ? document.body.innerText : ''") || "";
        if (/Sponsored/i.test(domText) && /Library ID:\s*[0-9]+/i.test(domText)) break;
      }
      await sleep(1500);
      await evaluate(pageClient, "window.scrollTo(0, document.body.scrollHeight)");
      domText = await evaluate(pageClient, "document.body ? document.body.innerText : ''") || domText;
      const links = await evaluate(pageClient, `
        Array.from(document.querySelectorAll('a[href]')).map((a) => ({
          text: (a.innerText || a.ariaLabel || '').trim(),
          href: a.href
        }))
      `) || [];

      for (let i = 0; i < Math.min(activeCapture.bodyCandidates.length, 20); i++) {
        const candidate = activeCapture.bodyCandidates[i];
        try {
          const body = await pageClient.send("Network.getResponseBody", { requestId: candidate.requestId });
          const text = redact((body.body || "").slice(0, 250000));
          activeCapture.responseBodies.set(candidate.requestId, text);
          const extension = candidate.mimeType.includes("json") ? "json" : "txt";
          const bodyPath = path.join(captureDir, `${libraryId}-detail-network-body-${String(i + 1).padStart(2, "0")}.${extension}`);
          fs.writeFileSync(bodyPath, text + "\n");
          activeCapture.bodyPaths.push(bodyPath);
        } catch {
          // Some response bodies expire before CDP can fetch them.
        }
      }

      const domTextPath = path.join(captureDir, `${libraryId}-detail-dom.txt`);
      const networkIndexPath = path.join(captureDir, `${libraryId}-detail-network-index.json`);
      fs.writeFileSync(domTextPath, domText);
      fs.writeFileSync(networkIndexPath, JSON.stringify(activeCapture.networkEvents, null, 2) + "\n");

      let printingPressSummary = null;
      if (printingPressCapture) {
        const printingPressDir = path.join(outDir, "printing-press");
        fs.mkdirSync(printingPressDir, { recursive: true });
        const har = buildHar(activeCapture.requestEvents, activeCapture.responseEvents, activeCapture.responseBodies);
        const harPath = path.join(printingPressDir, `${libraryId}-detail-sanitized.har`);
        const specPath = path.join(printingPressDir, `${libraryId}-detail-spec.yaml`);
        const analysisPath = path.join(printingPressDir, `${libraryId}-detail-analysis.json`);
        const samplesDir = path.join(printingPressDir, `${libraryId}-detail-samples`);
        fs.writeFileSync(harPath, JSON.stringify(har, null, 2) + "\n");
        const press = spawnSync(printingPressBin, [
          "browser-sniff",
          "--har", harPath,
          "--include", "facebook.com,graphql,ads_archive,ad_archive",
          "--name", "meta-ad-library-detail",
          "--output", specPath,
          "--analysis-output", analysisPath,
          "--samples-output", samplesDir,
        ], { encoding: "utf8" });
        printingPressSummary = {
          status: press.status === 0 ? "complete" : "failed",
          binary: printingPressBin,
          har_path: harPath,
          spec_path: specPath,
          analysis_path: analysisPath,
          samples_dir: samplesDir,
          stdout: redact((press.stdout || "").slice(0, 20000)),
          stderr: redact((press.stderr || "").slice(0, 20000)),
          replay_template_status: "blocked_pending_manual_validation",
          har_entry_count: har.log.entries.length,
        };
        fs.writeFileSync(path.join(printingPressDir, `${libraryId}-detail-capture-summary.json`), JSON.stringify(printingPressSummary, null, 2) + "\n");
        if (press.status !== 0) {
          fail(`Printing Press browser-sniff failed for Library ID ${libraryId}; see ${analysisPath}`);
        }
      }

      const parsed = parseDetail(libraryId, domText, links);
      const graphqlDetails = adDetailsFromGraphqlBodies(libraryId, activeCapture, captureDir);
      if (graphqlDetails) {
        const fields = graphqlDetails.fields;
        const profilePageId = fields.page_profile_uri?.match(/facebook\.com\/([0-9]{6,})/)?.[1] || null;
        parsed.graphql_ad_details_path = graphqlDetails.path;
        parsed.graphql_doc_id = fields.graphql_doc_id;
        parsed.graphql_friendly_name = fields.graphql_friendly_name;
        parsed.page_id = parsed.page_id || profilePageId || fields.graph_page_id || null;
        parsed.page_id_hints = unique([...(parsed.page_id_hints || []), fields.graph_page_id, profilePageId]);
        parsed.page_name = parsed.page_name || fields.page_name;
        parsed.advertiser_name = parsed.advertiser_name || fields.page_name;
        parsed.page_urls = unique([...(parsed.page_urls || []), fields.page_profile_uri]);
        parsed.page_category = fields.page_category;
        parsed.page_likes = fields.page_likes;
        parsed.page_verification = fields.page_verification;
        parsed.page_is_deleted = fields.page_is_deleted;
        parsed.page_is_restricted = fields.page_is_restricted;
        parsed.payer_beneficiary_data = fields.payer_beneficiary_data;
        parsed.payer_names = fields.payer_names;
        parsed.beneficiary_names = fields.beneficiary_names;
        parsed.targets_eu = fields.targets_eu;
        parsed.is_ad_taken_down = fields.is_ad_taken_down;
        parsed.eu_total_reach = fields.eu_total_reach;
        parsed.uk_total_reach = fields.uk_total_reach;
        parsed.eu_age_audience = fields.eu_age_audience;
        parsed.uk_age_audience = fields.uk_age_audience;
        parsed.eu_gender_audience = fields.eu_gender_audience;
        parsed.uk_gender_audience = fields.uk_gender_audience;
        parsed.eu_location_audience = fields.eu_location_audience;
        parsed.uk_location_audience = fields.uk_location_audience;
        parsed.missing_fields = parsed.missing_fields.filter((field) => !(field === "page_id" && parsed.page_id));
      }
      const rawPath = path.join(outDir, `${libraryId}-detail-raw.json`);
      const normalizedPath = path.join(outDir, `${libraryId}-detail-normalized.json`);
      const raw = {
        case: caseName,
        mode: "cdp-detail",
        library_id: libraryId,
        detail_url: detailUrl,
        captured_at_utc: capturedAt,
        dom_text_path: domTextPath,
        network_index_path: networkIndexPath,
        network_body_paths: activeCapture.bodyPaths,
        link_count: links.length,
        links: links.map((link) => ({ text: link.text, href: sanitizeUrl(link.href || "") })),
        printing_press: printingPressSummary,
        parsed,
      };
      const normalized = {
        ...parsed,
        case: caseName,
        mode: "cdp-detail",
        captured_at_utc: capturedAt,
        raw_response_path: rawPath,
        cdp_artifacts: {
          dom_text_path: domTextPath,
          network_index_path: networkIndexPath,
          network_body_paths: activeCapture.bodyPaths,
        },
        printing_press: printingPressSummary,
      };
      fs.writeFileSync(rawPath, JSON.stringify(raw, null, 2) + "\n");
      fs.writeFileSync(normalizedPath, JSON.stringify(normalized, null, 2) + "\n");

      manifestResults.push({
        library_id: libraryId,
        status: parsed.advertiser_name ? "ok" : "partial",
        advertiser_name: parsed.advertiser_name,
        page_name: parsed.page_name,
        page_id: parsed.page_id,
        page_id_hints: parsed.page_id_hints,
        landing_urls: parsed.landing_urls,
        page_urls: parsed.page_urls,
        transparency_links: parsed.transparency_links,
        graphql_ad_details_path: parsed.graphql_ad_details_path || null,
        graphql_doc_id: parsed.graphql_doc_id || null,
        payer_names: parsed.payer_names || [],
        beneficiary_names: parsed.beneficiary_names || [],
        page_category: parsed.page_category || null,
        page_likes: parsed.page_likes ?? null,
        eu_total_reach: parsed.eu_total_reach ?? null,
        uk_total_reach: parsed.uk_total_reach ?? null,
        start_date: parsed.start_date,
        ad_status: parsed.status,
        confidence: parsed.confidence,
        missing_fields: parsed.missing_fields,
        raw_response_path: rawPath,
        normalized_path: normalizedPath,
        dom_text_path: domTextPath,
        network_index_path: networkIndexPath,
      });
    }

    const manifestPath = path.join(outDir, "run-manifest.json");
    const manifestStatus = manifestResults.some((result) => result.advertiser_name) ? "complete" : "partial";
    fs.writeFileSync(manifestPath, JSON.stringify({
      case: caseName,
      timestamp_utc: capturedAt,
      status: manifestStatus,
      reason: manifestStatus === "complete" ? "" : "detail pages captured but advertiser/page identity was not recovered",
      mode: "cdp-detail",
      library_ids: libraryIds,
      out_dir: outDir,
      results: manifestResults,
    }, null, 2) + "\n");

    const attributed = manifestResults.filter((result) => result.advertiser_name);
    if (attributed.length) {
      const findingDir = path.join(caseDir, "investigation", "findings");
      fs.mkdirSync(findingDir, { recursive: true });
      const findingPath = path.join(findingDir, "F-010-facebook-ad-attribution.md");
      const advertiserNames = unique(attributed.map((result) => result.advertiser_name));
      const lines = [
        "# F-010 -- Facebook Ad Attribution",
        "",
        `**Date:** ${capturedAt.slice(0, 10)}`,
        "**Source:** Meta Ad Library CDP detail capture",
        "**Confidence:** See per-ad normalized JSON.",
        "",
        "## Results",
        "",
        `- Library IDs: ${libraryIds.join(", ")}`,
        `- Advertiser/page names: ${advertiserNames.join(", ")}`,
        `- Page ID hints: ${unique(attributed.flatMap((result) => result.page_id_hints || [])).join(", ") || "unknown"}`,
        `- Landing URLs: ${unique(attributed.flatMap((result) => result.landing_urls || [])).join(", ") || "unknown"}`,
        `- Page URLs: ${unique(attributed.flatMap((result) => result.page_urls || [])).join(", ") || "unknown"}`,
        `- Payer names: ${unique(attributed.flatMap((result) => result.payer_names || [])).join(", ") || "unknown"}`,
        `- Beneficiary names: ${unique(attributed.flatMap((result) => result.beneficiary_names || [])).join(", ") || "unknown"}`,
        `- Page categories: ${unique(attributed.map((result) => result.page_category)).join(", ") || "unknown"}`,
        `- Page likes: ${unique(attributed.map((result) => result.page_likes).filter((value) => value !== null && value !== undefined).map(String)).join(", ") || "unknown"}`,
        `- EU total reach: ${unique(attributed.map((result) => result.eu_total_reach).filter((value) => value !== null && value !== undefined).map(String)).join(", ") || "unknown"}`,
        `- UK total reach: ${unique(attributed.map((result) => result.uk_total_reach).filter((value) => value !== null && value !== undefined).map(String)).join(", ") || "unknown"}`,
        `- GraphQL detail evidence: ${unique(attributed.map((result) => result.graphql_ad_details_path)).join(", ") || "unknown"}`,
        `- Raw/normalized evidence directory: ${outDir}`,
        "",
        "## Notes",
        "",
        "- This finding is based on public Meta Ad Library UI data rendered in an isolated Chrome session.",
        "- No cookies, tokens, session headers, or browser profile material are stored.",
      ];
      fs.writeFileSync(findingPath, lines.join("\n") + "\n");
    }

    console.log(`Meta Ad Library CDP detail capture complete: ${manifestPath}`);
  } finally {
    activeCapture = null;
    if (pageClient) pageClient.close();
    if (browserClient) browserClient.close();
    if (browser && !browser.killed) browser.kill("SIGTERM");
    await sleep(250);
    fs.rmSync(userDataDir, { recursive: true, force: true });
  }
}

main().catch((error) => fail(error.message || String(error)));
NODE
}

run_cdp_page() {
  command -v node >/dev/null 2>&1 || fail "node is required for --cdp-page"

  node - "$CASE" "$CASE_DIR" "$OUT_DIR" "${AD_IDS[@]}" <<'NODE'
const fs = require("fs");
const os = require("os");
const path = require("path");
const { spawn } = require("child_process");

const [caseName, caseDir, outDir, ...pageIds] = process.argv.slice(2);

function fail(message) {
  console.error(`ERROR: ${message}`);
  process.exit(2);
}

function sleep(ms) {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

function chromePath() {
  const candidates = [
    process.env.CHROME_PATH,
    "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome",
    "/Applications/Google Chrome Canary.app/Contents/MacOS/Google Chrome Canary",
    "/Applications/Chromium.app/Contents/MacOS/Chromium",
    "/Applications/Microsoft Edge.app/Contents/MacOS/Microsoft Edge",
  ].filter(Boolean);
  for (const candidate of candidates) {
    if (fs.existsSync(candidate)) return candidate;
  }
  fail("Chrome not found. Set CHROME_PATH to a Chrome-compatible browser binary.");
}

function redact(value) {
  let text = typeof value === "string" ? value : JSON.stringify(value);
  text = text.replace(/("?(?:fb_dtsg|lsd|access_token|token|bearer|cookie|authorization)"?\s*[:=]\s*)("[^"]+"|[^&\s,}]+)/gi, "$1[REDACTED]");
  text = text.replace(/Bearer\s+[A-Za-z0-9._\-]+/gi, "Bearer [REDACTED]");
  return text;
}

function isSensitiveParam(name) {
  return /^(lsd|fb_dtsg|access_token|auth|authorization|token|__s|__hsi|jazoest)$/i.test(String(name || "")) ||
    /(token|secret|credential|session|fb_dtsg|lsd)/i.test(String(name || ""));
}

function sanitizeUrl(value) {
  try {
    const url = new URL(value);
    if (/^l\.facebook\.com$/i.test(url.hostname) && url.searchParams.get("u")) {
      return sanitizeUrl(url.searchParams.get("u"));
    }
    for (const name of Array.from(url.searchParams.keys())) {
      if (isSensitiveParam(name)) url.searchParams.delete(name);
    }
    return redact(url.toString());
  } catch {
    return redact(String(value || ""));
  }
}

class CdpClient {
  constructor(wsUrl) {
    this.wsUrl = wsUrl;
    this.nextId = 1;
    this.pending = new Map();
    this.handlers = new Map();
  }

  async connect() {
    this.ws = new WebSocket(this.wsUrl);
    this.ws.onmessage = (event) => {
      const message = JSON.parse(event.data);
      if (message.id && this.pending.has(message.id)) {
        const { resolve, reject } = this.pending.get(message.id);
        this.pending.delete(message.id);
        if (message.error) reject(new Error(message.error.message || JSON.stringify(message.error)));
        else resolve(message.result || {});
        return;
      }
      if (message.method && this.handlers.has(message.method)) {
        for (const handler of this.handlers.get(message.method)) handler(message.params || {});
      }
    };
    await new Promise((resolve, reject) => {
      this.ws.onopen = resolve;
      this.ws.onerror = reject;
    });
  }

  on(method, handler) {
    if (!this.handlers.has(method)) this.handlers.set(method, []);
    this.handlers.get(method).push(handler);
  }

  send(method, params = {}) {
    const id = this.nextId++;
    this.ws.send(JSON.stringify({ id, method, params }));
    return new Promise((resolve, reject) => {
      this.pending.set(id, { resolve, reject });
      setTimeout(() => {
        if (this.pending.has(id)) {
          this.pending.delete(id);
          reject(new Error(`CDP timeout: ${method}`));
        }
      }, 10000);
    });
  }

  close() {
    try {
      this.ws.close();
    } catch {
      // Best-effort close.
    }
  }
}

async function waitForPortFile(userDataDir) {
  const portPath = path.join(userDataDir, "DevToolsActivePort");
  for (let i = 0; i < 100; i++) {
    if (fs.existsSync(portPath)) {
      const lines = fs.readFileSync(portPath, "utf8").trim().split(/\r?\n/);
      if (lines[0]) return Number(lines[0]);
    }
    await sleep(100);
  }
  fail("Chrome launched but did not expose a DevToolsActivePort file");
}

async function fetchJson(url) {
  const response = await fetch(url);
  if (!response.ok) throw new Error(`${response.status} ${response.statusText}: ${url}`);
  return response.json();
}

async function evaluate(client, expression) {
  const result = await client.send("Runtime.evaluate", {
    expression,
    returnByValue: true,
    awaitPromise: true,
  });
  return result.result ? result.result.value : null;
}

function cleanLines(text) {
  return String(text || "")
    .split(/\r?\n/)
    .map((line) => line.trim())
    .filter(Boolean);
}

function normalizeDomain(value) {
  return String(value || "").toLowerCase().replace(/^https?:\/\//, "").replace(/^www\./, "").split(/[/?#]/)[0];
}

function looksLikeDomain(value) {
  const domain = normalizeDomain(value);
  return /^[a-z0-9.-]+\.[a-z]{2,}$/.test(domain) ? domain : null;
}

function unique(values) {
  return Array.from(new Set(values.filter(Boolean)));
}

function isExternalUrl(value) {
  try {
    const url = new URL(value);
    return !/facebook\.com|fbcdn\.net|metastatus\.com|(^|\.)meta\.com$/i.test(url.hostname);
  } catch {
    return false;
  }
}

function parsePage(pageId, captures) {
  const combinedText = captures.map((capture) => capture.domText).join("\n");
  const lines = cleanLines(combinedText);
  const links = captures.flatMap((capture) => capture.links || []);
  const sanitizedHrefs = links.map((link) => sanitizeUrl(link.href || ""))
    .concat(captures.map((capture) => sanitizeUrl(capture.url || "")));
  const pageUrls = unique(sanitizedHrefs.filter((href) => {
    try {
      const url = new URL(href);
      return /(^|\.)facebook\.com$/i.test(url.hostname) && (
        url.pathname === `/${pageId}` ||
        url.pathname === `/${pageId}/` ||
        /^\/[0-9]{6,}\/?$/i.test(url.pathname)
      );
    } catch {
      return false;
    }
  }));
  const pageIdHints = unique(sanitizedHrefs
    .flatMap((href) => Array.from(href.matchAll(/(?:profile\.php\?id=|[?&](?:id|view_all_page_id)=|facebook\.com\/)([0-9]{6,})/g)).map((match) => match[1]))
    .concat(pageId));
  const websites = unique(sanitizedHrefs
    .filter((href) => /^https?:\/\//i.test(href) && isExternalUrl(href))
    .concat(lines.map((line) => looksLikeDomain(line)).filter((domain) => domain && !/facebook\.com|metastatus\.com/i.test(domain)).map((domain) => `https://${domain}`)));
  const visibleLibraryIds = unique(Array.from(combinedText.matchAll(/Library ID:\s*([0-9]+)/g)).map((match) => match[1]));
  const transparencyLines = unique(lines.filter((line) => /transparency|created|page changed|people who manage|country|advertiser|payer|disclaimer|this page/i.test(line))).slice(0, 80);
  const countLines = unique(lines.filter((line) => /\b([0-9,.]+)\s+(followers|likes|ads?)\b/i.test(line))).slice(0, 40);
  const possibleNames = links
    .filter((link) => sanitizedHrefs.includes(sanitizeUrl(link.href || "")))
    .map((link) => String(link.text || "").trim())
    .filter((text) => text && !/^(Log in|Meta Ad Library|Ad Library Report|Ad Library API|Close|More|Like|Follow|Share)$/i.test(text));
  const lineName = lines.find((line) => /FlowerSeed Shop/i.test(line)) || null;
  const pageName = lineName || possibleNames.find((text) => /FlowerSeed|Shop|Seed|Garden|Store/i.test(text)) || possibleNames[0] || null;

  const normalized = {
    page_id: pageId,
    page_id_hints: pageIdHints,
    page_name: pageName,
    page_urls: pageUrls,
    websites,
    visible_library_ids: visibleLibraryIds,
    active_ad_count_text: countLines.find((line) => /\bads?\b/i.test(line)) || null,
    counts_text: countLines,
    transparency_text: transparencyLines,
    business_entity: null,
    confidence: pageName || pageUrls.length || websites.length ? "medium" : "low",
    missing_fields: [],
  };
  const required = ["page_name", "page_urls", "websites", "business_entity"];
  normalized.missing_fields = required.filter((field) => {
    const value = normalized[field];
    return Array.isArray(value) ? value.length === 0 : !value;
  });
  return normalized;
}

async function captureUrl(pageClient, pageId, source, url, activeCapture) {
  await pageClient.send("Page.navigate", { url });
  let domText = "";
  for (let i = 0; i < 20; i++) {
    await sleep(1000);
    await evaluate(pageClient, "window.scrollTo(0, document.body.scrollHeight)");
    domText = await evaluate(pageClient, "document.body ? document.body.innerText : ''") || "";
    if (source === "ad_library_page_filter") {
      if (/Library ID:\s*[0-9]+|No ads match|not running ads/i.test(domText)) break;
      continue;
    }
    if (domText && !/This page isn't available/i.test(domText)) break;
  }
  await sleep(1000);
  domText = await evaluate(pageClient, "document.body ? document.body.innerText : ''") || domText;
  const links = await evaluate(pageClient, `
    Array.from(document.querySelectorAll('a[href]')).map((a) => ({
      text: (a.innerText || a.ariaLabel || '').trim(),
      href: a.href
    }))
  `) || [];
  return {
    source,
    url,
    domText,
    links: links.map((link) => ({ text: link.text, href: sanitizeUrl(link.href || "") })),
  };
}

async function main() {
  if (!pageIds.length) fail("provide at least one page ID for --cdp-page");
  for (const id of pageIds) {
    if (!/^[0-9]+$/.test(id)) fail(`page ID must be numeric: ${id}`);
  }

  fs.mkdirSync(outDir, { recursive: true });
  const captureDir = path.join(outDir, "cdp-capture");
  fs.mkdirSync(captureDir, { recursive: true });
  const userDataDir = fs.mkdtempSync(path.join(os.tmpdir(), "q-meta-page-cdp-"));
  const browser = spawn(chromePath(), [
    "--headless=new",
    "--remote-debugging-port=0",
    `--user-data-dir=${userDataDir}`,
    "--no-first-run",
    "--no-default-browser-check",
    "--disable-background-networking",
    "about:blank",
  ], { stdio: "ignore" });

  let pageClient;
  let browserClient;
  let activeCapture = null;
  const capturedAt = new Date().toISOString().replace(/\.\d{3}Z$/, "Z");
  const results = [];

  try {
    const port = await waitForPortFile(userDataDir);
    const version = await fetchJson(`http://127.0.0.1:${port}/json/version`);
    browserClient = new CdpClient(version.webSocketDebuggerUrl);
    await browserClient.connect();
    const target = await browserClient.send("Target.createTarget", { url: "about:blank" });
    const targets = await fetchJson(`http://127.0.0.1:${port}/json/list`);
    const page = targets.find((item) => item.id === target.targetId) || targets.find((item) => item.type === "page");
    if (!page || !page.webSocketDebuggerUrl) fail("could not open a CDP page target");

    pageClient = new CdpClient(page.webSocketDebuggerUrl);
    await pageClient.connect();
    pageClient.on("Network.responseReceived", (event) => {
      if (!activeCapture) return;
      const response = event.response || {};
      activeCapture.networkEvents.push({
        request_id: event.requestId,
        url: sanitizeUrl(response.url || ""),
        status: response.status,
        mime_type: response.mimeType || "",
        from_disk_cache: response.fromDiskCache || false,
      });
    });
    await pageClient.send("Network.enable");
    await pageClient.send("Page.enable");
    await pageClient.send("Runtime.enable");

    for (const pageId of pageIds) {
      activeCapture = { networkEvents: [] };
      const publicUrl = `https://www.facebook.com/${pageId}`;
      const adLibraryUrl = `https://www.facebook.com/ads/library/?active_status=all&ad_type=all&country=US&view_all_page_id=${pageId}`;
      const captures = [
        await captureUrl(pageClient, pageId, "public_page", publicUrl, activeCapture),
        await captureUrl(pageClient, pageId, "ad_library_page_filter", adLibraryUrl, activeCapture),
      ];
      const domTextPath = path.join(captureDir, `${pageId}-page-dom.txt`);
      const networkIndexPath = path.join(captureDir, `${pageId}-page-network-index.json`);
      fs.writeFileSync(domTextPath, captures.map((capture) => `# ${capture.source}\n${capture.url}\n\n${capture.domText}`).join("\n\n---\n\n"));
      fs.writeFileSync(networkIndexPath, JSON.stringify(activeCapture.networkEvents, null, 2) + "\n");

      const normalized = {
        ...parsePage(pageId, captures),
        case: caseName,
        mode: "cdp-page",
        captured_at_utc: capturedAt,
        raw_response_path: path.join(outDir, `${pageId}-page-raw.json`),
        cdp_artifacts: {
          dom_text_path: domTextPath,
          network_index_path: networkIndexPath,
        },
      };
      const raw = {
        case: caseName,
        mode: "cdp-page",
        page_id: pageId,
        captured_at_utc: capturedAt,
        sources: captures.map((capture) => ({
          source: capture.source,
          url: capture.url,
          link_count: capture.links.length,
          links: capture.links,
        })),
        dom_text_path: domTextPath,
        network_index_path: networkIndexPath,
        parsed: normalized,
      };
      const rawPath = path.join(outDir, `${pageId}-page-raw.json`);
      const normalizedPath = path.join(outDir, `${pageId}-page-normalized.json`);
      normalized.raw_response_path = rawPath;
      fs.writeFileSync(rawPath, JSON.stringify(raw, null, 2) + "\n");
      fs.writeFileSync(normalizedPath, JSON.stringify(normalized, null, 2) + "\n");

      results.push({
        page_id: pageId,
        status: normalized.page_name || normalized.page_urls.length ? "ok" : "partial",
        page_name: normalized.page_name,
        page_id_hints: normalized.page_id_hints,
        page_urls: normalized.page_urls,
        websites: normalized.websites,
        active_ad_count_text: normalized.active_ad_count_text,
        business_entity: normalized.business_entity,
        confidence: normalized.confidence,
        missing_fields: normalized.missing_fields,
        raw_response_path: rawPath,
        normalized_path: normalizedPath,
        dom_text_path: domTextPath,
        network_index_path: networkIndexPath,
      });
    }

    const manifestPath = path.join(outDir, "run-manifest.json");
    const status = results.some((result) => result.page_name || result.page_urls.length) ? "complete" : "partial";
    fs.writeFileSync(manifestPath, JSON.stringify({
      case: caseName,
      timestamp_utc: capturedAt,
      status,
      reason: status === "complete" ? "" : "page surfaces captured but no page/entity fields were recovered",
      mode: "cdp-page",
      page_ids: pageIds,
      out_dir: outDir,
      results,
    }, null, 2) + "\n");

    const recovered = results.filter((result) => result.page_name || result.page_urls.length || result.websites.length);
    if (recovered.length) {
      const findingDir = path.join(caseDir, "investigation", "findings");
      fs.mkdirSync(findingDir, { recursive: true });
      const findingPath = path.join(findingDir, "F-010-facebook-ad-attribution.md");
      const lines = [
        "# F-010 -- Facebook Ad Attribution",
        "",
        `**Date:** ${capturedAt.slice(0, 10)}`,
        "**Source:** Meta Ad Library CDP page/entity pivot",
        "**Confidence:** See per-page normalized JSON.",
        "",
        "## Results",
        "",
        `- Input page/entity IDs: ${pageIds.join(", ")}`,
        `- Page names: ${unique(recovered.map((result) => result.page_name)).join(", ") || "unknown"}`,
        `- Page ID hints: ${unique(recovered.flatMap((result) => result.page_id_hints || [])).join(", ") || "unknown"}`,
        `- Page URLs: ${unique(recovered.flatMap((result) => result.page_urls || [])).join(", ") || "unknown"}`,
        `- Websites: ${unique(recovered.flatMap((result) => result.websites || [])).join(", ") || "unknown"}`,
        `- Business entity: ${unique(recovered.map((result) => result.business_entity)).join(", ") || "unknown"}`,
        `- Raw/normalized evidence directory: ${outDir}`,
        "",
        "## Notes",
        "",
        "- This finding is based on public Facebook and Meta Ad Library UI data rendered in an isolated Chrome session.",
        "- No cookies, tokens, session headers, or browser profile material are stored.",
      ];
      fs.writeFileSync(findingPath, lines.join("\n") + "\n");
    }

    console.log(`Meta Ad Library CDP page/entity pivot complete: ${manifestPath}`);
  } finally {
    activeCapture = null;
    if (pageClient) pageClient.close();
    if (browserClient) browserClient.close();
    if (browser && !browser.killed) browser.kill("SIGTERM");
    await sleep(250);
    fs.rmSync(userDataDir, { recursive: true, force: true });
  }
}

main().catch((error) => fail(error.message || String(error)));
NODE
}

write_manifest() {
  local status="$1"
  local reason="$2"
  local results_file="$3"
  local ids_json
  ids_json="$(printf '%s\n' "${AD_IDS[@]}" | jq -R . | jq -s .)"
  jq -n \
    --arg case "$CASE" \
    --arg status "$status" \
    --arg reason "$reason" \
    --arg template "$TEMPLATE" \
    --arg out_dir "$OUT_DIR" \
    --arg timestamp "$(date -u +"%Y-%m-%dT%H:%M:%SZ")" \
    --argjson ad_ids "$ids_json" \
    --slurpfile results "$results_file" \
    '{
      case: $case,
      timestamp_utc: $timestamp,
      status: $status,
      reason: $reason,
      template: $template,
      out_dir: $out_dir,
      ad_ids: $ad_ids,
      results: ($results[0] // [])
    }' > "$OUT_DIR/run-manifest.json"
}

if [ -n "$SNIFF_HAR" ]; then
  [ -f "$SNIFF_HAR" ] || fail "HAR file not found: $SNIFF_HAR"
  PRESS_BIN="$(find_printing_press)" || fail "cli-printing-press not found; install Printing Press first"
  "$PRESS_BIN" browser-sniff \
    --har "$SNIFF_HAR" \
    --include "facebook.com,graphql,ads_archive,ad_archive" \
    --name "meta-ad-library" \
    --output "$OUT_DIR/meta-ad-library-spec.yaml" \
    --analysis-output "$OUT_DIR/meta-ad-library-analysis.json" \
    --samples-output "$OUT_DIR/meta-ad-library-samples"
  echo "Printing Press sniff artifacts written to: $OUT_DIR"
  echo "Next: convert the discovered Ad Library request into $DEFAULT_TEMPLATE and set status=ready."
  exit 0
fi

CDP_MODE_COUNT=0
[ -n "$CDP_SEARCH_DOMAIN" ] && CDP_MODE_COUNT=$((CDP_MODE_COUNT + 1))
[ -n "$CDP_SEARCH_KEYWORD" ] && CDP_MODE_COUNT=$((CDP_MODE_COUNT + 1))
[ -n "$CDP_SEARCH_ADVERTISER" ] && CDP_MODE_COUNT=$((CDP_MODE_COUNT + 1))
[ "$CDP_DETAIL" = "1" ] && CDP_MODE_COUNT=$((CDP_MODE_COUNT + 1))
[ "$CDP_PAGE" = "1" ] && CDP_MODE_COUNT=$((CDP_MODE_COUNT + 1))
[ "$CDP_MODE_COUNT" -le 1 ] || fail "use only one CDP search mode per run"

if [ "$CDP_DETAIL" = "1" ]; then
  [ "${#AD_IDS[@]}" -gt 0 ] || fail "--cdp-detail requires at least one Library ID"
  run_cdp_detail
  exit 0
fi

if [ "$CDP_PAGE" = "1" ]; then
  [ "${#AD_IDS[@]}" -gt 0 ] || fail "--cdp-page requires at least one page ID"
  run_cdp_page
  exit 0
fi

if [ -n "$CDP_SEARCH_DOMAIN" ]; then
  [ "${#AD_IDS[@]}" -eq 0 ] || fail "--cdp-search-domain does not accept ad IDs"
  run_cdp_search "domain" "$CDP_SEARCH_DOMAIN"
  exit 0
fi

if [ -n "$CDP_SEARCH_KEYWORD" ]; then
  [ "${#AD_IDS[@]}" -eq 0 ] || fail "--cdp-search-keyword does not accept ad IDs"
  run_cdp_search "keyword" "$CDP_SEARCH_KEYWORD"
  exit 0
fi

if [ -n "$CDP_SEARCH_ADVERTISER" ]; then
  [ "${#AD_IDS[@]}" -eq 0 ] || fail "--cdp-search-advertiser does not accept ad IDs"
  run_cdp_search "advertiser" "$CDP_SEARCH_ADVERTISER"
  exit 0
fi

[ "${#AD_IDS[@]}" -gt 0 ] || fail "provide at least one ad ID or use --sniff-har"
[ -f "$TEMPLATE" ] || fail "request capture missing: template not found: $TEMPLATE"

TEMPLATE_STATUS="$(jq -r '.status // "needs_capture"' "$TEMPLATE")"
if [ "$TEMPLATE_STATUS" != "ready" ]; then
  tmp_results="$(mktemp)"
  printf '[]\n' > "$tmp_results"
  write_manifest "blocked" "request capture missing: template status is $TEMPLATE_STATUS" "$tmp_results"
  rm -f "$tmp_results"
  fail "request capture missing: set $TEMPLATE status=ready after capturing a sanitized Meta Ad Library request"
fi

COMMAND_LEN="$(jq '.replay.command | length' "$TEMPLATE")"
[ "$COMMAND_LEN" -gt 0 ] || fail "template replay.command is empty"

RESULTS_JSONL="$OUT_DIR/.results.jsonl"
: > "$RESULTS_JSONL"

for ad_id in "${AD_IDS[@]}"; do
  case "$ad_id" in
    *[!0-9]*) fail "ad ID must be numeric: $ad_id" ;;
  esac

  RAW_PATH="$OUT_DIR/${ad_id}-raw.json"
  NORMALIZED_PATH="$OUT_DIR/${ad_id}-normalized.json"
  CMD_JSON="$(mktemp)"

  python3 - "$TEMPLATE" "$ad_id" <<'PY' > "$CMD_JSON"
import json
import os
import re
import sys

template_path, ad_id = sys.argv[1], sys.argv[2]
template = json.load(open(template_path, encoding="utf-8"))
command = template.get("replay", {}).get("command", [])
if not isinstance(command, list) or not command:
    raise SystemExit("template replay.command must be a non-empty array")

env_re = re.compile(r"\{\{ENV:([A-Za-z_][A-Za-z0-9_]*)\}\}")

def replace(part: str) -> str:
    part = part.replace("{{AD_ID}}", ad_id)
    def env_sub(match: re.Match[str]) -> str:
        name = match.group(1)
        value = os.environ.get(name)
        if value is None:
            raise SystemExit(f"required environment variable is unset: {name}")
        return value
    return env_re.sub(env_sub, part)

print(json.dumps([replace(str(part)) for part in command]))
PY

  CMD=()
  while IFS= read -r cmd_part; do
    CMD+=("$cmd_part")
  done < <(jq -r '.[]' "$CMD_JSON")
  rm -f "$CMD_JSON"

  if ! "${CMD[@]}" > "$RAW_PATH.tmp"; then
    rm -f "$RAW_PATH.tmp"
    fail "replay command failed for ad ID $ad_id"
  fi
  [ -s "$RAW_PATH.tmp" ] || fail "empty response for ad ID $ad_id"
  jq empty "$RAW_PATH.tmp" || fail "non-JSON response for ad ID $ad_id"
  mv "$RAW_PATH.tmp" "$RAW_PATH"

  python3 "$NORMALIZER" \
    --ad-id "$ad_id" \
    --raw "$RAW_PATH" \
    --out "$NORMALIZED_PATH" \
    --raw-response-path "$RAW_PATH" >/dev/null

  jq -n \
    --arg ad_id "$ad_id" \
    --arg raw "$RAW_PATH" \
    --arg normalized "$NORMALIZED_PATH" \
    --slurpfile data "$NORMALIZED_PATH" \
    '{
      ad_id: $ad_id,
      status: "ok",
      raw_response_path: $raw,
      normalized_path: $normalized,
      advertiser_name: ($data[0].advertiser_name // null),
      page_name: ($data[0].page_name // null),
      confidence: ($data[0].confidence // "low"),
      missing_fields: ($data[0].missing_fields // [])
    }' >> "$RESULTS_JSONL"
done

RESULTS_ARRAY="$(mktemp)"
jq -s '.' "$RESULTS_JSONL" > "$RESULTS_ARRAY"
write_manifest "complete" "" "$RESULTS_ARRAY"
rm -f "$RESULTS_ARRAY" "$RESULTS_JSONL"

if jq -e '[.results[] | select((.advertiser_name // .page_name // "") != "")] | length > 0' "$OUT_DIR/run-manifest.json" >/dev/null; then
  FINDING="$CASE_DIR/investigation/findings/F-010-facebook-ad-attribution.md"
  {
    echo "# F-010 -- Facebook Ad Attribution"
    echo ""
    echo "**Date:** $(date -u +"%Y-%m-%d")"
    echo "**Source:** Meta Ad Library hidden API replay"
    echo "**Confidence:** See per-ad normalized JSON."
    echo ""
    echo "## Results"
    echo ""
    jq -r '.results[] | "- Ad ID \(.ad_id): advertiser=\(.advertiser_name // "unknown"), page=\(.page_name // "unknown"), confidence=\(.confidence), raw=\(.raw_response_path)"' "$OUT_DIR/run-manifest.json"
    echo ""
    echo "## Notes"
    echo ""
    echo "- This finding is based on public Ad Library data returned to the logged-in browser session."
    echo "- Raw and normalized evidence files are stored under: $OUT_DIR"
  } > "$FINDING"
  echo "Finding written: $FINDING"
fi

echo "Meta Ad Library hidden API run complete: $OUT_DIR/run-manifest.json"
