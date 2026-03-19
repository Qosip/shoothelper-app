// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'menu_tree_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MenuTreeModel _$MenuTreeModelFromJson(Map<String, dynamic> json) =>
    MenuTreeModel(
      firmwareVersion: json['firmware_version'] as String,
      root: (json['root'] as List<dynamic>)
          .map((e) => MenuItemModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$MenuTreeModelToJson(MenuTreeModel instance) =>
    <String, dynamic>{
      'firmware_version': instance.firmwareVersion,
      'root': instance.root,
    };

MenuItemModel _$MenuItemModelFromJson(Map<String, dynamic> json) =>
    MenuItemModel(
      id: json['id'] as String,
      type: json['type'] as String,
      labels: Map<String, String>.from(json['labels'] as Map),
      settingId: json['setting_id'] as String?,
      values: (json['values'] as List<dynamic>?)
          ?.map((e) => MenuValueModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      children: (json['children'] as List<dynamic>?)
          ?.map((e) => MenuItemModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      tabIndex: (json['tab_index'] as num?)?.toInt(),
      pageIndex: (json['page_index'] as num?)?.toInt(),
      itemIndex: (json['item_index'] as num?)?.toInt(),
      icon: json['icon'] as String?,
      note: json['note'] as String?,
      firmwareAdded: json['firmware_added'] as String?,
      firmwareRemoved: json['firmware_removed'] as String?,
    );

Map<String, dynamic> _$MenuItemModelToJson(MenuItemModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'type': instance.type,
      'labels': instance.labels,
      'setting_id': instance.settingId,
      'values': instance.values,
      'children': instance.children,
      'tab_index': instance.tabIndex,
      'page_index': instance.pageIndex,
      'item_index': instance.itemIndex,
      'icon': instance.icon,
      'note': instance.note,
      'firmware_added': instance.firmwareAdded,
      'firmware_removed': instance.firmwareRemoved,
    };

MenuValueModel _$MenuValueModelFromJson(Map<String, dynamic> json) =>
    MenuValueModel(
      id: json['id'] as String,
      labels: Map<String, String>.from(json['labels'] as Map),
      shortLabels: Map<String, String>.from(json['short_labels'] as Map),
    );

Map<String, dynamic> _$MenuValueModelToJson(MenuValueModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'labels': instance.labels,
      'short_labels': instance.shortLabels,
    };
