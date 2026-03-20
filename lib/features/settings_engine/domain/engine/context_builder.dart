import 'dart:math';

import '../../../../shared/domain/entities/body_spec.dart';
import '../../../../shared/domain/entities/lens_spec.dart';
import '../../../../shared/domain/entities/scene_input.dart';
import '../../../../shared/domain/enums/shooting_enums.dart';
import '../../../../shared/domain/value_objects/f_stop.dart';
import '../../../../shared/domain/value_objects/shutter_speed.dart';
import '../entities/engine_context.dart';
import 'astro_calculator.dart';

/// Builds EngineContext from raw inputs (Phase 1 of the pipeline).
/// Skill 06 §3: resolves focal, aperture, EV, and minimum shutter speeds.
class ContextBuilder {
  final AstroCalculator _astro;

  const ContextBuilder({AstroCalculator astro = const AstroCalculator()})
      : _astro = astro;

  EngineContext build(
    BodySpec body,
    LensSpec lens,
    SceneInput scene, {
    double filterLightLossStops = 0,
  }) {
    final focalMm = _chooseFocal(lens, scene);
    final focalEq = focalMm * body.cropFactor;
    final maxAp = FStop(lens.aperture.maxApertureAtFocal(focalMm));
    // Filter reduces available light → subtract from EV target
    final evTarget = _resolveEv(scene) - filterLightLossStops;
    final shutterSafe = _shutterMinSafe(body, lens, scene, focalEq);
    final shutterSubject = _shutterMinSubject(scene, body, focalMm, maxAp);
    // Pick the MORE restrictive (faster = smaller seconds value)
    var shutterEffective = shutterSafe.seconds < shutterSubject.seconds
        ? shutterSafe
        : shutterSubject;

    // User constraint override
    if (scene.constraintShutterMin != null) {
      final constraint = _parseShutterString(scene.constraintShutterMin!);
      if (constraint.seconds < shutterEffective.seconds) {
        shutterEffective = constraint;
      }
    }

    return EngineContext(
      body: body,
      lens: lens,
      scene: scene,
      focalMm: focalMm,
      focalEquivalentMm: focalEq,
      maxApertureAtFocal: maxAp,
      evTarget: evTarget,
      shutterMinSafe: shutterSafe,
      shutterMinSubject: shutterSubject,
      shutterMinEffective: shutterEffective,
      filterLightLossStops: filterLightLossStops,
    );
  }

  // --- §3.1 Focal length ---

  int _chooseFocal(LensSpec lens, SceneInput scene) {
    if (lens.focalLength.isPrime) return lens.focalLength.minMm;

    final minF = lens.focalLength.minMm;
    final maxF = lens.focalLength.maxMm;
    final mid = ((minF + maxF) / 2).round();

    switch (scene.subject) {
      case Subject.landscape:
      case Subject.architecture:
      case Subject.astro:
      case Subject.realEstate:
      case Subject.aurora:
      case Subject.nightCityscape:
      case Subject.droneAerial:
        return minF;
      case Subject.portrait:
      case Subject.selfPortrait:
      case Subject.wedding:
        return min(maxF, (85 / 1.5).round()); // ~85mm eq / crop
      case Subject.street:
      case Subject.event:
        return min(max(minF, (35 / 1.5).round()), maxF); // ~35mm eq
      case Subject.macro:
      case Subject.sport:
      case Subject.wildlife:
      case Subject.concert:
        return maxF;
      case Subject.product:
      case Subject.food:
        return mid;
      case Subject.lightning:
      case Subject.fireworks:
      case Subject.starTrails:
        return minF; // wide for sky
      case Subject.underwater:
      case Subject.pet:
        return mid;
    }
  }

  // --- §3.3 EV target ---

  double _resolveEv(SceneInput scene) {
    double ev;

    // Level 2: precise light condition
    if (scene.lightCondition != null) {
      ev = _evFromLightCondition(scene.lightCondition!);
    } else {
      // Level 1: derive from environment
      ev = _evFromEnvironment(scene.environment);
    }

    // Mood adjustments
    if (scene.mood != null) {
      ev += _evMoodAdjustment(scene.mood!);
    }

    return ev;
  }

  double _evFromLightCondition(LightCondition lc) {
    switch (lc) {
      case LightCondition.directSun:
        return 15;
      case LightCondition.shade:
        return 12;
      case LightCondition.overcast:
        return 13;
      case LightCondition.goldenHour:
        return 11; // average of 10-12
      case LightCondition.blueHour:
        return 6.5; // average of 5-8
      case LightCondition.starryNight:
        return -3; // average of -4 to -2
      case LightCondition.neon:
        return 8.5;
      case LightCondition.tungsten:
        return 7.5;
      case LightCondition.led:
        return 8.5;
      case LightCondition.mixedLighting:
        return 9; // interior with window
      case LightCondition.backlit:
        return 14; // bright behind subject
      case LightCondition.harshMidday:
        return 16; // hard midday sun
      case LightCondition.diffused:
        return 13.5; // thin clouds
      case LightCondition.candlelight:
        return 4; // very dim, warm
      case LightCondition.stageLighting:
        return 7; // colored spots
      case LightCondition.moonlight:
        return -1; // ~EV -2 to 0
    }
  }

