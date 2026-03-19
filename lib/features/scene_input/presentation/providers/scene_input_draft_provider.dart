import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/domain/entities/scene_input.dart';
import '../../../../shared/domain/enums/shooting_enums.dart';

/// Draft state for the scene input form. All fields nullable until submitted.
class SceneInputDraftState {
  // Level 1 — required
  final ShootType? shootType;
  final Environment? environment;
  final Subject? subject;
  final Intention? intention;

  // Level 2 — optional
  final LightCondition? lightCondition;
  final SubjectMotion? subjectMotion;
  final SubjectDistance? subjectDistance;
  final Mood? mood;
  final Support? support;
  final int? constraintIsoMax;

  // Level 3 — overrides
  final DofPreference? dofPreference;
  final WbOverride? wbOverride;
  final AfAreaOverride? afAreaOverride;
  final BracketingMode? bracketing;
  final FileFormatOverride? fileFormatOverride;

  const SceneInputDraftState({
    this.shootType,
    this.environment,
    this.subject,
    this.intention,
    this.lightCondition,
    this.subjectMotion,
    this.subjectDistance,
    this.mood,
    this.support,
    this.constraintIsoMax,
    this.dofPreference,
    this.wbOverride,
    this.afAreaOverride,
    this.bracketing,
    this.fileFormatOverride,
  });

  bool get isLevel1Complete =>
      shootType != null &&
      environment != null &&
      subject != null &&
      intention != null;

  SceneInputDraftState copyWith({
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
    DofPreference? Function()? dofPreference,
    WbOverride? Function()? wbOverride,
    AfAreaOverride? Function()? afAreaOverride,
    BracketingMode? Function()? bracketing,
    FileFormatOverride? Function()? fileFormatOverride,
  }) {
    return SceneInputDraftState(
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
      dofPreference:
          dofPreference != null ? dofPreference() : this.dofPreference,
      wbOverride: wbOverride != null ? wbOverride() : this.wbOverride,
      afAreaOverride:
          afAreaOverride != null ? afAreaOverride() : this.afAreaOverride,
      bracketing: bracketing != null ? bracketing() : this.bracketing,
      fileFormatOverride: fileFormatOverride != null
          ? fileFormatOverride()
          : this.fileFormatOverride,
    );
  }

  /// Convert validated draft to SceneInput for the engine.
  SceneInput toSceneInput() {
    assert(isLevel1Complete);
    return SceneInput(
      shootType: shootType!,
      environment: environment!,
      subject: subject!,
      intention: intention!,
      lightCondition: lightCondition,
      subjectMotion: subjectMotion,
      subjectDistance: subjectDistance,
      mood: mood,
      support: support,
      constraintIsoMax: constraintIsoMax,
      dofPreference: dofPreference,
      wbOverride: wbOverride,
      afAreaOverride: afAreaOverride,
      bracketing: bracketing,
      fileFormatOverride: fileFormatOverride,
    );
  }
}

/// Draft notifier for scene input form.
class SceneInputDraftNotifier extends StateNotifier<SceneInputDraftState> {
  SceneInputDraftNotifier() : super(const SceneInputDraftState());

  // Level 1
  void setShootType(ShootType v) => state = state.copyWith(shootType: v);
  void setEnvironment(Environment v) => state = state.copyWith(environment: v);
  void setSubject(Subject v) => state = state.copyWith(subject: v);
  void setIntention(Intention v) => state = state.copyWith(intention: v);

  // Level 2
  void setLightCondition(LightCondition? v) =>
      state = state.copyWith(lightCondition: () => v);
  void setSubjectMotion(SubjectMotion? v) =>
      state = state.copyWith(subjectMotion: () => v);
  void setSubjectDistance(SubjectDistance? v) =>
      state = state.copyWith(subjectDistance: () => v);
  void setMood(Mood? v) => state = state.copyWith(mood: () => v);
  void setSupport(Support? v) => state = state.copyWith(support: () => v);
  void setConstraintIsoMax(int? v) =>
      state = state.copyWith(constraintIsoMax: () => v);

  // Level 3
  void setDofPreference(DofPreference? v) =>
      state = state.copyWith(dofPreference: () => v);
  void setWbOverride(WbOverride? v) =>
      state = state.copyWith(wbOverride: () => v);
  void setAfAreaOverride(AfAreaOverride? v) =>
      state = state.copyWith(afAreaOverride: () => v);
  void setBracketing(BracketingMode? v) =>
      state = state.copyWith(bracketing: () => v);
  void setFileFormatOverride(FileFormatOverride? v) =>
      state = state.copyWith(fileFormatOverride: () => v);

  void reset() => state = const SceneInputDraftState();
}

final sceneInputDraftProvider =
    StateNotifierProvider<SceneInputDraftNotifier, SceneInputDraftState>(
        (ref) => SceneInputDraftNotifier());
