import '../../../../../shared/domain/enums/shooting_enums.dart';
import '../../../../../shared/domain/entities/settings_result.dart';
import '../../entities/engine_context.dart';

/// Exposure mode recommendation — Skill 06 §10.
class ExposureModeResolver {
  const ExposureModeResolver();

  SettingRecommendation resolve(EngineContext ctx) {
    final scene = ctx.scene;
    ExposureMode mode;
    String explanation;

    if (scene.subject == Subject.astro) {
      mode = ExposureMode.m;
      explanation =
          'Le mode M est obligatoire en astro. Le posemètre ne fonctionne pas dans le noir.';
    } else if (scene.intention == Intention.bokeh ||
        scene.intention == Intention.maxSharpness) {
      mode = ExposureMode.a;
      explanation =
          'Le mode A te laisse contrôler l\'ouverture — le paramètre clé ici — '
          'et l\'appareil ajuste la vitesse automatiquement.';
    } else if (scene.intention == Intention.freezeMotion ||
        scene.intention == Intention.motionBlur) {
      mode = ExposureMode.s;
      explanation =
          'Le mode S te laisse contrôler la vitesse — le paramètre clé ici — '
          'et l\'appareil ajuste l\'ouverture automatiquement.';
    } else if (scene.intention == Intention.lowLight) {
      mode = ExposureMode.m;
      explanation =
          'En basse lumière, le mode M te donne le contrôle total pour pousser chaque paramètre à son maximum.';
    } else if (scene.environment == Environment.studio) {
      mode = ExposureMode.m;
      explanation = 'En studio, la lumière est contrôlée. Le mode M est standard.';
    } else {
      mode = ExposureMode.a;
      explanation =
          'Le mode A est le plus polyvalent pour apprendre. Tu contrôles le flou (ouverture), l\'appareil gère le reste.';
    }

    return SettingRecommendation(
      settingId: 'exposure_mode',
      value: mode,
      valueDisplay: _display(mode),
      explanationShort: explanation,
    );
  }

  String _display(ExposureMode m) {
    switch (m) {
      case ExposureMode.p: return 'P';
      case ExposureMode.a: return 'A';
      case ExposureMode.s: return 'S';
      case ExposureMode.m: return 'M';
    }
  }
}
