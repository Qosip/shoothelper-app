import '../../../domain/entities/body_spec.dart';
import '../../../domain/entities/brand.dart';
import '../../../domain/entities/lens_spec.dart';
import '../../../domain/entities/menu_tree.dart';
import '../../../domain/entities/nav_path.dart';
import '../../../domain/entities/setting_def.dart';
import 'json_data_source.dart';

/// In-memory cache that holds all loaded camera data.
/// Loaded once at startup, ~750 KB per body in RAM.
/// Skill 12 §5 CameraDataCache.
class CameraDataCache {
  BodySpec? _body;
  Map<String, LensSpec> _lenses = {};
  MenuTree? _menuTree;
  List<SettingNavPath> _navPaths = [];
  List<SettingDef> _settingDefs = [];
  List<Brand> _brands = [];
  List<Mount> _mounts = [];

  bool get isLoaded => _body != null;

  BodySpec get body {
    assert(_body != null, 'CameraDataCache not loaded');
    return _body!;
  }

  LensSpec getLens(String lensId) {
    assert(_lenses.containsKey(lensId), 'Lens $lensId not found in cache');
    return _lenses[lensId]!;
  }

  List<LensSpec> get allLenses => _lenses.values.toList();

  MenuTree get menuTree {
    assert(_menuTree != null, 'CameraDataCache not loaded');
    return _menuTree!;
  }

  List<SettingNavPath> get navPaths => _navPaths;

  SettingNavPath? getNavPath(String settingId) {
    for (final np in _navPaths) {
      if (np.settingId == settingId) return np;
    }
    return null;
  }

  List<SettingDef> get settingDefs => _settingDefs;
  List<Brand> get brands => _brands;
  List<Mount> get mounts => _mounts;

  /// Load all data for a body from the data source (parallel reads).
  Future<void> load(String bodyId, JsonDataSource dataSource) async {
    // Load shared data + body-specific data in parallel
    final lensFiles = await dataSource.listLensFiles(bodyId);

    final results = await Future.wait([
      dataSource.loadBody(bodyId),
      dataSource.loadMenuTree(bodyId),
      dataSource.loadNavPaths(bodyId),
      dataSource.loadSettingDefs(),
      dataSource.loadBrands(),
      dataSource.loadMounts(),
      ...lensFiles.map((f) => dataSource.loadLens(bodyId, f)),
    ]);

    _body = results[0] as BodySpec;
    _menuTree = results[1] as MenuTree;
    _navPaths = results[2] as List<SettingNavPath>;
    _settingDefs = results[3] as List<SettingDef>;
    _brands = results[4] as List<Brand>;
    _mounts = results[5] as List<Mount>;

    _lenses = {};
    for (var i = 6; i < results.length; i++) {
      final lens = results[i] as LensSpec;
      _lenses[lens.id] = lens;
    }
  }

  /// Clear all cached data.
  void clear() {
    _body = null;
    _lenses = {};
    _menuTree = null;
    _navPaths = [];
    _settingDefs = [];
    _brands = [];
    _mounts = [];
  }
}
