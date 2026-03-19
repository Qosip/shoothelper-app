import '../../mappers/body_mapper.dart';
import '../../mappers/brand_mapper.dart';
import '../../mappers/lens_mapper.dart';
import '../../mappers/menu_tree_mapper.dart';
import '../../mappers/nav_path_mapper.dart';
import '../../mappers/setting_def_mapper.dart';
import '../../models/body_model.dart';
import '../../models/brand_model.dart';
import '../../models/lens_model.dart';
import '../../models/menu_tree_model.dart';
import '../../models/nav_path_model.dart';
import '../../models/setting_def_model.dart';
import '../../../domain/entities/body_spec.dart';
import '../../../domain/entities/brand.dart';
import '../../../domain/entities/lens_spec.dart';
import '../../../domain/entities/menu_tree.dart';
import '../../../domain/entities/nav_path.dart';
import '../../../domain/entities/setting_def.dart';
import 'file_manager.dart';

/// Reads JSON files via FileManager, parses via Models, maps to Entities.
/// Skill 12 §4 JsonDataSource.
class JsonDataSource {
  final FileManager _fm;

  const JsonDataSource(this._fm);

  Future<BodySpec> loadBody(String bodyId) async {
    final json = await _fm.readJson('packs/$bodyId/body.json');
    final model = BodyModel.fromJson(json as Map<String, dynamic>);
    return BodyMapper.toEntity(model);
  }

  Future<LensSpec> loadLens(String bodyId, String lensFileName) async {
    final json = await _fm.readJson('packs/$bodyId/lenses/$lensFileName');
    final model = LensModel.fromJson(json as Map<String, dynamic>);
    return LensMapper.toEntity(model);
  }

  Future<MenuTree> loadMenuTree(String bodyId) async {
    final json = await _fm.readJson('packs/$bodyId/menu_tree.json');
    final model = MenuTreeModel.fromJson(json as Map<String, dynamic>);
    return MenuTreeMapper.toEntity(model);
  }

  Future<List<SettingNavPath>> loadNavPaths(String bodyId) async {
    final json = await _fm.readJson('packs/$bodyId/nav_paths.json');
    final list = json as List<dynamic>;
    return list
        .map((j) => NavPathMapper.toEntity(
            NavPathModel.fromJson(j as Map<String, dynamic>)))
        .toList();
  }

  Future<List<SettingDef>> loadSettingDefs() async {
    final json = await _fm.readJson('shared/setting_defs.json');
    final list = json as List<dynamic>;
    return list
        .map((j) => SettingDefMapper.toEntity(
            SettingDefModel.fromJson(j as Map<String, dynamic>)))
        .toList();
  }

  Future<List<Brand>> loadBrands() async {
    final json = await _fm.readJson('shared/brands.json');
    final list = json as List<dynamic>;
    return list
        .map((j) =>
            BrandMapper.toEntity(BrandModel.fromJson(j as Map<String, dynamic>)))
        .toList();
  }

  Future<List<Mount>> loadMounts() async {
    final json = await _fm.readJson('shared/mounts.json');
    final list = json as List<dynamic>;
    return list
        .map((j) => MountMapper.toEntity(
            MountModel.fromJson(j as Map<String, dynamic>)))
        .toList();
  }

  Future<List<String>> listLensFiles(String bodyId) async {
    return _fm.listFiles('packs/$bodyId/lenses');
  }
}
