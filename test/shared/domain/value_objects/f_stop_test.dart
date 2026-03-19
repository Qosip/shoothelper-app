import 'package:flutter_test/flutter_test.dart';
import 'package:shoothelper/shared/domain/value_objects/f_stop.dart';

void main() {
  group('FStop', () {
    test('display formats correctly', () {
      expect(const FStop(2.8).display, 'f/2.8');
      expect(const FStop(8).display, 'f/8');
      expect(const FStop(11).display, 'f/11');
      expect(const FStop(1.4).display, 'f/1.4');
    });

    test('toNearestStandard rounds correctly', () {
      expect(const FStop(2.9).toNearestStandard().value, 2.8);
      expect(const FStop(7.5).toNearestStandard().value, 7.1); // 7.1 is closer
      expect(const FStop(5.3).toNearestStandard().value, 5.0);
    });

    test('toNearestWider returns smaller f-number', () {
      expect(const FStop(3.0).toNearestWider().value, 2.8);
      expect(const FStop(8.5).toNearestWider().value, 8.0);
    });

    test('toNearestNarrower returns larger f-number', () {
      expect(const FStop(3.0).toNearestNarrower().value, 3.2);
      expect(const FStop(7.5).toNearestNarrower().value, 8.0);
    });

    test('evContribution is correct for known values', () {
      expect(const FStop(1.0).evContribution, closeTo(0, 0.01));
      expect(const FStop(2.0).evContribution, closeTo(2, 0.01));
      expect(const FStop(4.0).evContribution, closeTo(4, 0.01));
    });

    test('equality works', () {
      expect(const FStop(2.8), equals(const FStop(2.8)));
      expect(const FStop(2.8) == const FStop(4.0), isFalse);
    });

    test('comparison works', () {
      expect(const FStop(2.8) < const FStop(4.0), isTrue);
      expect(const FStop(8.0) > const FStop(5.6), isTrue);
    });
  });
}
