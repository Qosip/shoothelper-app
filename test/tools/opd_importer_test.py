#!/usr/bin/env python3
"""Tests for opd_importer.py"""

import json
import sys
import tempfile
from pathlib import Path

# Add tools to path
sys.path.insert(0, str(Path(__file__).parent.parent.parent / "tools"))

from opd_importer import import_body, slugify, parse_sensor_size, estimate_usable_iso


def test_slugify():
    assert slugify("Sony A6700") == "sony_a6700"
    assert slugify("Canon EOS R50") == "canon_eos_r50"
    assert slugify("Nikon Z50 II") == "nikon_z50_ii"
    print("  OK test_slugify")


def test_parse_sensor_size():
    assert parse_sensor_size("APS-C") == ("aps_c", 1.5)
    assert parse_sensor_size("Full-Frame") == ("full_frame", 1.0)
    assert parse_sensor_size("Micro Four Thirds") == ("micro_four_thirds", 2.0)
    assert parse_sensor_size("1 inch") == ("one_inch", 2.7)
    print("  OK test_parse_sensor_size")


def test_estimate_usable_iso():
    # APS-C with max 51200 → usable ≈ 6400
    opd = {"SensorSize": "APS-C", "ISOMaximum": 51200}
    result = estimate_usable_iso(opd)
    assert 3200 <= result <= 12800, f"Got {result}"
    print("  OK test_estimate_usable_iso")


def test_import_body_basic():
    opd = {
        "Brand": "Sony",
        "CameraName": "Sony A6400",
        "SensorSize": "APS-C",
        "MaxResolution": {"MP": 24.2},
        "ISOMinimum": 100,
        "ISOMaximum": 32000,
        "ShutterSpeedRange": {"Min": "30", "Max": "1/4000"},
        "AFPoints": 425,
        "SubjectDetection": True,
        "IBIS": False,
        "Mount": "Sony E",
    }

    body = import_body(opd)

    assert body["id"] == "sony_a6400"
    assert body["brand_id"] == "sony"
    assert body["name"] == "Sony A6400"
    assert body["support_level"] == "basic"
    assert body["spec"]["sensor"]["megapixels"] == 24.2
    assert body["spec"]["sensor"]["iso_range"]["min"] == 100
    assert body["spec"]["sensor"]["iso_range"]["max"] == 32000
    assert body["spec"]["sensor"]["has_ibis"] == False
    assert body["spec"]["sensor"]["ibis_stops"] is None
    assert body["spec"]["autofocus"]["points"] == 425
    assert body["spec"]["autofocus"]["has_eye_af"] == True
    assert body["mount_id"] == "sony_e"
    print("  OK test_import_body_basic")


def test_import_body_output_json():
    opd = {
        "Brand": "Canon",
        "CameraName": "Canon EOS R6 Mark II",
        "SensorSize": "Full-Frame",
        "MaxResolution": {"MP": 24.2},
        "ISOMinimum": 100,
        "ISOMaximum": 102400,
        "AFPoints": 1053,
        "SubjectDetection": True,
        "IBIS": True,
        "Mount": "Canon RF",
    }

    body = import_body(opd)
    # Should be valid JSON
    json_str = json.dumps(body)
    parsed = json.loads(json_str)
    assert parsed["id"] == "canon_eos_r6_mark_ii"
    assert parsed["sensor_size"] == "full_frame"
    assert parsed["support_level"] == "basic"
    print("  OK test_import_body_output_json")


if __name__ == "__main__":
    print("Running opd_importer tests...")
    test_slugify()
    test_parse_sensor_size()
    test_estimate_usable_iso()
    test_import_body_basic()
    test_import_body_output_json()
    print("\nAll tests passed!")
