#!/usr/bin/env python3
"""
Validates all data pack JSON files for structural correctness.
Usage: python tools/validate.py
"""

import json
import sys
from pathlib import Path

ASSETS = Path(__file__).parent.parent / "assets"
PACKS = ASSETS / "packs"
SHARED = ASSETS / "shared"

REQUIRED_BODY_FIELDS = [
    "id", "brand_id", "mount_id", "name", "display_name", "sensor_size",
    "crop_factor", "firmware_versions", "current_firmware",
    "supported_languages", "release_year", "spec", "controls",
]

REQUIRED_SPEC_SECTIONS = [
    "sensor", "shutter", "autofocus", "metering", "exposure",
    "white_balance", "file_formats", "stabilization", "drive",
]

REQUIRED_LENS_FIELDS = [
    "id", "brand_id", "mount_id", "name", "display_name", "type", "spec",
]

REQUIRED_NAV_PATH_FIELDS = [
    "body_id", "setting_id", "firmware_version",
]

errors = []


def error(msg: str):
    errors.append(msg)
    print(f"  ERROR: {msg}")


def validate_json_file(path: Path) -> dict | list | None:
    """Load and parse a JSON file, returning its content or None on error."""
    if not path.exists():
        error(f"File not found: {path}")
        return None
    try:
        with open(path, encoding="utf-8") as f:
            return json.load(f)
    except json.JSONDecodeError as e:
        error(f"Invalid JSON in {path}: {e}")
        return None


def validate_body(body_dir: Path):
    body_id = body_dir.name
    print(f"\nValidating body: {body_id}")

    # body.json
    body = validate_json_file(body_dir / "body.json")
    if body:
        for field in REQUIRED_BODY_FIELDS:
            if field not in body:
                error(f"body.json missing field: {field}")
        if "spec" in body:
            for section in REQUIRED_SPEC_SECTIONS:
                if section not in body["spec"]:
                    error(f"body.json spec missing section: {section}")
        if body.get("id") != body_id:
            error(f"body.json id '{body.get('id')}' != directory name '{body_id}'")

    # menu_tree.json
    menu_tree = validate_json_file(body_dir / "menu_tree.json")
    if menu_tree:
        # Accept both array and dict with "tabs" key
        tabs = menu_tree if isinstance(menu_tree, list) else menu_tree.get("tabs", [])
        if not isinstance(tabs, list):
            error("menu_tree.json must be an array or object with 'tabs' array")
        else:
            for tab in tabs:
                if "id" not in tab or "type" not in tab:
                    error(f"menu_tree tab missing id or type")
                if "labels" in tab:
                    if "en" not in tab["labels"]:
                        error(f"menu_tree tab '{tab.get('id')}' missing 'en' label")

    # nav_paths.json
    nav_paths = validate_json_file(body_dir / "nav_paths.json")
    if nav_paths:
        if not isinstance(nav_paths, list):
            error("nav_paths.json must be an array")
        else:
            setting_ids = set()
            for np in nav_paths:
                for field in REQUIRED_NAV_PATH_FIELDS:
                    if field not in np:
                        error(f"nav_path missing field: {field}")
                sid = np.get("setting_id", "?")
                if np.get("body_id") != body_id:
                    error(f"nav_path '{sid}' body_id mismatch")
                setting_ids.add(sid)
            print(f"  nav_paths: {len(nav_paths)} settings: {', '.join(sorted(setting_ids))}")

    # Lenses
    lenses_dir = body_dir / "lenses"
    if lenses_dir.exists():
        lens_files = list(lenses_dir.glob("*.json"))
        print(f"  lenses: {len(lens_files)} files")
        for lf in lens_files:
            lens = validate_json_file(lf)
            if lens:
                for field in REQUIRED_LENS_FIELDS:
                    if field not in lens:
                        error(f"lens {lf.name} missing field: {field}")
    else:
        error(f"No lenses directory for {body_id}")

    # manifest.json
    manifest = validate_json_file(body_dir / "manifest.json")
    if manifest:
        if manifest.get("body_id") != body_id:
            error(f"manifest body_id mismatch")


def validate_shared():
    print("\nValidating shared data")
    shared = SHARED

    for name in ["setting_defs.json", "brands.json", "mounts.json"]:
        data = validate_json_file(shared / name)
        if data:
            if not isinstance(data, list):
                error(f"shared/{name} must be an array")
            else:
                print(f"  {name}: {len(data)} entries")


def validate_catalog():
    print("\nValidating catalog.json")
    catalog = validate_json_file(ASSETS / "catalog.json")
    if catalog:
        bodies = catalog.get("bodies", [])
        print(f"  catalog: {len(bodies)} bodies")
        for b in bodies:
            bid = b.get("id", "?")
            if not (PACKS / bid).exists():
                error(f"catalog references body '{bid}' but no pack directory found")
            lens_count = len(b.get("lenses", []))
            print(f"    {bid}: {lens_count} lenses, langs={b.get('languages', [])}")


def main():
    print("=" * 60)
    print("ShootHelper Data Pack Validation")
    print("=" * 60)

    # Find all body packs
    body_dirs = [d for d in PACKS.iterdir() if d.is_dir() and d.name != "shared"]
    print(f"\nFound {len(body_dirs)} body packs: {[d.name for d in body_dirs]}")

    for body_dir in sorted(body_dirs):
        validate_body(body_dir)

    validate_shared()
    validate_catalog()

    print("\n" + "=" * 60)
    if errors:
        print(f"FAILED: {len(errors)} errors found")
        sys.exit(1)
    else:
        print("PASSED: All validations OK")
        sys.exit(0)


if __name__ == "__main__":
    main()
