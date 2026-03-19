import '../../../../../shared/domain/enums/shooting_enums.dart';
import '../../../../../shared/domain/entities/settings_result.dart';
import '../../entities/engine_context.dart';

/// Metering mode decision tree — Skill 06 §4.3.
class MeteringResolver {
  const MeteringResolver();

  SettingRecommendation resolve(EngineContext ctx) {
    final scene = ctx.scene;
    MeteringMode mode;
    String explanation;

    if (scene.mood == Mood.silhouette) {
      mode = MeteringMode.spot;
      explanation =
          'Pour une silhouette, mesure sur le fond lumineux. Le sujet sera naturellement sous-exposé.';
    } else if (scene.mood == Mood.dramatic ||
        scene.mood == Mood.highContrast) {
      mode = MeteringMode.spot;
      explanation =
          'Mesure ciblée pour contrôler précisément l\'exposition sur la zone d\'intérêt.';
    } else if (scene.subject == Subject.portrait) {
      mode = MeteringMode.centerWeighted;
      explanation =
          'La mesure centre pondéré expose correctement le visage sans être trop influencée par l\'arrière-plan.';
    } else if (scene.subject == Subject.landscape) {
      mode = MeteringMode.multi;
      explanation =
          'La mesure matricielle évalue l\'ensemble de la scène pour une exposition équilibrée du paysage.';
    } else if (scene.environment == Environment.studio) {
      mode = MeteringMode.spot;
      explanation =
          'En studio, la mesure spot permet de mesurer précisément la lumière sur le sujet.';
    } else {
      mode = MeteringMode.multi;
      explanation = 'Mesure matricielle par défaut — évalue l\'ensemble de la scène.';
    }

    return SettingRecommendation(
      settingId: 'metering',
      value: mode,
      valueDisplay: _display(mode),
      explanationShort: explanation,
    );
  }

  String _display(MeteringMode m) {
    switch (m) {
      case MeteringMode.multi: return 'Matricielle';
      case MeteringMode.centerWeighted: return 'Centre pondéré';
      case MeteringMode.spot: return 'Spot';
      case MeteringMode.highlight: return 'Hautes lumières';
    }
  }
}
