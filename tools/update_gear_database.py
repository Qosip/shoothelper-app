#!/usr/bin/env python3
"""
Update gear database: pull OPD + Lensfun repos, import bodies/lenses, rebuild catalog.

Usage:
  python tools/update_gear_database.py [--skip-pull]

This script:
1. Pulls latest open-product-data/digital-cameras (if available)
2. Pulls latest lensfun/lensfun (if available)
3. Imports new bodies from OPD YAML → assets/packs/<body_id>/body.json
4. Imports new lenses from Lensfun XML → assets/shared/lenses/
5. Rebuilds catalog.json (merging full-support + basic-support bodies)
"""

import argparse
import json
import subprocess
import sys
from pathlib import Path

TOOLS = Path(__file__).parent
ROOT = TOOLS.parent
ASSETS = ROOT / "assets"
PACKS = ASSETS / "packs"
SHARED_LENSES = ASSETS / "shared" / "lenses"

# External repos (cloned alongside the project)
OPD_DIR = ROOT.parent / "digital-cameras"
LENSFUN_DIR = ROOT.parent / "lensfun"


def pull_repo(repo_dir: Path, name: str):
    """Git pull a repo if it exists."""
    if not repo_dir.exists():
        print(f"  {name}: not found at {repo_dir} — skipping")
        return False
    try:
        subprocess.run(
            ["git", "pull", "--quiet"],
            cwd=repo_dir,
            check=True,
            capture_output=True,
        )
        print(f"  {name}: updated")
        return True
    except subprocess.CalledProcessError as e:
        print(f"  {name}: pull failed — {e}")
        return False


def import_opd_bodies():
    """Import bodies from OPD if available."""
    if not OPD_DIR.exists():
        print("  OPD repo not found — skipping body import")
        return 0

    database_dir = OPD_DIR / "database"
    if not database_dir.exists():
        database_dir = OPD_DIR  # Try root

    # Import using opd_importer
    sys.path.insert(0, str(TOOLS))
    from opd_importer import process_batch

    results = process_batch(database_dir, PACKS)
    return sum(1 for r in results if r["status"] == "ok")


def import_lensfun_lenses():
    """Import lenses from Lensfun if available."""
    if not LENSFUN_DIR.exists():
        print("  Lensfun repo not found — skipping lens import")
        return 0

    data_dir = LENSFUN_DIR / "data" / "db"
    if not data_dir.exists():
        print("  Lensfun data dir not found")
        return 0

    sys.path.insert(0, str(TOOLS))
    from lensfun_importer import process_batch

    process_batch(data_dir, SHARED_LENSES)
    return len(list(SHARED_LENSES.glob("*.json"))) if SHARED_LENSES.exists() else 0


def rebuild_catalog():
    """Rebuild catalog.json."""
    sys.path.insert(0, str(TOOLS))
    from build_catalog import build_catalog
    build_catalog()


def main():
    parser = argparse.ArgumentParser(description="Update gear database")
    parser.add_argument("--skip-pull", action="store_true", help="Skip git pull")
    args = parser.parse_args()

    print("=== Gear Database Update ===\n")

    if not args.skip_pull:
        print("1. Pulling repos...")
        pull_repo(OPD_DIR, "OPD digital-cameras")
        pull_repo(LENSFUN_DIR, "Lensfun")
    else:
        print("1. Skipping git pull")

    print("\n2. Importing OPD bodies...")
    n_bodies = import_opd_bodies()
    print(f"   {n_bodies} bodies imported")

    print("\n3. Importing Lensfun lenses...")
    n_lenses = import_lensfun_lenses()
    print(f"   {n_lenses} lenses available")

    print("\n4. Rebuilding catalog...")
    rebuild_catalog()

    print("\n=== Done ===")


if __name__ == "__main__":
    main()
