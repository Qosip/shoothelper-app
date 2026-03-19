// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'setting_def_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SettingDefModel _$SettingDefModelFromJson(Map<String, dynamic> json) =>
    SettingDefModel(
      id: json['id'] as String,
      category: json['category'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      dataType: json['data_type'] as String,
      unit: json['unit'] as String?,
      possibleValues: (json['possible_values'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      stepValues: (json['step_values'] as List<dynamic>?)
          ?.map((e) => (e as num).toDouble())
          .toList(),
      adjustableViaMenu: json['adjustable_via_menu'] as bool,
      adjustableViaDial: json['adjustable_via_dial'] as bool,
      adjustableViaFn: json['adjustable_via_fn'] as bool,
      affectsExposure: json['affects_exposure'] as bool,
    );

Map<String, dynamic> _$SettingDefModelToJson(SettingDefModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'category': instance.category,
      'name': instance.name,
      'description': instance.description,
      'data_type': instance.dataType,
      'unit': instance.unit,
      'possible_values': instance.possibleValues,
      'step_values': instance.stepValues,
      'adjustable_via_menu': instance.adjustableViaMenu,
      'adjustable_via_dial': instance.adjustableViaDial,
      'adjustable_via_fn': instance.adjustableViaFn,
      'affects_exposure': instance.affectsExposure,
    };
