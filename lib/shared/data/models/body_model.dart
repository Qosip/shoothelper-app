import 'package:json_annotation/json_annotation.dart';

part 'body_model.g.dart';

@JsonSerializable()
class BodyModel {
  final String id;
  @JsonKey(name: 'brand_id')
  final String brandId;
  @JsonKey(name: 'mount_id')
  final String mountId;
  final String name;
  @JsonKey(name: 'display_name')
  final String displayName;
  @JsonKey(name: 'sensor_size')
  final String sensorSize;
  @JsonKey(name: 'crop_factor')
  final double cropFactor;
  @JsonKey(name: 'firmware_versions')
  final List<String> firmwareVersions;
  @JsonKey(name: 'current_firmware')
  final String currentFirmware;
  @JsonKey(name: 'supported_languages')
  final List<String> supportedLanguages;
  @JsonKey(name: 'release_year')
  final int releaseYear;
  final BodySpecModel spec;
  final ControlsModel controls;

  const BodyModel({
    required this.id,
    required this.brandId,
    required this.mountId,
    required this.name,
    required this.displayName,
    required this.sensorSize,
    required this.cropFactor,
    required this.firmwareVersions,
    required this.currentFirmware,
    required this.supportedLanguages,
    required this.releaseYear,
    required this.spec,
    required this.controls,
  });

  factory BodyModel.fromJson(Map<String, dynamic> json) =>
      _$BodyModelFromJson(json);

  Map<String, dynamic> toJson() => _$BodyModelToJson(this);
}

@JsonSerializable()
class BodySpecModel {
  final SensorSpecModel sensor;
  final ShutterSpecModel shutter;
  final AutofocusSpecModel autofocus;
  final MeteringSpecModel metering;
  final ExposureSpecModel exposure;
  @JsonKey(name: 'white_balance')
  final WhiteBalanceSpecModel whiteBalance;
  @JsonKey(name: 'file_formats')
  final FileFormatsSpecModel fileFormats;
  final StabilizationSpecModel stabilization;
  final DriveSpecModel drive;

  const BodySpecModel({
    required this.sensor,
    required this.shutter,
    required this.autofocus,
    required this.metering,
    required this.exposure,
    required this.whiteBalance,
    required this.fileFormats,
    required this.stabilization,
    required this.drive,
  });

  factory BodySpecModel.fromJson(Map<String, dynamic> json) =>
      _$BodySpecModelFromJson(json);

  Map<String, dynamic> toJson() => _$BodySpecModelToJson(this);
}

@JsonSerializable()
class SensorSpecModel {
  final double megapixels;
  @JsonKey(name: 'iso_range')
  final RangeIntModel isoRange;
  @JsonKey(name: 'iso_extended_range')
  final RangeIntModel isoExtendedRange;
  @JsonKey(name: 'iso_usable_max')
  final int isoUsableMax;
  @JsonKey(name: 'dynamic_range_ev')
  final double dynamicRangeEv;
  @JsonKey(name: 'has_ibis')
  final bool hasIbis;
  @JsonKey(name: 'ibis_stops')
  final double ibisStops;
  @JsonKey(name: 'sensor_width_mm')
  final double sensorWidthMm;
  @JsonKey(name: 'sensor_height_mm')
  final double sensorHeightMm;

  const SensorSpecModel({
    required this.megapixels,
    required this.isoRange,
    required this.isoExtendedRange,
    required this.isoUsableMax,
    required this.dynamicRangeEv,
    required this.hasIbis,
    required this.ibisStops,
    required this.sensorWidthMm,
    required this.sensorHeightMm,
  });

  factory SensorSpecModel.fromJson(Map<String, dynamic> json) =>
      _$SensorSpecModelFromJson(json);

  Map<String, dynamic> toJson() => _$SensorSpecModelToJson(this);
}

@JsonSerializable()
class RangeIntModel {
  final int min;
  final int max;

  const RangeIntModel({required this.min, required this.max});

  factory RangeIntModel.fromJson(Map<String, dynamic> json) =>
      _$RangeIntModelFromJson(json);

  Map<String, dynamic> toJson() => _$RangeIntModelToJson(this);
}

