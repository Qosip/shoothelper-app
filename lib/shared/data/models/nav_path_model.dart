import 'package:json_annotation/json_annotation.dart';

part 'nav_path_model.g.dart';

@JsonSerializable()
class NavPathModel {
  @JsonKey(name: 'body_id')
  final String bodyId;
  @JsonKey(name: 'setting_id')
  final String settingId;
  @JsonKey(name: 'firmware_version')
  final String firmwareVersion;
  @JsonKey(name: 'menu_path')
  final List<String>? menuPath;
  @JsonKey(name: 'menu_item_id')
  final String? menuItemId;
  @JsonKey(name: 'quick_access')
  final QuickAccessModel? quickAccess;
  @JsonKey(name: 'dial_access')
  final DialAccessModel? dialAccess;
  final List<TipModel>? tips;

  const NavPathModel({
    required this.bodyId,
    required this.settingId,
    required this.firmwareVersion,
    this.menuPath,
    this.menuItemId,
    this.quickAccess,
    this.dialAccess,
    this.tips,
  });

  factory NavPathModel.fromJson(Map<String, dynamic> json) =>
      _$NavPathModelFromJson(json);

  Map<String, dynamic> toJson() => _$NavPathModelToJson(this);
}

@JsonSerializable()
class QuickAccessModel {
  final String method;
  final List<StepModel> steps;

  const QuickAccessModel({
    required this.method,
    required this.steps,
  });

  factory QuickAccessModel.fromJson(Map<String, dynamic> json) =>
      _$QuickAccessModelFromJson(json);

  Map<String, dynamic> toJson() => _$QuickAccessModelToJson(this);
}

@JsonSerializable()
class StepModel {
  final String action;
  final String target;
  final Map<String, String> labels;

  const StepModel({
    required this.action,
    required this.target,
    required this.labels,
  });

  factory StepModel.fromJson(Map<String, dynamic> json) =>
      _$StepModelFromJson(json);

  Map<String, dynamic> toJson() => _$StepModelToJson(this);
}

@JsonSerializable()
class DialAccessModel {
  @JsonKey(name: 'exposure_modes')
  final List<String> exposureModes;
  @JsonKey(name: 'dial_id')
  final String dialId;
  final Map<String, String> labels;

  const DialAccessModel({
    required this.exposureModes,
    required this.dialId,
    required this.labels,
  });

  factory DialAccessModel.fromJson(Map<String, dynamic> json) =>
      _$DialAccessModelFromJson(json);

  Map<String, dynamic> toJson() => _$DialAccessModelToJson(this);
}

@JsonSerializable()
class TipModel {
  final Map<String, String> labels;
  @JsonKey(name: 'related_menu_path')
  final List<String>? relatedMenuPath;

  const TipModel({
    required this.labels,
    this.relatedMenuPath,
  });

  factory TipModel.fromJson(Map<String, dynamic> json) =>
      _$TipModelFromJson(json);

  Map<String, dynamic> toJson() => _$TipModelToJson(this);
}
