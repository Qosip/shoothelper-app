import 'package:flutter_test/flutter_test.dart';
import 'package:shoothelper/shared/domain/entities/body_spec.dart';
import 'package:shoothelper/shared/domain/value_objects/f_stop.dart';
import 'package:shoothelper/features/settings_engine/domain/engine/astro_calculator.dart';

void main() {
  const calc = AstroCalculator();

  final a6700Sensor = const SensorSpec(
    megapixels: 26.0,
    isoMin: 100,
    isoMax: 32000,
    isoUsableMax: 6400,
    sensorWidthMm: 23.5,
    sensorHeightMm: 15.6,
  );

  group('AstroCalculator', () {
    test('pixel pitch for A6700 is ~3.75µm', () {
      final pp = calc.pixelPitch(a6700Sensor);
      expect(pp, closeTo(3.75, 0.1));
    });

    test('NPF rule at 18mm f/2.8 gives ~11-12s', () {
      final result = calc.maxExposureTime(
        aperture: const FStop(2.8),
        sensor: a6700Sensor,
        focalMm: 18,
      );
      // (35*2.8 + 30*3.75) / 18 = (98 + 112.5) / 18 ≈ 11.7s
      expect(result.seconds, closeTo(11.7, 1));
    });

    test('NPF rule at 50mm gives shorter exposure', () {
      final result = calc.maxExposureTime(
        aperture: const FStop(2.8),
        sensor: a6700Sensor,
        focalMm: 50,
      );
      // (98 + 112.5) / 50 ≈ 4.2s
      expect(result.seconds, closeTo(4.2, 0.5));
    });
  });
}
