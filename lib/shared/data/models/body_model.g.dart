// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'body_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

BodyModel _$BodyModelFromJson(Map<String, dynamic> json) => BodyModel(
  id: json['id'] as String,
  brandId: json['brand_id'] as String,
  mountId: json['mount_id'] as String,
  name: json['name'] as String,
  displayName: json['display_name'] as String,
  sensorSize: json['sensor_size'] as String,
  cropFactor: (json['crop_factor'] as num).toDouble(),
  firmwareVersions: (json['firmware_versions'] as List<dynamic>)
      .map((e) => e as String)
      .toList(),
  currentFirmware: json['current_firmware'] as String,
  supportedLanguages: (json['supported_languages'] as List<dynamic>)
      .map((e) => e as String)
      .toList(),
  releaseYear: (json['release_year'] as num).toInt(),
  spec: BodySpecModel.fromJson(json['spec'] as Map<String, dynamic>),
  controls: ControlsModel.fromJson(json['controls'] as Map<String, dynamic>),
);

Map<String, dynamic> _$BodyModelToJson(BodyModel instance) => <String, dynamic>{
  'id': instance.id,
  'brand_id': instance.brandId,
  'mount_id': instance.mountId,
  'name': instance.name,
  'display_name': instance.displayName,
  'sensor_size': instance.sensorSize,
  'crop_factor': instance.cropFactor,
  'firmware_versions': instance.firmwareVersions,
  'current_firmware': instance.currentFirmware,
  'supported_languages': instance.supportedLanguages,
  'release_year': instance.releaseYear,
  'spec': instance.spec,
  'controls': instance.controls,
};

