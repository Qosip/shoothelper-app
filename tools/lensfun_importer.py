#!/usr/bin/env python3
"""
Import lens specs from Lensfun XML database files.

Reads Lensfun XML and produces lens.json files in ShootHelper LensSpec format.

Usage:
  python lensfun_importer.py <lensfun_xml> --mount <mount_id> [--output <dir>]
  python lensfun_importer.py --batch <lensfun_data_dir> [--output <dir>]

Examples:
  python lensfun_importer.py lensfun/data/db/slr-sony.xml --mount sony_e
  python lensfun_importer.py --batch lensfun/data/db/ --output assets/shared/lenses/
"""

import argparse
import json
import re
import sys
import xml.etree.ElementTree as ET
from pathlib import Path


# ── Mount mapping ─────────────────────────────────────────────────

LENSFUN_MOUNT_MAP = {
    "Sony E": "sony_e",
    "Sony A": "sony_a",
    "Canon EF": "canon_ef",
    "Canon EF-S": "canon_ef_s",
    "Canon EF-M": "canon_ef_m",
    "Canon RF": "canon_rf",
    "Nikon F": "nikon_f",
    "Nikon Z": "nikon_z",
    "Nikon CX": "nikon_cx",
    "Fujifilm X": "fujifilm_x",
    "Micro 4/3 System": "micro_four_thirds",
    "Pentax KAF2": "pentax_k",
    "Leica L": "l_mount",
    "Samsung NX": "samsung_nx",
    "Sigma SA": "sigma_sa",
    "Generic": "generic",
}


def slugify(text: str) -> str:
    """Convert text to a slug ID."""
    text = text.lower().strip()
    text = re.sub(r"[^\w\s-]", "", text)
    text = re.sub(r"[\s_-]+", "_", text)
    return text.strip("_")


def map_mount(lensfun_mount: str) -> str:
    """Map Lensfun mount name to ShootHelper mount_id."""
    return LENSFUN_MOUNT_MAP.get(lensfun_mount, slugify(lensfun_mount))


def parse_focal(model_name: str) -> dict:
    """Parse focal length from lens model name."""
    # Zoom: "18-50mm" or "18-50 mm"
    zoom_match = re.search(r"(\d+(?:\.\d+)?)\s*-\s*(\d+(?:\.\d+)?)\s*mm", model_name, re.I)
    if zoom_match:
        return {
            "min_mm": float(zoom_match.group(1)),
            "max_mm": float(zoom_match.group(2)),
            "is_zoom": True,
        }

    # Prime: "50mm" or "50 mm"
    prime_match = re.search(r"(\d+(?:\.\d+)?)\s*mm", model_name, re.I)
    if prime_match:
        val = float(prime_match.group(1))
        return {"min_mm": val, "max_mm": val, "is_zoom": False}

    return {"min_mm": 0, "max_mm": 0, "is_zoom": False}


def parse_aperture(model_name: str) -> dict:
    """Parse aperture from lens model name."""
    # Variable aperture: "f/3.5-6.3" or "F3.5-6.3"
    var_match = re.search(r"[fF]/?(\d+(?:\.\d+)?)\s*-\s*(\d+(?:\.\d+)?)", model_name)
    if var_match:
        return {
            "min_f": float(var_match.group(1)),
            "max_f": float(var_match.group(2)),
            "is_variable": True,
        }

    # Fixed aperture: "f/2.8" or "F1.4"
    fixed_match = re.search(r"[fF]/?(\d+(?:\.\d+)?)", model_name)
    if fixed_match:
        val = float(fixed_match.group(1))
        return {"min_f": val, "max_f": val, "is_variable": False}

    return {"min_f": 0, "max_f": 0, "is_variable": False}


def detect_stabilization(model_name: str, maker: str) -> dict:
    """Detect optical stabilization from lens name."""
    name_upper = model_name.upper()
    has_ois = any(
        tag in name_upper
        for tag in ["IS", "VR", "OSS", "OIS", "VC", "OS", "POWER O.I.S"]
    )
    return {
        "has_ois": has_ois,
        "ois_stops": 4.0 if has_ois else None,
    }


def detect_lens_type(focal: dict) -> str:
    """Classify lens type from focal length."""
    if not focal["is_zoom"]:
        return "prime"
    min_f = focal["min_mm"]
    max_f = focal["max_mm"]
    if max_f <= 35:
        return "wide_zoom"
    if min_f <= 35 and max_f >= 70:
        return "standard_zoom"
    if min_f >= 70:
        return "telephoto_zoom"
    return "zoom"


