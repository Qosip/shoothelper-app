import 'package:json_annotation/json_annotation.dart';

part 'menu_tree_model.g.dart';

@JsonSerializable()
class MenuTreeModel {
  @JsonKey(name: 'firmware_version')
  final String firmwareVersion;
  final List<MenuItemModel> root;

  const MenuTreeModel({
    required this.firmwareVersion,
    required this.root,
  });

  factory MenuTreeModel.fromJson(Map<String, dynamic> json) =>
      _$MenuTreeModelFromJson(json);

  Map<String, dynamic> toJson() => _$MenuTreeModelToJson(this);
}

@JsonSerializable()
class MenuItemModel {
  final String id;
  final String type;
  final Map<String, String> labels;
  @JsonKey(name: 'setting_id')
  final String? settingId;
  final List<MenuValueModel>? values;
  final List<MenuItemModel>? children;
  @JsonKey(name: 'tab_index')
  final int? tabIndex;
  @JsonKey(name: 'page_index')
  final int? pageIndex;
  @JsonKey(name: 'item_index')
  final int? itemIndex;
  final String? icon;
  final String? note;
  @JsonKey(name: 'firmware_added')
  final String? firmwareAdded;
  @JsonKey(name: 'firmware_removed')
  final String? firmwareRemoved;

  const MenuItemModel({
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
    this.note,
    this.firmwareAdded,
    this.firmwareRemoved,
  });

  factory MenuItemModel.fromJson(Map<String, dynamic> json) =>
      _$MenuItemModelFromJson(json);

  Map<String, dynamic> toJson() => _$MenuItemModelToJson(this);
}

@JsonSerializable()
class MenuValueModel {
  final String id;
  final Map<String, String> labels;
  @JsonKey(name: 'short_labels')
  final Map<String, String> shortLabels;

  const MenuValueModel({
    required this.id,
    required this.labels,
    required this.shortLabels,
  });

  factory MenuValueModel.fromJson(Map<String, dynamic> json) =>
      _$MenuValueModelFromJson(json);

  Map<String, dynamic> toJson() => _$MenuValueModelToJson(this);
}