BodySpecModel _$BodySpecModelFromJson(Map<String, dynamic> json) =>
    BodySpecModel(
      sensor: SensorSpecModel.fromJson(json['sensor'] as Map<String, dynamic>),
      shutter: ShutterSpecModel.fromJson(
        json['shutter'] as Map<String, dynamic>,
      ),
      autofocus: AutofocusSpecModel.fromJson(
        json['autofocus'] as Map<String, dynamic>,
      ),
      metering: MeteringSpecModel.fromJson(
        json['metering'] as Map<String, dynamic>,
      ),
      exposure: ExposureSpecModel.fromJson(
        json['exposure'] as Map<String, dynamic>,
      ),
      whiteBalance: WhiteBalanceSpecModel.fromJson(
        json['white_balance'] as Map<String, dynamic>,
      ),
      fileFormats: FileFormatsSpecModel.fromJson(
        json['file_formats'] as Map<String, dynamic>,
      ),
      stabilization: StabilizationSpecModel.fromJson(
        json['stabilization'] as Map<String, dynamic>,
      ),
      drive: DriveSpecModel.fromJson(json['drive'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$BodySpecModelToJson(BodySpecModel instance) =>
    <String, dynamic>{
      'sensor': instance.sensor,
      'shutter': instance.shutter,
      'autofocus': instance.autofocus,
      'metering': instance.metering,
      'exposure': instance.exposure,
      'white_balance': instance.whiteBalance,
      'file_formats': instance.fileFormats,
      'stabilization': instance.stabilization,
      'drive': instance.drive,
    };

SensorSpecModel _$SensorSpecModelFromJson(Map<String, dynamic> json) =>
    SensorSpecModel(
      megapixels: (json['megapixels'] as num).toDouble(),
      isoRange: RangeIntModel.fromJson(
        json['iso_range'] as Map<String, dynamic>,
      ),
      isoExtendedRange: RangeIntModel.fromJson(
        json['iso_extended_range'] as Map<String, dynamic>,
      ),
      isoUsableMax: (json['iso_usable_max'] as num).toInt(),
      dynamicRangeEv: (json['dynamic_range_ev'] as num).toDouble(),
      hasIbis: json['has_ibis'] as bool,
      ibisStops: (json['ibis_stops'] as num?)?.toDouble(),
      sensorWidthMm: (json['sensor_width_mm'] as num).toDouble(),
      sensorHeightMm: (json['sensor_height_mm'] as num).toDouble(),
    );

Map<String, dynamic> _$SensorSpecModelToJson(SensorSpecModel instance) =>
    <String, dynamic>{
      'megapixels': instance.megapixels,
      'iso_range': instance.isoRange,
      'iso_extended_range': instance.isoExtendedRange,
      'iso_usable_max': instance.isoUsableMax,
      'dynamic_range_ev': instance.dynamicRangeEv,
      'has_ibis': instance.hasIbis,
      'ibis_stops': instance.ibisStops,
      'sensor_width_mm': instance.sensorWidthMm,
      'sensor_height_mm': instance.sensorHeightMm,
    };

RangeIntModel _$RangeIntModelFromJson(Map<String, dynamic> json) =>
    RangeIntModel(
      min: (json['min'] as num).toInt(),
      max: (json['max'] as num).toInt(),
    );

Map<String, dynamic> _$RangeIntModelToJson(RangeIntModel instance) =>
    <String, dynamic>{'min': instance.min, 'max': instance.max};

ShutterSpecModel _$ShutterSpecModelFromJson(Map<String, dynamic> json) =>
    ShutterSpecModel(
      mechanicalMinSeconds: (json['mechanical_min_seconds'] as num).toDouble(),
      mechanicalMaxSeconds: (json['mechanical_max_seconds'] as num).toDouble(),
      hasBulb: json['has_bulb'] as bool,
      electronicMinSeconds: (json['electronic_min_seconds'] as num).toDouble(),
      electronicMaxSeconds: (json['electronic_max_seconds'] as num).toDouble(),
      flashSyncSpeed: json['flash_sync_speed'] as String,
    );

Map<String, dynamic> _$ShutterSpecModelToJson(ShutterSpecModel instance) =>
    <String, dynamic>{
      'mechanical_min_seconds': instance.mechanicalMinSeconds,
      'mechanical_max_seconds': instance.mechanicalMaxSeconds,
      'has_bulb': instance.hasBulb,
      'electronic_min_seconds': instance.electronicMinSeconds,
      'electronic_max_seconds': instance.electronicMaxSeconds,
      'flash_sync_speed': instance.flashSyncSpeed,
    };

AutofocusSpecModel _$AutofocusSpecModelFromJson(Map<String, dynamic> json) =>
    AutofocusSpecModel(
      system: json['system'] as String,
      points: (json['points'] as num).toInt(),
      modes: (json['modes'] as List<dynamic>).map((e) => e as String).toList(),
      areas: (json['areas'] as List<dynamic>).map((e) => e as String).toList(),
      subjectDetection: (json['subject_detection'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      hasEyeAf: json['has_eye_af'] as bool,
      eyeAfModes: (json['eye_af_modes'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      minEv: (json['min_ev'] as num).toDouble(),
      touchAf: json['touch_af'] as bool,
    );

Map<String, dynamic> _$AutofocusSpecModelToJson(AutofocusSpecModel instance) =>
    <String, dynamic>{
      'system': instance.system,
      'points': instance.points,
      'modes': instance.modes,
      'areas': instance.areas,
      'subject_detection': instance.subjectDetection,
      'has_eye_af': instance.hasEyeAf,
      'eye_af_modes': instance.eyeAfModes,
      'min_ev': instance.minEv,
      'touch_af': instance.touchAf,
    };

MeteringSpecModel _$MeteringSpecModelFromJson(Map<String, dynamic> json) =>
    MeteringSpecModel(
      modes: (json['modes'] as List<dynamic>).map((e) => e as String).toList(),
    );

Map<String, dynamic> _$MeteringSpecModelToJson(MeteringSpecModel instance) =>
    <String, dynamic>{'modes': instance.modes};

ExposureSpecModel _$ExposureSpecModelFromJson(Map<String, dynamic> json) =>
    ExposureSpecModel(
      modes: (json['modes'] as List<dynamic>).map((e) => e as String).toList(),
      compensationRange: CompensationRangeModel.fromJson(
        json['compensation_range'] as Map<String, dynamic>,
      ),
      bracketing: BracketingSpecModel.fromJson(
        json['bracketing'] as Map<String, dynamic>,
      ),
    );

Map<String, dynamic> _$ExposureSpecModelToJson(ExposureSpecModel instance) =>
    <String, dynamic>{
      'modes': instance.modes,
      'compensation_range': instance.compensationRange,
      'bracketing': instance.bracketing,
    };

CompensationRangeModel _$CompensationRangeModelFromJson(
  Map<String, dynamic> json,
) => CompensationRangeModel(
  min: (json['min'] as num).toDouble(),
  max: (json['max'] as num).toDouble(),
  step: (json['step'] as num).toDouble(),
);

Map<String, dynamic> _$CompensationRangeModelToJson(
  CompensationRangeModel instance,
) => <String, dynamic>{
  'min': instance.min,
  'max': instance.max,
  'step': instance.step,
};

BracketingSpecModel _$BracketingSpecModelFromJson(Map<String, dynamic> json) =>
    BracketingSpecModel(
      exposureMaxShots: (json['exposure_max_shots'] as num).toInt(),
      exposureMaxEvStep: (json['exposure_max_ev_step'] as num).toDouble(),
      focusBracket: json['focus_bracket'] as bool,
    );

Map<String, dynamic> _$BracketingSpecModelToJson(
  BracketingSpecModel instance,
) => <String, dynamic>{
  'exposure_max_shots': instance.exposureMaxShots,
  'exposure_max_ev_step': instance.exposureMaxEvStep,
  'focus_bracket': instance.focusBracket,
};

WhiteBalanceSpecModel _$WhiteBalanceSpecModelFromJson(
  Map<String, dynamic> json,
) => WhiteBalanceSpecModel(
  presets: (json['presets'] as List<dynamic>).map((e) => e as String).toList(),
  customKelvinMin: (json['custom_kelvin_min'] as num).toInt(),
  customKelvinMax: (json['custom_kelvin_max'] as num).toInt(),
  customKelvinStep: (json['custom_kelvin_step'] as num).toInt(),
  customSlots: (json['custom_slots'] as num).toInt(),
);

Map<String, dynamic> _$WhiteBalanceSpecModelToJson(
  WhiteBalanceSpecModel instance,
) => <String, dynamic>{
  'presets': instance.presets,
  'custom_kelvin_min': instance.customKelvinMin,
  'custom_kelvin_max': instance.customKelvinMax,
  'custom_kelvin_step': instance.customKelvinStep,
  'custom_slots': instance.customSlots,
};

FileFormatsSpecModel _$FileFormatsSpecModelFromJson(
  Map<String, dynamic> json,
) => FileFormatsSpecModel(
  photo: (json['photo'] as List<dynamic>).map((e) => e as String).toList(),
  rawFormat: json['raw_format'] as String,
  jpegQualityLevels: (json['jpeg_quality_levels'] as List<dynamic>)
      .map((e) => e as String)
      .toList(),
  video: (json['video'] as List<dynamic>).map((e) => e as String).toList(),
);

Map<String, dynamic> _$FileFormatsSpecModelToJson(
  FileFormatsSpecModel instance,
) => <String, dynamic>{
  'photo': instance.photo,
  'raw_format': instance.rawFormat,
  'jpeg_quality_levels': instance.jpegQualityLevels,
  'video': instance.video,
};

StabilizationSpecModel _$StabilizationSpecModelFromJson(
  Map<String, dynamic> json,
) => StabilizationSpecModel(
  hasIbis: json['has_ibis'] as bool,
  ibisStops: (json['ibis_stops'] as num?)?.toDouble(),
  ibisAxes: (json['ibis_axes'] as num?)?.toInt(),
);

Map<String, dynamic> _$StabilizationSpecModelToJson(
  StabilizationSpecModel instance,
) => <String, dynamic>{
  'has_ibis': instance.hasIbis,
  'ibis_stops': instance.ibisStops,
  'ibis_axes': instance.ibisAxes,
};

DriveSpecModel _$DriveSpecModelFromJson(Map<String, dynamic> json) =>
    DriveSpecModel(
      modes: (json['modes'] as List<dynamic>).map((e) => e as String).toList(),
      continuousFpsHi: (json['continuous_fps_hi'] as num).toDouble(),
      continuousFpsMid: (json['continuous_fps_mid'] as num).toDouble(),
      continuousFpsLo: (json['continuous_fps_lo'] as num).toDouble(),
    );

Map<String, dynamic> _$DriveSpecModelToJson(DriveSpecModel instance) =>
    <String, dynamic>{
      'modes': instance.modes,
      'continuous_fps_hi': instance.continuousFpsHi,
      'continuous_fps_mid': instance.continuousFpsMid,
      'continuous_fps_lo': instance.continuousFpsLo,
    };

ControlsModel _$ControlsModelFromJson(Map<String, dynamic> json) =>
    ControlsModel(
      dials: (json['dials'] as List<dynamic>)
          .map((e) => DialModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      buttons: (json['buttons'] as List<dynamic>)
          .map((e) => ButtonModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      fnMenuItems: (json['fn_menu_items'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
    );

Map<String, dynamic> _$ControlsModelToJson(ControlsModel instance) =>
    <String, dynamic>{
      'dials': instance.dials,
      'buttons': instance.buttons,
      'fn_menu_items': instance.fnMenuItems,
    };

DialModel _$DialModelFromJson(Map<String, dynamic> json) => DialModel(
  id: json['id'] as String,
  position: json['position'] as String,
  label: Map<String, String>.from(json['label'] as Map),
  defaultFunction: Map<String, String>.from(json['default_function'] as Map),
);

Map<String, dynamic> _$DialModelToJson(DialModel instance) => <String, dynamic>{
  'id': instance.id,
  'position': instance.position,
  'label': instance.label,
  'default_function': instance.defaultFunction,
};

ButtonModel _$ButtonModelFromJson(Map<String, dynamic> json) => ButtonModel(
  id: json['id'] as String,
  position: json['position'] as String,
  label: Map<String, String>.from(json['label'] as Map),
  defaultFunction: json['default_function'] as String,
  customizable: json['customizable'] as bool,
);

Map<String, dynamic> _$ButtonModelToJson(ButtonModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'position': instance.position,
      'label': instance.label,
      'default_function': instance.defaultFunction,
      'customizable': instance.customizable,
    };
