import 'dart:math';

import '../../../../../shared/domain/enums/shooting_enums.dart';
import '../../../../../shared/domain/entities/settings_result.dart';
import '../../../../../shared/domain/value_objects/f_stop.dart';
import '../../../../../shared/domain/value_objects/iso_value.dart';
import '../../../../../shared/domain/value_objects/shutter_speed.dart';
import '../../entities/engine_context.dart';
import '../exposure_calculator.dart';

/// Resolves the exposure triangle (aperture, shutter, ISO) based on intention.
/// Skill 06 §5.
class ExposureTriangleResult {
  final FStop aperture;
  final ShutterSpeed shutter;
  final IsoValue iso;
  final List<Compromise> compromises;

  const ExposureTriangleResult({
    required this.aperture,
    required this.shutter,
    required this.iso,
    this.compromises = const [],
  });
}

class ExposureTriangleResolver {
  final ExposureCalculator _calc;

  const ExposureTriangleResolver({
    ExposureCalculator calc = const ExposureCalculator(),
  }) : _calc = calc;

  ExposureTriangleResult resolve(EngineContext ctx) {
    // Astro has its own dedicated flow (Skill 06 §8.1)
    if (ctx.scene.subject == Subject.astro) {
      return _resolveAstro(ctx);
    }

    // Video override: shutter by 180° rule
    if (ctx.scene.shootType == ShootType.video) {
      return _resolveVideo(ctx);
    }

    switch (ctx.scene.intention) {
      case Intention.bokeh:
        return _resolveBokeh(ctx);
      case Intention.maxSharpness:
      case Intention.minimalistNoise:
        return _resolveMaxSharpness(ctx);
      case Intention.freezeMotion:
      case Intention.highSpeedSync:
        return _resolveFreezeMotion(ctx);
      case Intention.motionBlur:
      case Intention.panning:
        return _resolveMotionBlur(ctx);
      case Intention.lowLight:
      case Intention.documentary:
        return _resolveLowLight(ctx);
      case Intention.hdrDynamicRange:
      case Intention.longExposure:
        return _resolveMaxSharpness(ctx);
    }
  }

  // --- §8.1 Astro (dedicated flow) ---
  ExposureTriangleResult _resolveAstro(EngineContext ctx) {
    final compromises = <Compromise>[];

    // Aperture: wide open
    final aperture = ctx.maxApertureAtFocal;

    // Shutter: NPF rule (stored in shutterMinEffective for astro)
    final shutter = ctx.shutterMinEffective;

    // ISO: for astro, push to usable max (Skill 06 §8.1)
    // "ISO target = iso_usable_max (on pousse volontairement)"
    final calculatedIso = _calc.resolveIso(aperture, shutter, ctx.evTarget);
    final targetIso = ctx.body.sensor.isoUsableMax;
    // Use the higher of calculated need and target (we want signal from faint stars)
    var iso = IsoValue(max(calculatedIso.value, targetIso)).toNearestStandard();

    if (iso.value > ctx.body.sensor.isoMax) {
      iso = IsoValue(ctx.body.sensor.isoMax).toNearestStandard();
      compromises.add(const Compromise(
        type: CompromiseType.noise,
        severity: CompromiseSeverity.critical,
        message: 'ISO max atteint. Pas assez de lumière même avec les réglages extrêmes.',
        affectedSettings: ['iso'],
        suggestion: 'Utilise un objectif plus lumineux ou une monture de suivi.',
      ));
    }

    if (iso.value < ctx.body.sensor.isoMin) {
      iso = IsoValue(ctx.body.sensor.isoMin);
    }

    return ExposureTriangleResult(
      aperture: aperture.toNearestStandard(),
      shutter: shutter.toNearestStandard(),
      iso: iso,
      compromises: compromises,
    );
  }

  // --- §5.2.1 Bokeh ---
  ExposureTriangleResult _resolveBokeh(EngineContext ctx) {
    var aperture = ctx.maxApertureAtFocal; // widest possible
    final compromises = <Compromise>[];

    // Step 2: compute shutter
    var shutter = _calc.resolveShutter(
      aperture,
      const IsoValue(100),
      ctx.evTarget,
    );

    // If shutter too fast for camera, we're fine (bright scene)
    // If shutter too slow for subject/shake → raise ISO
    if (shutter.seconds < ctx.shutterMinEffective.seconds) {
      shutter = ctx.shutterMinEffective;
    }

    // Step 3: compute ISO
    var iso = _calc.resolveIso(aperture, shutter, ctx.evTarget);
    iso = iso.toNearestStandard();

    // Clamp ISO
    final (clampedIso, isoCompromises) = _clampIso(ctx, iso);
    iso = clampedIso;
    compromises.addAll(isoCompromises);

    // If too much light (shutter > max speed), close aperture
    final maxSpeed = ShutterSpeed(ctx.body.shutter.electronicMinSeconds);
    if (shutter.seconds < maxSpeed.seconds && iso.value <= ctx.body.sensor.isoMin) {
      aperture = _calc.resolveAperture(maxSpeed, IsoValue(ctx.body.sensor.isoMin), ctx.evTarget);
      aperture = aperture.toNearestNarrower();
      shutter = maxSpeed;
      iso = IsoValue(ctx.body.sensor.isoMin);
      if (aperture > ctx.maxApertureAtFocal) {
        compromises.add(const Compromise(
          type: CompromiseType.depthOfField,
          severity: CompromiseSeverity.info,
          message: 'Ouverture fermée pour éviter la surexposition — moins de bokeh.',
          affectedSettings: ['aperture'],
        ));
      }
    }

    return ExposureTriangleResult(
      aperture: aperture.toNearestStandard(),
      shutter: shutter.toNearestStandard(),
      iso: iso,
      compromises: compromises,
    );
  }

