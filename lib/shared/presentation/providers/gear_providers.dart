import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/data_sources/local/camera_data_cache.dart';
import '../../data/data_sources/local/file_manager.dart';
import '../../data/data_sources/local/json_data_source.dart';
import '../../domain/entities/body_spec.dart';
import '../../domain/entities/lens_spec.dart';

/// Global camera data cache — loaded once at startup.
final cameraDataCacheProvider =
    FutureProvider<CameraDataCache>((ref) async {
  final fm = FileSystemManager(rootPath: 'assets');
  final ds = JsonDataSource(fm);
  final cache = CameraDataCache();
  await cache.load('sony_a6700', ds);
  return cache;
});

/// Current body spec from cache.
final currentBodyProvider = Provider<AsyncValue<BodySpec>>((ref) {
  final cacheAsync = ref.watch(cameraDataCacheProvider);
  return cacheAsync.whenData((cache) => cache.body);
});

/// Current lens spec from cache.
final currentLensProvider = Provider<AsyncValue<LensSpec>>((ref) {
  final cacheAsync = ref.watch(cameraDataCacheProvider);
  return cacheAsync.whenData(
      (cache) => cache.getLens('sigma_18-50_f2.8_dc_dn_c'));
});

/// Firmware language (for menu labels).
final firmwareLanguageProvider = StateProvider<String>((ref) => 'fr');
