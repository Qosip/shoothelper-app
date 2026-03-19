import 'package:json_annotation/json_annotation.dart';

part 'brand_model.g.dart';

@JsonSerializable()
class BrandModel {
  final String id;
  final String name;

  const BrandModel({
    required this.id,
    required this.name,
  });

  factory BrandModel.fromJson(Map<String, dynamic> json) =>
      _$BrandModelFromJson(json);

  Map<String, dynamic> toJson() => _$BrandModelToJson(this);
}

@JsonSerializable()
class MountModel {
  final String id;
  @JsonKey(name: 'brand_id')
  final String brandId;
  final String name;
  @JsonKey(name: 'covers_sensor_sizes')
  final List<String> coversSensorSizes;

  const MountModel({
    required this.id,
    required this.brandId,
    required this.name,
    required this.coversSensorSizes,
  });

  factory MountModel.fromJson(Map<String, dynamic> json) =>
      _$MountModelFromJson(json);

  Map<String, dynamic> toJson() => _$MountModelToJson(this);
}
