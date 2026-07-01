#!/usr/bin/env python3
"""
security-stack-extract.py

Extracts security tool mentions from one or more text sources (careers page,
LinkedIn employee scrape, job postings) using a deterministic dictionary of
known security products. Produces JSON + markdown reports.

Inputs: one or more JSON files with a common "text" field, or raw .txt files.
Output: a structured report showing which tools were found in which signal,
with match counts and excerpt snippets.

Usage:
  security-stack-extract.py --company "Acme Corp" \\
      --careers /tmp/acme-careers.json \\
      --linkedin /tmp/acme-linkedin.json \\
      --jobs /tmp/acme-jobs.json \\
      --output-dir ./out/

At least one signal file required. All sources are optional.
"""

import argparse
import datetime
import json
import re
import sys
from collections import defaultdict
from pathlib import Path

SKILL_DIR = Path(__file__).resolve().parent.parent
DICT_PATH = SKILL_DIR / "references" / "security-tools.json"


def load_dictionary():
    with open(DICT_PATH) as f:
        d = json.load(f)
    tools = []
    for t in d["tools"]:
        compiled = []
        for pattern in t["patterns"]:
            # Whole-word match, case-insensitive. Escape regex metachars.
            escaped = re.escape(pattern)
            # \b boundaries only work cleanly on word chars; for multi-word
            # patterns (spaces, dots) we rely on boundaries around the whole.
            compiled.append(re.compile(rf"(?i)(?<![A-Za-z0-9]){escaped}(?![A-Za-z0-9])"))
        tools.append({
            "name": t["name"],
            "category": t["category"],
            "patterns": t["patterns"],
            "compiled": compiled,
        })
    return d["categories"], tools


def load_text(path: Path) -> str:
    """Load text from a JSON (common Apify output structures) or plain text."""
    if path.suffix.lower() == ".json":
        with open(path) as f:
            data = json.load(f)
        # Apify datasets often return a list of dicts; flatten all string values.
        return _flatten_text(data)
    return path.read_text(encoding="utf-8", errors="replace")


def _flatten_text(obj) -> str:
    out = []
    if isinstance(obj, dict):
        for v in obj.values():
            out.append(_flatten_text(v))
    elif isinstance(obj, list):
        for v in obj:
            out.append(_flatten_text(v))
    elif isinstance(obj, str):
        out.append(obj)
    return " \n ".join(x for x in out if x)


