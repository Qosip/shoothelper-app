import 'package:flutter_test/flutter_test.dart';
import 'package:shoothelper/features/settings_engine/domain/engine/context_builder.dart';
import 'package:shoothelper/shared/domain/entities/body_spec.dart';
import 'package:shoothelper/shared/domain/entities/lens_spec.dart';
import 'package:shoothelper/shared/domain/entities/scene_input.dart';
import 'package:shoothelper/shared/domain/enums/shooting_enums.dart';

void main() {
  group('Filter integration in ContextBuilder', () {
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
      aperture: ApertureSpec(isConstant: true, maxAperture: 2.8, minAperture: 22),
      focus: LensFocusSpec(minFocusDistanceM: 0.125),
      stabilization: LensStabilizationSpec(),
    );
    const scene = SceneInput(
      shootType: ShootType.photo,
      environment: Environment.outdoorDay,
      subject: Subject.landscape,
      intention: Intention.maxSharpness,
    );

    test('no filter gives base EV', () {
      final ctx = builder.build(body, lens, scene);
      final evNoFilter = ctx.evTarget;
      expect(evNoFilter, 14.0); // outdoorDay base EV
    });

    test('ND64 (6 stops) reduces EV by 6', () {
      final ctxNoFilter = builder.build(body, lens, scene);
      final ctxWithFilter =
          builder.build(body, lens, scene, filterLightLossStops: 6);
      expect(ctxWithFilter.evTarget, ctxNoFilter.evTarget - 6);
    });

    test('CPL (1.5 stops) reduces EV by 1.5', () {
      final ctxNoFilter = builder.build(body, lens, scene);
      final ctxWithFilter =
          builder.build(body, lens, scene, filterLightLossStops: 1.5);
      expect(ctxWithFilter.evTarget, ctxNoFilter.evTarget - 1.5);
    });

    test('filterLightLossStops is stored in context', () {
      final ctx =
          builder.build(body, lens, scene, filterLightLossStops: 3);
      expect(ctx.filterLightLossStops, 3);
    });
  });
}
