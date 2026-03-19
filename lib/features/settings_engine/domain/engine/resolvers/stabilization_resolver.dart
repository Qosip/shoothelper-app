import '../../../../../shared/domain/enums/shooting_enums.dart';
import '../../../../../shared/domain/entities/settings_result.dart';
import '../../entities/engine_context.dart';

/// Stabilization decision tree — Skill 06 §4.6.
class StabilizationResolver {
  const StabilizationResolver();

  SettingRecommendation resolve(EngineContext ctx) {
    if (!ctx.body.stabilization.hasIbis) {
      return const SettingRecommendation(
        settingId: 'stabilization',
        value: null,
        valueDisplay: 'N/A',
        explanationShort:
            'Pas de stabilisation dans le boîtier. La stabilisation optique de l\'objectif est gérée automatiquement.',
      );
    }

    if (ctx.scene.support == Support.tripod) {
      return const SettingRecommendation(
        settingId: 'stabilization',
        value: false,
        valueDisplay: 'OFF',
        explanationShort:
            'Sur trépied, la stabilisation peut introduire des micro-vibrations parasites. Désactive-la.',
      );
    }

    // Video: almost always ON
    // Handheld/monopod/gimbal: ON
    return const SettingRecommendation(
      settingId: 'stabilization',
      value: true,
      valueDisplay: 'ON',
      explanationShort:
          'La stabilisation compense les micro-mouvements et te permet d\'utiliser des vitesses plus lentes.',
    );
  }
}
