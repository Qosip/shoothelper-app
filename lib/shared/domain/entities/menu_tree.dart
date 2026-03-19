/// Menu tree structure for camera body navigation.
/// Skill 04 §3.6 MenuTree.
class MenuTree {
  final String firmwareVersion;
  final List<MenuItem> root;

  const MenuTree({
    required this.firmwareVersion,
    required this.root,
  });

  /// Find a menu item by its ID, searching recursively.
  MenuItem? findItemById(String id) {
    for (final item in root) {
      final found = _searchItem(item, id);
      if (found != null) return found;
    }
    return null;
  }

  static MenuItem? _searchItem(MenuItem item, String id) {
    if (item.id == id) return item;
    if (item.children != null) {
      for (final child in item.children!) {
        final found = _searchItem(child, id);
        if (found != null) return found;
      }
    }
    return null;
  }

  /// Find a menu item by setting_id.
  MenuItem? findBySetting(String settingId) {
    for (final item in root) {
      final found = _searchBySetting(item, settingId);
      if (found != null) return found;
    }
    return null;
  }

  static MenuItem? _searchBySetting(MenuItem item, String settingId) {
    if (item.settingId == settingId) return item;
    if (item.children != null) {
      for (final child in item.children!) {
        final found = _searchBySetting(child, settingId);
        if (found != null) return found;
      }
    }
    return null;
  }
}

class MenuItem {
  final String id;
  final MenuItemType type;
  final Map<String, String> labels;
  final String? settingId;
  final List<MenuValue>? values;
  final List<MenuItem>? children;
  final int? tabIndex;
  final int? pageIndex;
  final int? itemIndex;
  final String? icon;

  const MenuItem({
    required this.id,
    required this.type,
    required this.labels,
    this.settingId,
    this.values,
    this.children,
    this.tabIndex,
    this.pageIndex,
    this.itemIndex,
    this.icon,
  });

  /// Resolve label with full fallback chain:
  /// lang → "en" → first_available → id.
  String label(String lang) =>
      labels[lang] ??
      labels['en'] ??
      (labels.isNotEmpty ? labels.values.first : id);
}

enum MenuItemType { tab, page, setting, info }

class MenuValue {
  final String id;
  final Map<String, String> labels;
  final Map<String, String> shortLabels;

  const MenuValue({
    required this.id,
    required this.labels,
    required this.shortLabels,
  });

  String label(String lang) =>
      labels[lang] ??
      labels['en'] ??
      (labels.isNotEmpty ? labels.values.first : id);

  String shortLabel(String lang) =>
      shortLabels[lang] ??
      shortLabels['en'] ??
      (shortLabels.isNotEmpty ? shortLabels.values.first : id);
}