@JsonSerializable()
class ShutterSpecModel {
  @JsonKey(name: 'mechanical_min_seconds')
  final double mechanicalMinSeconds;
  @JsonKey(name: 'mechanical_max_seconds')
  final double mechanicalMaxSeconds;
  @JsonKey(name: 'has_bulb')
  final bool hasBulb;
  @JsonKey(name: 'electronic_min_seconds')
  final double electronicMinSeconds;
  @JsonKey(name: 'electronic_max_seconds')
  final double electronicMaxSeconds;
  @JsonKey(name: 'flash_sync_speed')
  final String flashSyncSpeed;

  const ShutterSpecModel({
    required this.mechanicalMinSeconds,
    required this.mechanicalMaxSeconds,
    required this.hasBulb,
    required this.electronicMinSeconds,
    required this.electronicMaxSeconds,
    required this.flashSyncSpeed,
  });

  factory ShutterSpecModel.fromJson(Map<String, dynamic> json) =>
      _$ShutterSpecModelFromJson(json);

  Map<String, dynamic> toJson() => _$ShutterSpecModelToJson(this);
}

@JsonSerializable()
class AutofocusSpecModel {
  final String system;
  final int points;
  final List<String> modes;
  final List<String> areas;
  @JsonKey(name: 'subject_detection')
  final List<String> subjectDetection;
  @JsonKey(name: 'has_eye_af')
  final bool hasEyeAf;
  @JsonKey(name: 'eye_af_modes')
  final List<String> eyeAfModes;
  @JsonKey(name: 'min_ev')
  final double minEv;
  @JsonKey(name: 'touch_af')
  final bool touchAf;

  const AutofocusSpecModel({
    required this.system,
    required this.points,
    required this.modes,
    required this.areas,
    required this.subjectDetection,
    required this.hasEyeAf,
    required this.eyeAfModes,
    required this.minEv,
    required this.touchAf,
  });

  factory AutofocusSpecModel.fromJson(Map<String, dynamic> json) =>
      _$AutofocusSpecModelFromJson(json);

  Map<String, dynamic> toJson() => _$AutofocusSpecModelToJson(this);
}

@JsonSerializable()
class MeteringSpecModel {
  final List<String> modes;

  const MeteringSpecModel({required this.modes});

  factory MeteringSpecModel.fromJson(Map<String, dynamic> json) =>
      _$MeteringSpecModelFromJson(json);

  Map<String, dynamic> toJson() => _$MeteringSpecModelToJson(this);
}

@JsonSerializable()
class ExposureSpecModel {
  final List<String> modes;
  @JsonKey(name: 'compensation_range')
  final CompensationRangeModel compensationRange;
  final BracketingSpecModel bracketing;

  const ExposureSpecModel({
    required this.modes,
    required this.compensationRange,
    required this.bracketing,
  });

  factory ExposureSpecModel.fromJson(Map<String, dynamic> json) =>
      _$ExposureSpecModelFromJson(json);

  Map<String, dynamic> toJson() => _$ExposureSpecModelToJson(this);
}

@JsonSerializable()
class CompensationRangeModel {
  final double min;
  final double max;
  final double step;

  const CompensationRangeModel({
    required this.min,
    required this.max,
    required this.step,
  });

  factory CompensationRangeModel.fromJson(Map<String, dynamic> json) =>
      _$CompensationRangeModelFromJson(json);

  Map<String, dynamic> toJson() => _$CompensationRangeModelToJson(this);
}

@JsonSerializable()
class BracketingSpecModel {
  @JsonKey(name: 'exposure_max_shots')
  final int exposureMaxShots;
  @JsonKey(name: 'exposure_max_ev_step')
  final double exposureMaxEvStep;
  @JsonKey(name: 'focus_bracket')
  final bool focusBracket;

  const BracketingSpecModel({
    required this.exposureMaxShots,
    required this.exposureMaxEvStep,
    required this.focusBracket,
  });

  factory BracketingSpecModel.fromJson(Map<String, dynamic> json) =>
      _$BracketingSpecModelFromJson(json);

  Map<String, dynamic> toJson() => _$BracketingSpecModelToJson(this);
}

@JsonSerializable()
class WhiteBalanceSpecModel {
  final List<String> presets;
  @JsonKey(name: 'custom_kelvin_min')
  final int customKelvinMin;
  @JsonKey(name: 'custom_kelvin_max')
  final int customKelvinMax;
  @JsonKey(name: 'custom_kelvin_step')
  final int customKelvinStep;
  @JsonKey(name: 'custom_slots')
  final int customSlots;