def extract_mentions(text: str, tools):
    """Return list of (tool_name, category, count, sample_excerpt) hits."""
    results = []
    for t in tools:
        total = 0
        sample = None
        for rx in t["compiled"]:
            for m in rx.finditer(text):
                total += 1
                if sample is None:
                    start = max(0, m.start() - 60)
                    end = min(len(text), m.end() + 60)
                    sample = text[start:end].replace("\n", " ").strip()
        if total > 0:
            results.append({
                "name": t["name"],
                "category": t["category"],
                "count": total,
                "sample_excerpt": sample,
            })
    return results


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--company", required=True, help="Target company name")
    ap.add_argument("--careers", help="Path to careers page scrape (json or txt)")
    ap.add_argument("--linkedin", help="Path to LinkedIn employees scrape (json)")
    ap.add_argument("--jobs", help="Path to job postings scrape (json)")
    ap.add_argument("--output-dir", required=True, help="Where to write reports")
    args = ap.parse_args()

    sources = {}
    for label, path in (("careers", args.careers),
                        ("linkedin", args.linkedin),
                        ("jobs", args.jobs)):
        if path:
            p = Path(path)
            if not p.exists():
                print(f"WARN: {label} path does not exist: {p}", file=sys.stderr)
                continue
            sources[label] = load_text(p)

    if not sources:
        print("ERROR: no source files provided (--careers / --linkedin / --jobs)", file=sys.stderr)
        sys.exit(1)

    categories, tools = load_dictionary()

    per_source = {}
    for label, text in sources.items():
        per_source[label] = extract_mentions(text, tools)

    # Build merged view: tool -> which signals found it, total count
    merged = defaultdict(lambda: {
        "name": None,
        "category": None,
        "signals": {},
        "total": 0,
        "sample_excerpt": None,
    })
    for label, hits in per_source.items():
        for h in hits:
            m = merged[h["name"]]
            m["name"] = h["name"]
            m["category"] = h["category"]
            m["signals"][label] = h["count"]
            m["total"] += h["count"]
            if m["sample_excerpt"] is None:
                m["sample_excerpt"] = h["sample_excerpt"]

    merged_list = sorted(merged.values(),
                         key=lambda x: (x["category"], -x["total"], x["name"]))

    # Confidence: 3 signals = HIGH, 2 = MEDIUM, 1 = LOW
    for m in merged_list:
        n = len(m["signals"])
        m["confidence"] = "HIGH" if n >= 2 and m["total"] >= 3 else (
            "MEDIUM" if n >= 2 or m["total"] >= 3 else "LOW")

    today = datetime.date.today().isoformat()
    out_dir = Path(args.output_dir)
    out_dir.mkdir(parents=True, exist_ok=True)
    slug = re.sub(r"[^A-Za-z0-9]+", "-", args.company).strip("-").lower()

    # JSON
    json_path = out_dir / f"security-stack-{slug}-{today}.json"
    payload = {
        "company": args.company,
        "generated_at": datetime.datetime.utcnow().isoformat() + "Z",
        "sources_provided": sorted(sources.keys()),
        "dictionary_tool_count": len(tools),
        "tools_found": merged_list,
        "per_source_raw": per_source,
    }
    with open(json_path, "w") as f:
        json.dump(payload, f, indent=2)

    # Markdown
    md_path = out_dir / f"security-stack-{slug}-{today}.md"
    lines = []
    lines.append(f"# Security Stack Profile: {args.company}")
    lines.append("")
    lines.append(f"**Generated:** {today}")
    lines.append(f"**Signals analyzed:** {', '.join(sorted(sources.keys()))}")
    lines.append(f"**Dictionary size:** {len(tools)} tools across {len(categories)} categories")
    lines.append("")

    if not merged_list:
        lines.append("_No security tool mentions matched the dictionary._")
    else:
        by_cat = defaultdict(list)
        for m in merged_list:
            by_cat[m["category"]].append(m)
        for cat in sorted(by_cat.keys()):
            lines.append(f"## {cat} — {categories.get(cat, cat)}")
            lines.append("")
            lines.append("| Tool | Confidence | Total mentions | Signals |")
            lines.append("|------|------------|----------------|---------|")
            for m in by_cat[cat]:
                sig = ", ".join(f"{k}:{v}" for k, v in sorted(m["signals"].items()))
                lines.append(f"| {m['name']} | {m['confidence']} | {m['total']} | {sig} |")
            lines.append("")
            # Excerpt block
            for m in by_cat[cat]:
                if m["sample_excerpt"]:
                    lines.append(f"- **{m['name']}**: `…{m['sample_excerpt']}…`")
            lines.append("")

    lines.append("---")
    lines.append("")
    lines.append("## Source-by-source counts (diagnostic)")
    lines.append("")
    for label in sorted(per_source.keys()):
        hits = per_source[label]
        lines.append(f"### {label} — {len(hits)} unique tools found")
        if not hits:
            lines.append("_(no matches)_")
            continue
        for h in sorted(hits, key=lambda x: (x["category"], -x["count"])):
            lines.append(f"- [{h['category']}] {h['name']} — {h['count']} mention(s)")
        lines.append("")

    md_path.write_text("\n".join(lines))

    print(f"JSON: {json_path}")
    print(f"MD:   {md_path}")
    print(f"Tools found: {len(merged_list)}")


if __name__ == "__main__":
    main()
