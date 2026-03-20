import 'package:flutter_test/flutter_test.dart';
import 'package:shoothelper/shared/domain/entities/optical_filter.dart';

void main() {
  group('OpticalFilter', () {
    test('NdFilter lightLossStops equals stops', () {
      const f = NdFilter(id: 'nd64', name: 'ND64', stops: 6, filterDiameterMm: 67);
      expect(f.lightLossStops, 6.0);
    });

    test('NdVariableFilter lightLossStops uses selectedStops or minStops', () {
      const f = NdVariableFilter(
        id: 'ndv', name: 'ND Var', minStops: 2, maxStops: 5, filterDiameterMm: 67,
      );
      expect(f.lightLossStops, 2.0); // defaults to minStops
      final f2 = f.withSelectedStops(4);
      expect(f2.lightLossStops, 4.0);
      // Clamps out of range
      final f3 = f.withSelectedStops(10);
      expect(f3.lightLossStops, 5.0);
    });

    test('CplFilter lightLossStops equals lightLoss', () {
      const f = CplFilter(id: 'cpl', name: 'CPL', lightLoss: 1.5, filterDiameterMm: 67);
      expect(f.lightLossStops, 1.5);
    });

    test('UvFilter lightLossStops is 0', () {
      const f = UvFilter(id: 'uv', name: 'UV', filterDiameterMm: 67);
      expect(f.lightLossStops, 0);
    });

    test('toJson and fromJson roundtrip for NdFilter', () {
      const f = NdFilter(id: 'nd8', name: 'ND8', stops: 3, filterDiameterMm: 55);
      final json = f.toJson();
      final restored = OpticalFilter.fromJson(json);
      expect(restored, isA<NdFilter>());
      expect((restored as NdFilter).stops, 3);
      expect(restored.filterDiameterMm, 55);
    });

    test('toJson and fromJson roundtrip for NdVariableFilter', () {
      const f = NdVariableFilter(
        id: 'ndv', name: 'ND Var', minStops: 2, maxStops: 8, filterDiameterMm: 77,
      );
      final json = f.toJson();
      final restored = OpticalFilter.fromJson(json);
      expect(restored, isA<NdVariableFilter>());
      expect((restored as NdVariableFilter).minStops, 2);
      expect(restored.maxStops, 8);
    });

    test('toJson and fromJson roundtrip for CplFilter', () {
      const f = CplFilter(id: 'cpl', name: 'CPL', lightLoss: 1.5, filterDiameterMm: 67);
      final json = f.toJson();
      final restored = OpticalFilter.fromJson(json);
      expect(restored, isA<CplFilter>());
      expect((restored as CplFilter).lightLoss, 1.5);
    });

    test('toJson and fromJson roundtrip for UvFilter', () {
      const f = UvFilter(id: 'uv', name: 'UV', filterDiameterMm: 52);
      final json = f.toJson();
      final restored = OpticalFilter.fromJson(json);
      expect(restored, isA<UvFilter>());
      expect(restored.filterDiameterMm, 52);
    });

    test('fromJson throws for unknown type', () {
      expect(
        () => OpticalFilter.fromJson({'type': 'ir', 'id': 'x', 'name': 'x', 'filter_diameter_mm': 67}),
        throwsArgumentError,
      );
    });
  });
}
