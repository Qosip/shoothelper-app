#!/usr/bin/env python3
"""Tests for lensfun_importer.py"""

import json
import sys
import tempfile
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent.parent.parent / "tools"))

from lensfun_importer import (
    slugify, parse_focal, parse_aperture, detect_stabilization,
    detect_lens_type, map_mount, import_lenses_from_xml,
)


def test_parse_focal_zoom():
    result = parse_focal("18-50mm f/2.8 DC DN")
    assert result["min_mm"] == 18
    assert result["max_mm"] == 50
    assert result["is_zoom"] == True
    print("  OK test_parse_focal_zoom")


def test_parse_focal_prime():
    result = parse_focal("50mm f/1.4 DG DN")
    assert result["min_mm"] == 50
    assert result["max_mm"] == 50
    assert result["is_zoom"] == False
    print("  OK test_parse_focal_prime")


def test_parse_aperture_fixed():
    result = parse_aperture("50mm f/1.4")
    assert result["min_f"] == 1.4
    assert result["max_f"] == 1.4
    assert result["is_variable"] == False
    print("  OK test_parse_aperture_fixed")


def test_parse_aperture_variable():
    result = parse_aperture("18-55mm f/3.5-5.6")
    assert result["min_f"] == 3.5
    assert result["max_f"] == 5.6
    assert result["is_variable"] == True
    print("  OK test_parse_aperture_variable")


def test_detect_stabilization():
    assert detect_stabilization("18-55mm VR", "Nikon")["has_ois"] == True
    assert detect_stabilization("50mm f/1.8", "Canon")["has_ois"] == False
    assert detect_stabilization("18-55mm IS STM", "Canon")["has_ois"] == True
    assert detect_stabilization("70-200mm OSS", "Sony")["has_ois"] == True
    print("  OK test_detect_stabilization")


def test_detect_lens_type():
    assert detect_lens_type({"min_mm": 50, "max_mm": 50, "is_zoom": False}) == "prime"
    assert detect_lens_type({"min_mm": 10, "max_mm": 24, "is_zoom": True}) == "wide_zoom"
    assert detect_lens_type({"min_mm": 24, "max_mm": 70, "is_zoom": True}) == "standard_zoom"
    assert detect_lens_type({"min_mm": 70, "max_mm": 200, "is_zoom": True}) == "telephoto_zoom"
    print("  OK test_detect_lens_type")


def test_map_mount():
    assert map_mount("Sony E") == "sony_e"
    assert map_mount("Canon RF") == "canon_rf"
    assert map_mount("Nikon Z") == "nikon_z"
    assert map_mount("Micro 4/3 System") == "micro_four_thirds"
    print("  OK test_map_mount")


def test_import_from_xml():
    """Test parsing a minimal Lensfun XML."""
    xml_content = """<?xml version="1.0" encoding="utf-8"?>
<lensdatabase version="2">
  <lens>
    <maker>Sigma</maker>
    <model>18-50mm f/2.8 DC DN | Contemporary</model>
    <mount>Sony E</mount>
    <cropfactor>1.5</cropfactor>
  </lens>
  <lens>
    <maker>Sony</maker>
    <model>FE 50mm f/1.8</model>
    <mount>Sony E</mount>
  </lens>
</lensdatabase>"""

    with tempfile.NamedTemporaryFile(mode="w", suffix=".xml", delete=False) as f:
        f.write(xml_content)
        f.flush()
        lenses = import_lenses_from_xml(Path(f.name), mount_filter="sony_e")

    assert len(lenses) == 2
    assert lenses[0]["mount_id"] == "sony_e"
    assert lenses[0]["spec"]["focal_length"]["min_mm"] == 18
    assert lenses[0]["spec"]["focal_length"]["is_zoom"] == True
    assert lenses[1]["spec"]["focal_length"]["min_mm"] == 50
    assert lenses[1]["spec"]["focal_length"]["is_zoom"] == False
    print("  OK test_import_from_xml")


if __name__ == "__main__":
    print("Running lensfun_importer tests...")
    test_parse_focal_zoom()
    test_parse_focal_prime()
    test_parse_aperture_fixed()
    test_parse_aperture_variable()
    test_detect_stabilization()
    test_detect_lens_type()
    test_map_mount()
    test_import_from_xml()
    print("\nAll tests passed!")