def import_lens(lens_elem, maker: str, mount_id: str) -> dict | None:
    """Transform a Lensfun <lens> element into ShootHelper lens.json format."""
    model_elem = lens_elem.find("model")
    if model_elem is None or not model_elem.text:
        return None

    model_name = model_elem.text.strip()
    lens_id = slugify(f"{maker}_{model_name}")
    brand_id = slugify(maker)

    focal = parse_focal(model_name)
    aperture = parse_aperture(model_name)
    stab = detect_stabilization(model_name, maker)
    lens_type = detect_lens_type(focal)

    # Parse cropfactor (for DX/EF-S lenses)
    cropfactor = lens_elem.find("cropfactor")
    crop = float(cropfactor.text) if cropfactor is not None and cropfactor.text else None

    # Parse min focus distance
    min_focus_elem = lens_elem.find("min-focus")
    min_focus = float(min_focus_elem.text) if min_focus_elem is not None and min_focus_elem.text else None

    # Parse filter diameter
    filter_elem = lens_elem.find("filter-diameter")
    filter_diam = float(filter_elem.text) if filter_elem is not None and filter_elem.text else None

    return {
        "id": lens_id,
        "brand_id": brand_id,
        "mount_id": mount_id,
        "name": f"{maker} {model_name}",
        "display_name": model_name,
        "type": lens_type,
        "spec": {
            "focal_length": focal,
            "aperture": aperture,
            "stabilization": stab,
            "crop_factor": crop,
            "filter_diameter_mm": filter_diam,
            "min_focus_distance_m": min_focus,
        },
    }


def import_lenses_from_xml(xml_path: Path, mount_filter: str | None = None) -> list:
    """Extract all lenses from a Lensfun XML file."""
    tree = ET.parse(xml_path)
    root = tree.getroot()
    lenses = []

    for lens_elem in root.iter("lens"):
        # Get maker
        maker_elem = lens_elem.find("maker")
        if maker_elem is None or not maker_elem.text:
            continue
        maker = maker_elem.text.strip()

        # Get mount(s)
        mounts = []
        for mount_elem in lens_elem.findall("mount"):
            if mount_elem.text:
                mounts.append(mount_elem.text.strip())

        if not mounts:
            continue

        # Process each mount
        for mount_name in mounts:
            mount_id = map_mount(mount_name)

            if mount_filter and mount_id != mount_filter:
                continue

            lens = import_lens(lens_elem, maker, mount_id)
            if lens:
                lenses.append(lens)

    return lenses


def write_lenses(lenses: list, output_dir: Path):
    """Write each lens as a separate JSON file."""
    output_dir.mkdir(parents=True, exist_ok=True)
    for lens in lenses:
        out_path = output_dir / f"{lens['id']}.json"
        with open(out_path, "w", encoding="utf-8") as f:
            json.dump(lens, f, indent=2, ensure_ascii=False)


def process_batch(data_dir: Path, output_dir: Path):
    """Process all Lensfun XML files in a directory."""
    xml_files = sorted(data_dir.glob("*.xml"))
    total = 0

    for xml_file in xml_files:
        try:
            lenses = import_lenses_from_xml(xml_file)
            if lenses:
                write_lenses(lenses, output_dir)
                total += len(lenses)
                print(f"  OK  {xml_file.name}: {len(lenses)} lenses")
        except Exception as e:
            print(f"  ERR {xml_file.name}: {e}")

    print(f"\nTotal: {total} lenses imported")


def main():
    parser = argparse.ArgumentParser(description="Import Lensfun lenses")
    parser.add_argument("input", help="XML file or directory (with --batch)")
    parser.add_argument("--mount", help="Filter by mount ID (e.g. sony_e)")
    parser.add_argument("--output", "-o", help="Output directory", default="assets/shared/lenses")
    parser.add_argument("--batch", action="store_true", help="Process entire directory")
    args = parser.parse_args()

    input_path = Path(args.input)
    output_dir = Path(args.output)

    if args.batch:
        if not input_path.is_dir():
            print(f"ERROR: {input_path} is not a directory")
            sys.exit(1)
        process_batch(input_path, output_dir)
    else:
        if not input_path.is_file():
            print(f"ERROR: {input_path} not found")
            sys.exit(1)
        lenses = import_lenses_from_xml(input_path, args.mount)
        write_lenses(lenses, output_dir)
        print(f"OK: {len(lenses)} lenses → {output_dir}")


if __name__ == "__main__":
    main()
