import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:shoothelper/shared/data/models/body_model.dart';

void main() {
  group('BodyModel JSON parsing', () {
    late Map<String, dynamic> json;

    setUpAll(() {
      final file = File('assets/packs/sony_a6700/body.json');
      json = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
    });

    test('parses body.json without error', () {
      final model = BodyModel.fromJson(json);
      expect(model.id, 'sony_a6700');
      expect(model.brandId, 'sony');
      expect(model.mountId, 'sony_e');
      expect(model.name, 'Sony A6700');
      expect(model.displayName, 'A6700');
      expect(model.sensorSize, 'aps-c');
      expect(model.cropFactor, 1.5);
    });

    test('parses sensor spec correctly', () {
      final model = BodyModel.fromJson(json);
      final sensor = model.spec.sensor;
      expect(sensor.megapixels, 26.0);
      expect(sensor.isoRange.min, 100);
      expect(sensor.isoRange.max, 32000);
      expect(sensor.isoUsableMax, 6400);
      expect(sensor.sensorWidthMm, 23.5);
      expect(sensor.sensorHeightMm, 15.6);
    });

    test('parses shutter spec correctly', () {
      final model = BodyModel.fromJson(json);
      final shutter = model.spec.shutter;
      expect(shutter.mechanicalMinSeconds, 0.00025);
      expect(shutter.mechanicalMaxSeconds, 30.0);
      expect(shutter.electronicMinSeconds, 0.000125);
      expect(shutter.flashSyncSpeed, '1/160');
    });

    test('parses autofocus spec correctly', () {
      final model = BodyModel.fromJson(json);
      final af = model.spec.autofocus;
      expect(af.points, 759);
      expect(af.hasEyeAf, isTrue);
      expect(af.modes, contains('af-c'));
      expect(af.areas, contains('tracking'));
      expect(af.subjectDetection, contains('human_eye'));
    });

    test('parses controls correctly', () {
      final model = BodyModel.fromJson(json);
      expect(model.controls.dials.length, 2);
      expect(model.controls.buttons.length, 4);
      expect(model.controls.fnMenuItems, contains('iso'));
    });

    test('roundtrip: toJson → jsonEncode → jsonDecode → fromJson', () {
      final model = BodyModel.fromJson(json);
      final encoded = jsonEncode(model.toJson());
      final decoded = jsonDecode(encoded) as Map<String, dynamic>;
      final model2 = BodyModel.fromJson(decoded);
      expect(model2.id, model.id);
      expect(model2.spec.sensor.isoRange.max, model.spec.sensor.isoRange.max);
      expect(model2.controls.dials.length, model.controls.dials.length);
    });
  });
}
