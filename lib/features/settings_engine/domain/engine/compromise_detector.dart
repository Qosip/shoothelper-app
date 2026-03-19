import '../../../../shared/domain/enums/shooting_enums.dart';
import '../../../../shared/domain/entities/settings_result.dart';
import '../../../../shared/domain/value_objects/f_stop.dart';
import '../../../../shared/domain/value_objects/iso_value.dart';
import '../../../../shared/domain/value_objects/shutter_speed.dart';
import '../entities/engine_context.dart';

/// Detects additional compromises beyond the exposure triangle.
/// Skill 06 §6.1.
class CompromiseDetector {
  const CompromiseDetector();

  List<Compromise> detect({
    required EngineContext ctx,
    required FStop aperture,
    required ShutterSpeed shutter,
    required IsoValue iso,
    required List<Compromise> existingCompromises,
  }) {
    final compromises = <Compromise>[...existingCompromises];

    // Astro without tripod
    if (ctx.scene.subject == Subject.astro &&
        ctx.scene.support != Support.tripod) {
      compromises.add(const Compromise(
        type: CompromiseType.impossible,
        severity: CompromiseSeverity.critical,
        message:
            'L\'astrophoto nécessite un trépied. Main levée, les temps de pose de 10+ secondes sont impossibles.',
        affectedSettings: ['shutter_speed', 'support'],
        suggestion: 'Utilise un trépied stable.',
      ));
    }

    // User ISO constraint impossible
    if (ctx.scene.constraintIsoMax != null &&
        iso.value > ctx.scene.constraintIsoMax!) {
      compromises.add(Compromise(
        type: CompromiseType.impossible,
        severity: CompromiseSeverity.critical,
        message:
            'ISO ${iso.value} nécessaire mais ta contrainte est ISO ${ctx.scene.constraintIsoMax}. '
            'Impossible sans changer d\'autres paramètres.',
        affectedSettings: ['iso'],
        suggestion:
            'Retire la contrainte ISO, utilise un trépied, ou choisis un objectif plus lumineux.',
      ));
    }

    // Shutter forced below effective min
    if (shutter.seconds > ctx.shutterMinEffective.seconds &&
        ctx.scene.subject != Subject.astro &&
        ctx.scene.intention != Intention.motionBlur) {
      compromises.add(Compromise(
        type: CompromiseType.motionBlur,
        severity: CompromiseSeverity.warning,
        message:
            'Vitesse ${shutter.display} plus lente que recommandé. Risque de flou de bougé.',
        affectedSettings: ['shutter_speed'],
        suggestion: 'Stabilise-toi ou utilise un trépied.',
      ));
    }

    return compromises;
  }
}
