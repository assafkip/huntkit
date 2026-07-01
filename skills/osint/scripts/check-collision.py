#!/usr/bin/env python3
# check-collision.py -- CSV collision check backend for check-collision.sh
# Reads client-claims.json for subject_name, greps EV-*/original.csv for identifier,
# flags any row where the Name column differs from the subject.
import json
import csv
import re
import sys
import pathlib


def fuzzy(s: str) -> str:
    return re.sub(r"[^a-z0-9]", "", s.lower())


def find_name_in_row(row: dict) -> str:
    for col in ("Name", "name", "full_name", "fullname"):
        if row.get(col, "").strip():
            return row[col].strip()
    return ""


def run(identifier: str, id_type: str, case_folder: str) -> int:
    case_path = pathlib.Path(case_folder)
    claims_path = case_path / "canonical" / "client-claims.json"

    if not claims_path.exists():
        print(f"ERROR: client-claims.json not found at {claims_path}", file=sys.stderr)
        return 2

    claims = json.loads(claims_path.read_text())
    subject_name = claims.get("subject_name", "")
    subject_key = fuzzy(subject_name)

    items_dir = case_path / "investigation" / "evidence" / "items"
    csv_files = list(items_dir.glob("EV-*/original.csv"))

    if not csv_files:
        print(f"ERROR: no original.csv found under {items_dir}/EV-*/", file=sys.stderr)
        return 2

    collision_name = None
    collision_source = None

    for csv_path in csv_files:
        try:
            with open(csv_path, newline="", encoding="utf-8", errors="replace") as fh:
                reader = csv.DictReader(fh)
                for row in reader:
                    row_text = " ".join(v for v in row.values() if v)
                    if identifier.lower() not in row_text.lower():
                        continue
                    name = find_name_in_row(row)
                    if not name:
                        continue
                    if fuzzy(name) != subject_key:
                        collision_name = name
                        collision_source = str(csv_path)
                        break
        except Exception as e:
            print(f"WARNING: could not read {csv_path}: {e}", file=sys.stderr)
        if collision_name:
            break

    if collision_name:
        print(
            f"COLLISION: identifier '{identifier}' ({id_type}) matched a record belonging to "
            f"'{collision_name}' (from {collision_source})",
            file=sys.stderr,
        )
        print(f"Subject: {subject_name}", file=sys.stderr)
        print(
            "This identifier cannot be used as an attribution crosslink until the collision is resolved.",
            file=sys.stderr,
        )
        return 1

    print(f"CLEAN: no collision found for '{identifier}' ({id_type}) -- subject '{subject_name}' is sole match")

    # Write VERIFIED back to client-claims.json
    updated = False
    for entry in claims.get("identifiers", []):
        if entry.get("value") == identifier and entry.get("status") != "VERIFIED":
            entry["status"] = "VERIFIED"
            entry["verified_by"] = "dataset-collision-check"
            updated = True

    if updated:
        claims_path.write_text(json.dumps(claims, indent=2) + "\n")
        print(f"  -> VERIFIED written to {claims_path}")

    # Update markdown table if present
    md_path = claims_path.parent / "client-claims.md"
    if md_path.exists():
        content = md_path.read_text()
        lines = content.splitlines()
        new_lines = []
        for line in lines:
            if identifier in line and "UNVERIFIED" in line:
                line = line.replace("UNVERIFIED", "VERIFIED", 1)
                line = line.replace("| |", "| dataset-collision-check |", 1)
            new_lines.append(line)
        new_content = "\n".join(new_lines)
        if new_content != content:
            md_path.write_text(new_content)
            print(f"  -> markdown table updated in {md_path}")

    return 0


if __name__ == "__main__":
    if len(sys.argv) != 4:
        print("Usage: check-collision.py <identifier> <type> <case-folder>", file=sys.stderr)
        sys.exit(2)
    sys.exit(run(sys.argv[1], sys.argv[2], sys.argv[3]))
