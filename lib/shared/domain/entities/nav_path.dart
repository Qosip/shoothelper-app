/// Navigation path to reach a setting in the camera menus.
/// Skill 04 §3.7 SettingNavPath — the "killer feature" data.
class SettingNavPath {
  final String bodyId;
  final String settingId;
  final String firmwareVersion;
  final List<String>? menuPath;
  final String? menuItemId;
  final QuickAccess? quickAccess;
  final DialAccess? dialAccess;
  final List<Tip> tips;

  const SettingNavPath({
    required this.bodyId,
    required this.settingId,
    required this.firmwareVersion,
    this.menuPath,
    this.menuItemId,
    this.quickAccess,
    this.dialAccess,
    this.tips = const [],
  });

  /// Whether this setting can be reached via a menu.
  bool get hasMenuPath => menuPath != null && menuPath!.isNotEmpty;

  /// Whether this setting has a quick access shortcut.
  bool get hasQuickAccess => quickAccess != null;

  /// Whether this setting is controlled via a dial.
  bool get hasDialAccess => dialAccess != null;
}

class QuickAccess {
  final String method;
  final List<NavStep> steps;

  const QuickAccess({
    required this.method,
    required this.steps,
  });
}

class NavStep {
  final String action;
  final String target;
  final Map<String, String> labels;

  const NavStep({
    required this.action,
    required this.target,
    required this.labels,
  });

  /// Resolve label with full fallback chain:
  /// lang → "en" → first_available → target.
  String label(String lang) =>
      labels[lang] ??
      labels['en'] ??
      (labels.isNotEmpty ? labels.values.first : target);
}

class DialAccess {
  final List<String> exposureModes;
  final String dialId;
  final Map<String, String> labels;

  const DialAccess({
    required this.exposureModes,
    required this.dialId,
    required this.labels,
  });

  String label(String lang) =>
      labels[lang] ??
      labels['en'] ??
      (labels.isNotEmpty ? labels.values.first : dialId);
}

class Tip {
  final Map<String, String> labels;
  final List<String>? relatedMenuPath;

  const Tip({
    required this.labels,
    this.relatedMenuPath,
  });

  String label(String lang) =>
      labels[lang] ??
      labels['en'] ??
      (labels.isNotEmpty ? labels.values.first : '');
}
