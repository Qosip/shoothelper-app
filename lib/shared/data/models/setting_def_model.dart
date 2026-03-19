import 'package:json_annotation/json_annotation.dart';

part 'setting_def_model.g.dart';

@JsonSerializable()
class SettingDefModel {
  final String id;
  final String category;
  final String name;
  final String description;
  @JsonKey(name: 'data_type')
  final String dataType;
  final String? unit;
  @JsonKey(name: 'possible_values')
  final List<String>? possibleValues;
  @JsonKey(name: 'step_values')
  final List<double>? stepValues;
  @JsonKey(name: 'adjustable_via_menu')
  final bool adjustableViaMenu;
  @JsonKey(name: 'adjustable_via_dial')
  final bool adjustableViaDial;
  @JsonKey(name: 'adjustable_via_fn')
  final bool adjustableViaFn;
  @JsonKey(name: 'affects_exposure')
  final bool affectsExposure;

  const SettingDefModel({
    required this.id,
    required this.category,
    required this.name,
    required this.description,
    required this.dataType,
    this.unit,
    this.possibleValues,
    this.stepValues,
    required this.adjustableViaMenu,
    required this.adjustableViaDial,
    required this.adjustableViaFn,
    required this.affectsExposure,
  });

  factory SettingDefModel.fromJson(Map<String, dynamic> json) =>
      _$SettingDefModelFromJson(json);

  Map<String, dynamic> toJson() => _$SettingDefModelToJson(this);
}
