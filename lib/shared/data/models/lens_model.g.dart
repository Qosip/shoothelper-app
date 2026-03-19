// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'lens_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

LensModel _$LensModelFromJson(Map<String, dynamic> json) => LensModel(
  id: json['id'] as String,
  brandId: json['brand_id'] as String,
  mountId: json['mount_id'] as String,
  name: json['name'] as String,
  displayName: json['display_name'] as String,
  type: json['type'] as String,
  designedFor: json['designed_for'] as String,
  spec: LensSpecModel.fromJson(json['spec'] as Map<String, dynamic>),
);

Map<String, dynamic> _$LensModelToJson(LensModel instance) => <String, dynamic>{
  'id': instance.id,
  'brand_id': instance.brandId,
  'mount_id': instance.mountId,
  'name': instance.name,
  'display_name': instance.displayName,
  'type': instance.type,
  'designed_for': instance.designedFor,
  'spec': instance.spec,
};

LensSpecModel _$LensSpecModelFromJson(
  Map<String, dynamic> json,
) => LensSpecModel(
  focalLength: FocalLengthModel.fromJson(
    json['focal_length'] as Map<String, dynamic>,
  ),
  aperture: ApertureModel.fromJson(json['aperture'] as Map<String, dynamic>),
  focus: LensFocusModel.fromJson(json['focus'] as Map<String, dynamic>),
  stabilization: LensStabilizationModel.fromJson(
    json['stabilization'] as Map<String, dynamic>,
  ),
  optical: json['optical'] == null
      ? null
      : LensOpticalModel.fromJson(json['optical'] as Map<String, dynamic>),
  physical: json['physical'] == null
      ? null
      : LensPhysicalModel.fromJson(json['physical'] as Map<String, dynamic>),
);

Map<String, dynamic> _$LensSpecModelToJson(LensSpecModel instance) =>
    <String, dynamic>{
      'focal_length': instance.focalLength,
      'aperture': instance.aperture,
      'focus': instance.focus,
      'stabilization': instance.stabilization,
      'optical': instance.optical,
      'physical': instance.physical,
    };

FocalLengthModel _$FocalLengthModelFromJson(Map<String, dynamic> json) =>
    FocalLengthModel(
      type: json['type'] as String,
      minMm: (json['min_mm'] as num).toInt(),
      maxMm: (json['max_mm'] as num).toInt(),
    );

Map<String, dynamic> _$FocalLengthModelToJson(FocalLengthModel instance) =>
    <String, dynamic>{
      'type': instance.type,
      'min_mm': instance.minMm,
      'max_mm': instance.maxMm,
    };

ApertureModel _$ApertureModelFromJson(Map<String, dynamic> json) =>
    ApertureModel(
      type: json['type'] as String,
      maxAperture: (json['max_aperture'] as num).toDouble(),
      minAperture: (json['min_aperture'] as num).toDouble(),
      variableApertureMap: (json['variable_aperture_map'] as List<dynamic>?)
          ?.map(
            (e) =>
                VariableAperturePointModel.fromJson(e as Map<String, dynamic>),
          )
          .toList(),
    );

Map<String, dynamic> _$ApertureModelToJson(ApertureModel instance) =>
    <String, dynamic>{
      'type': instance.type,
      'max_aperture': instance.maxAperture,
      'min_aperture': instance.minAperture,
      'variable_aperture_map': instance.variableApertureMap,
    };

VariableAperturePointModel _$VariableAperturePointModelFromJson(
  Map<String, dynamic> json,
) => VariableAperturePointModel(
  focalMm: (json['focal_mm'] as num).toInt(),
  maxAperture: (json['max_aperture'] as num).toDouble(),
);

Map<String, dynamic> _$VariableAperturePointModelToJson(
  VariableAperturePointModel instance,
) => <String, dynamic>{
  'focal_mm': instance.focalMm,
  'max_aperture': instance.maxAperture,
};

LensFocusModel _$LensFocusModelFromJson(Map<String, dynamic> json) =>
    LensFocusModel(
      minFocusDistanceM: (json['min_focus_distance_m'] as num).toDouble(),
      minFocusDistanceAtFocalMm:
          (json['min_focus_distance_at_focal_mm'] as num?)?.toInt(),
      minFocusDistanceMap: (json['min_focus_distance_map'] as List<dynamic>?)
          ?.map(
            (e) => FocusDistancePointModel.fromJson(e as Map<String, dynamic>),
          )
          .toList(),
      autofocus: json['autofocus'] as bool,
      afMotor: json['af_motor'] as String?,
      manualOverride: json['manual_override'] as bool?,
      internalFocus: json['internal_focus'] as bool?,
    );

Map<String, dynamic> _$LensFocusModelToJson(LensFocusModel instance) =>
    <String, dynamic>{
      'min_focus_distance_m': instance.minFocusDistanceM,
      'min_focus_distance_at_focal_mm': instance.minFocusDistanceAtFocalMm,
      'min_focus_distance_map': instance.minFocusDistanceMap,
      'autofocus': instance.autofocus,
      'af_motor': instance.afMotor,
      'manual_override': instance.manualOverride,
      'internal_focus': instance.internalFocus,
    };

FocusDistancePointModel _$FocusDistancePointModelFromJson(
  Map<String, dynamic> json,
) => FocusDistancePointModel(
  focalMm: (json['focal_mm'] as num).toInt(),
  distanceM: (json['distance_m'] as num).toDouble(),
);

Map<String, dynamic> _$FocusDistancePointModelToJson(
  FocusDistancePointModel instance,
) => <String, dynamic>{
  'focal_mm': instance.focalMm,
  'distance_m': instance.distanceM,
};

LensStabilizationModel _$LensStabilizationModelFromJson(
  Map<String, dynamic> json,
) => LensStabilizationModel(
  hasOis: json['has_ois'] as bool,
  oisStops: (json['ois_stops'] as num?)?.toDouble(),
);

Map<String, dynamic> _$LensStabilizationModelToJson(
  LensStabilizationModel instance,
) => <String, dynamic>{
  'has_ois': instance.hasOis,
  'ois_stops': instance.oisStops,
};

LensOpticalModel _$LensOpticalModelFromJson(Map<String, dynamic> json) =>
    LensOpticalModel(
      elements: (json['elements'] as num?)?.toInt(),
      groups: (json['groups'] as num?)?.toInt(),
      filterDiameterMm: (json['filter_diameter_mm'] as num?)?.toInt(),
      maxMagnification: (json['max_magnification'] as num?)?.toDouble(),
    );

Map<String, dynamic> _$LensOpticalModelToJson(LensOpticalModel instance) =>
    <String, dynamic>{
      'elements': instance.elements,
      'groups': instance.groups,
      'filter_diameter_mm': instance.filterDiameterMm,
      'max_magnification': instance.maxMagnification,
    };

LensPhysicalModel _$LensPhysicalModelFromJson(Map<String, dynamic> json) =>
    LensPhysicalModel(
      weightG: (json['weight_g'] as num?)?.toInt(),
      lengthMm: (json['length_mm'] as num?)?.toDouble(),
      diameterMm: (json['diameter_mm'] as num?)?.toDouble(),
    );

Map<String, dynamic> _$LensPhysicalModelToJson(LensPhysicalModel instance) =>
    <String, dynamic>{
      'weight_g': instance.weightG,
      'length_mm': instance.lengthMm,
      'diameter_mm': instance.diameterMm,
    };
