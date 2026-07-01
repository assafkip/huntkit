# Evidence Capture Protocol (ENFORCED, all investigations)

This rule governs how evidence enters any investigation under `investigations/`. It is non-negotiable. The founder approved this protocol on 2026-04-09 after identifying that post-hoc screenshot dumps break chain of custody.

## Core principle

**Every piece of evidence gets captured at the time of collection, not after.** Reports must reference evidence by stable ID, with the screenshot rendered inline. No report writer should ever be responsible for "going back to capture screenshots" because that step is already done.

## Folder format

Every evidence item lives in its own folder under the active case:

```
investigations/<case>/investigation/evidence/items/EV-NNNN-<slug>/
  source.json              # capture metadata + integrity hashes (REQUIRED)
  chain-of-custody.md      # who/when/how (REQUIRED)
  content.md               # transcription + OCR notes (REQUIRED stub)
  capture.pdf              # full-page PDF (REQUIRED for URL-sourced items)
  capture.png              # PNG rendering for inline embedding (REQUIRED for URL-sourced items)
```

The EV-NNNN ID is zero-padded four digits, assigned by `skills/osint/scripts/next-ev-id.sh`, monotonic per case. Never reuse an ID. Never renumber.

## The one command that creates evidence

```
bash skills/osint/scripts/capture-evidence.sh <url> <slug> \
  [--case <case-folder>] [--account <@handle>] [--platform <name>] [--note "text"]
```

This script:
1. Assigns the next EV-NNNN
2. Submits to Wayback Machine
3. Submits to archive.today
4. Runs Chrome headless to produce `capture.pdf` + `capture.png`
5. Computes SHA-256 of the PDF
6. Writes `source.json`, `chain-of-custody.md`, `content.md` stub

If any of steps 2-5 fail, the item is marked `INCOMPLETE` in `source.json` and the script exits non-zero. An INCOMPLETE item **may not be cited in any report** until it's resolved or explicitly re-classified.

**Do not write your own capture logic. Do not manually zip screenshots.** Use the script. If the script is broken, fix the script, do not bypass it.

## SCREENSHOT_ONLY evidence class

For client-provided evidence where the original URL is lost (e.g., the Sowell PDF the client gave us on 2026-04-09), use this structure:

```
items/EV-NNNN-<slug>/
  original.pdf (or .png/.jpg)     # the artifact the client gave us
  source.json                     # {"type": "screenshot_only", "provided_by": "<who>", ...}
  chain-of-custody.md             # received-from, received-date, hash of original
  content.md                      # transcription + OCR
```

Set `"type": "screenshot_only"` in `source.json`. Reports can cite these items but the rendered footnote must say `Screenshot-only (no original URL)` so an attorney immediately sees the evidentiary difference.

## Citation in reports

All findings, briefs, and reports reference evidence by ID:

```markdown
At 2:46 AM Mar 14, @ohmstone posted "There are 9243 reasons why Brad sucks." [EV-0014]
```

Before delivery, run:

```
python3 skills/osint/scripts/render-report.py <input.md> <output.md>
```

This resolves `[EV-NNNN]` citations to inline PNG embeds + footnote metadata. It exits non-zero if any citation is broken.

## Forbidden patterns

- Do not create a `screenshots/` dump folder alongside a report. That pattern is deprecated.
- Do not reference evidence by filename (e.g., "see image4.png"). Always use the EV-NNNN ID.
- Do not cite an INCOMPLETE item in a report.
- Do not modify `source.json` after capture. Chain of custody depends on its immutability.
- Do not delete an EV-NNNN folder even if the evidence turns out to be irrelevant. Mark it superseded in `content.md` instead.
- Do not bypass `capture-evidence.sh` to "save time." The script enforces the protocol.

## When the script fails

Fail-stop rule applies. If `capture-evidence.sh` fails:
1. Stop collection immediately.
2. Tell the founder what broke (which step failed, what URL).
3. Wait for instructions before continuing.

Common failure modes:
- Wayback rate limits (they throttle aggressive submitters) -- back off, space requests
- archive.today captchas on new submissions -- may require manual fallback
- Chrome headless blocked by a paywall or login wall -- the PDF will be the login page; mark INCOMPLETE and flag
- URL redirects to a 404 or deleted page -- archive still useful; mark INCOMPLETE if Chrome can't render

## Enforcement

Any new investigation case gets the `investigation/evidence/items/` directory scaffolded automatically via `templates/new-investigation/`. The template includes a `README.md` pointing at this protocol.

Any time a Q command (`/q-collect`, `/q-osint`, `/q-intake`, `/q-brief`, `/q-export`) touches evidence, it must route through `capture-evidence.sh` for URL-sourced items. Raw OCR/extraction of client-provided files still happens through existing extraction scripts but the output must land in an `EV-NNNN-<slug>` folder with `source.json` type set to `screenshot_only` (or `document` for non-screenshot docs).
