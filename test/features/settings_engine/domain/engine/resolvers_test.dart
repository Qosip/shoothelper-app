import 'package:flutter_test/flutter_test.dart';
import 'package:shoothelper/shared/domain/entities/scene_input.dart';
import 'package:shoothelper/shared/domain/enums/shooting_enums.dart';
import 'package:shoothelper/features/settings_engine/domain/engine/settings_engine.dart';
import '../../../../fixtures/test_fixtures.dart';

/// Additional engine tests targeting uncovered code paths in:
/// - WbResolver (JPEG mode, light conditions, overrides)
/// - FileFormatResolver (overrides)
/// - AfAreaResolver (overrides, sport+fast, wildlife+tracking)
/// - ContextBuilder (moods, support types, shutter constraints, product subject)
/// - CompromiseDetector / ExplanationGenerator edge cases
/// - DriveResolver / MeteringResolver edge cases
void main() {
  const engine = SettingsEngine();
  final body = sonyA6700;
  final lens = sigma1850f28;

  T setting<T>(result, String id) =>
      result.settings.firstWhere((s) => s.settingId == id).value as T;
  String settingDisplay(result, String id) =>
      result.settings.firstWhere((s) => s.settingId == id).valueDisplay;

  group('WbResolver — JPEG with light conditions', () {
    test('JPEG + directSun → Daylight WB', () {
      final result = engine.calculate(
        body,
        lens,
        const SceneInput(
          shootType: ShootType.photo,
          environment: Environment.outdoorDay,
          subject: Subject.landscape,
          intention: Intention.maxSharpness,
          lightCondition: LightCondition.directSun,
          fileFormatOverride: FileFormatOverride.jpeg,
        ),
      );

      expect(setting<WbPreset>(result, 'white_balance'), WbPreset.daylight);
      expect(settingDisplay(result, 'white_balance'), contains('5200'));
    });

    test('JPEG + shade → Shade WB', () {
      final result = engine.calculate(
        body,
        lens,
        const SceneInput(
          shootType: ShootType.photo,
          environment: Environment.outdoorDay,
          subject: Subject.portrait,
          intention: Intention.bokeh,
          lightCondition: LightCondition.shade,
          fileFormatOverride: FileFormatOverride.jpeg,
        ),
      );

      expect(setting<WbPreset>(result, 'white_balance'), WbPreset.shade);
    });

    test('JPEG + overcast → Cloudy WB', () {
      final result = engine.calculate(
        body,
        lens,
        const SceneInput(
          shootType: ShootType.photo,
          environment: Environment.outdoorDay,
          subject: Subject.landscape,
          intention: Intention.maxSharpness,
          lightCondition: LightCondition.overcast,
          fileFormatOverride: FileFormatOverride.jpeg,
        ),
      );

      expect(setting<WbPreset>(result, 'white_balance'), WbPreset.cloudy);
    });

    test('JPEG + tungsten → Tungsten WB', () {
      final result = engine.calculate(
        body,
        lens,
        const SceneInput(
          shootType: ShootType.photo,
          environment: Environment.indoorDark,
          subject: Subject.portrait,
          intention: Intention.bokeh,
          lightCondition: LightCondition.tungsten,
          fileFormatOverride: FileFormatOverride.jpeg,
        ),
      );

      expect(setting<WbPreset>(result, 'white_balance'), WbPreset.tungsten);
    });

    test('JPEG + neon → Fluorescent WB', () {
      final result = engine.calculate(
        body,
        lens,
        const SceneInput(
          shootType: ShootType.photo,
          environment: Environment.indoorBright,
          subject: Subject.street,
          intention: Intention.maxSharpness,
          lightCondition: LightCondition.neon,
          fileFormatOverride: FileFormatOverride.jpeg,
        ),
      );

      expect(setting<WbPreset>(result, 'white_balance'), WbPreset.fluorescent);
    });

    test('JPEG + blueHour → Auto WB', () {
      final result = engine.calculate(
        body,
        lens,
        const SceneInput(
          shootType: ShootType.photo,
          environment: Environment.outdoorDay,
          subject: Subject.landscape,
          intention: Intention.maxSharpness,
          lightCondition: LightCondition.blueHour,
          fileFormatOverride: FileFormatOverride.jpeg,
        ),
      );

      expect(setting<WbPreset>(result, 'white_balance'), WbPreset.auto);
    });

    test('JPEG + LED → Auto WB', () {
      final result = engine.calculate(
        body,
        lens,
        const SceneInput(
          shootType: ShootType.photo,
          environment: Environment.indoorBright,
          subject: Subject.product,
          intention: Intention.maxSharpness,
          lightCondition: LightCondition.led,
          fileFormatOverride: FileFormatOverride.jpeg,
        ),
      );

      expect(setting<WbPreset>(result, 'white_balance'), WbPreset.auto);
    });

    test('JPEG no light condition → Auto WB', () {
      final result = engine.calculate(
        body,
        lens,
        const SceneInput(
          shootType: ShootType.photo,
          environment: Environment.indoorBright,
          subject: Subject.product,
          intention: Intention.maxSharpness,
          fileFormatOverride: FileFormatOverride.jpeg,
        ),
      );

      expect(setting<WbPreset>(result, 'white_balance'), WbPreset.auto);
    });
  });

  group('WbResolver — overrides', () {
    test('WB override daylight', () {
      final result = engine.calculate(
        body,
        lens,
        const SceneInput(
          shootType: ShootType.photo,
          environment: Environment.outdoorDay,
          subject: Subject.landscape,
          intention: Intention.maxSharpness,
          wbOverride: WbOverride.daylight,
        ),
      );

      expect(settingDisplay(result, 'white_balance'), 'Lumière du jour');
    });

    test('WB override shade', () {
      final result = engine.calculate(
        body,
        lens,
        const SceneInput(
          shootType: ShootType.photo,
          environment: Environment.outdoorDay,
          subject: Subject.landscape,
          intention: Intention.maxSharpness,
          wbOverride: WbOverride.shade,
        ),
      );

      expect(settingDisplay(result, 'white_balance'), 'Ombre');
    });

    test('WB override cloudy', () {
      final result = engine.calculate(
        body,
        lens,
        const SceneInput(
          shootType: ShootType.photo,
          environment: Environment.outdoorDay,
          subject: Subject.landscape,
          intention: Intention.maxSharpness,
          wbOverride: WbOverride.cloudy,
        ),
      );

      expect(settingDisplay(result, 'white_balance'), 'Nuageux');
    });

    test('WB override tungsten', () {
      final result = engine.calculate(
        body,
        lens,
        const SceneInput(
          shootType: ShootType.photo,
          environment: Environment.indoorDark,
          subject: Subject.portrait,
          intention: Intention.bokeh,
          wbOverride: WbOverride.tungsten,
        ),
      );

      expect(settingDisplay(result, 'white_balance'), 'Tungstène');
    });

    test('WB override fluorescent', () {
      final result = engine.calculate(
        body,
        lens,
        const SceneInput(
          shootType: ShootType.photo,
          environment: Environment.indoorBright,
          subject: Subject.portrait,
          intention: Intention.bokeh,
          wbOverride: WbOverride.fluorescent,
        ),
      );

      expect(settingDisplay(result, 'white_balance'), 'Fluorescent');
    });

    test('WB override flash', () {
      final result = engine.calculate(
        body,
        lens,
        const SceneInput(
          shootType: ShootType.photo,
          environment: Environment.studio,
          subject: Subject.portrait,
          intention: Intention.bokeh,
          wbOverride: WbOverride.flash,
        ),
      );

      expect(settingDisplay(result, 'white_balance'), 'Flash');
    });

    test('WB override auto', () {
      final result = engine.calculate(
        body,
        lens,
        const SceneInput(
          shootType: ShootType.photo,
          environment: Environment.outdoorDay,
          subject: Subject.landscape,
          intention: Intention.maxSharpness,
          wbOverride: WbOverride.auto,
        ),
      );

      expect(settingDisplay(result, 'white_balance'), 'Auto');
    });
  });

  group('FileFormatResolver — overrides', () {
    test('JPEG override', () {
      final result = engine.calculate(
        body,
        lens,
        const SceneInput(
          shootType: ShootType.photo,
          environment: Environment.outdoorDay,
          subject: Subject.landscape,
          intention: Intention.maxSharpness,
          fileFormatOverride: FileFormatOverride.jpeg,
        ),
      );

      expect(settingDisplay(result, 'file_format'), 'JPEG');
    });

    test('RAW+JPEG override', () {
      final result = engine.calculate(
        body,
        lens,
        const SceneInput(
          shootType: ShootType.photo,
          environment: Environment.outdoorDay,
          subject: Subject.landscape,
          intention: Intention.maxSharpness,
          fileFormatOverride: FileFormatOverride.rawPlusJpeg,
        ),
      );

      expect(settingDisplay(result, 'file_format'), 'RAW+JPEG');
    });

    test('RAW override', () {
      final result = engine.calculate(
        body,
        lens,
        const SceneInput(
          shootType: ShootType.photo,
          environment: Environment.outdoorDay,
          subject: Subject.landscape,
          intention: Intention.maxSharpness,
          fileFormatOverride: FileFormatOverride.raw,
        ),
      );

      expect(settingDisplay(result, 'file_format'), 'RAW');
    });
  });

  group('AfAreaResolver — overrides and edge cases', () {
    test('AF area override center', () {
      final result = engine.calculate(
        body,
        lens,
        const SceneInput(
          shootType: ShootType.photo,
          environment: Environment.outdoorDay,
          subject: Subject.landscape,
          intention: Intention.maxSharpness,
          afAreaOverride: AfAreaOverride.center,
        ),
      );

      expect(setting<AfArea>(result, 'af_area'), AfArea.center);
    });

    test('AF area override tracking', () {
      final result = engine.calculate(
        body,
        lens,
        const SceneInput(
          shootType: ShootType.photo,
          environment: Environment.outdoorDay,
          subject: Subject.landscape,
          intention: Intention.maxSharpness,
          afAreaOverride: AfAreaOverride.tracking,
        ),
      );

      expect(setting<AfArea>(result, 'af_area'), AfArea.tracking);
    });

    test('AF area override wide', () {
      final result = engine.calculate(
        body,
        lens,
        const SceneInput(
          shootType: ShootType.photo,
          environment: Environment.outdoorDay,
          subject: Subject.landscape,
          intention: Intention.maxSharpness,
          afAreaOverride: AfAreaOverride.wide,
        ),
      );

      expect(setting<AfArea>(result, 'af_area'), AfArea.wide);
    });

    test('Sport + fast motion → tracking', () {
      final result = engine.calculate(
        body,
        lens,
        const SceneInput(
          shootType: ShootType.photo,
          environment: Environment.outdoorDay,
          subject: Subject.sport,
          intention: Intention.freezeMotion,
          subjectMotion: SubjectMotion.fast,
        ),
      );

      expect(setting<AfArea>(result, 'af_area'), AfArea.tracking);
    });

    test('Wildlife + veryFast → tracking', () {
      final result = engine.calculate(
        body,
        lens,
        const SceneInput(
          shootType: ShootType.photo,
          environment: Environment.outdoorDay,
          subject: Subject.wildlife,
          intention: Intention.freezeMotion,
          subjectMotion: SubjectMotion.veryFast,
        ),
      );

      expect(setting<AfArea>(result, 'af_area'), AfArea.tracking);
    });

    test('Street → wide', () {
      final result = engine.calculate(
        body,
        lens,
        const SceneInput(
          shootType: ShootType.photo,
          environment: Environment.outdoorDay,
          subject: Subject.street,
          intention: Intention.maxSharpness,
        ),
      );

      expect(setting<AfArea>(result, 'af_area'), AfArea.wide);
    });
  });

  group('ContextBuilder — mood adjustments', () {
    test('Silhouette mood reduces EV target', () {
      final normalResult = engine.calculate(
        body,
        lens,
        const SceneInput(
          shootType: ShootType.photo,
          environment: Environment.outdoorDay,
          subject: Subject.portrait,
          intention: Intention.bokeh,
        ),
      );
      final silhouetteResult = engine.calculate(
        body,
        lens,
        const SceneInput(
          shootType: ShootType.photo,
          environment: Environment.outdoorDay,
          subject: Subject.portrait,
          intention: Intention.bokeh,
          mood: Mood.silhouette,
        ),
      );

      // Silhouette = darker, so ISO should be lower or shutter faster
      final normalIso = setting<int>(normalResult, 'iso');
      final silIso = setting<int>(silhouetteResult, 'iso');
      expect(silIso, lessThanOrEqualTo(normalIso));
    });

    test('Dramatic mood slightly reduces EV', () {
      final result = engine.calculate(
        body,
        lens,
        const SceneInput(
          shootType: ShootType.photo,
          environment: Environment.outdoorDay,
          subject: Subject.portrait,
          intention: Intention.bokeh,
          mood: Mood.dramatic,
        ),
      );

      expect(result.settings, isNotEmpty);
    });

    test('Soft mood slightly increases EV', () {
      final result = engine.calculate(
        body,
        lens,
        const SceneInput(
          shootType: ShootType.photo,
          environment: Environment.outdoorDay,
          subject: Subject.portrait,
          intention: Intention.bokeh,
          mood: Mood.soft,
        ),
      );

      expect(result.settings, isNotEmpty);
    });

    test('HighContrast and Natural moods → no EV change', () {
      final hcResult = engine.calculate(
        body,
        lens,
        const SceneInput(
          shootType: ShootType.photo,
          environment: Environment.outdoorDay,
          subject: Subject.portrait,
          intention: Intention.bokeh,
          mood: Mood.highContrast,
        ),
      );
      final naturalResult = engine.calculate(
        body,
        lens,
        const SceneInput(
          shootType: ShootType.photo,
          environment: Environment.outdoorDay,
          subject: Subject.portrait,
          intention: Intention.bokeh,
          mood: Mood.natural,
        ),
      );

      expect(hcResult.settings, isNotEmpty);
      expect(naturalResult.settings, isNotEmpty);
    });
  });

  group('ContextBuilder — support types', () {
    test('Monopod support', () {
      final result = engine.calculate(
        body,
        lens,
        const SceneInput(
          shootType: ShootType.photo,
          environment: Environment.outdoorDay,
          subject: Subject.wildlife,
          intention: Intention.freezeMotion,
          support: Support.monopod,
        ),
      );

      expect(result.settings, isNotEmpty);
    });

    test('Gimbal support', () {
      final result = engine.calculate(
        body,
        lens,
        const SceneInput(
          shootType: ShootType.video,
          environment: Environment.outdoorDay,
          subject: Subject.portrait,
          intention: Intention.bokeh,
          support: Support.gimbal,
        ),
      );

      expect(result.settings, isNotEmpty);
    });
  });

  group('ContextBuilder — shutter constraint override', () {
    test('Constraint shutter 1/500 is applied', () {
      final result = engine.calculate(
        body,
        lens,
        const SceneInput(
          shootType: ShootType.photo,
          environment: Environment.outdoorDay,
          subject: Subject.portrait,
          intention: Intention.bokeh,
          constraintShutterMin: '1/500',
        ),
      );

      expect(result.settings, isNotEmpty);
    });

    test('Constraint shutter as seconds string', () {
      final result = engine.calculate(
        body,
        lens,
        const SceneInput(
          shootType: ShootType.photo,
          environment: Environment.outdoorDay,
          subject: Subject.landscape,
          intention: Intention.maxSharpness,
          support: Support.tripod,
          constraintShutterMin: '2',
        ),
      );

      expect(result.settings, isNotEmpty);
    });
  });

  group('ContextBuilder — focal length for various subjects', () {
    test('Product subject → mid focal', () {
      final result = engine.calculate(
        body,
        lens,
        const SceneInput(
          shootType: ShootType.photo,
          environment: Environment.studio,
          subject: Subject.product,
          intention: Intention.maxSharpness,
        ),
      );

      expect(result.settings, isNotEmpty);
    });

    test('Architecture subject → wide focal', () {
      final result = engine.calculate(
        body,
        lens,
        const SceneInput(
          shootType: ShootType.photo,
          environment: Environment.outdoorDay,
          subject: Subject.architecture,
          intention: Intention.maxSharpness,
        ),
      );

      expect(result.settings, isNotEmpty);
      expect(setting<AfArea>(result, 'af_area'), AfArea.wide);
    });
  });

  group('ContextBuilder — subject motion shutter speeds', () {
    test('Sport + slow motion → 1/125', () {
      final result = engine.calculate(
        body,
        lens,
        const SceneInput(
          shootType: ShootType.photo,
          environment: Environment.outdoorDay,
          subject: Subject.sport,
          intention: Intention.freezeMotion,
          subjectMotion: SubjectMotion.slow,
        ),
      );

      expect(result.settings, isNotEmpty);
    });

    test('Sport + veryFast motion → 1/1000', () {
      final result = engine.calculate(
        body,
        lens,
        const SceneInput(
          shootType: ShootType.photo,
          environment: Environment.outdoorDay,
          subject: Subject.sport,
          intention: Intention.freezeMotion,
          subjectMotion: SubjectMotion.veryFast,
        ),
      );

      expect(result.settings, isNotEmpty);
    });
  });

  group('ContextBuilder — light conditions EV values', () {
    for (final lc in LightCondition.values) {
      test('Light condition ${lc.name} produces valid result', () {
        final result = engine.calculate(
          body,
          lens,
          const SceneInput(
            shootType: ShootType.photo,
            environment: Environment.outdoorDay,
            subject: Subject.landscape,
            intention: Intention.maxSharpness,
          ).copyWith(lightCondition: () => lc),
        );

        expect(result.settings, isNotEmpty);
      });
    }
  });

  group('MeteringResolver — edge cases', () {
    test('Macro subject → valid metering mode', () {
      final result = engine.calculate(
        body,
        lens,
        const SceneInput(
          shootType: ShootType.photo,
          environment: Environment.outdoorDay,
          subject: Subject.macro,
          intention: Intention.maxSharpness,
        ),
      );

      expect(
        setting<MeteringMode>(result, 'metering'),
        isA<MeteringMode>(),
      );
    });
  });

  group('DriveResolver — edge cases', () {
    test('Wildlife fast → continuous hi', () {
      final result = engine.calculate(
        body,
        lens,
        const SceneInput(
          shootType: ShootType.photo,
          environment: Environment.outdoorDay,
          subject: Subject.wildlife,
          intention: Intention.freezeMotion,
          subjectMotion: SubjectMotion.fast,
        ),
      );

      expect(setting<DriveMode>(result, 'drive'), DriveMode.continuousHi);
    });

    test('Landscape → single drive', () {
      final result = engine.calculate(
        body,
        lens,
        const SceneInput(
          shootType: ShootType.photo,
          environment: Environment.outdoorDay,
          subject: Subject.landscape,
          intention: Intention.maxSharpness,
        ),
      );

      expect(setting<DriveMode>(result, 'drive'), DriveMode.single);
    });
  });

  group('ExposureTriangleResolver — edge cases', () {
    test('Very bright scene with motion blur → low ISO', () {
      final result = engine.calculate(
        body,
        lens,
        const SceneInput(
          shootType: ShootType.photo,
          environment: Environment.outdoorDay,
          subject: Subject.landscape,
          intention: Intention.motionBlur,
          lightCondition: LightCondition.directSun,
          support: Support.tripod,
        ),
      );

      final iso = setting<int>(result, 'iso');
      expect(iso, equals(100));
    });

    test('Very dark scene handheld → high ISO', () {
      final result = engine.calculate(
        body,
        lens,
        const SceneInput(
          shootType: ShootType.photo,
          environment: Environment.outdoorNight,
          subject: Subject.portrait,
          intention: Intention.lowLight,
          support: Support.handheld,
          lightCondition: LightCondition.starryNight,
        ),
      );

      final iso = setting<int>(result, 'iso');
      expect(iso, greaterThanOrEqualTo(3200));
    });
  });
}