  double _evFromEnvironment(Environment env) {
    switch (env) {
      case Environment.outdoorDay:
        return 14;
      case Environment.outdoorNight:
        return 4;
      case Environment.indoorBright:
        return 9;
      case Environment.indoorDark:
        return 6;
      case Environment.studio:
        return 11;
    }
  }

  double _evMoodAdjustment(Mood mood) {
    switch (mood) {
      case Mood.silhouette:
        return -2;
      case Mood.dramatic:
        return -0.5;
      case Mood.soft:
        return 0.3;
      case Mood.highContrast:
      case Mood.natural:
        return 0;
    }
  }

  // --- §3.4 Shutter min safe (camera shake) ---

  ShutterSpeed _shutterMinSafe(
    BodySpec body,
    LensSpec lens,
    SceneInput scene,
    double focalEq,
  ) {
    final support = scene.support ?? Support.handheld;

    switch (support) {
      case Support.tripod:
        return const ShutterSpeed(30); // no limit
      case Support.gimbal:
        return ShutterSpeed.fraction(30); // 1/30s
      case Support.monopod:
        return ShutterSpeed(1 / (focalEq * 0.5));
      case Support.handheld:
        final base = 1 / focalEq;
        final ibisStops =
            body.stabilization.hasIbis ? body.stabilization.ibisStops : 0.0;
        final oisStops =
            lens.stabilization.hasOis ? lens.stabilization.oisStops : 0.0;
        final totalStab = max(ibisStops, oisStops);
        var safe = base / pow(2, totalStab);
        // Clamp: never below 1/15s handheld
        safe = max(safe, 1 / 15);
        return ShutterSpeed(safe);
    }
  }

  // --- §3.5 Shutter min subject ---

  ShutterSpeed _shutterMinSubject(
    SceneInput scene,
    BodySpec body,
    int focalMm,
    FStop aperture,
  ) {
    // Special cases by subject
    if (scene.subject == Subject.astro || scene.subject == Subject.aurora) {
      return _astro.maxExposureTime(
        aperture: aperture,
        sensor: body.sensor,
        focalMm: focalMm,
      );
    }
    if (scene.subject == Subject.starTrails) {
      return const ShutterSpeed(30); // BULB / long exposure stacking
    }
    if (scene.subject == Subject.fireworks) {
      return const ShutterSpeed(4); // ~2-4s typical
    }
    if (scene.subject == Subject.lightning) {
      return const ShutterSpeed(15); // long exposure to catch bolt
    }
    if (scene.subject == Subject.nightCityscape) {
      return const ShutterSpeed(30); // tripod long exposure
    }
    if (scene.subject == Subject.macro &&
        (scene.support == null || scene.support == Support.handheld)) {
      return ShutterSpeed.fraction(250);
    }
    if (scene.subject == Subject.food) {
      return ShutterSpeed.fraction(125);
    }
    if ((scene.subject == Subject.sport ||
            scene.subject == Subject.concert) &&
        scene.subjectMotion == null) {
      return ShutterSpeed.fraction(500);
    }
    if (scene.subject == Subject.pet && scene.subjectMotion == null) {
      return ShutterSpeed.fraction(250); // unpredictable movement
    }
    if (scene.subject == Subject.wedding ||
        scene.subject == Subject.event) {
      return ShutterSpeed.fraction(125);
    }
    if (scene.subject == Subject.droneAerial) {
      return ShutterSpeed.fraction(250);
    }

    // From subject motion
    if (scene.subjectMotion != null) {
      switch (scene.subjectMotion!) {
        case SubjectMotion.still:
          return const ShutterSpeed(30); // no constraint
        case SubjectMotion.slow:
          return ShutterSpeed.fraction(125);
        case SubjectMotion.fast:
          return ShutterSpeed.fraction(500);
        case SubjectMotion.veryFast:
          return ShutterSpeed.fraction(1000);
      }
    }

    return const ShutterSpeed(30); // no constraint
  }

  ShutterSpeed _parseShutterString(String s) {
    if (s.startsWith('1/')) {
      final denom = int.tryParse(s.substring(2));
      if (denom != null && denom > 0) return ShutterSpeed.fraction(denom);
    }
    final secs = double.tryParse(s);
    if (secs != null && secs > 0) return ShutterSpeed(secs);
    return const ShutterSpeed(30);
  }
}
