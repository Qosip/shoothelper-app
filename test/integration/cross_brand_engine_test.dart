import 'package:flutter_test/flutter_test.dart';
import 'package:shoothelper/features/settings_engine/domain/engine/settings_engine.dart';
import 'package:shoothelper/shared/data/data_sources/local/camera_data_cache.dart';
import 'package:shoothelper/shared/data/data_sources/local/file_manager.dart';
import 'package:shoothelper/shared/data/data_sources/local/json_data_source.dart';
import 'package:shoothelper/shared/domain/entities/scene_input.dart';
import 'package:shoothelper/shared/domain/entities/settings_result.dart';
import 'package:shoothelper/shared/domain/enums/shooting_enums.dart';

void main() {
  late JsonDataSource dataSource;
  final engine = const SettingsEngine();

  setUpAll(() {
    final fm = FileSystemManager(rootPath: 'assets');
    dataSource = JsonDataSource(fm);
  });

  /// Portrait bokeh scene: outdoor, person, bokeh intention.
  const portraitScene = SceneInput(
    shootType: ShootType.photo,
    subject: Subject.portrait,
    environment: Environment.outdoorDay,
    intention: Intention.bokeh,
    lightCondition: LightCondition.goldenHour,
    subjectMotion: SubjectMotion.still,
    subjectDistance: SubjectDistance.medium,
  );

  group('Cross-brand portrait bokeh — coherent results', () {
    final bodies = ['sony_a6700', 'canon_r50', 'nikon_z50ii'];

    for (final bodyId in bodies) {
      test('$bodyId produces valid portrait bokeh result', () async {
        final cache = CameraDataCache();
        await cache.load(bodyId, dataSource);

        final body = cache.body;
        final lens = cache.allLenses.first;
        final result = engine.calculate(body, lens, portraitScene);

        // Should produce a complete result with all settings
        expect(result.settings, isNotEmpty);
        expect(result.confidence, isNotNull);

        // Should have the core exposure settings
        final settingIds = result.settings.map((s) => s.settingId).toSet();
        expect(settingIds, contains('aperture'));
        expect(settingIds, contains('shutter_speed'));
        expect(settingIds, contains('iso'));
        expect(settingIds, contains('af_mode'));
        expect(settingIds, contains('metering'));
        expect(settingIds, contains('exposure_mode'));
      });
    }

    test('all 3 bodies recommend wide aperture for bokeh', () async {
      final results = <String, SettingsResult>{};

      for (final bodyId in bodies) {
        final cache = CameraDataCache();
        await cache.load(bodyId, dataSource);
        final body = cache.body;
        final lens = cache.allLenses.first;
        results[bodyId] = engine.calculate(body, lens, portraitScene);
      }

      for (final entry in results.entries) {
        final aperture = entry.value.settings
            .firstWhere((s) => s.settingId == 'aperture');
        // Bokeh intention → engine should pick wide aperture (low f-number)
        // Kit lenses vary (f/2.8 to f/4.5) but should be at or near max aperture
        final fValue = aperture.value as double;
        expect(fValue, lessThanOrEqualTo(8.0),
            reason:
                '${entry.key} aperture $fValue should be wide for bokeh');
      }
    });

    test('all 3 bodies recommend AF-S or AF-C for portrait', () async {
      for (final bodyId in bodies) {
        final cache = CameraDataCache();
        await cache.load(bodyId, dataSource);
        final body = cache.body;
        final lens = cache.allLenses.first;
        final result = engine.calculate(body, lens, portraitScene);

        final afMode = result.settings
            .firstWhere((s) => s.settingId == 'af_mode');
        // Portrait still → engine picks AF-S (single) or AF-C (continuous)
        expect(
          afMode.value,
          anyOf(AfMode.afS, AfMode.afC),
          reason: '$bodyId should use AF-S or AF-C for portrait',
        );
      }
    });

    test('all 3 bodies recommend aperture priority for bokeh', () async {
      for (final bodyId in bodies) {
        final cache = CameraDataCache();
        await cache.load(bodyId, dataSource);
        final body = cache.body;
        final lens = cache.allLenses.first;
        final result = engine.calculate(body, lens, portraitScene);

        final expMode = result.settings
            .firstWhere((s) => s.settingId == 'exposure_mode');
        // Bokeh → aperture priority
        expect(
          expMode.value,
          ExposureMode.a,
          reason: '$bodyId should use aperture priority for bokeh',
        );
      }
    });

    test('ISO stays reasonable (≤ 3200) in bright outdoor', () async {
      for (final bodyId in bodies) {
        final cache = CameraDataCache();
        await cache.load(bodyId, dataSource);
        final body = cache.body;
        final lens = cache.allLenses.first;
        final result = engine.calculate(body, lens, portraitScene);

        final iso = result.settings
            .firstWhere((s) => s.settingId == 'iso');
        final isoValue = iso.value as int;
        expect(isoValue, lessThanOrEqualTo(3200),
            reason:
                '$bodyId ISO $isoValue should be low in bright outdoor');
      }
    });

    test('confidence is medium or high for detailed scene', () async {
      for (final bodyId in bodies) {
        final cache = CameraDataCache();
        await cache.load(bodyId, dataSource);
        final body = cache.body;
        final lens = cache.allLenses.first;
        final result = engine.calculate(body, lens, portraitScene);

        expect(
          result.confidence,
          anyOf(Confidence.medium, Confidence.high),
          reason: '$bodyId should have medium+ confidence with detailed input',
        );
      }
    });
  });
}
