import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/data_sources/local/camera_data_cache.dart';
import '../../data/data_sources/local/file_manager.dart';
import '../../data/data_sources/local/json_data_source.dart';
import '../../domain/entities/body_spec.dart';
import '../../domain/entities/lens_spec.dart';
import 'gear_profile_provider.dart';

/// Global camera data cache — loaded once at startup.
/// Reads body ID from gear profile (defaults to sony_a6700).
final cameraDataCacheProvider =
    FutureProvider<CameraDataCache>((ref) async {
  final profile = ref.watch(gearProfileProvider);
  final bodyId = profile.bodyId ?? 'sony_a6700';
  final fm = FileSystemManager(rootPath: 'assets');
  final ds = JsonDataSource(fm);
  final cache = CameraDataCache();
  await cache.load(bodyId, ds);
  return cache;
});

/// Current body spec from cache.
final currentBodyProvider = Provider<AsyncValue<BodySpec>>((ref) {
  final cacheAsync = ref.watch(cameraDataCacheProvider);
  return cacheAsync.whenData((cache) => cache.body);
});

/// Current lens spec from cache.
/// Reads active lens ID from gear profile.
final currentLensProvider = Provider<AsyncValue<LensSpec>>((ref) {
  final profile = ref.watch(gearProfileProvider);
  final activeLensId =
      profile.activeLensId ?? 'sigma_18-50_f2.8_dc_dn_c';
  final cacheAsync = ref.watch(cameraDataCacheProvider);
  return cacheAsync.whenData((cache) => cache.getLens(activeLensId));
});

/// Firmware language (for menu labels).
/// Initialized from gear profile.
final firmwareLanguageProvider = StateProvider<String>((ref) {
  final profile = ref.watch(gearProfileProvider);
  return profile.language;
});
