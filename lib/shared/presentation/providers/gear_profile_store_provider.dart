import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/data_sources/local/gear_profile_store.dart';
import 'gear_profile_provider.dart';

/// GearProfileStore — multi-profile storage.
final gearProfileStoreProvider = Provider<GearProfileStore>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return GearProfileStore(prefs);
});

/// All profiles.
final allProfilesProvider = Provider<List<GearProfileData>>((ref) {
  final store = ref.watch(gearProfileStoreProvider);
  return store.profiles;
});

/// Active profile ID.
final activeProfileIdProvider = StateProvider<String?>((ref) {
  final store = ref.watch(gearProfileStoreProvider);
  return store.activeProfileId;
});

/// Active profile data.
final activeProfileProvider = Provider<GearProfileData?>((ref) {
  final store = ref.watch(gearProfileStoreProvider);
  final id = ref.watch(activeProfileIdProvider);
  if (id == null) return null;
  final all = store.profiles;
  return all.where((p) => p.id == id).firstOrNull;
});
