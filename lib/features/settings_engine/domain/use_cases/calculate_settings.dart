import '../../../../shared/domain/entities/body_spec.dart';
import '../../../../shared/domain/entities/lens_spec.dart';
import '../../../../shared/domain/entities/scene_input.dart';
import '../../../../shared/domain/entities/settings_result.dart';
import '../engine/settings_engine.dart';

/// Use case: calculate optimal camera settings for a scene.
/// Single responsibility: delegates to SettingsEngine.
class CalculateSettings {
  final SettingsEngine _engine;

  const CalculateSettings({SettingsEngine engine = const SettingsEngine()})
      : _engine = engine;

  SettingsResult call({
    required BodySpec body,
    required LensSpec lens,
    required SceneInput scene,
  }) {
    return _engine.calculate(body, lens, scene);
  }
}
