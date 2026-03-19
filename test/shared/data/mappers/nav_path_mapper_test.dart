import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:shoothelper/shared/data/mappers/nav_path_mapper.dart';
import 'package:shoothelper/shared/data/models/nav_path_model.dart';

void main() {
  group('NavPathMapper', () {
    late List<NavPathModel> models;

    setUpAll(() {
      final file = File('assets/packs/sony_a6700/nav_paths.json');
      final jsonList = jsonDecode(file.readAsStringSync()) as List<dynamic>;
      models = jsonList
          .map((j) => NavPathModel.fromJson(j as Map<String, dynamic>))
          .toList();
    });

    test('maps all nav paths to entities', () {
      final entities = models.map(NavPathMapper.toEntity).toList();
      expect(entities.length, models.length);
    });

    test('maps AF mode nav path correctly', () {
      final afModel = models.firstWhere((m) => m.settingId == 'af_mode');
      final entity = NavPathMapper.toEntity(afModel);
      expect(entity.settingId, 'af_mode');
      expect(entity.hasMenuPath, isTrue);
      expect(entity.hasQuickAccess, isTrue);
      expect(entity.hasDialAccess, isFalse);
    });

    test('maps aperture dial access correctly', () {
      final apModel = models.firstWhere((m) => m.settingId == 'aperture');
      final entity = NavPathMapper.toEntity(apModel);
      expect(entity.hasMenuPath, isFalse);
      expect(entity.hasQuickAccess, isFalse);
      expect(entity.hasDialAccess, isTrue);
      expect(entity.dialAccess!.dialId, 'front_dial');
      expect(entity.dialAccess!.exposureModes, contains('A'));
    });

    test('maps quick access steps with localized labels', () {
      final afModel = models.firstWhere((m) => m.settingId == 'af_mode');
      final entity = NavPathMapper.toEntity(afModel);
      final steps = entity.quickAccess!.steps;
      expect(steps.length, 2);
      expect(steps[0].label('fr'), contains('Fn'));
      expect(steps[1].label('en'), contains('Focus Mode'));
    });

    test('maps tips correctly', () {
      final stabModel = models.firstWhere((m) => m.settingId == 'stabilization');
      final entity = NavPathMapper.toEntity(stabModel);
      expect(entity.tips, isNotEmpty);
      expect(entity.tips.first.label('fr'), contains('trépied'));
    });
  });
}
