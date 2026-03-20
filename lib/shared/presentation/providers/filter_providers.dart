import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/data_sources/local/filter_store.dart';
import '../../domain/entities/optical_filter.dart';
import 'gear_profile_provider.dart';

/// FilterStore instance.
final filterStoreProvider = Provider<FilterStore>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return FilterStore(prefs);
});

/// All user filters.
final userFiltersProvider = Provider<List<OpticalFilter>>((ref) {
  final store = ref.watch(filterStoreProvider);
  return store.filters;
});

/// Currently active filter for scene input (null = no filter).
final activeFilterProvider = StateProvider<OpticalFilter?>((ref) => null);
