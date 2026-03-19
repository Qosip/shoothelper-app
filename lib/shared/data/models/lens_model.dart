import 'package:json_annotation/json_annotation.dart';

part 'lens_model.g.dart';

@JsonSerializable()
class LensModel {
  final String id;
  @JsonKey(name: 'brand_id')
  final String brandId;
  @JsonKey(name: 'mount_id')
  final String mountId;
  final String name;
  @JsonKey(name: 'display_name')
  final String displayName;
  final String type;
  @JsonKey(name: 'designed_for')
  final String designedFor;
  final LensSpecModel spec;

  const LensModel({
    required this.id,
    required this.brandId,
    required this.mountId,
    required this.name,
    required this.displayName,
    required this.type,
    required this.designedFor,
    required this.spec,
  });

  factory LensModel.fromJson(Map<String, dynamic> json) =>
      _$LensModelFromJson(json);

  Map<String, dynamic> toJson() => _$LensModelToJson(this);
}

@JsonSerializable()
class LensSpecModel {
  @JsonKey(name: 'focal_length')
  final FocalLengthModel focalLength;
  final ApertureModel aperture;
  final LensFocusModel focus;
  final LensStabilizationModel stabilization;
  final LensOpticalModel? optical;
  final LensPhysicalModel? physical;

  const LensSpecModel({
    required this.focalLength,
    required this.aperture,
    required this.focus,
    required this.stabilization,
    this.optical,
    this.physical,
  });

  factory LensSpecModel.fromJson(Map<String, dynamic> json) =>
      _$LensSpecModelFromJson(json);

  Map<String, dynamic> toJson() => _$LensSpecModelToJson(this);
}

@JsonSerializable()
class FocalLengthModel {
  final String type;
  @JsonKey(name: 'min_mm')
  final int minMm;
  @JsonKey(name: 'max_mm')
  final int maxMm;

  const FocalLengthModel({
    required this.type,
    required this.minMm,
    required this.maxMm,
  });

  factory FocalLengthModel.fromJson(Map<String, dynamic> json) =>
      _$FocalLengthModelFromJson(json);

  Map<String, dynamic> toJson() => _$FocalLengthModelToJson(this);
}

@JsonSerializable()
class ApertureModel {
  final String type;
  @JsonKey(name: 'max_aperture')
  final double maxAperture;
  @JsonKey(name: 'min_aperture')
  final double minAperture;
  @JsonKey(name: 'variable_aperture_map')
  final List<VariableAperturePointModel>? variableApertureMap;

  const ApertureModel({
    required this.type,
    required this.maxAperture,
    required this.minAperture,
    this.variableApertureMap,
  });

  factory ApertureModel.fromJson(Map<String, dynamic> json) =>
      _$ApertureModelFromJson(json);

  Map<String, dynamic> toJson() => _$ApertureModelToJson(this);
}

@JsonSerializable()
class VariableAperturePointModel {
  @JsonKey(name: 'focal_mm')
  final int focalMm;
  @JsonKey(name: 'max_aperture')
  final double maxAperture;

  const VariableAperturePointModel({
    required this.focalMm,
    required this.maxAperture,
  });

  factory VariableAperturePointModel.fromJson(Map<String, dynamic> json) =>
      _$VariableAperturePointModelFromJson(json);

  Map<String, dynamic> toJson() => _$VariableAperturePointModelToJson(this);
}

@JsonSerializable()
class LensFocusModel {
  @JsonKey(name: 'min_focus_distance_m')
  final double minFocusDistanceM;
  @JsonKey(name: 'min_focus_distance_at_focal_mm')
  final int? minFocusDistanceAtFocalMm;
  @JsonKey(name: 'min_focus_distance_map')
  final List<FocusDistancePointModel>? minFocusDistanceMap;
  final bool autofocus;
  @JsonKey(name: 'af_motor')
  final String? afMotor;
  @JsonKey(name: 'manual_override')
  final bool? manualOverride;
  @JsonKey(name: 'internal_focus')
  final bool? internalFocus;

  const LensFocusModel({
    required this.minFocusDistanceM,
    this.minFocusDistanceAtFocalMm,
    this.minFocusDistanceMap,
    required this.autofocus,
    this.afMotor,
    this.manualOverride,
    this.internalFocus,
  });

  factory LensFocusModel.fromJson(Map<String, dynamic> json) =>
      _$LensFocusModelFromJson(json);

  Map<String, dynamic> toJson() => _$LensFocusModelToJson(this);
}

@JsonSerializable()
class FocusDistancePointModel {
  @JsonKey(name: 'focal_mm')
  final int focalMm;
  @JsonKey(name: 'distance_m')
  final double distanceM;

  const FocusDistancePointModel({
    required this.focalMm,
    required this.distanceM,
  });

  factory FocusDistancePointModel.fromJson(Map<String, dynamic> json) =>
      _$FocusDistancePointModelFromJson(json);

  Map<String, dynamic> toJson() => _$FocusDistancePointModelToJson(this);
}

@JsonSerializable()
class LensStabilizationModel {
  @JsonKey(name: 'has_ois')
  final bool hasOis;
  @JsonKey(name: 'ois_stops')
  final double? oisStops;

  const LensStabilizationModel({
    required this.hasOis,
    this.oisStops,
  });

  factory LensStabilizationModel.fromJson(Map<String, dynamic> json) =>
      _$LensStabilizationModelFromJson(json);

  Map<String, dynamic> toJson() => _$LensStabilizationModelToJson(this);
}

@JsonSerializable()
class LensOpticalModel {
  final int? elements;
  final int? groups;
  @JsonKey(name: 'filter_diameter_mm')
  final int? filterDiameterMm;
  @JsonKey(name: 'max_magnification')
  final double? maxMagnification;

  const LensOpticalModel({
    this.elements,
    this.groups,
    this.filterDiameterMm,
    this.maxMagnification,
  });

  factory LensOpticalModel.fromJson(Map<String, dynamic> json) =>
      _$LensOpticalModelFromJson(json);

  Map<String, dynamic> toJson() => _$LensOpticalModelToJson(this);
}

@JsonSerializable()
class LensPhysicalModel {
  @JsonKey(name: 'weight_g')
  final int? weightG;
  @JsonKey(name: 'length_mm')
  final double? lengthMm;
  @JsonKey(name: 'diameter_mm')
  final double? diameterMm;

  const LensPhysicalModel({
    this.weightG,
    this.lengthMm,
    this.diameterMm,
  });

  factory LensPhysicalModel.fromJson(Map<String, dynamic> json) =>
      _$LensPhysicalModelFromJson(json);

  Map<String, dynamic> toJson() => _$LensPhysicalModelToJson(this);
}
