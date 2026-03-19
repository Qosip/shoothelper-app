import 'package:flutter_test/flutter_test.dart';
import 'package:shoothelper/shared/domain/value_objects/f_stop.dart';
import 'package:shoothelper/shared/domain/value_objects/iso_value.dart';
import 'package:shoothelper/shared/domain/value_objects/shutter_speed.dart';
import 'package:shoothelper/features/settings_engine/domain/engine/exposure_calculator.dart';

void main() {
  const calc = ExposureCalculator();

  group('ExposureCalculator', () {
    test('resolveIso at EV 15 (sunny 16)', () {
      // f/16, 1/100s, EV 15 → ISO should be ~100
      final iso = calc.resolveIso(
        const FStop(16),
        const ShutterSpeed(1 / 100),
        15,
      );
      expect(iso.value, closeTo(100, 30));
    });

    test('resolveShutter for known exposure', () {
      // f/2.8, ISO 100, EV 14
      // S = A²/((ISO/100)×2^EV) = 7.84/(1×16384) ≈ 0.000479 ≈ 1/2088s
      final shutter = calc.resolveShutter(
        const FStop(2.8),
        const IsoValue(100),
        14,
      );
      expect(shutter.seconds, closeTo(0.000479, 0.0001));
    });

    test('resolveAperture for known exposure', () {
      // 1/250s, ISO 100, EV 14
      // A = sqrt(S × (ISO/100) × 2^EV) = sqrt(0.004 × 1 × 16384) ≈ 8.1
      final ap = calc.resolveAperture(
        ShutterSpeed.fraction(250),
        const IsoValue(100),
        14,
      );
      expect(ap.value, closeTo(8.1, 0.5));
    });

    test('computeEv returns correct value', () {
      // f/16, 1/100s, ISO 100 → EV ~15
      final ev = calc.computeEv(
        const FStop(16),
        const ShutterSpeed(1 / 100),
        const IsoValue(100),
      );
      expect(ev, closeTo(15, 0.5));
    });

    test('triangle is self-consistent', () {
      // Set values and compute EV, then resolve back
      const ap = FStop(5.6);
      final shutter = ShutterSpeed.fraction(250);
      const iso = IsoValue(400);

      final ev = calc.computeEv(ap, shutter, iso);
      final resolvedIso = calc.resolveIso(ap, shutter, ev);
      expect(resolvedIso.value, closeTo(iso.value, 5));
    });
  });
}
