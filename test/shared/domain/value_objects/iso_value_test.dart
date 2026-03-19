import 'package:flutter_test/flutter_test.dart';
import 'package:shoothelper/shared/domain/value_objects/iso_value.dart';

void main() {
  group('IsoValue', () {
    test('display formats correctly', () {
      expect(const IsoValue(100).display, 'ISO 100');
      expect(const IsoValue(3200).display, 'ISO 3200');
    });

    test('toNearestStandard rounds correctly', () {
      expect(const IsoValue(150).toNearestStandard().value, 160);
      expect(const IsoValue(3000).toNearestStandard().value, 3200);
      expect(const IsoValue(100).toNearestStandard().value, 100);
    });

    test('toNearestLower returns lower standard', () {
      expect(const IsoValue(150).toNearestLower().value, 125);
      expect(const IsoValue(3200).toNearestLower().value, 3200);
    });

    test('toNearestHigher returns higher standard', () {
      expect(const IsoValue(150).toNearestHigher().value, 160);
      expect(const IsoValue(100).toNearestHigher().value, 100);
    });

    test('evContribution is correct', () {
      expect(const IsoValue(100).evContribution, closeTo(0, 0.01));
      expect(const IsoValue(200).evContribution, closeTo(-1, 0.01));
      expect(const IsoValue(400).evContribution, closeTo(-2, 0.01));
    });

    test('comparison works', () {
      expect(const IsoValue(100) < const IsoValue(200), isTrue);
      expect(const IsoValue(6400) > const IsoValue(3200), isTrue);
    });
  });
}
