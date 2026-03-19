import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:shoothelper/shared/data/models/lens_model.dart';

void main() {
  group('LensModel JSON parsing', () {
    late Map<String, dynamic> json;

    setUpAll(() {
      final file = File('assets/packs/sony_a6700/lenses/sigma_18-50_f2.8.json');
      json = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
    });

    test('parses lens JSON without error', () {
      final model = LensModel.fromJson(json);
      expect(model.id, 'sigma_18-50_f2.8_dc_dn_c');
      expect(model.brandId, 'sigma');
      expect(model.mountId, 'sony_e');
      expect(model.displayName, 'Sigma 18-50mm f/2.8');
      expect(model.type, 'zoom');
      expect(model.designedFor, 'aps-c');
    });

    test('parses focal length correctly', () {
      final model = LensModel.fromJson(json);
      expect(model.spec.focalLength.minMm, 18);
      expect(model.spec.focalLength.maxMm, 50);
      expect(model.spec.focalLength.type, 'zoom');
    });

    test('parses aperture correctly', () {
      final model = LensModel.fromJson(json);
      expect(model.spec.aperture.type, 'constant');
      expect(model.spec.aperture.maxAperture, 2.8);
      expect(model.spec.aperture.minAperture, 22);
      expect(model.spec.aperture.variableApertureMap, isNull);
    });

    test('parses focus spec correctly', () {
      final model = LensModel.fromJson(json);
      expect(model.spec.focus.minFocusDistanceM, 0.125);
      expect(model.spec.focus.autofocus, isTrue);
    });

    test('parses stabilization correctly', () {
      final model = LensModel.fromJson(json);
      expect(model.spec.stabilization.hasOis, isFalse);
    });

    test('roundtrip: toJson → jsonEncode → jsonDecode → fromJson', () {
      final model = LensModel.fromJson(json);
      final encoded = jsonEncode(model.toJson());
      final decoded = jsonDecode(encoded) as Map<String, dynamic>;
      final model2 = LensModel.fromJson(decoded);
      expect(model2.id, model.id);
      expect(model2.spec.aperture.maxAperture, model.spec.aperture.maxAperture);
    });
  });
}
