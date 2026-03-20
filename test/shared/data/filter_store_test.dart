import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shoothelper/shared/data/data_sources/local/filter_store.dart';
import 'package:shoothelper/shared/domain/entities/optical_filter.dart';

void main() {
  group('FilterStore', () {
    late SharedPreferences prefs;
    late FilterStore store;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
      store = FilterStore(prefs);
    });

    test('starts empty', () {
      expect(store.filters, isEmpty);
    });

    test('addFilter persists and retrieves', () async {
      const f = NdFilter(id: 'nd64', name: 'ND64', stops: 6, filterDiameterMm: 67);
      await store.addFilter(f);
      expect(store.filters.length, 1);
      expect(store.filters.first.name, 'ND64');
    });

    test('removeFilter works', () async {
      const f1 = NdFilter(id: 'nd8', name: 'ND8', stops: 3, filterDiameterMm: 67);
      const f2 = CplFilter(id: 'cpl', name: 'CPL', lightLoss: 1.5, filterDiameterMm: 67);
      await store.addFilter(f1);
      await store.addFilter(f2);
      expect(store.filters.length, 2);

      await store.removeFilter('nd8');
      expect(store.filters.length, 1);
      expect(store.filters.first.id, 'cpl');
    });

    test('addFilter with same id replaces', () async {
      const f1 = NdFilter(id: 'nd64', name: 'ND64', stops: 6, filterDiameterMm: 67);
      const f2 = NdFilter(id: 'nd64', name: 'ND64 v2', stops: 6, filterDiameterMm: 77);
      await store.addFilter(f1);
      await store.addFilter(f2);
      expect(store.filters.length, 1);
      expect(store.filters.first.filterDiameterMm, 77);
    });
  });
}
