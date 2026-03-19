import '../../domain/entities/setting_def.dart';
import '../models/setting_def_model.dart';

/// Maps SettingDefModel (JSON) → SettingDef (domain entity).
class SettingDefMapper {
  static SettingDef toEntity(SettingDefModel model) {
    return SettingDef(
      id: model.id,
      category: model.category,
      name: model.name,
      description: model.description,
      dataType: model.dataType,
      unit: model.unit,
      possibleValues: model.possibleValues,
      stepValues: model.stepValues,
      adjustableViaMenu: model.adjustableViaMenu,
      adjustableViaDial: model.adjustableViaDial,
      adjustableViaFn: model.adjustableViaFn,
      affectsExposure: model.affectsExposure,
    );
  }
}
