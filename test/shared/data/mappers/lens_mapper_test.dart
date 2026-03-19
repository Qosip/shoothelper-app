import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:shoothelper/shared/data/mappers/lens_mapper.dart';
import 'package:shoothelper/shared/data/models/lens_model.dart';
import 'package:shoothelper/shared/domain/entities/lens_spec.dart';

void main() {
  group('LensMapper', () {
    late LensModel model;

    setUpAll(() {
      final file = File('assets/packs/sony_a6700/lenses/sigma_18-50_f2.8.json');
      final json = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
      model = LensModel.fromJson(json);
    });

    test('maps LensModel to LensSpec correctly', () {
      final lens = LensMapper.toEntity(model);
      expect(lens.id, 'sigma_18-50_f2.8_dc_dn_c');
      expect(lens.brandId, 'sigma');
      expect(lens.displayName, 'Sigma 18-50mm f/2.8');
      expect(lens.type, LensType.zoom);
    });

    test('maps focal length correctly', () {
      final lens = LensMapper.toEntity(model);
      expect(lens.focalLength.minMm, 18);
      expect(lens.focalLength.maxMm, 50);
      expect(lens.focalLength.isZoom, isTrue);
    });

    test('maps aperture correctly', () {
      final lens = LensMapper.toEntity(model);
      expect(lens.aperture.isConstant, isTrue);
      expect(lens.aperture.maxAperture, 2.8);
      expect(lens.aperture.minAperture, 22);
    });

    test('maps focus spec correctly', () {
      final lens = LensMapper.toEntity(model);
      expect(lens.focus.minFocusDistanceM, 0.125);
      expect(lens.focus.hasAutofocus, isTrue);
    });

    test('maps stabilization correctly', () {
      final lens = LensMapper.toEntity(model);
      expect(lens.stabilization.hasOis, isFalse);
      expect(lens.stabilization.oisStops, 0);
    });

    test('mapped lens matches test fixture values', () {
      final lens = LensMapper.toEntity(model);
      // Should match sigma1850f28 fixture
      expect(lens.aperture.maxAperture, 2.8);
      expect(lens.focalLength.minMm, 18);
      expect(lens.focalLength.maxMm, 50);
    });
  });
}