  // --- §5.2.2 Max Sharpness ---
  ExposureTriangleResult _resolveMaxSharpness(EngineContext ctx) {
    final compromises = <Compromise>[];

    // Sweet spot: ~2.5 stops from max aperture
    var sweetSpot = ctx.maxApertureAtFocal.value * 2.8;
    sweetSpot = sweetSpot.clamp(ctx.maxApertureAtFocal.value, 11);

    // Diffraction limit by sensor size
    final diffLimit = ctx.body.sensorSize == SensorSize.apsc ? 11.0 : 16.0;
    sweetSpot = min(sweetSpot, diffLimit);

    // Landscape: close more for DoF
    if (ctx.scene.subject == Subject.landscape &&
        ctx.scene.dofPreference != DofPreference.shallow) {
      sweetSpot = sweetSpot.clamp(8, 11);
    }

    var aperture = FStop(sweetSpot);

    // Same flow as bokeh for shutter + ISO
    var shutter = _calc.resolveShutter(
      aperture,
      const IsoValue(100),
      ctx.evTarget,
    );

    if (shutter.seconds < ctx.shutterMinEffective.seconds) {
      shutter = ctx.shutterMinEffective;
    }

    var iso = _calc.resolveIso(aperture, shutter, ctx.evTarget);
    iso = iso.toNearestStandard();

    final (clampedIso, isoCompromises) = _clampIso(ctx, iso);
    iso = clampedIso;
    compromises.addAll(isoCompromises);

    return ExposureTriangleResult(
      aperture: aperture.toNearestStandard(),
      shutter: shutter.toNearestStandard(),
      iso: iso,
      compromises: compromises,
    );
  }

  // --- §5.2.3 Freeze Motion ---
  ExposureTriangleResult _resolveFreezeMotion(EngineContext ctx) {
    final compromises = <Compromise>[];

    // Step 1: fix shutter speed
    ShutterSpeed shutterTarget;
    if (ctx.scene.subjectMotion != null) {
      shutterTarget = ctx.shutterMinSubject;
    } else if (ctx.scene.subject == Subject.sport) {
      shutterTarget = ShutterSpeed.fraction(500);
    } else if (ctx.scene.subject == Subject.wildlife) {
      shutterTarget = ShutterSpeed.fraction(1000);
    } else {
      shutterTarget = ShutterSpeed.fraction(250);
    }

    // Use target if it's already faster than safe; otherwise use safe minimum
    var shutter = shutterTarget.seconds > ctx.shutterMinSafe.seconds
        ? ctx.shutterMinSafe
        : shutterTarget;

    // Step 2: open aperture to max
    var aperture = ctx.maxApertureAtFocal;

    // Step 3: compute ISO
    var iso = _calc.resolveIso(aperture, shutter, ctx.evTarget);
    iso = iso.toNearestStandard();

    final (clampedIso, isoCompromises) = _clampIso(ctx, iso);
    iso = clampedIso;
    compromises.addAll(isoCompromises);

    return ExposureTriangleResult(
      aperture: aperture.toNearestStandard(),
      shutter: shutter.toNearestStandard(),
      iso: iso,
      compromises: compromises,
    );
  }

  // --- §5.2.4 Motion Blur ---
  ExposureTriangleResult _resolveMotionBlur(EngineContext ctx) {
    final compromises = <Compromise>[];

    // Step 1: slow shutter
    double shutterTarget;
    switch (ctx.scene.subjectMotion) {
      case SubjectMotion.slow:
        shutterTarget = 1 / 15;
      case SubjectMotion.fast:
        shutterTarget = 1 / 30;
      case SubjectMotion.veryFast:
        shutterTarget = 1 / 60;
      default:
        shutterTarget = 1 / 15;
    }

    if (ctx.scene.support != Support.tripod &&
        ctx.scene.support != Support.monopod) {
      compromises.add(const Compromise(
        type: CompromiseType.motionBlur,
        severity: CompromiseSeverity.warning,
        message:
            'Le filé de mouvement est plus facile avec un trépied. Main levée, le risque de bougé global est élevé.',
        affectedSettings: ['shutter_speed'],
        suggestion: 'Utilise un trépied ou un monopode.',
      ));
    }

    var shutter = ShutterSpeed(shutterTarget);

    // Step 2: close aperture to avoid overexposure
    var aperture = _calc.resolveAperture(
      shutter,
      const IsoValue(100),
      ctx.evTarget,
    );

    if (aperture.value > ctx.lens.aperture.minAperture) {
      compromises.add(Compromise(
        type: CompromiseType.exposure,
        severity: CompromiseSeverity.warning,
        message:
            'Tu as besoin d\'un filtre ND pour cette vitesse dans ces conditions de lumière.',
        affectedSettings: ['aperture', 'shutter_speed'],
        suggestion: 'Utilise un filtre ND pour réduire la lumière.',
      ));
      aperture = FStop(ctx.lens.aperture.minAperture);
    }

    // Step 3: ISO at minimum
    final iso = IsoValue(ctx.body.sensor.isoMin);

    return ExposureTriangleResult(
      aperture: aperture.toNearestStandard(),
      shutter: shutter.toNearestStandard(),
      iso: iso,
      compromises: compromises,
    );
  }

