import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/data_sources/local/gear_profile_source.dart';

/// SharedPreferences instance — must be initialized before app starts.
final sharedPreferencesProvider =
    Provider<SharedPreferences>((ref) => throw UnimplementedError(
          'sharedPreferencesProvider must be overridden at startup',
        ));

/// Gear profile source backed by SharedPreferences.
final gearProfileProvider = Provider<GearProfileSource>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return GearProfileSource(prefs);
});
