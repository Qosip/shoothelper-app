// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'nav_path_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

NavPathModel _$NavPathModelFromJson(Map<String, dynamic> json) => NavPathModel(
  bodyId: json['body_id'] as String,
  settingId: json['setting_id'] as String,
  firmwareVersion: json['firmware_version'] as String,
  menuPath: (json['menu_path'] as List<dynamic>?)
      ?.map((e) => e as String)
      .toList(),
  menuItemId: json['menu_item_id'] as String?,
  quickAccess: json['quick_access'] == null
      ? null
      : QuickAccessModel.fromJson(json['quick_access'] as Map<String, dynamic>),
  dialAccess: json['dial_access'] == null
      ? null
      : DialAccessModel.fromJson(json['dial_access'] as Map<String, dynamic>),
  tips: (json['tips'] as List<dynamic>?)
      ?.map((e) => TipModel.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$NavPathModelToJson(NavPathModel instance) =>
    <String, dynamic>{
      'body_id': instance.bodyId,
      'setting_id': instance.settingId,
      'firmware_version': instance.firmwareVersion,
      'menu_path': instance.menuPath,
      'menu_item_id': instance.menuItemId,
      'quick_access': instance.quickAccess,
      'dial_access': instance.dialAccess,
      'tips': instance.tips,
    };

QuickAccessModel _$QuickAccessModelFromJson(Map<String, dynamic> json) =>
    QuickAccessModel(
      method: json['method'] as String,
      steps: (json['steps'] as List<dynamic>)
          .map((e) => StepModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$QuickAccessModelToJson(QuickAccessModel instance) =>
    <String, dynamic>{'method': instance.method, 'steps': instance.steps};

StepModel _$StepModelFromJson(Map<String, dynamic> json) => StepModel(
  action: json['action'] as String,
  target: json['target'] as String,
  labels: Map<String, String>.from(json['labels'] as Map),
);

Map<String, dynamic> _$StepModelToJson(StepModel instance) => <String, dynamic>{
  'action': instance.action,
  'target': instance.target,
  'labels': instance.labels,
};

DialAccessModel _$DialAccessModelFromJson(Map<String, dynamic> json) =>
    DialAccessModel(
      exposureModes: (json['exposure_modes'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      dialId: json['dial_id'] as String,
      labels: Map<String, String>.from(json['labels'] as Map),
    );

Map<String, dynamic> _$DialAccessModelToJson(DialAccessModel instance) =>
    <String, dynamic>{
      'exposure_modes': instance.exposureModes,
      'dial_id': instance.dialId,
      'labels': instance.labels,
    };

TipModel _$TipModelFromJson(Map<String, dynamic> json) => TipModel(
  labels: Map<String, String>.from(json['labels'] as Map),
  relatedMenuPath: (json['related_menu_path'] as List<dynamic>?)
      ?.map((e) => e as String)
      .toList(),
);

Map<String, dynamic> _$TipModelToJson(TipModel instance) => <String, dynamic>{
  'labels': instance.labels,
  'related_menu_path': instance.relatedMenuPath,
};
