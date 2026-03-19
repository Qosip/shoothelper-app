// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'brand_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

BrandModel _$BrandModelFromJson(Map<String, dynamic> json) =>
    BrandModel(id: json['id'] as String, name: json['name'] as String);

Map<String, dynamic> _$BrandModelToJson(BrandModel instance) =>
    <String, dynamic>{'id': instance.id, 'name': instance.name};

MountModel _$MountModelFromJson(Map<String, dynamic> json) => MountModel(
  id: json['id'] as String,
  brandId: json['brand_id'] as String,
  name: json['name'] as String,
  coversSensorSizes: (json['covers_sensor_sizes'] as List<dynamic>)
      .map((e) => e as String)
      .toList(),
);

Map<String, dynamic> _$MountModelToJson(MountModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'brand_id': instance.brandId,
      'name': instance.name,
      'covers_sensor_sizes': instance.coversSensorSizes,
    };
