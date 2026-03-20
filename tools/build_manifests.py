#!/usr/bin/env python3
"""
Generates manifest.json for each body pack based on actual file sizes.
Usage: python tools/build_manifests.py
"""

import json
from pathlib import Path

PACKS = Path(__file__).parent.parent / "assets" / "packs"
SHARED_FILES = {
    "setting_defs.json": "shared/setting_defs.json",
    "brands.json": "shared/brands.json",
    "mounts.json": "shared/mounts.json",
}


def build_manifest(body_dir: Path):
    body_id = body_dir.name
    print(f"Building manifest for {body_id}")

    files = {}
    for f in sorted(body_dir.rglob("*.json")):
        if f.name == "manifest.json":
            continue
        rel = f.relative_to(body_dir)
        files[str(rel).replace("\\", "/")] = {
            "path": f"{body_id}/{rel}".replace("\\", "/"),
            "size_bytes": f.stat().st_size,
        }

    shared = {}
    for name, path in SHARED_FILES.items():
        full = PACKS / path
        if full.exists():
            shared[name] = {
                "path": path,
                "size_bytes": full.stat().st_size,
            }

    manifest = {
        "body_id": body_id,
        "pack_version": "1.0.0",
        "min_app_version": "1.0.0",
        "files": files,
        "shared_files": shared,
    }

    out = body_dir / "manifest.json"
    with open(out, "w", encoding="utf-8") as f:
        json.dump(manifest, f, indent=2, ensure_ascii=False)
    print(f"  Wrote {out} ({len(files)} files, {len(shared)} shared)")


def main():
    body_dirs = [d for d in PACKS.iterdir() if d.is_dir() and d.name != "shared"]
    for d in sorted(body_dirs):
        build_manifest(d)
    print("Done.")


if __name__ == "__main__":
    main()
