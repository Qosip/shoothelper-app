import '../enums/shooting_enums.dart';

/// User's scene description — input to the Settings Engine.
/// Skill 06 §2.2 SceneInput.
class SceneInput {
  // Level 1 (required)
  final ShootType shootType;
  final Environment environment;
  final Subject subject;
  final Intention intention;

  // Level 2 (optional)
  final LightCondition? lightCondition;
  final SubjectMotion? subjectMotion;
  final SubjectDistance? subjectDistance;
  final Mood? mood;
  final Support? support;
  final int? constraintIsoMax;
  final String? constraintShutterMin; // e.g. "1/500"

  // Level 3 (optional overrides)
  final WbOverride? wbOverride;
  final DofPreference? dofPreference;
  final AfAreaOverride? afAreaOverride;
  final BracketingMode? bracketing;
  final FileFormatOverride? fileFormatOverride;

  const SceneInput({
    required this.shootType,
    required this.environment,
    required this.subject,
    required this.intention,
    this.lightCondition,
    this.subjectMotion,
    this.subjectDistance,
    this.mood,
    this.support,
    this.constraintIsoMax,
    this.constraintShutterMin,
    this.wbOverride,
    this.dofPreference,
    this.afAreaOverride,
    this.bracketing,
    this.fileFormatOverride,
  });

  SceneInput copyWith({
    ShootType? shootType,
    Environment? environment,
    Subject? subject,
    Intention? intention,
    LightCondition? Function()? lightCondition,
    SubjectMotion? Function()? subjectMotion,
    SubjectDistance? Function()? subjectDistance,
    Mood? Function()? mood,
    Support? Function()? support,
    int? Function()? constraintIsoMax,
    String? Function()? constraintShutterMin,
    WbOverride? Function()? wbOverride,
    DofPreference? Function()? dofPreference,
    AfAreaOverride? Function()? afAreaOverride,
    BracketingMode? Function()? bracketing,
    FileFormatOverride? Function()? fileFormatOverride,
  }) {
    return SceneInput(
      shootType: shootType ?? this.shootType,
      environment: environment ?? this.environment,
      subject: subject ?? this.subject,
      intention: intention ?? this.intention,
      lightCondition:
          lightCondition != null ? lightCondition() : this.lightCondition,
      subjectMotion:
          subjectMotion != null ? subjectMotion() : this.subjectMotion,
      subjectDistance:
          subjectDistance != null ? subjectDistance() : this.subjectDistance,
      mood: mood != null ? mood() : this.mood,
      support: support != null ? support() : this.support,
      constraintIsoMax:
          constraintIsoMax != null ? constraintIsoMax() : this.constraintIsoMax,
      constraintShutterMin: constraintShutterMin != null
          ? constraintShutterMin()
          : this.constraintShutterMin,
      wbOverride: wbOverride != null ? wbOverride() : this.wbOverride,
      dofPreference:
          dofPreference != null ? dofPreference() : this.dofPreference,
      afAreaOverride:
          afAreaOverride != null ? afAreaOverride() : this.afAreaOverride,
      bracketing: bracketing != null ? bracketing() : this.bracketing,
      fileFormatOverride: fileFormatOverride != null
          ? fileFormatOverride()
          : this.fileFormatOverride,
    );
  }
}
