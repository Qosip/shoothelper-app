import '../../../../shared/domain/enums/shooting_enums.dart';
import '../../../../shared/domain/value_objects/f_stop.dart';
import '../../../../shared/domain/value_objects/iso_value.dart';
import '../../../../shared/domain/value_objects/shutter_speed.dart';
import '../entities/engine_context.dart';

/// Generates short and detailed explanations for exposure settings.
/// Skill 06 §9.
class ExplanationGenerator {
  const ExplanationGenerator();

  // --- Aperture ---

  String apertureShort(EngineContext ctx, FStop aperture) {
    final reason = _apertureReasonFragment(ctx.scene.intention);
    return 'Ouverture ${aperture.display} $reason avec ton ${ctx.lens.displayName}.';
  }

  String apertureDetail(EngineContext ctx, FStop aperture) {
    final buf = StringBuffer();
    buf.writeln(
        '1. POURQUOI : ${aperture.display} ${_apertureReasonFragment(ctx.scene.intention)}.');
    buf.writeln(
        '2. IMPLICATION : À ${aperture.display} et ${ctx.focalMm}mm sur '
        '${_sensorLabel(ctx.body.sensorSize)}, la profondeur de champ varie selon la distance au sujet.');
    if (aperture == ctx.maxApertureAtFocal) {
      buf.writeln(
          '3. LIMITE : ${ctx.lens.displayName} ne descend pas en dessous de ${ctx.maxApertureAtFocal.display}.');
    }
    return buf.toString();
  }

  String _apertureReasonFragment(Intention i) {
    switch (i) {
      case Intention.bokeh:
        return 'grande ouverte pour maximiser le flou d\'arrière-plan';
      case Intention.maxSharpness:
        return 'au sweet spot de netteté';
      case Intention.lowLight:
        return 'grande ouverte pour capter le maximum de lumière';
      case Intention.freezeMotion:
        return 'grande ouverte pour compenser la vitesse élevée';
      case Intention.motionBlur:
        return 'fermée pour réduire la lumière et permettre une pose longue';
      case Intention.hdrDynamicRange:
        return 'au sweet spot pour maximiser la plage dynamique en bracketing';
      case Intention.longExposure:
        return 'fermée pour allonger le temps de pose';
      case Intention.panning:
        return 'fermée pour permettre une vitesse lente de panning';
      case Intention.highSpeedSync:
        return 'grande ouverte pour compenser la perte de puissance du flash HSS';
      case Intention.documentary:
        return 'polyvalente pour s\'adapter aux conditions changeantes';
      case Intention.minimalistNoise:
        return 'au sweet spot pour garder l\'ISO le plus bas possible';
    }
  }

  // --- Shutter Speed ---

  String shutterShort(EngineContext ctx, ShutterSpeed shutter) {
    return 'Vitesse ${shutter.display} — ${_shutterReasonFragment(ctx)}.';
  }

  String _shutterReasonFragment(EngineContext ctx) {
    if (ctx.scene.shootType == ShootType.video) {
      return 'règle du double (180° shutter angle)';
    }
    if (ctx.scene.subject == Subject.astro) {
      return 'règle NPF pour des étoiles ponctuelles';
    }
    switch (ctx.scene.intention) {
      case Intention.freezeMotion:
        return 'assez rapide pour figer le mouvement';
      case Intention.motionBlur:
        return 'lente pour créer un filé de mouvement';
      case Intention.lowLight:
        return 'la plus lente acceptable pour maximiser la lumière';
      default:
        return 'adaptée au sujet et aux conditions';
    }
  }

  // --- ISO ---

  String isoShort(EngineContext ctx, IsoValue iso) {
    return '${iso.display} — ${_noiseAssessment(ctx, iso)}.';
  }

  String _noiseAssessment(EngineContext ctx, IsoValue iso) {
    final usableMax = ctx.body.sensor.isoUsableMax;
    if (iso.value <= 400) return 'bruit quasi inexistant';
    if (iso.value <= usableMax ~/ 2) return 'bruit très faible';
    if (iso.value <= usableMax) return 'bruit visible mais acceptable';
    if (iso.value <= usableMax * 2) {
      return 'bruit notable, shooter en RAW recommandé';
    }
    return 'bruit élevé — accepter le compromis ou modifier les conditions';
  }

  // --- Confidence message ---

  String confidenceMessage(Confidence c) {
    switch (c) {
      case Confidence.high:
        return 'Ces réglages sont optimaux pour ta scène.';
      case Confidence.medium:
        return 'Ces réglages sont une bonne base. Affine la description de ta scène pour des résultats plus précis.';
      case Confidence.low:
        return 'Ces réglages sont un point de départ, mais des compromis importants ont été faits.';
    }
  }

  String _sensorLabel(SensorSize s) {
    switch (s) {
      case SensorSize.apsc: return 'APS-C';
      case SensorSize.fullFrame: return 'Full-Frame';
      case SensorSize.microFourThirds: return 'Micro 4/3';
    }
  }
}
