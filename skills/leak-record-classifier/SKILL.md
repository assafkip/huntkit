---
name: leak-record-classifier
description: >
  Classify a client-provided leaked/breach-database CSV export (Maltego D4 format)
  against a subject's identity anchors (SSN, DOB, address, email) into confidence
  tiers, producing cleaned/filtered-out CSVs and a color-coded Excel deliverable.
  Use when: analyzing a leaked-records CSV, a Maltego D4 export, breach data for a
  named subject, "leaked database export", "reformat this CSV of records",
  filtering false-positive name matches out of a data broker/breach dump.
  NOT for: live OSINT collection (see the osint skill), report narrative writing
  (case-specific, stays bespoke per subject), or non-CSV evidence (see
  extract-intake.py for PDF/DOCX/image verbatim extraction).
---

# Leak Record Classifier

Shared scaffold for the recurring "client hands us a leaked-database CSV, find
the records that belong to our subject" task. Consolidated 2026-07-21 after two
cases (`case-001-example`, `case-001-example`) independently
rewrote the same ~250-line Maltego-parsing + classification + Excel-writing
scaffold from scratch, differing only in each subject's identity anchors.

## Prerequisite -- ingest first (enforced by a hook, not optional)

The source CSV must already be registered as an EV-NNNN item and deterministically
extracted before you write or run a classification script against it:

```bash
bash skills/osint/scripts/ingest-client-document.sh <file> <slug> document \
  --case <case-folder> --provided-by "<who>"

python3 skills/osint/scripts/extract-intake.py --case <case-folder>
```

`skills/osint/scripts/evidence-pipeline-guard.py` (wired as a
PostToolUse hook in `.claude/settings.json`) BLOCKS writing or running a script
under a case's `investigation/evidence/scripts/` if either step above is
missing for any file in that case's `investigation/intake/`. This exists
because a prior case skipped both tools entirely (see
`.claude/rules/evidence-capture-protocol.md`'s scar note).

## Usage

1. Copy `templates/case_classifier_template.py` to the case's
   `investigation/evidence/scripts/reformat_csv.py`.
2. Do a recon pass on the extracted CSV first
   (`investigation/evidence/extracted/<stem>/text.md`) to find the subject's
   real SSN/DOB/address/email anchors -- do not guess, verify each one against
   actual rows, the way both origin cases did (grep for the SSN digit string,
   confirm DOB co-occurrence, check which addresses cluster together).
3. Fill in `TARGET_SSN_DIGITS`, `TARGET_DOB`, `CONFIRMED_ADDR_TOKENS`,
   `CONFIRMED_EMAILS`, and `classify_row()` in the copied file. Define your own
   tier vocabulary in `TIER_CONFIG` / `CLEANED_TIERS` / `FILTERED_OUT_TIERS` --
   the two origin cases used different tiers (one had a "household" tier for a
   blended family, the other didn't need one) because every case's data is
   different. Don't force a case into tiers it doesn't need.
4. **Precedence lesson (read this before writing classify_row):** case-039
   shipped an early version where an SSN-matches-but-DOB-conflicts row got
   silently absorbed into "confirmed" because a weaker address-match branch
   ran first and returned before the conflict check was reached. Check for
   genuine identifier conflicts FIRST, before any weaker corroborating signal
   can short-circuit past them. Leak databases (National Public Data
   especially) have real, documented record-matching quality issues.
5. Run it: `python3 investigation/evidence/scripts/reformat_csv.py --case <case-folder>`

## What's shared vs. case-specific

| Shared (`lib/leak_csv.py`) | Case-specific (the copied template) |
|---|---|
| Maltego Section 1/2/3 boundary detection | The subject's actual SSN/DOB/address/email anchors |
| `csv.DictReader` parsing (handles embedded newlines in quoted fields) | `classify_row()` -- the tier logic and precedence rules |
| DOB/digit normalization helpers | Tier vocabulary and which tiers are "cleaned" vs "filtered out" |
| Colored multi-tab Excel writer | -- |
| Cleaned / filtered-out CSV writers | -- |
| CLI arg handling + path resolution | -- |

Report generation (the docx synopsis) stays entirely case-specific and is NOT
part of this skill -- every subject's findings, employment, household, and
narrative are genuinely different and don't benefit from a shared template
beyond what the report structure already gives (see any case's
`output/briefs/generate-report.js` for that pattern).

## Origin cases (not migrated -- already delivered, left as-is)

- `investigations/case-001-example/investigation/evidence/scripts/reformat_csv.py`
- `investigations/case-001-example/investigation/evidence/scripts/reformat_csv.py`

## Verification

`lib/leak_csv.py` was verified by reimplementing case-039's exact
`classify_row()` on top of it and confirming an identical classification
result against the real 170-row source CSV (37 confirmed / 8 flagged / 50
household / 6 excluded / 69 unrelated -- exact match, not approximate).

## Known follow-up (not part of this skill, flagged separately)

A second, larger duplication exists: `extract_intake.py` / `extract_all.py`
variants live in 5 case folders (case-010, case-013, case-020, case-025,
case-028) alongside the canonical `skills/osint/scripts/extract-intake.py`,
all added in the same 2026-06-14 commit and never pruned. Some have real
per-case additions (e.g. case-020's `ocr_hd.py`, case-028's `ocr_pass2.py`),
so this needs a careful case-by-case review before consolidating, not a
blanket delete. Out of scope here.
