import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:shoothelper/shared/data/mappers/body_mapper.dart';
import 'package:shoothelper/shared/data/models/body_model.dart';
import 'package:shoothelper/shared/domain/enums/shooting_enums.dart';

void main() {
  group('BodyMapper', () {
    late BodyModel model;

    setUpAll(() {
      final file = File('assets/packs/sony_a6700/body.json');
      final json = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
      model = BodyModel.fromJson(json);
    });

    test('maps BodyModel to BodySpec correctly', () {
      final body = BodyMapper.toEntity(model);
      expect(body.id, 'sony_a6700');
      expect(body.brandId, 'sony');
      expect(body.name, 'Sony A6700');
      expect(body.sensorSize, SensorSize.apsc);
      expect(body.cropFactor, 1.5);
    });

    test('maps sensor spec with correct ISO values', () {
      final body = BodyMapper.toEntity(model);
      expect(body.sensor.isoMin, 100);
      expect(body.sensor.isoMax, 32000);
      expect(body.sensor.isoUsableMax, 6400);
      expect(body.sensor.megapixels, 26.0);
      expect(body.sensor.sensorWidthMm, 23.5);
    });

    test('maps shutter spec correctly', () {
      final body = BodyMapper.toEntity(model);
      expect(body.shutter.mechanicalMinSeconds, 0.00025);
      expect(body.shutter.electronicMinSeconds, 0.000125);
      expect(body.shutter.flashSyncSpeed, '1/160');
    });

    test('maps autofocus spec correctly', () {
      final body = BodyMapper.toEntity(model);
      expect(body.autofocus.points, 759);
      expect(body.autofocus.hasEyeAf, isTrue);
      expect(body.autofocus.modes, contains('af-c'));
    });

    test('maps stabilization correctly', () {
      final body = BodyMapper.toEntity(model);
      expect(body.stabilization.hasIbis, isTrue);
      expect(body.stabilization.ibisStops, 5.0);
    });

    test('mapped body matches test fixture values', () {
      final body = BodyMapper.toEntity(model);
      // These should match the test_fixtures.dart values
      expect(body.sensor.isoMin, 100);
      expect(body.sensor.isoMax, 32000);
      expect(body.sensor.isoUsableMax, 6400);
      expect(body.drive.continuousFpsHi, 11.0);
      expect(body.photoFormats, contains('raw'));
    });
  });
}
