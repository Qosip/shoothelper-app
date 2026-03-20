#!/usr/bin/env python3
"""
Import camera body specs from open-product-data/digital-cameras YAML files.

Reads OPD YAML and produces body.json in ShootHelper BodySpec format.
These bodies get "basic" support level (specs only, no menu trees/nav paths).

Usage:
  python opd_importer.py <opd_yaml_file> [<output_dir>]
  python opd_importer.py --batch <opd_database_dir> [<output_dir>]

Examples:
  python opd_importer.py digital-cameras/database/sony_a6700.yaml
  python opd_importer.py --batch digital-cameras/database/ assets/packs/
"""

import argparse
import hashlib
import json
import re
import sys
from pathlib import Path

try:
    import yaml
except ImportError:
    print("ERROR: PyYAML required. Install with: pip install pyyaml")
    sys.exit(1)


# ── Sensor size mapping ──────────────────────────────────────────────

SENSOR_SIZE_MAP = {
    "full_frame": ("full_frame", 1.0),
    "full-frame": ("full_frame", 1.0),
    "35mm": ("full_frame", 1.0),
    "aps-c": ("aps_c", 1.5),
    "aps-h": ("aps_h", 1.3),
    "micro_four_thirds": ("micro_four_thirds", 2.0),
    "micro four thirds": ("micro_four_thirds", 2.0),
    "four_thirds": ("four_thirds", 2.0),
    "1 inch": ("one_inch", 2.7),
    "1\"": ("one_inch", 2.7),
    "medium_format": ("medium_format", 0.79),
}


def slugify(text: str) -> str:
    """Convert text to a slug ID."""
    text = text.lower().strip()
    text = re.sub(r"[^\w\s-]", "", text)
    text = re.sub(r"[\s_-]+", "_", text)
    return text.strip("_")


def parse_sensor_size(raw: str) -> tuple:
    """Map OPD sensor size string to (sensor_size_id, crop_factor)."""
    key = raw.lower().strip()
    for pattern, result in SENSOR_SIZE_MAP.items():
        if pattern in key:
            return result
    # Canon APS-C has 1.6x crop
    if "aps" in key and "c" in key:
        return ("aps_c", 1.5)
    return ("unknown", 1.0)


def parse_iso_range(opd: dict) -> dict:
    """Extract ISO range from OPD data."""
    iso_min = opd.get("ISOMinimum") or opd.get("iso_min") or 100
    iso_max = opd.get("ISOMaximum") or opd.get("iso_max") or 25600
    return {"min": int(iso_min), "max": int(iso_max)}