  // --- §5.2.5 Low Light ---
  ExposureTriangleResult _resolveLowLight(EngineContext ctx) {
    final compromises = <Compromise>[];

    // Step 1: max aperture
    var aperture = ctx.maxApertureAtFocal;

    // Step 2: slowest acceptable shutter
    var shutter = ctx.shutterMinEffective;

    // Step 3: ISO as result
    var iso = _calc.resolveIso(aperture, shutter, ctx.evTarget);
    iso = iso.toNearestStandard();

    final (clampedIso, isoCompromises) = _clampIso(ctx, iso);
    iso = clampedIso;
    compromises.addAll(isoCompromises);

    return ExposureTriangleResult(
      aperture: aperture.toNearestStandard(),
      shutter: shutter.toNearestStandard(),
      iso: iso,
      compromises: compromises,
    );
  }

  // --- §8.2 Video ---
  ExposureTriangleResult _resolveVideo(EngineContext ctx) {
    final compromises = <Compromise>[];

    // 180° shutter angle rule: shutter = 1/(2 × fps)
    // Default 24fps → 1/50, 30fps → 1/60
    final shutterSeconds = 1.0 / 50; // assume 24fps default
    var shutter = ShutterSpeed(shutterSeconds);

    // Unless freeze_motion intent
    if (ctx.scene.intention == Intention.freezeMotion) {
      shutter = ctx.shutterMinEffective;
    }

    // Aperture from intention
    FStop aperture;
    if (ctx.scene.intention == Intention.bokeh) {
      aperture = ctx.maxApertureAtFocal;
    } else if (ctx.scene.intention == Intention.maxSharpness) {
      final sweetSpot = ctx.maxApertureAtFocal.value * 2.8;
      aperture = FStop(sweetSpot.clamp(ctx.maxApertureAtFocal.value, 11));
    } else {
      aperture = ctx.maxApertureAtFocal;
    }

    // ISO
    var iso = _calc.resolveIso(aperture, shutter, ctx.evTarget);
    // Video: lower usable max (×0.7)
    final videoUsableMax = (ctx.body.sensor.isoUsableMax * 0.7).round();
    iso = iso.toNearestStandard();

    if (iso.value > videoUsableMax) {
      compromises.add(Compromise(
        type: CompromiseType.noise,
        severity: CompromiseSeverity.warning,
        message:
            'ISO élevé pour la vidéo. Le bruit est plus visible en vidéo qu\'en photo.',
        affectedSettings: ['iso'],
      ));
    }

    final (clampedIso, isoCompromises) = _clampIso(ctx, iso);
    iso = clampedIso;
    compromises.addAll(isoCompromises);

    return ExposureTriangleResult(
      aperture: aperture.toNearestStandard(),
      shutter: shutter.toNearestStandard(),
      iso: iso,
      compromises: compromises,
    );
  }

  // --- Helpers ---

  (IsoValue, List<Compromise>) _clampIso(EngineContext ctx, IsoValue iso) {
    final compromises = <Compromise>[];
    var value = iso.value;

    if (value > ctx.body.sensor.isoMax) {
      compromises.add(Compromise(
        type: CompromiseType.noise,
        severity: CompromiseSeverity.critical,
        message:
            'Pas assez de lumière même avec les réglages les plus extrêmes. '
            'ISO ${ctx.body.sensor.isoMax} max atteint.',
        affectedSettings: ['iso'],
        suggestion:
            'Trépied (vitesse plus lente), flash, ou objectif plus lumineux.',
      ));
      value = ctx.body.sensor.isoMax;
    } else if (value > ctx.body.sensor.isoUsableMax) {
      compromises.add(Compromise(
        type: CompromiseType.noise,
        severity: CompromiseSeverity.warning,
        message:
            'ISO élevé nécessaire. Bruit visible mais acceptable pour capturer la scène.',
        affectedSettings: ['iso'],
        suggestion: 'Shooter en RAW pour réduire le bruit en post.',
      ));
    }

    if (value < ctx.body.sensor.isoMin) {
      value = ctx.body.sensor.isoMin;
    }

    return (IsoValue(value).toNearestStandard(), compromises);
  }
}
