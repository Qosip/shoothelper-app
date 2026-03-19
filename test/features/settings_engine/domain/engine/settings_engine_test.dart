import 'package:flutter_test/flutter_test.dart';
import 'package:shoothelper/shared/domain/entities/scene_input.dart';
import 'package:shoothelper/shared/domain/enums/shooting_enums.dart';
import 'package:shoothelper/features/settings_engine/domain/engine/settings_engine.dart';
import '../../../../fixtures/test_fixtures.dart';

void main() {
  const engine = SettingsEngine();
  final body = sonyA6700;
  final lens = sigma1850f28;

  // Helper to get a setting value by ID
  T setting<T>(result, String id) =>
      result.settings.firstWhere((s) => s.settingId == id).value as T;
  String settingDisplay(result, String id) =>
      result.settings.firstWhere((s) => s.settingId == id).valueDisplay;

  group('Settings Engine — 10 Scenarios (Skill 06 §13)', () {
    // T1: Portrait sunny — bokeh
    test('T1: Portrait outdoor_day bokeh → f/2.8, low ISO', () {
      final result = engine.calculate(
        body,
        lens,
        const SceneInput(
          shootType: ShootType.photo,
          environment: Environment.outdoorDay,
          subject: Subject.portrait,
          intention: Intention.bokeh,
        ),
      );

      final ap = setting<double>(result, 'aperture');
      final iso = setting<int>(result, 'iso');
      expect(ap, closeTo(2.8, 0.1)); // max aperture
      expect(iso, lessThanOrEqualTo(400)); // bright day = low ISO
      expect(settingDisplay(result, 'af_area'), 'Eye-AF');
      expect(setting<ExposureMode>(result, 'exposure_mode'), ExposureMode.a);
    });

    // T2: Landscape overcast — max sharpness
    test('T2: Landscape outdoor_day max_sharpness → f/8, low ISO', () {
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

      final ap = setting<double>(result, 'aperture');
      final iso = setting<int>(result, 'iso');
      expect(ap, inInclusiveRange(7.0, 11.0)); // sweet spot
      expect(iso, lessThanOrEqualTo(800));
      expect(setting<MeteringMode>(result, 'metering'), MeteringMode.multi);
    });

    // T3: Sport indoor dark — freeze motion
    test('T3: Sport indoor_dark freeze_motion → f/2.8, 1/500s, high ISO', () {
      final result = engine.calculate(
        body,
        lens,
        const SceneInput(
          shootType: ShootType.photo,
          environment: Environment.indoorDark,
          subject: Subject.sport,
          intention: Intention.freezeMotion,
        ),
      );

      final ap = setting<double>(result, 'aperture');
      final iso = setting<int>(result, 'iso');
      expect(ap, closeTo(2.8, 0.1));
      expect(iso, greaterThanOrEqualTo(1600)); // dark = high ISO
      expect(setting<DriveMode>(result, 'drive'), DriveMode.continuousHi);
      expect(setting<AfMode>(result, 'af_mode'), AfMode.afS); // no motion specified, sport default
    });

    // T4: Astro tripod
    test('T4: Astro outdoor_night tripod → f/2.8, ~12s, high ISO, MF', () {
      final result = engine.calculate(
        body,
        lens,
        const SceneInput(
          shootType: ShootType.photo,
          environment: Environment.outdoorNight,
          subject: Subject.astro,
          intention: Intention.maxSharpness,
          support: Support.tripod,
          lightCondition: LightCondition.starryNight,
        ),
      );

      final ap = setting<double>(result, 'aperture');
      final iso = setting<int>(result, 'iso');
      expect(ap, closeTo(2.8, 0.1));
      expect(iso, inInclusiveRange(2000, 12800));
      expect(setting<AfMode>(result, 'af_mode'), AfMode.mf);
      expect(setting<ExposureMode>(result, 'exposure_mode'), ExposureMode.m);
      // No critical compromise (tripod present)
      expect(
        result.compromises.where((c) =>
            c.type == CompromiseType.impossible &&
            c.message.contains('trépied')),
        isEmpty,
      );
    });

    // T5: Street golden hour
    test('T5: Street golden_hour bokeh → f/2.8, reasonable ISO', () {
      final result = engine.calculate(
        body,
        lens,
        const SceneInput(
          shootType: ShootType.photo,
          environment: Environment.outdoorDay,
          subject: Subject.street,
          intention: Intention.bokeh,
          lightCondition: LightCondition.goldenHour,
        ),
      );

      final ap = setting<double>(result, 'aperture');
      final iso = setting<int>(result, 'iso');
      expect(ap, closeTo(2.8, 0.1));
      expect(iso, lessThanOrEqualTo(800));
    });

    // T6: Portrait night handheld — low light
    test('T6: Portrait outdoor_night low_light handheld → high ISO compromise', () {
      final result = engine.calculate(
        body,
        lens,
        const SceneInput(
          shootType: ShootType.photo,
          environment: Environment.outdoorNight,
          subject: Subject.portrait,
          intention: Intention.lowLight,
          support: Support.handheld,
        ),
      );

      final ap = setting<double>(result, 'aperture');
      final iso = setting<int>(result, 'iso');
      expect(ap, closeTo(2.8, 0.1)); // wide open
      expect(iso, greaterThanOrEqualTo(640)); // night + handheld = moderate-high ISO
    });

    // T7: Macro outdoor
    test('T7: Macro outdoor_day max_sharpness → f/8, fast shutter', () {
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

      final ap = setting<double>(result, 'aperture');
      expect(ap, inInclusiveRange(7.0, 11.0));
      expect(setting<AfArea>(result, 'af_area'), AfArea.spot);
    });

    // T8: Impossible scenario
    test('T8: Sport outdoor_night freeze_motion ISO max 1600 → critical compromise', () {
      final result = engine.calculate(
        body,
        lens,
        const SceneInput(
          shootType: ShootType.photo,
          environment: Environment.outdoorNight,
          subject: Subject.sport,
          intention: Intention.freezeMotion,
          support: Support.handheld,
          constraintIsoMax: 1600,
        ),
      );

      // Should have a critical compromise about ISO constraint
      expect(
        result.compromises.any((c) => c.severity == CompromiseSeverity.critical),
        isTrue,
      );
      expect(result.confidence, Confidence.low);
    });

    // T9: Motion blur in bright sun
    test('T9: Motion blur direct_sun → ND filter warning', () {
      final result = engine.calculate(
        body,
        lens,
        const SceneInput(
          shootType: ShootType.photo,
          environment: Environment.outdoorDay,
          subject: Subject.sport,
          intention: Intention.motionBlur,
          lightCondition: LightCondition.directSun,
        ),
      );

      final iso = setting<int>(result, 'iso');
      expect(iso, equals(100)); // ISO at minimum
      // Should warn about ND filter or overexposure
      expect(
        result.compromises.any((c) =>
            c.type == CompromiseType.exposure ||
            c.type == CompromiseType.motionBlur),
        isTrue,
      );
    });

    // T10: Video portrait indoor
    test('T10: Video portrait indoor_bright bokeh → 1/50s, f/2.8', () {
      final result = engine.calculate(
        body,
        lens,
        const SceneInput(
          shootType: ShootType.video,
          environment: Environment.indoorBright,
          subject: Subject.portrait,
          intention: Intention.bokeh,
        ),
      );

      final ap = setting<double>(result, 'aperture');
      expect(ap, closeTo(2.8, 0.1));
      // Video: AF-C always
      expect(setting<AfMode>(result, 'af_mode'), AfMode.afC);
    });
  });
}
