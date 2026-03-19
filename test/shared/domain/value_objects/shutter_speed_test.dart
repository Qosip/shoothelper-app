import 'package:flutter_test/flutter_test.dart';
import 'package:shoothelper/shared/domain/value_objects/shutter_speed.dart';

void main() {
  group('ShutterSpeed', () {
    test('display formats fractions correctly', () {
      expect(ShutterSpeed.fraction(250).display, '1/250s');
      expect(ShutterSpeed.fraction(1000).display, '1/1000s');
      expect(ShutterSpeed.fraction(60).display, '1/60s');
    });

    test('display formats whole seconds correctly', () {
      expect(const ShutterSpeed(1).display, '1s');
      expect(const ShutterSpeed(2).display, '2s');
      expect(const ShutterSpeed(30).display, '30s');
    });

    test('fraction constructor works', () {
      final s = ShutterSpeed.fraction(500);
      expect(s.seconds, closeTo(0.002, 0.0001));
    });

    test('toNearestStandard rounds correctly', () {
      final s = const ShutterSpeed(0.003); // ~1/333
      final std = s.toNearestStandard();
      expect(std.seconds, closeTo(1 / 320, 0.0001));
    });

    test('evContribution is correct', () {
      expect(const ShutterSpeed(1).evContribution, closeTo(0, 0.01));
      expect(const ShutterSpeed(0.5).evContribution, closeTo(1, 0.01));
      expect(const ShutterSpeed(0.25).evContribution, closeTo(2, 0.01));
    });

    test('comparison works', () {
      expect(
        ShutterSpeed.fraction(500) < ShutterSpeed.fraction(250),
        isTrue,
      );
    });
  });
}
