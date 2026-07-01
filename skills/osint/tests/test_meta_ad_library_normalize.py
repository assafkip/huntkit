#!/usr/bin/env python3
import json
import subprocess
import sys
import tempfile
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
SCRIPT = ROOT / "scripts" / "meta_ad_library_normalize.py"
FIXTURE = ROOT / "tests" / "fixtures" / "meta_ad_library_sample.json"


def test_normalizer_extracts_core_fields():
    with tempfile.TemporaryDirectory() as tmp:
        out = Path(tmp) / "normalized.json"
        subprocess.run(
            [
                sys.executable,
                str(SCRIPT),
                "--ad-id",
                "1234567890",
                "--raw",
                str(FIXTURE),
                "--out",
                str(out),
                "--raw-response-path",
                str(FIXTURE),
            ],
            check=True,
            text=True,
            capture_output=True,
        )
        data = json.loads(out.read_text())

    assert data["ad_id"] == "1234567890"
    assert data["page_id"] == "99887766"
    assert data["page_name"] == "Haiyi Plants"
    assert data["advertiser_name"] == "Haiyi Plants"
    assert data["creative_text"] == "Rare cat face flower seeds. Limited garden offer."
    assert data["landing_urls"] == ["https://haiyiplants.example/products/cat-face-flower"]
    assert data["snapshot_url"] == "https://www.facebook.com/ads/library/?id=1234567890"
    assert data["start_date"] == "2025-09-12"
    assert data["status"] == "active"
    assert data["confidence"] == "high"
    assert data["missing_fields"] == []
