#!/usr/bin/env python3
"""
render-report.py -- resolve [EV-NNNN] citations in a markdown report.

Takes a markdown file containing [EV-NNNN] citations and produces a rendered
markdown with inline PNG embeds, PDF links, Wayback/archive.today links, and
a footnote block with capture metadata.

Usage:
    render-report.py <input.md> <output.md> [--case <case-folder>]

Resolution rules:
- [EV-NNNN] inline in prose becomes a superscript footnote link: [[EV-NNNN]][^EV-NNNN]
- After the paragraph containing the citation, the image is embedded:
    ![EV-NNNN capture](relative/path/to/capture.png)
  (only once per EV per section; subsequent citations just link)
- A footnote block is appended at the end of the document with full metadata
  for every cited EV item (URL, Wayback, archive.today, capture timestamp,
  PDF sha256).
- Any citation pointing at an INCOMPLETE or missing EV is flagged with a
  [BROKEN CITATION] marker and listed in stderr. render exits non-zero if any
  broken citations are found.

Evidence folder resolution:
    <workspace>/investigations/<case>/investigation/evidence/items/EV-NNNN-*/
"""

import argparse
import json
import os
import re
import sys
from pathlib import Path
from typing import Optional

CITATION_RE = re.compile(r"\[EV-(\d{4})\]")


def resolve_workspace(script_path: Path) -> Path:
    # skills/osint/scripts/render-report.py -> workspace is three parents up
    return script_path.resolve().parents[3]


def active_case(workspace: Path) -> str:
    marker = workspace / ".active-case"
    if not marker.exists():
        sys.exit("ERROR: no active case set and --case not given")
    return marker.read_text().strip()


def find_item_dir(items_root: Path, ev_id: str) -> Optional[Path]:
    if not items_root.exists():
        return None
    for child in items_root.iterdir():
        if child.is_dir() and child.name.startswith(f"{ev_id}-"):
            return child
    return None


def load_source_json(item_dir: Path) -> Optional[dict]:
    src = item_dir / "source.json"
    if not src.exists():
        return None
    try:
        return json.loads(src.read_text())
    except json.JSONDecodeError:
        return None


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("input", help="input markdown file")
    parser.add_argument("output", help="output markdown file")
    parser.add_argument("--case", help="case folder name (defaults to active case)")
    args = parser.parse_args()

    script_path = Path(__file__)
    workspace = resolve_workspace(script_path)
    case = args.case or active_case(workspace)
    case_dir = workspace / "investigations" / case
    if not case_dir.is_dir():
        sys.exit(f"ERROR: case directory not found: {case_dir}")

    items_root = case_dir / "investigation" / "evidence" / "items"

    input_path = Path(args.input).resolve()
    output_path = Path(args.output).resolve()
    output_dir = output_path.parent
    output_dir.mkdir(parents=True, exist_ok=True)

    text = input_path.read_text()

    # Collect all unique EV IDs referenced
    ev_ids = sorted(set(f"EV-{m.group(1)}" for m in CITATION_RE.finditer(text)))
    resolved = {}  # type: dict
    broken = []  # type: list

    for ev_id in ev_ids:
        item_dir = find_item_dir(items_root, ev_id)
        if item_dir is None:
            broken.append(f"{ev_id}: no item directory found")
            continue
        meta = load_source_json(item_dir)
        if meta is None:
            broken.append(f"{ev_id}: source.json missing or invalid")
            continue
        if meta.get("overall_status") == "INCOMPLETE":
            broken.append(f"{ev_id}: overall_status=INCOMPLETE")
            # still resolve but mark

        resolved[ev_id] = {
            "meta": meta,
            "item_dir": item_dir,
            "png_rel": os.path.relpath(item_dir / "capture.png", output_dir),
            "pdf_rel": os.path.relpath(item_dir / "capture.pdf", output_dir),
        }

    # Inline substitution: add PNG embed after first occurrence per paragraph
    lines = text.split("\n")
    out_lines = []  # type: list
    seen_in_section = set()  # type: set

    for line in lines:
        # Reset per heading
        if line.startswith("#"):
            seen_in_section.clear()
        out_lines.append(line)

        # Find citations on this line
        matches = list(CITATION_RE.finditer(line))
        for m in matches:
            ev_id = f"EV-{m.group(1)}"
            if ev_id in resolved and ev_id not in seen_in_section:
                png_rel = resolved[ev_id]["png_rel"]
                out_lines.append("")
                out_lines.append(f"![{ev_id} capture]({png_rel})")
                out_lines.append("")
                seen_in_section.add(ev_id)
            elif ev_id not in resolved:
                out_lines.append("")
                out_lines.append(f"> **[BROKEN CITATION: {ev_id}]**")
                out_lines.append("")

    rendered = "\n".join(out_lines)

    # Replace [EV-NNNN] with footnote references
    def cite_replace(m: re.Match) -> str:
        ev_id = f"EV-{m.group(1)}"
        return f"[[{ev_id}]][^{ev_id}]"

    rendered = CITATION_RE.sub(cite_replace, rendered)

    # Append footnote block
    if resolved or broken:
        rendered += "\n\n---\n\n## Evidence Footnotes\n\n"
        for ev_id in ev_ids:
            if ev_id not in resolved:
                rendered += f"[^{ev_id}]: **{ev_id}** BROKEN -- item directory or source.json missing\n\n"
                continue
            meta = resolved[ev_id]["meta"]
            captures = meta.get("captures", {})
            wb = captures.get("wayback", {})
            at = captures.get("archive_today", {})
            pdf = captures.get("pdf", {})
            note = meta.get("note") or ""

            lines_out = [
                f"[^{ev_id}]: **{ev_id}**",
                f"  - Source: {meta.get('source_url', '(none)')}",
            ]
            if meta.get("account"):
                lines_out.append(f"  - Account: {meta['account']}")
            if meta.get("platform"):
                lines_out.append(f"  - Platform: {meta['platform']}")
            lines_out.append(f"  - Captured: {meta.get('capture_timestamp_utc', '(unknown)')}")
            if wb.get("url"):
                lines_out.append(f"  - Wayback: {wb['url']}")
            if at.get("url"):
                lines_out.append(f"  - archive.today: {at['url']}")
            pdf_rel = resolved[ev_id]["pdf_rel"]
            pdf_sha = pdf.get("sha256") or ""
            lines_out.append(f"  - PDF: [{pdf_rel}]({pdf_rel}) (sha256: {pdf_sha[:16]}...)" if pdf_sha else f"  - PDF: [{pdf_rel}]({pdf_rel})")
            status = meta.get("overall_status", "UNKNOWN")
            lines_out.append(f"  - Status: {status}")
            if note:
                lines_out.append(f"  - Note: {note}")

            rendered += "\n".join(lines_out) + "\n\n"

    output_path.write_text(rendered)

    print(f"Resolved {len(resolved)} of {len(ev_ids)} citations")
    print(f"Output: {output_path}")
    if broken:
        print("\nBROKEN CITATIONS:", file=sys.stderr)
        for b in broken:
            print(f"  - {b}", file=sys.stderr)
        return 2
    return 0


if __name__ == "__main__":
    sys.exit(main())
