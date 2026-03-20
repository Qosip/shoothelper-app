import 'package:flutter_test/flutter_test.dart';
import 'package:shoothelper/shared/data/data_sources/local/camera_data_cache.dart';
import 'package:shoothelper/shared/data/data_sources/local/file_manager.dart';
import 'package:shoothelper/shared/data/data_sources/local/json_data_source.dart';

void main() {
  late JsonDataSource dataSource;

  setUpAll(() {
    final fm = FileSystemManager(rootPath: 'assets');
    dataSource = JsonDataSource(fm);
  });

  group('Cross-brand data loading', () {
    for (final bodyId in ['sony_a6700', 'canon_r50', 'nikon_z50ii']) {
      test('loads $bodyId data pack without error', () async {
        final cache = CameraDataCache();
        await cache.load(bodyId, dataSource);

        expect(cache.isLoaded, true);
        expect(cache.body.id, bodyId);
        expect(cache.allLenses, isNotEmpty);
        expect(cache.navPaths, isNotEmpty);
        expect(cache.settingDefs, isNotEmpty);
      });
    }
  });

  group('Cross-brand AF mode terminology', () {
    test('Sony uses AF-S / AF-C', () async {
      final cache = CameraDataCache();
      await cache.load('sony_a6700', dataSource);
      final afItem = cache.menuTree.findBySetting('af_mode');
      expect(afItem, isNotNull);

      final afcValue =
          afItem!.values?.firstWhere((v) => v.id == 'af-c');
      expect(afcValue, isNotNull);
      expect(afcValue!.shortLabel('en'), 'AF-C');
      expect(afcValue.label('en'), contains('Continuous'));
    });

    test('Canon uses One-Shot / Servo', () async {
      final cache = CameraDataCache();
      await cache.load('canon_r50', dataSource);
      final afItem = cache.menuTree.findBySetting('af_mode');
      expect(afItem, isNotNull);

      final servoValue =
          afItem!.values?.firstWhere((v) => v.id == 'servo-af');
      expect(servoValue, isNotNull);
      expect(servoValue!.shortLabel('en'), 'Servo');
      expect(servoValue.label('en'), contains('Servo'));

      final oneShotValue =
          afItem.values?.firstWhere((v) => v.id == 'one-shot-af');
      expect(oneShotValue, isNotNull);
      expect(oneShotValue!.shortLabel('en'), 'One-Shot');
    });

    test('Nikon uses AF-S / AF-C', () async {
      final cache = CameraDataCache();
      await cache.load('nikon_z50ii', dataSource);
      final afItem = cache.menuTree.findBySetting('af_mode');
      expect(afItem, isNotNull);

      final afcValue =
          afItem!.values?.firstWhere((v) => v.id == 'af-c');
      expect(afcValue, isNotNull);
      expect(afcValue!.shortLabel('en'), 'AF-C');
    });
  });

  group('Cross-brand metering terminology', () {
    test('Sony uses Multi metering', () async {
      final cache = CameraDataCache();
      await cache.load('sony_a6700', dataSource);
      final meterItem = cache.menuTree.findBySetting('metering');
      expect(meterItem, isNotNull);
      final multiValue =
          meterItem!.values?.firstWhere((v) => v.id == 'multi');
      expect(multiValue, isNotNull);
    });

    test('Canon uses Evaluative metering', () async {
      final cache = CameraDataCache();
      await cache.load('canon_r50', dataSource);
      final meterItem = cache.menuTree.findBySetting('metering');
      expect(meterItem, isNotNull);
      final evalValue =
          meterItem!.values?.firstWhere((v) => v.id == 'evaluative');
      expect(evalValue, isNotNull);
      expect(evalValue!.label('en'), contains('Evaluative'));
    });

    test('Nikon uses Matrix metering', () async {
      final cache = CameraDataCache();
      await cache.load('nikon_z50ii', dataSource);
      final meterItem = cache.menuTree.findBySetting('metering');
      expect(meterItem, isNotNull);
      final matrixValue =
          meterItem!.values?.firstWhere((v) => v.id == 'matrix');
      expect(matrixValue, isNotNull);
      expect(matrixValue!.label('en'), contains('Matrix'));
    });
  });

  group('Cross-brand exposure mode terminology', () {
    test('Canon uses Av/Tv (not A/S)', () async {
      final cache = CameraDataCache();
      await cache.load('canon_r50', dataSource);
      final modeItem = cache.menuTree.findBySetting('exposure_mode');
      expect(modeItem, isNotNull);
      final avValue =
          modeItem!.values?.firstWhere((v) => v.id == 'av');
      expect(avValue, isNotNull);
      expect(avValue!.shortLabel('en'), 'Av');

      final tvValue =
          modeItem.values?.firstWhere((v) => v.id == 'tv');
      expect(tvValue, isNotNull);
      expect(tvValue!.shortLabel('en'), 'Tv');
    });

    test('Nikon uses A/S', () async {
      final cache = CameraDataCache();
      await cache.load('nikon_z50ii', dataSource);
      final modeItem = cache.menuTree.findBySetting('exposure_mode');
      expect(modeItem, isNotNull);
      final aValue =
          modeItem!.values?.firstWhere((v) => v.id == 'a');
      expect(aValue, isNotNull);
      expect(aValue!.shortLabel('en'), 'A');
    });
  });

  group('Cross-brand nav paths', () {
    test('all 3 bodies have nav path for af_mode', () async {
      for (final bodyId in ['sony_a6700', 'canon_r50', 'nikon_z50ii']) {
        final cache = CameraDataCache();
        await cache.load(bodyId, dataSource);
        final navPath = cache.getNavPath('af_mode');
        expect(navPath, isNotNull,
            reason: '$bodyId should have af_mode nav path');
      }
    });

    test('all 3 bodies have nav path for iso', () async {
      for (final bodyId in ['sony_a6700', 'canon_r50', 'nikon_z50ii']) {
        final cache = CameraDataCache();
        await cache.load(bodyId, dataSource);
        final navPath = cache.getNavPath('iso');
        expect(navPath, isNotNull,
            reason: '$bodyId should have iso nav path');
      }
    });

    test('Sony quick access uses Fn, Canon uses Q SET, Nikon uses i', () async {
      // Sony
      var cache = CameraDataCache();
      await cache.load('sony_a6700', dataSource);
      var np = cache.getNavPath('af_mode');
      expect(np!.quickAccess!.method, 'fn_menu');

      // Canon
      cache = CameraDataCache();
      await cache.load('canon_r50', dataSource);
      np = cache.getNavPath('af_mode');
      expect(np!.quickAccess!.method, 'q_menu');

      // Nikon
      cache = CameraDataCache();
      await cache.load('nikon_z50ii', dataSource);
      np = cache.getNavPath('af_mode');
      expect(np!.quickAccess!.method, 'i_menu');
    });
  });

  group('Cross-brand French labels', () {
    test('Canon AF mode has French labels', () async {
      final cache = CameraDataCache();
      await cache.load('canon_r50', dataSource);
      final afItem = cache.menuTree.findBySetting('af_mode');
      expect(afItem!.label('fr'), 'Fonctionnement AF');
    });

    test('Nikon AF mode has French labels', () async {
      final cache = CameraDataCache();
      await cache.load('nikon_z50ii', dataSource);
      final afItem = cache.menuTree.findBySetting('af_mode');
      expect(afItem!.label('fr'), 'Mode de mise au point');
    });
  });
}
