import '../enums/shooting_enums.dart';

/// Output of the Settings Engine.
/// Skill 06 §2.2 SettingsResult.
class SettingsResult {
  final List<SettingRecommendation> settings;
  final List<Compromise> compromises;
  final String sceneSummary;
  final Confidence confidence;

  const SettingsResult({
    required this.settings,
    required this.compromises,
    required this.sceneSummary,
    required this.confidence,
  });

  SettingRecommendation? findSetting(String settingId) {
    for (final s in settings) {
      if (s.settingId == settingId) return s;
    }
    return null;
  }
}

class SettingRecommendation {
  final String settingId;
  final dynamic value;
  final String valueDisplay;
  final String explanationShort;
  final String explanationDetail;
  final bool isOverride;
  final bool isCompromised;
  final List<Alternative> alternatives;

  const SettingRecommendation({
    required this.settingId,
    required this.value,
    required this.valueDisplay,
    required this.explanationShort,
    this.explanationDetail = '',
    this.isOverride = false,
    this.isCompromised = false,
    this.alternatives = const [],
  });
}

class Alternative {
  final dynamic value;
  final String valueDisplay;
  final String tradeOff;
  final List<CascadeChange> cascadeChanges;

  const Alternative({
    required this.value,
    required this.valueDisplay,
    required this.tradeOff,
    this.cascadeChanges = const [],
  });
}

class CascadeChange {
  final String settingId;
  final String fromValue;
  final String toValue;
  final String reason;

  const CascadeChange({
    required this.settingId,
    required this.fromValue,
    required this.toValue,
    required this.reason,
  });
}

class Compromise {
  final CompromiseType type;
  final CompromiseSeverity severity;
  final String message;
  final List<String> affectedSettings;
  final String suggestion;

  const Compromise({
    required this.type,
    required this.severity,
    required this.message,
    this.affectedSettings = const [],
    this.suggestion = '',
  });
}
