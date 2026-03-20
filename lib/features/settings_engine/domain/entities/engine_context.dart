import '../../../../shared/domain/entities/body_spec.dart';
import '../../../../shared/domain/entities/lens_spec.dart';
import '../../../../shared/domain/entities/scene_input.dart';
import '../../../../shared/domain/value_objects/f_stop.dart';
import '../../../../shared/domain/value_objects/shutter_speed.dart';

/// Bundles all inputs + derived values for the engine pipeline.
/// Built in Phase 1 of the engine, consumed by Phases 2-4.
class EngineContext {
  final BodySpec body;
  final LensSpec lens;
  final SceneInput scene;

  // Derived in Phase 1
  final int focalMm;
  final double focalEquivalentMm;
  final FStop maxApertureAtFocal;
  final double evTarget;
  final ShutterSpeed shutterMinSafe;
  final ShutterSpeed shutterMinSubject;
  final ShutterSpeed shutterMinEffective;

  /// Light loss from optical filter (ND, CPL) in stops. 0 = no filter.
  final double filterLightLossStops;

  const EngineContext({
    required this.body,
    required this.lens,
    required this.scene,
    required this.focalMm,
    required this.focalEquivalentMm,
    required this.maxApertureAtFocal,
    required this.evTarget,
    required this.shutterMinSafe,
    required this.shutterMinSubject,
    required this.shutterMinEffective,
    this.filterLightLossStops = 0,
  });
}