def estimate_usable_iso(opd: dict) -> int:
    """Estimate max usable ISO based on sensor size and generation."""
    sensor_raw = opd.get("SensorSize", "aps-c")
    _, crop = parse_sensor_size(str(sensor_raw))

    iso_max = opd.get("ISOMaximum") or opd.get("iso_max") or 25600

    # Heuristic: usable ≈ max / 4 for APS-C, max / 3 for FF
    if crop <= 1.0:
        return min(int(iso_max) // 3, 12800)
    elif crop <= 1.6:
        return min(int(iso_max) // 4, 6400)
    else:
        return min(int(iso_max) // 6, 3200)


def parse_shutter_speed(raw) -> str | None:
    """Parse shutter speed string like '1/4000' or '30'."""
    if raw is None:
        return None
    s = str(raw).strip()
    if "/" in s:
        return s
    try:
        return str(int(float(s)))
    except (ValueError, TypeError):
        return s


def detect_mount(brand: str, model: str, opd: dict) -> str:
    """Detect mount from brand and model info."""
    mount = opd.get("Mount", opd.get("mount", "")).lower()
    brand_l = brand.lower()

    if "sony e" in mount or "e-mount" in mount:
        return "sony_e"
    if "canon rf" in mount or "rf mount" in mount:
        return "canon_rf"
    if "canon ef-m" in mount:
        return "canon_ef_m"
    if "canon ef" in mount:
        return "canon_ef"
    if "nikon z" in mount or "z mount" in mount:
        return "nikon_z"
    if "nikon f" in mount or "f mount" in mount:
        return "nikon_f"
    if "micro four thirds" in mount or "mft" in mount:
        return "micro_four_thirds"
    if "fuji" in mount or "x mount" in mount:
        return "fujifilm_x"
    if "l mount" in mount or "l-mount" in mount:
        return "l_mount"

    # Fallback: guess from brand
    mount_by_brand = {
        "sony": "sony_e",
        "canon": "canon_rf",
        "nikon": "nikon_z",
        "fujifilm": "fujifilm_x",
        "panasonic": "micro_four_thirds",
        "olympus": "micro_four_thirds",
        "om system": "micro_four_thirds",
        "leica": "l_mount",
        "sigma": "l_mount",
    }
    return mount_by_brand.get(brand_l, "unknown")


def import_body(opd: dict) -> dict:
    """Transform OPD YAML data into ShootHelper body.json format."""
    brand = opd.get("Brand", opd.get("brand", "Unknown"))
    name = opd.get("CameraName", opd.get("camera_name", opd.get("name", "Unknown")))
    display_name = name.replace(brand, "").strip()
    body_id = slugify(f"{brand}_{display_name}")
    brand_id = slugify(brand)

    sensor_raw = str(opd.get("SensorSize", opd.get("sensor_size", "aps-c")))
    sensor_size, crop = parse_sensor_size(sensor_raw)

    megapixels = opd.get("MaxResolution", {})
    if isinstance(megapixels, dict):
        mp = megapixels.get("MP", megapixels.get("mp"))
    else:
        mp = megapixels
    if mp is None:
        mp = opd.get("megapixels")

    iso_range = parse_iso_range(opd)
    usable_iso = estimate_usable_iso(opd)

    shutter_min = parse_shutter_speed(
        opd.get("ShutterSpeedRange", {}).get("Min")
        if isinstance(opd.get("ShutterSpeedRange"), dict)
        else opd.get("shutter_min")
    )
    shutter_max = parse_shutter_speed(
        opd.get("ShutterSpeedRange", {}).get("Max")
        if isinstance(opd.get("ShutterSpeedRange"), dict)
        else opd.get("shutter_max")
    )

    af_points = opd.get("AFPoints", opd.get("af_points"))
    has_eye_af = opd.get("SubjectDetection", opd.get("eye_af", False))
    has_ibis = opd.get("IBIS", opd.get("ibis", False))

    mount = detect_mount(brand, name, opd)

    body = {
        "id": body_id,
        "brand_id": brand_id,
        "name": name,
        "display_name": display_name,
        "mount_id": mount,
        "sensor_size": sensor_size,
        "support_level": "basic",
        "spec": {
            "sensor": {
                "megapixels": float(mp) if mp else None,
                "crop_factor": crop,
                "iso_range": iso_range,
                "iso_usable_max": usable_iso,
                "has_ibis": bool(has_ibis),
                "ibis_stops": None,
                "ibis_axes": None,
            },
            "shutter": {
                "mechanical_min": shutter_min or "30",
                "mechanical_max": shutter_max or "1/4000",
                "has_electronic": opd.get("ElectronicShutter", True),
                "electronic_max": opd.get("ElectronicShutterMax", "1/8000"),
            },
            "autofocus": {
                "type": opd.get("AFType", "hybrid"),
                "points": int(af_points) if af_points else None,
                "has_eye_af": bool(has_eye_af),
                "modes": ["af-s", "af-c", "mf"],
            },
            "controls": {
                "dials": [],
                "buttons": [],
            },
        },
    }

    return body


def process_file(yaml_path: Path, output_dir: Path | None = None) -> Path:
    """Process a single OPD YAML file and write body.json."""
    with open(yaml_path, "r", encoding="utf-8") as f:
        opd = yaml.safe_load(f)

    if opd is None:
        raise ValueError(f"Empty YAML file: {yaml_path}")

    body = import_body(opd)
    body_id = body["id"]

    if output_dir is None:
        output_dir = Path("assets/packs")

    pack_dir = output_dir / body_id
    pack_dir.mkdir(parents=True, exist_ok=True)

    out_path = pack_dir / "body.json"
    with open(out_path, "w", encoding="utf-8") as f:
        json.dump(body, f, indent=2, ensure_ascii=False)

    return out_path


def process_batch(database_dir: Path, output_dir: Path | None = None) -> list:
    """Process all YAML files in a directory."""
    results = []
    yaml_files = sorted(database_dir.glob("*.yaml")) + sorted(database_dir.glob("*.yml"))

    for yaml_file in yaml_files:
        try:
            out = process_file(yaml_file, output_dir)
            results.append({"file": str(yaml_file), "output": str(out), "status": "ok"})
            print(f"  OK  {yaml_file.name} → {out}")
        except Exception as e:
            results.append({"file": str(yaml_file), "status": "error", "error": str(e)})
            print(f"  ERR {yaml_file.name}: {e}")

    return results


def main():
    parser = argparse.ArgumentParser(description="Import OPD camera bodies")
    parser.add_argument("input", help="YAML file or directory (with --batch)")
    parser.add_argument("output", nargs="?", help="Output directory")
    parser.add_argument("--batch", action="store_true", help="Process entire directory")
    args = parser.parse_args()

    input_path = Path(args.input)
    output_dir = Path(args.output) if args.output else None

    if args.batch:
        if not input_path.is_dir():
            print(f"ERROR: {input_path} is not a directory")
            sys.exit(1)
        results = process_batch(input_path, output_dir)
        ok = sum(1 for r in results if r["status"] == "ok")
        err = sum(1 for r in results if r["status"] == "error")
        print(f"\nDone: {ok} imported, {err} errors")
    else:
        if not input_path.is_file():
            print(f"ERROR: {input_path} not found")
            sys.exit(1)
        out = process_file(input_path, output_dir)
        print(f"OK → {out}")


if __name__ == "__main__":
    main()
