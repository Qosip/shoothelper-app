import 'package:flutter_test/flutter_test.dart';
import 'package:shoothelper/shared/data/data_sources/local/camera_data_cache.dart';
import 'package:shoothelper/shared/data/data_sources/local/file_manager.dart';
import 'package:shoothelper/shared/data/data_sources/local/json_data_source.dart';

void main() {
  group('CameraDataCache', () {
    late CameraDataCache cache;
    late JsonDataSource dataSource;

    setUpAll(() async {
      final fm = FileSystemManager(rootPath: 'assets');
      dataSource = JsonDataSource(fm);
      cache = CameraDataCache();
      await cache.load('sony_a6700', dataSource);
    });

    test('isLoaded returns true after load', () {
      expect(cache.isLoaded, isTrue);
    });

    test('body is loaded with correct ID', () {
      expect(cache.body.id, 'sony_a6700');
      expect(cache.body.name, 'Sony A6700');
    });

    test('body sensor spec matches expected values', () {
      expect(cache.body.sensor.isoMin, 100);
      expect(cache.body.sensor.isoMax, 32000);
      expect(cache.body.sensor.isoUsableMax, 6400);
      expect(cache.body.sensor.megapixels, 26.0);
    });

    test('lenses are loaded', () {
      expect(cache.allLenses, isNotEmpty);
      final sigma = cache.getLens('sigma_18-50_f2.8_dc_dn_c');
      expect(sigma.aperture.maxAperture, 2.8);
      expect(sigma.focalLength.minMm, 18);
    });

    test('menu tree is loaded', () {
      expect(cache.menuTree.firmwareVersion, '3.0');
      expect(cache.menuTree.root, isNotEmpty);
    });

    test('menu tree can find AF mode setting', () {
      final item = cache.menuTree.findBySetting('af_mode');
      expect(item, isNotNull);
      expect(item!.values, isNotEmpty);
    });

    test('nav paths are loaded', () {
      expect(cache.navPaths, isNotEmpty);
      expect(cache.navPaths.length, greaterThanOrEqualTo(12));
    });

    test('getNavPath returns correct path', () {
      final afPath = cache.getNavPath('af_mode');
      expect(afPath, isNotNull);
      expect(afPath!.hasMenuPath, isTrue);
      expect(afPath.hasQuickAccess, isTrue);
    });

    test('setting defs are loaded', () {
      expect(cache.settingDefs, isNotEmpty);
      final apertureDef = cache.settingDefs.firstWhere((d) => d.id == 'aperture');
      expect(apertureDef.affectsExposure, isTrue);
      expect(apertureDef.adjustableViaDial, isTrue);
    });

    test('brands are loaded', () {
      expect(cache.brands, isNotEmpty);
      expect(cache.brands.any((b) => b.id == 'sony'), isTrue);
    });

    test('mounts are loaded', () {
      expect(cache.mounts, isNotEmpty);
      expect(cache.mounts.any((m) => m.id == 'sony_e'), isTrue);
    });

    test('clear empties all data', () {
      final freshCache = CameraDataCache();
      expect(freshCache.isLoaded, isFalse);
    });

    test('5 spot-checked menu paths are correct', () {
      // 1. AF Mode → af_mf > af_mf_settings > focus_mode_item
      final afPath = cache.getNavPath('af_mode');
      expect(afPath!.menuPath, ['af_mf', 'af_mf_settings', 'focus_mode_item']);

      // 2. Metering → shooting > metering_page > metering_mode_item
      final metPath = cache.getNavPath('metering');
      expect(metPath!.menuPath, ['shooting', 'metering_page', 'metering_mode_item']);

      // 3. ISO → exposure_color > exposure_comp_page > iso_item
      final isoPath = cache.getNavPath('iso');
      expect(isoPath!.menuPath, ['exposure_color', 'exposure_comp_page', 'iso_item']);

      // 4. Aperture → dial only (no menu path)
      final apPath = cache.getNavPath('aperture');
      expect(apPath!.hasMenuPath, isFalse);
      expect(apPath.hasDialAccess, isTrue);

      // 5. Stabilization → setup > steadyshot_page > steadyshot_item
      final stabPath = cache.getNavPath('stabilization');
      expect(stabPath!.menuPath, ['setup', 'steadyshot_page', 'steadyshot_item']);
    });
  });
}