  const WhiteBalanceSpecModel({
    required this.presets,
    required this.customKelvinMin,
    required this.customKelvinMax,
    required this.customKelvinStep,
    required this.customSlots,
  });

  factory WhiteBalanceSpecModel.fromJson(Map<String, dynamic> json) =>
      _$WhiteBalanceSpecModelFromJson(json);

  Map<String, dynamic> toJson() => _$WhiteBalanceSpecModelToJson(this);
}

@JsonSerializable()
class FileFormatsSpecModel {
  final List<String> photo;
  @JsonKey(name: 'raw_format')
  final String rawFormat;
  @JsonKey(name: 'jpeg_quality_levels')
  final List<String> jpegQualityLevels;
  final List<String> video;

  const FileFormatsSpecModel({
    required this.photo,
    required this.rawFormat,
    required this.jpegQualityLevels,
    required this.video,
  });

  factory FileFormatsSpecModel.fromJson(Map<String, dynamic> json) =>
      _$FileFormatsSpecModelFromJson(json);

  Map<String, dynamic> toJson() => _$FileFormatsSpecModelToJson(this);
}

@JsonSerializable()
class StabilizationSpecModel {
  @JsonKey(name: 'has_ibis')
  final bool hasIbis;
  @JsonKey(name: 'ibis_stops')
  final double ibisStops;
  @JsonKey(name: 'ibis_axes')
  final int ibisAxes;

  const StabilizationSpecModel({
    required this.hasIbis,
    required this.ibisStops,
    required this.ibisAxes,
  });

  factory StabilizationSpecModel.fromJson(Map<String, dynamic> json) =>
      _$StabilizationSpecModelFromJson(json);

  Map<String, dynamic> toJson() => _$StabilizationSpecModelToJson(this);
}

@JsonSerializable()
class DriveSpecModel {
  final List<String> modes;
  @JsonKey(name: 'continuous_fps_hi')
  final double continuousFpsHi;
  @JsonKey(name: 'continuous_fps_mid')
  final double continuousFpsMid;
  @JsonKey(name: 'continuous_fps_lo')
  final double continuousFpsLo;

  const DriveSpecModel({
    required this.modes,
    required this.continuousFpsHi,
    required this.continuousFpsMid,
    required this.continuousFpsLo,
  });

  factory DriveSpecModel.fromJson(Map<String, dynamic> json) =>
      _$DriveSpecModelFromJson(json);

  Map<String, dynamic> toJson() => _$DriveSpecModelToJson(this);
}

@JsonSerializable()
class ControlsModel {
  final List<DialModel> dials;
  final List<ButtonModel> buttons;
  @JsonKey(name: 'fn_menu_items')
  final List<String> fnMenuItems;

  const ControlsModel({
    required this.dials,
    required this.buttons,
    required this.fnMenuItems,
  });

  factory ControlsModel.fromJson(Map<String, dynamic> json) =>
      _$ControlsModelFromJson(json);

  Map<String, dynamic> toJson() => _$ControlsModelToJson(this);
}

@JsonSerializable()
class DialModel {
  final String id;
  final String position;
  final Map<String, String> label;
  @JsonKey(name: 'default_function')
  final Map<String, String> defaultFunction;

  const DialModel({
    required this.id,
    required this.position,
    required this.label,
    required this.defaultFunction,
  });

  factory DialModel.fromJson(Map<String, dynamic> json) =>
      _$DialModelFromJson(json);

  Map<String, dynamic> toJson() => _$DialModelToJson(this);
}

@JsonSerializable()
class ButtonModel {
  final String id;
  final String position;
  final Map<String, String> label;
  @JsonKey(name: 'default_function')
  final String defaultFunction;
  final bool customizable;

  const ButtonModel({
    required this.id,
    required this.position,
    required this.label,
    required this.defaultFunction,
    required this.customizable,
  });

  factory ButtonModel.fromJson(Map<String, dynamic> json) =>
      _$ButtonModelFromJson(json);

  Map<String, dynamic> toJson() => _$ButtonModelToJson(this);
}
