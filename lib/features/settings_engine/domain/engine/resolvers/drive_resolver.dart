import '../../../../../shared/domain/enums/shooting_enums.dart';
import '../../../../../shared/domain/entities/settings_result.dart';
import '../../entities/engine_context.dart';

/// Drive mode decision tree — Skill 06 §4.7.
class DriveResolver {
  const DriveResolver();

  SettingRecommendation resolve(EngineContext ctx) {
    final scene = ctx.scene;
    DriveMode mode;
    String explanation;

    if (scene.subjectMotion == SubjectMotion.fast ||
        scene.subjectMotion == SubjectMotion.veryFast) {
      mode = DriveMode.continuousHi;
      explanation =
          'La rafale haute multiplie tes chances de capturer le bon moment avec un sujet rapide.';
    } else if (scene.subject == Subject.sport ||
        scene.subject == Subject.wildlife) {
      mode = DriveMode.continuousHi;
      explanation =
          'Rafale haute pour maximiser les chances en sport/animalier.';
    } else if (scene.bracketing != null &&
        scene.bracketing != BracketingMode.none) {
      mode = DriveMode.bracket;
      explanation = 'Mode bracket activé pour le bracketing.';
    } else if (scene.subject == Subject.portrait) {
      mode = DriveMode.single;
      explanation = 'En portrait, une seule image suffit.';
    } else if (scene.subject == Subject.astro) {
      mode = DriveMode.selfTimer;
      explanation =
          'Timer 2s pour éviter les vibrations du déclenchement sur trépied.';
    } else {
      mode = DriveMode.single;
      explanation = 'Prise de vue unique par défaut.';
    }

    return SettingRecommendation(
      settingId: 'drive',
      value: mode,
      valueDisplay: _display(mode),
      explanationShort: explanation,
    );
  }

  String _display(DriveMode m) {
    switch (m) {
      case DriveMode.single: return 'Simple';
      case DriveMode.continuousHi: return 'Rafale haute';
      case DriveMode.continuousMid: return 'Rafale moyenne';
      case DriveMode.continuousLo: return 'Rafale basse';
      case DriveMode.selfTimer: return 'Retardateur';
      case DriveMode.bracket: return 'Bracket';
    }
  }
}
