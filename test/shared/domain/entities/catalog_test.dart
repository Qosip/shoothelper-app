import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:shoothelper/shared/domain/entities/catalog.dart';

void main() {
  group('Catalog', () {
    final json = jsonDecode('''
{
  "version": "1.0.0",
  "bodies": [
    {
      "id": "sony_a6700",
      "brand_id": "sony",
      "name": "Sony A6700",
      "display_name": "Sony α6700",
      "sensor_size": "aps-c",
      "mount": "sony_e",
      "pack_version": "1.0.0",
      "pack_size_bytes": 52000,
      "languages": ["fr", "en"],
      "lenses": [
        {
          "id": "sigma_18-50_f2.8",
          "brand_id": "sigma",
          "name": "Sigma 18-50mm f/2.8 DC DN",
          "display_name": "Sigma 18-50mm f/2.8",
          "is_kit_lens": false,
          "popularity_rank": 1
        }
      ]
    }
  ]
}
''') as Map<String, dynamic>;

    test('parses catalog from JSON', () {
      final catalog = Catalog.fromJson(json);
      expect(catalog.version, '1.0.0');
      expect(catalog.bodies.length, 1);
    });

    test('parses body details', () {
      final catalog = Catalog.fromJson(json);
      final body = catalog.bodies.first;
      expect(body.id, 'sony_a6700');
      expect(body.brandId, 'sony');
      expect(body.displayName, 'Sony α6700');
      expect(body.sensorSize, 'aps-c');
      expect(body.mount, 'sony_e');
      expect(body.packVersion, '1.0.0');
      expect(body.packSizeBytes, 52000);
      expect(body.languages, ['fr', 'en']);
    });

    test('parses lens details', () {
      final catalog = Catalog.fromJson(json);
      final lens = catalog.bodies.first.lenses.first;
      expect(lens.id, 'sigma_18-50_f2.8');
      expect(lens.displayName, 'Sigma 18-50mm f/2.8');
      expect(lens.isKitLens, false);
      expect(lens.popularityRank, 1);
    });

    test('findBody returns correct body', () {
      final catalog = Catalog.fromJson(json);
      expect(catalog.findBody('sony_a6700'), isNotNull);
      expect(catalog.findBody('canon_r50'), isNull);
    });
  });
}
