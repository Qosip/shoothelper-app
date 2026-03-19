/// Definition of a camera setting (metadata).
/// Skill 04 §3.8 SettingDef.
class SettingDef {
  final String id;
  final String category;
  final String name;
  final String description;
  final String dataType;
  final String? unit;
  final List<String>? possibleValues;
  final List<double>? stepValues;
  final bool adjustableViaMenu;
  final bool adjustableViaDial;
  final bool adjustableViaFn;
  final bool affectsExposure;

  const SettingDef({
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
}
