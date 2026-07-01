#!/usr/bin/env python3
"""Normalize Meta Ad Library hidden API responses into Q evidence JSON."""

from __future__ import annotations

import argparse
import json
import re
import sys
from pathlib import Path
from typing import Any


URL_RE = re.compile(r"https?://[^\s\"'<>]+")

PAGE_ID_KEYS = {
    "page_id",
    "pageid",
    "pageID",
    "pageId",
    "facebook_page_id",
    "fb_page_id",
}
PAGE_NAME_KEYS = {
    "page_name",
    "pageName",
    "page",
    "page_title",
    "publisher_platform_page_name",
}
ADVERTISER_KEYS = {
    "advertiser_name",
    "advertiserName",
    "advertiser",
    "byline",
    "page_name",
    "pageName",
}
CREATIVE_KEYS = {
    "creative_text",
    "ad_creative_body",
    "adCreativeBody",
    "creative_body",
    "body",
    "message",
    "text",
    "title",
    "caption",
}
SNAPSHOT_KEYS = {
    "snapshot_url",
    "snapshotUrl",
    "ad_snapshot_url",
    "adSnapshotUrl",
    "archive_url",
}
START_DATE_KEYS = {
    "start_date",
    "startDate",
    "ad_delivery_start_time",
    "adDeliveryStartTime",
    "created_time",
    "createdTime",
}
STATUS_KEYS = {
    "status",
    "delivery_status",
    "ad_delivery_status",
    "is_active",
    "active",
}
LANDING_KEYS = {
    "link_url",
    "linkUrl",
    "landing_url",
    "landingUrl",
    "cta_url",
    "url",
    "website_url",
}


def load_json(path: Path) -> Any:
    try:
        with path.open("r", encoding="utf-8") as handle:
            return json.load(handle)
    except json.JSONDecodeError as exc:
        raise SystemExit(f"ERROR: raw response is not valid JSON: {path}: {exc}") from exc


def walk(value: Any) -> list[tuple[str | None, Any]]:
    pairs: list[tuple[str | None, Any]] = []

    def _walk(node: Any, key: str | None = None) -> None:
        pairs.append((key, node))
        if isinstance(node, dict):
            for child_key, child_value in node.items():
                _walk(child_value, str(child_key))
        elif isinstance(node, list):
            for item in node:
                _walk(item, key)

    _walk(value)
    return pairs


def text_value(value: Any) -> str | None:
    if isinstance(value, str):
        cleaned = value.strip()
        return cleaned or None
    if isinstance(value, (int, float)) and not isinstance(value, bool):
        return str(value)
    if isinstance(value, bool):
        return "active" if value else "inactive"
    return None


def first_by_keys(pairs: list[tuple[str | None, Any]], keys: set[str]) -> str | None:
    for key, value in pairs:
        if key in keys:
            text = text_value(value)
            if text:
                return text
    return None


def collect_urls(pairs: list[tuple[str | None, Any]]) -> list[str]:
    urls: list[str] = []
    seen: set[str] = set()
    for key, value in pairs:
        candidates: list[str] = []
        if key in LANDING_KEYS or key in SNAPSHOT_KEYS:
            text = text_value(value)
            if text:
                candidates.append(text)
        if isinstance(value, str):
            candidates.extend(URL_RE.findall(value))
        for candidate in candidates:
            cleaned = candidate.rstrip(".,);]")
            if cleaned.startswith("http") and cleaned not in seen:
                seen.add(cleaned)
                urls.append(cleaned)
    return urls


def infer_creative_text(pairs: list[tuple[str | None, Any]]) -> str | None:
    candidates: list[str] = []
    for key, value in pairs:
        if key in CREATIVE_KEYS:
            text = text_value(value)
            if text and len(text) > 2 and not text.startswith("http"):
                candidates.append(text)
    if not candidates:
        return None
    candidates.sort(key=len, reverse=True)
    return candidates[0]


def normalize(ad_id: str, raw: Any, raw_response_path: str) -> dict[str, Any]:
    pairs = walk(raw)
    landing_urls = collect_urls(pairs)
    snapshot_url = first_by_keys(pairs, SNAPSHOT_KEYS)
    if snapshot_url and snapshot_url in landing_urls:
        landing_urls = [url for url in landing_urls if url != snapshot_url]

    result: dict[str, Any] = {
        "ad_id": ad_id,
        "page_id": first_by_keys(pairs, PAGE_ID_KEYS),
        "page_name": first_by_keys(pairs, PAGE_NAME_KEYS),
        "advertiser_name": first_by_keys(pairs, ADVERTISER_KEYS),
        "creative_text": infer_creative_text(pairs),
        "landing_urls": landing_urls,
        "snapshot_url": snapshot_url,
        "start_date": first_by_keys(pairs, START_DATE_KEYS),
        "status": first_by_keys(pairs, STATUS_KEYS),
        "raw_response_path": raw_response_path,
        "confidence": "low",
        "missing_fields": [],
    }

    required = [
        "page_id",
        "page_name",
        "advertiser_name",
        "creative_text",
        "landing_urls",
        "snapshot_url",
        "start_date",
        "status",
    ]
    result["missing_fields"] = [
        field for field in required if not result.get(field)
    ]

    if result["advertiser_name"] and (result["creative_text"] or result["landing_urls"]):
        result["confidence"] = "high"
    elif result["advertiser_name"] or result["page_name"]:
        result["confidence"] = "medium"

    return result


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Normalize a Meta Ad Library hidden API JSON response."
    )
    parser.add_argument("--ad-id", required=True)
    parser.add_argument("--raw", required=True, type=Path)
    parser.add_argument("--out", required=True, type=Path)
    parser.add_argument("--raw-response-path", required=True)
    args = parser.parse_args()

    raw = load_json(args.raw)
    normalized = normalize(args.ad_id, raw, args.raw_response_path)
    args.out.parent.mkdir(parents=True, exist_ok=True)
    with args.out.open("w", encoding="utf-8") as handle:
        json.dump(normalized, handle, indent=2, sort_keys=True)
        handle.write("\n")
    json.dump(normalized, sys.stdout, indent=2, sort_keys=True)
    sys.stdout.write("\n")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
