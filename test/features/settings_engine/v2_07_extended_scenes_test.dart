import 'package:flutter_test/flutter_test.dart';
import 'package:shoothelper/features/settings_engine/domain/engine/context_builder.dart';
import 'package:shoothelper/shared/domain/entities/body_spec.dart';
import 'package:shoothelper/shared/domain/entities/lens_spec.dart';
import 'package:shoothelper/shared/domain/entities/scene_input.dart';
import 'package:shoothelper/shared/domain/enums/shooting_enums.dart';

/// V2-07: At least 1 scenario test per new subject + new intentions + new light conditions.
void main() {
  const builder = ContextBuilder();
  const body = BodySpec(
    id: 'sony_a6700',
    brandId: 'sony',
    name: 'Sony A6700',
    displayName: 'Sony α6700',
    sensorSize: SensorSize.apsc,
    cropFactor: 1.5,
    sensor: SensorSpec(
      megapixels: 26.0,
      isoMin: 100,
      isoMax: 32000,
      isoUsableMax: 6400,
      sensorWidthMm: 23.5,
      sensorHeightMm: 15.6,
    ),
    shutter: ShutterSpec(
      mechanicalMinSeconds: 1 / 4000,
      mechanicalMaxSeconds: 30,
      electronicMinSeconds: 1 / 8000,
      electronicMaxSeconds: 30,
      flashSyncSpeed: '1/160',
    ),
    autofocus: AutofocusSpec(
      modes: ['af-s', 'af-c'],
      areas: ['wide', 'spot'],
      hasEyeAf: true,
    ),
    metering: MeteringSpec(modes: ['multi', 'center', 'spot']),
    exposure: ExposureSpec(modes: ['p', 'a', 's', 'm']),
    stabilization: StabilizationSpec(hasIbis: true, ibisStops: 5),
    drive: DriveSpec(modes: ['single', 'continuous_hi']),
    photoFormats: ['raw', 'jpeg'],
  );
  const lens = LensSpec(
    id: 'sigma_18-50',
    brandId: 'sigma',
    name: 'Sigma 18-50mm f/2.8',
    displayName: 'Sigma 18-50mm f/2.8',
    type: LensType.zoom,
    focalLength: FocalLengthSpec(minMm: 18, maxMm: 50),
    aperture:
        ApertureSpec(isConstant: true, maxAperture: 2.8, minAperture: 22),
    focus: LensFocusSpec(minFocusDistanceM: 0.125),
    stabilization: LensStabilizationSpec(),
  );

  SceneInput makeScene({
    Subject subject = Subject.landscape,
    Intention intention = Intention.maxSharpness,
    Environment environment = Environment.outdoorDay,
    LightCondition? lightCondition,
    Support? support,
  }) =>
      SceneInput(
        shootType: ShootType.photo,
        environment: environment,
        subject: subject,
        intention: intention,
        lightCondition: lightCondition,
        support: support,
      );

  group('V2-07 New Subjects — ContextBuilder', () {
    test('concert: uses max focal, shutter ≥ 1/500', () {
      final ctx = builder.build(
          body, lens, makeScene(subject: Subject.concert, intention: Intention.freezeMotion));
      expect(ctx.focalMm, 50); // maxF for concert
      expect(ctx.shutterMinSubject.seconds, lessThanOrEqualTo(1 / 500));
    });

    test('food: uses mid focal, shutter ≥ 1/125', () {
      final ctx = builder.build(body, lens, makeScene(subject: Subject.food));
      expect(ctx.focalMm, 34); // mid of 18-50
      expect(ctx.shutterMinSubject.seconds, lessThanOrEqualTo(1 / 125));
    });

    test('realEstate: uses minF (wide)', () {
      final ctx = builder.build(body, lens, makeScene(subject: Subject.realEstate));
      expect(ctx.focalMm, 18);
    });

    test('aurora: uses minF, astro calculator for shutter', () {
      final ctx = builder.build(body, lens,
          makeScene(subject: Subject.aurora, environment: Environment.outdoorNight));
      expect(ctx.focalMm, 18);
      // shutterMinSubject from astro calculator
      expect(ctx.shutterMinSubject.seconds, greaterThan(1));
    });

    test('lightning: uses minF, long exposure', () {
      final ctx = builder.build(body, lens,
          makeScene(subject: Subject.lightning, support: Support.tripod));
      expect(ctx.focalMm, 18);
      expect(ctx.shutterMinSubject.seconds, 15);
    });

    test('fireworks: uses minF, ~4s shutter', () {
      final ctx = builder.build(body, lens,
          makeScene(subject: Subject.fireworks, support: Support.tripod));
      expect(ctx.focalMm, 18);
      expect(ctx.shutterMinSubject.seconds, 4);
    });

    test('underwater: uses mid focal', () {
      final ctx = builder.build(body, lens, makeScene(subject: Subject.underwater));
      expect(ctx.focalMm, 34);
    });

    test('wedding: uses portrait focal, shutter ≥ 1/125', () {
      final ctx = builder.build(body, lens,
          makeScene(subject: Subject.wedding, intention: Intention.bokeh));
      expect(ctx.focalMm, 50); // min(maxF, 85/1.5=57) → 50
      expect(ctx.shutterMinSubject.seconds, lessThanOrEqualTo(1 / 125));
    });

    test('event: uses ~35mm eq focal, shutter ≥ 1/125', () {
      final ctx = builder.build(body, lens, makeScene(subject: Subject.event));
      expect(ctx.focalMm, greaterThanOrEqualTo(18));
      expect(ctx.shutterMinSubject.seconds, lessThanOrEqualTo(1 / 125));
    });

    test('droneAerial: uses minF, shutter ≥ 1/250', () {
      final ctx = builder.build(body, lens, makeScene(subject: Subject.droneAerial));
      expect(ctx.focalMm, 18);
      expect(ctx.shutterMinSubject.seconds, lessThanOrEqualTo(1 / 250));
    });

    test('selfPortrait: uses portrait focal', () {
      final ctx = builder.build(body, lens, makeScene(subject: Subject.selfPortrait));
      expect(ctx.focalMm, 50); // min(maxF, 85/1.5)
    });

    test('pet: uses mid focal, shutter ≥ 1/250 (no motion specified)', () {
      final ctx = builder.build(body, lens, makeScene(subject: Subject.pet));
      expect(ctx.focalMm, 34);
      expect(ctx.shutterMinSubject.seconds, lessThanOrEqualTo(1 / 250));
    });

    test('nightCityscape: uses minF, 30s shutter', () {
      final ctx = builder.build(body, lens,
          makeScene(subject: Subject.nightCityscape, support: Support.tripod,
              environment: Environment.outdoorNight));
      expect(ctx.focalMm, 18);
      expect(ctx.shutterMinSubject.seconds, 30);
    });

    test('starTrails: uses minF, 30s shutter', () {
      final ctx = builder.build(body, lens,
          makeScene(subject: Subject.starTrails, support: Support.tripod,
              environment: Environment.outdoorNight));
      expect(ctx.focalMm, 18);
      expect(ctx.shutterMinSubject.seconds, 30);
    });
  });

  group('V2-07 New Light Conditions — EV values', () {
    test('mixedLighting EV = 9', () {
      final ctx = builder.build(body, lens,
          makeScene(lightCondition: LightCondition.mixedLighting,
              environment: Environment.indoorBright));
      expect(ctx.evTarget, 9);
    });

    test('backlit EV = 14', () {
      final ctx = builder.build(body, lens,
          makeScene(lightCondition: LightCondition.backlit));
      expect(ctx.evTarget, 14);
    });

    test('harshMidday EV = 16', () {
      final ctx = builder.build(body, lens,
          makeScene(lightCondition: LightCondition.harshMidday));
      expect(ctx.evTarget, 16);
    });

    test('diffused EV = 13.5', () {
      final ctx = builder.build(body, lens,
          makeScene(lightCondition: LightCondition.diffused));
      expect(ctx.evTarget, 13.5);
    });

    test('candlelight EV = 4', () {
      final ctx = builder.build(body, lens,
          makeScene(lightCondition: LightCondition.candlelight,
              environment: Environment.indoorDark));
      expect(ctx.evTarget, 4);
    });

    test('stageLighting EV = 7', () {
      final ctx = builder.build(body, lens,
          makeScene(lightCondition: LightCondition.stageLighting,
              environment: Environment.indoorDark));
      expect(ctx.evTarget, 7);
    });

    test('moonlight EV = -1', () {
      final ctx = builder.build(body, lens,
          makeScene(lightCondition: LightCondition.moonlight,
              environment: Environment.outdoorNight));
      expect(ctx.evTarget, -1);
    });
  });

  group('V2-07 New Intentions — ExposureTriangleResolver mapping', () {
    test('hdrDynamicRange builds context without error', () {
      final ctx = builder.build(body, lens,
          makeScene(intention: Intention.hdrDynamicRange));
      expect(ctx.evTarget, isNotNull);
    });

    test('longExposure builds context without error', () {
      final ctx = builder.build(body, lens,
          makeScene(intention: Intention.longExposure, support: Support.tripod));
      expect(ctx.evTarget, isNotNull);
    });

    test('panning builds context without error', () {
      final ctx = builder.build(body, lens,
          makeScene(intention: Intention.panning));
      expect(ctx.evTarget, isNotNull);
    });

    test('highSpeedSync builds context without error', () {
      final ctx = builder.build(body, lens,
          makeScene(intention: Intention.highSpeedSync));
      expect(ctx.evTarget, isNotNull);
    });

    test('documentary builds context without error', () {
      final ctx = builder.build(body, lens,
          makeScene(intention: Intention.documentary));
      expect(ctx.evTarget, isNotNull);
    });

    test('minimalistNoise builds context without error', () {
      final ctx = builder.build(body, lens,
          makeScene(intention: Intention.minimalistNoise));
      expect(ctx.evTarget, isNotNull);
    });
  });
}
