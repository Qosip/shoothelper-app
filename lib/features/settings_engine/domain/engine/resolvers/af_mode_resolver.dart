import '../../../../../shared/domain/enums/shooting_enums.dart';
import '../../../../../shared/domain/entities/settings_result.dart';
import '../../entities/engine_context.dart';

/// AF mode decision tree — Skill 06 §4.1.
class AfModeResolver {
  const AfModeResolver();

  SettingRecommendation resolve(EngineContext ctx) {
    final scene = ctx.scene;
    AfMode mode;
    String explanation;

    if (scene.subject == Subject.astro &&
        scene.intention == Intention.maxSharpness) {
      mode = AfMode.mf;
      explanation =
          'En astrophoto, l\'autofocus ne peut pas accrocher les étoiles. '
          'Passe en MF et fais la mise au point sur une étoile brillante avec le zoom d\'aide.';
    } else if (scene.subject == Subject.landscape &&
        scene.subjectDistance == SubjectDistance.infinity) {
      mode = AfMode.afS;
      explanation =
          'Pour un paysage à l\'infini, AF-S verrouille la mise au point en une fois.';
    } else if (scene.subjectMotion != null &&
        (scene.subjectMotion == SubjectMotion.slow ||
            scene.subjectMotion == SubjectMotion.fast ||
            scene.subjectMotion == SubjectMotion.veryFast)) {
      mode = AfMode.afC;
      explanation =
          'Sujet en mouvement : AF-C ajuste la mise au point en continu pour suivre le sujet.';
    } else if (scene.subject == Subject.macro) {
      mode = AfMode.afS;
      explanation =
          'En macro, la profondeur de champ est si fine que l\'AF peut manquer le sujet. '
          'AF-S pour les sujets stables, MF pour le contrôle total.';
    } else if (scene.shootType == ShootType.video) {
      mode = AfMode.afC;
      explanation = 'En vidéo, AF-C est recommandé pour suivre le sujet en continu.';
    } else if (scene.subjectMotion == SubjectMotion.still ||
        scene.subjectMotion == null) {
      mode = AfMode.afS;
      explanation = 'Sujet immobile : AF-S verrouille la mise au point en une fois.';
    } else {
      mode = AfMode.afS;
      explanation = 'AF-S par défaut.';
    }

    // Fallback: verify mode is supported
    final modeStr = _afModeToString(mode);
    if (!ctx.body.autofocus.modes.contains(modeStr)) {
      mode = AfMode.afS; // safest fallback
    }

    return SettingRecommendation(
      settingId: 'af_mode',
      value: mode,
      valueDisplay: _displayAfMode(mode),
      explanationShort: explanation,
    );
  }

  String _afModeToString(AfMode m) {
    switch (m) {
      case AfMode.afS: return 'af-s';
      case AfMode.afC: return 'af-c';
      case AfMode.dmf: return 'dmf';
      case AfMode.mf: return 'mf';
    }
  }

  String _displayAfMode(AfMode m) {
    switch (m) {
      case AfMode.afS: return 'AF-S';
      case AfMode.afC: return 'AF-C';
      case AfMode.dmf: return 'DMF';
      case AfMode.mf: return 'MF';
    }
  }
}
