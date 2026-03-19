import '../../domain/entities/menu_tree.dart';
import '../models/menu_tree_model.dart';

/// Maps MenuTreeModel (JSON) → MenuTree (domain entity).
class MenuTreeMapper {
  static MenuTree toEntity(MenuTreeModel model) {
    return MenuTree(
      firmwareVersion: model.firmwareVersion,
      root: model.root.map(_mapItem).toList(),
    );
  }

  static MenuItem _mapItem(MenuItemModel m) {
    return MenuItem(
      id: m.id,
      type: _parseType(m.type),
      labels: m.labels,
      settingId: m.settingId,
      values: m.values?.map(_mapValue).toList(),
      children: m.children?.map(_mapItem).toList(),
      tabIndex: m.tabIndex,
      pageIndex: m.pageIndex,
      itemIndex: m.itemIndex,
      icon: m.icon,
    );
  }

  static MenuItemType _parseType(String type) {
    switch (type) {
      case 'tab':
        return MenuItemType.tab;
      case 'page':
        return MenuItemType.page;
      case 'setting':
        return MenuItemType.setting;
      case 'info':
        return MenuItemType.info;
      default:
        return MenuItemType.info;
    }
  }

  static MenuValue _mapValue(MenuValueModel m) {
    return MenuValue(
      id: m.id,
      labels: m.labels,
      shortLabels: m.shortLabels,
    );
  }
}
