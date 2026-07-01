#!/usr/bin/env python3
# findings-verify-hook.py -- PostToolUse gate for findings attribution confidence
#
# Wired in .claude/settings.json as a PostToolUse hook on Edit and Write tool calls.
# kipi update safety: .claude/settings.json is NOT overwritten by `kipi update`
# (only q-system/ and plugins/ propagate). The hook wiring entry is safe in project settings.json.
#
# Self-test: python3 findings-verify-hook.py --self-test
import json
import pathlib
import re
import sys
import tempfile
import os

HIGH_CONFIDENCE_RE = re.compile(r"(CONFIRMED|HIGH[\s\-]+CONFIDENCE)", re.IGNORECASE)


def find_case_root(findings_path: pathlib.Path) -> pathlib.Path | None:
    """Walk up from the findings file to the case root (contains canonical/)."""
    p = findings_path.parent
    while p != p.parent:
        if (p / "canonical").is_dir():
            return p
        p = p.parent
    return None


def check_findings_file(file_path: str, content: str) -> int:
    """
    Returns 0 (pass) or 2 (block).
    Blocks if content contains HIGH CONFIDENCE or CONFIRMED and any identifier
    in the case's client-claims.json is still UNVERIFIED.
    """
    fp = pathlib.Path(file_path)

    # Scope guard: only fires on investigation findings files
    pattern = re.compile(r"investigations/.+/investigation/findings/.+\.md$")
    if not pattern.search(str(fp)):
        return 0

    # Check for high-confidence language
    if not HIGH_CONFIDENCE_RE.search(content):
        return 0

    # Find the case root
    case_root = find_case_root(fp)
    if not case_root:
        return 0

    claims_path = case_root / "canonical" / "client-claims.json"
    if not claims_path.exists():
        # No claims file -- legacy case, pass silently
        return 0

    claims = json.loads(claims_path.read_text())
    unverified = [
        e["value"]
        for e in claims.get("identifiers", [])
        if e.get("status", "UNVERIFIED") == "UNVERIFIED"
    ]

    if not unverified:
        return 0

    # Check if any unverified identifier appears in the file content
    for identifier in unverified:
        if identifier.lower() in content.lower():
            case_name = case_root.name
            print(
                f"\n[findings-verify-hook] BLOCKED: '{identifier}' is cited in a HIGH CONFIDENCE or CONFIRMED finding "
                f"but is still UNVERIFIED in {case_name}/canonical/client-claims.json\n"
                f"Remediation: run check-collision.sh {identifier} <type> {case_root} to verify the identifier first.\n",
                file=sys.stderr,
            )
            return 2

    return 0


def self_test() -> int:
    print("=== findings-verify-hook.py --self-test ===")

    with tempfile.TemporaryDirectory() as tmp:
        tmp_path = pathlib.Path(tmp)

        # Build a fake case structure
        case_path = tmp_path / "workspace" / "investigations" / "case-test-selftest"
        findings_dir = case_path / "investigation" / "findings"
        canonical_dir = case_path / "canonical"
        findings_dir.mkdir(parents=True)
        canonical_dir.mkdir(parents=True)

        claims = {
            "subject_name": "Test Subject",
            "identifiers": [
                {"value": "unverifiedhandle", "type": "username", "status": "UNVERIFIED", "verified_by": ""},
                {"value": "verifiedhandle", "type": "username", "status": "VERIFIED", "verified_by": "dataset-collision-check"},
            ],
        }
        (canonical_dir / "client-claims.json").write_text(json.dumps(claims, indent=2))

        findings_file = str(findings_dir / "FINDINGS-2026-06-26.md")

        # Test 1: block on CONFIRMED + UNVERIFIED identifier
        content_block = "## Attribution\n\nCONFIRMED: unverifiedhandle belongs to the subject."
        result = check_findings_file(findings_file, content_block)
        if result == 2:
            print("PASS Test 1: blocked on CONFIRMED + UNVERIFIED identifier")
        else:
            print(f"FAIL Test 1: expected exit 2, got {result}", file=sys.stderr)
            return 1

        # Test 2: block on HIGH CONFIDENCE (mixed case) + UNVERIFIED identifier
        content_block2 = "High Confidence -- unverifiedhandle is the primary account."
        result = check_findings_file(findings_file, content_block2)
        if result == 2:
            print("PASS Test 2: blocked on 'High Confidence' (mixed case)")
        else:
            print(f"FAIL Test 2: expected exit 2, got {result}", file=sys.stderr)
            return 1

        # Test 3: no-op when identifier is VERIFIED
        content_ok = "HIGH CONFIDENCE: verifiedhandle is attributed to the subject."
        result = check_findings_file(findings_file, content_ok)
        if result == 0:
            print("PASS Test 3: pass when cited identifier is VERIFIED")
        else:
            print(f"FAIL Test 3: expected exit 0, got {result}", file=sys.stderr)
            return 1

        # Test 4: no-op on non-findings file path
        non_findings = str(tmp_path / "workspace" / "investigations" / "case-test" / "output" / "report.md")
        result = check_findings_file(non_findings, content_block)
        if result == 0:
            print("PASS Test 4: no-op on out-of-scope file path")
        else:
            print(f"FAIL Test 4: expected exit 0, got {result}", file=sys.stderr)
            return 1

        # Test 5: no-op when no client-claims.json (legacy case)
        legacy_case = tmp_path / "workspace" / "investigations" / "case-legacy"
        legacy_findings = legacy_case / "investigation" / "findings"
        legacy_findings.mkdir(parents=True)
        (legacy_case / "canonical").mkdir()
        result = check_findings_file(str(legacy_findings / "FINDINGS.md"), content_block)
        if result == 0:
            print("PASS Test 5: no-op when client-claims.json is absent (legacy case)")
        else:
            print(f"FAIL Test 5: expected exit 0, got {result}", file=sys.stderr)
            return 1

    print("\n=== ALL SELF-TESTS PASSED ===")
    return 0


def main() -> int:
    if len(sys.argv) > 1 and sys.argv[1] == "--self-test":
        return self_test()

    # Hook invocation: read JSON from stdin (Claude Code PostToolUse hook format)
    try:
        payload = json.load(sys.stdin)
    except json.JSONDecodeError:
        return 0

    tool_name = payload.get("tool_name", "")
    if tool_name not in ("Edit", "Write"):
        return 0

    tool_input = payload.get("tool_input", {})
    file_path = tool_input.get("file_path", "")
    # For Edit, new content is in new_string; for Write, it's in content
    content = tool_input.get("new_string", "") or tool_input.get("content", "")

    return check_findings_file(file_path, content)


if __name__ == "__main__":
    sys.exit(main())
