import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:shoothelper/shared/data/models/nav_path_model.dart';

void main() {
  group('NavPathModel JSON parsing', () {
    late List<dynamic> jsonList;

    setUpAll(() {
      final file = File('assets/packs/sony_a6700/nav_paths.json');
      jsonList = jsonDecode(file.readAsStringSync()) as List<dynamic>;
    });

    test('parses all nav paths without error', () {
      final models = jsonList
          .map((j) => NavPathModel.fromJson(j as Map<String, dynamic>))
          .toList();
      expect(models.length, greaterThanOrEqualTo(12));
    });

    test('parses AF mode nav path with menu path', () {
      final model = NavPathModel.fromJson(jsonList[0] as Map<String, dynamic>);
      expect(model.settingId, 'af_mode');
      expect(model.menuPath, isNotNull);
      expect(model.menuPath, contains('af_mf'));
    });

    test('parses quick access steps', () {
      final model = NavPathModel.fromJson(jsonList[0] as Map<String, dynamic>);
      expect(model.quickAccess, isNotNull);
      expect(model.quickAccess!.method, 'fn_menu');
      expect(model.quickAccess!.steps.length, 2);
      expect(model.quickAccess!.steps[0].action, 'press');
      expect(model.quickAccess!.steps[0].labels['fr'], isNotNull);
    });

    test('parses aperture with dial access (no menu path)', () {
      final apertureJson = jsonList.firstWhere(
        (j) => (j as Map<String, dynamic>)['setting_id'] == 'aperture',
      ) as Map<String, dynamic>;
      final model = NavPathModel.fromJson(apertureJson);
      expect(model.menuPath, isNull);
      expect(model.quickAccess, isNull);
      expect(model.dialAccess, isNotNull);
      expect(model.dialAccess!.dialId, 'front_dial');
      expect(model.dialAccess!.exposureModes, contains('M'));
    });

    test('parses tips correctly', () {
      final model = NavPathModel.fromJson(jsonList[0] as Map<String, dynamic>);
      expect(model.tips, isNotNull);
      expect(model.tips!.length, greaterThanOrEqualTo(1));
      expect(model.tips!.first.labels['en'], isNotNull);
    });
  });
}
