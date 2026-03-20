#!/usr/bin/env python3
"""
Generates catalog.json from all body packs.
Usage: python tools/build_catalog.py
"""

import json
from pathlib import Path

ASSETS = Path(__file__).parent.parent / "assets"
PACKS = ASSETS / "packs"


def build_catalog():
    bodies = []
    body_dirs = [d for d in PACKS.iterdir() if d.is_dir() and d.name != "shared"]

    for body_dir in sorted(body_dirs):
        body_file = body_dir / "body.json"
        if not body_file.exists():
            print(f"  Skipping {body_dir.name} (no body.json)")
            continue

        with open(body_file, encoding="utf-8") as f:
            body = json.load(f)

        # Compute pack size (sum of all files except manifest)
        pack_size = sum(
            f.stat().st_size
            for f in body_dir.rglob("*.json")
            if f.name != "manifest.json"
        )

        # Discover lenses
        lenses = []
        lenses_dir = body_dir / "lenses"
        if lenses_dir.exists():
            for i, lf in enumerate(sorted(lenses_dir.glob("*.json"))):
                with open(lf, encoding="utf-8") as f:
                    lens = json.load(f)
                lenses.append({
                    "id": lens["id"],
                    "brand_id": lens["brand_id"],
                    "name": lens["name"],
                    "display_name": lens["display_name"],
                    "is_kit_lens": i == 0,
                    "popularity_rank": i + 1,
                })

        bodies.append({
            "id": body["id"],
            "brand_id": body["brand_id"],
            "name": body["name"],
            "display_name": body["display_name"],
            "sensor_size": body["sensor_size"],
            "mount": body["mount_id"],
            "pack_version": "1.0.0",
            "pack_size_bytes": pack_size,
            "languages": body.get("supported_languages", ["en"]),
            "lenses": lenses,
        })
        print(f"  {body['id']}: {len(lenses)} lenses, {pack_size} bytes")

    catalog = {
        "version": "1.1.0",
        "bodies": bodies,
    }

    out = ASSETS / "catalog.json"
    with open(out, "w", encoding="utf-8") as f:
        json.dump(catalog, f, indent=2, ensure_ascii=False)
    print(f"\nWrote {out} ({len(bodies)} bodies)")


def main():
    print("Building catalog.json")
    build_catalog()
    print("Done.")


if __name__ == "__main__":
    main()
