import '../../domain/entities/nav_path.dart';
import '../models/nav_path_model.dart';

/// Maps NavPathModel (JSON) → SettingNavPath (domain entity).
class NavPathMapper {
  static SettingNavPath toEntity(NavPathModel model) {
    return SettingNavPath(
      bodyId: model.bodyId,
      settingId: model.settingId,
      firmwareVersion: model.firmwareVersion,
      menuPath: model.menuPath,
      menuItemId: model.menuItemId,
      quickAccess: model.quickAccess != null
          ? _mapQuickAccess(model.quickAccess!)
          : null,
      dialAccess: model.dialAccess != null
          ? _mapDialAccess(model.dialAccess!)
          : null,
      tips: model.tips?.map(_mapTip).toList() ?? [],
    );
  }

  static QuickAccess _mapQuickAccess(QuickAccessModel m) {
    return QuickAccess(
      method: m.method,
      steps: m.steps.map(_mapStep).toList(),
    );
  }

  static NavStep _mapStep(StepModel m) {
    return NavStep(
      action: m.action,
      target: m.target,
      labels: m.labels,
    );
  }

  static DialAccess _mapDialAccess(DialAccessModel m) {
    return DialAccess(
      exposureModes: m.exposureModes,
      dialId: m.dialId,
      labels: m.labels,
    );
  }

  static Tip _mapTip(TipModel m) {
    return Tip(
      labels: m.labels,
      relatedMenuPath: m.relatedMenuPath,
    );
  }
}
